*** Settings ***
Documentation    Mots-clés de pilotage de l'interface Angular, avec la bibliothèque Browser (Playwright).
...
...              Principe des *page objects* : les tests décrivent ce que fait l'utilisateur
...              (`Create Post From Form`, `Success Message Should Be`...) ; seul ce fichier
...              connaît la structure HTML des pages. Si le HTML change, ce sont les sélecteurs
...              de la section *** Variables *** qu'il faut mettre à jour. Seule exception : les
...              champs de formulaire, trouvés par leur nom (``title``, ``body``...) dans
...              `Fill Post Form` et `Field Error Should Be`, car Angular génère leur ``id``.
...
...              Les textes attendus ne sont jamais recopiés : ils viennent des traductions de
...              l'application (mot-clé `Text` de ``web_app.resource``).
...
...              Les mots-clés ``Get Text``, ``Get Element Count``... de Browser vérifient et
...              *attendent* en même temps : ``Get Text    css=h1    ==    Leanne Graham`` réessaie
...              jusqu'à ``\${UI_TIMEOUT}``, le temps qu'Angular reçoive la réponse de l'API.
...              Aucune pause fixe (``Sleep``) n'est donc nécessaire.

Variables        ../variables/web.py
Library          Browser    timeout=${UI_TIMEOUT}
Resource         web_app.resource


*** Variables ***
# ---------- Sélecteurs (seul endroit qui dépend du HTML des pages) ----------
${NAVIGATION}             css=header nav
${LANGUAGE_SELECT}        css=header select
${PAGE_TITLE}             css=main h1
${SUBTITLE}               css=main .card-head .muted
${WRITE_STATUS}           css=main [role=status]
${SUCCESS_MESSAGE}        ${WRITE_STATUS} > p >> nth=0
${SIMULATED_NOTICE}       ${WRITE_STATUS} .notice
${ERROR_ALERT}            css=main p[role=alert]
${USER_ROWS}              css=main table tbody tr
${USER_SEARCH}            css=main input[type=search]
${EMPTY_TABLE_MESSAGE}    css=main table tbody td.muted
${GOTO_USER_INPUT}        id=goto-users
${GOTO_USER_BUTTON}       css=form:has(#goto-users) button[type=submit]
${LIST_ROWS}              css=main ul.rows > li
${ADD_BUTTON}             css=main .card-head > button
${FORM}                   css=main form.form
${FORM_SUBMIT}            ${FORM} >> css=button[type=submit]
${CARD_ACTIONS}           css=main .card-head .inline
${CONFIRM_GROUP}          css=main .confirm-inline
${CONFIRM_QUESTION}       ${CONFIRM_GROUP} > span >> nth=0
${REPORT_STATS}           css=main .stat .stat-value


*** Keywords ***
# =====================================================================
# 1. Navigateur
# =====================================================================

Open Test Browser
    [Documentation]    Ouvre la fenêtre du navigateur une fois par suite. Elle est visible par
    ...    défaut ; ``HEADLESS=True`` la masque (intégration continue).
    ...    ``\${BROWSER_CHANNEL}`` choisit un navigateur installé (Edge par défaut sous Windows).
    ...
    ...    Fenêtre visible : chaque action est ralentie de ``\${SLOW_MO}`` pour qu'on puisse
    ...    suivre les changements. Fenêtre masquée : pas de ralentissement.
    ${visible}=    Browser Window Is Visible
    ${slow_mo}=    Set Variable If    ${visible}    ${SLOW_MO}    0s
    New Browser    ${BROWSER}    headless=${{ not $visible }}    channel=${BROWSER_CHANNEL}
    ...    slowMo=${slow_mo}

Open Application
    [Documentation]    Ouvre l'application dans un contexte neuf, pour chaque test.
    ...
    ...    Un contexte Playwright est un profil de navigateur vierge : pas de cookies ni de
    ...    ``localStorage`` (où l'application mémorise la langue). Chaque test démarre donc
    ...    dans le même état, quel que soit l'ordre d'exécution.
    New Context    locale=fr-FR    viewport={'width': 1280, 'height': 900}
    New Page    ${WEB_URL}
    Wait For Elements State    ${NAVIGATION}    visible

Close Application
    [Documentation]    Ferme le contexte du test (et ses pages). Fenêtre visible : attend
    ...    d'abord ``\${PAUSE_AFTER_TEST}``, pour voir le résultat du test avant la fermeture.
    ${visible}=    Browser Window Is Visible
    IF    ${visible}
        Sleep    ${PAUSE_AFTER_TEST}    Temps d'observation du résultat
    END
    Close Context

Browser Window Is Visible
    [Documentation]    Vrai si la fenêtre du navigateur est affichée (``HEADLESS`` faux).
    ...    ``--variable HEADLESS:True`` donne le texte "True" : il est converti en booléen.
    [Tags]    robot:private
    ${headless}=    Convert To Boolean    ${HEADLESS}
    RETURN    ${{ not $headless }}

Close Test Browser
    [Documentation]    Ferme le navigateur à la fin de la suite.
    Close Browser    ALL

# =====================================================================
# 2. Navigation
# =====================================================================

Go To Users Page
    [Documentation]    Ouvre la liste des utilisateurs.
    Go To    ${WEB_URL}/users
    ${title}=    Text    nav_users
    Page Title Should Be    ${title}

Go To User Page
    [Documentation]    Ouvre directement la fiche d'un utilisateur par son adresse.
    [Arguments]    ${user_id}
    Go To    ${WEB_URL}/users/${user_id}

Go To User Report Page
    [Documentation]    Ouvre le rapport d'un utilisateur.
    [Arguments]    ${user_id}
    Go To    ${WEB_URL}/users/${user_id}/report

Go To Posts Page
    [Documentation]    Ouvre la liste de tous les posts.
    Go To    ${WEB_URL}/posts
    ${title}=    Text    res_posts
    Page Title Should Be    ${title}

Go To Post Page
    [Documentation]    Ouvre directement la page d'un post par son adresse.
    [Arguments]    ${post_id}
    Go To    ${WEB_URL}/posts/${post_id}

Switch Language To
    [Documentation]    Change la langue avec le sélecteur de l'en-tête (``Français``, ``English``).
    [Arguments]    ${language_name}
    Select Options By    ${LANGUAGE_SELECT}    label    ${language_name}

# =====================================================================
# 3. Actions sur les utilisateurs
# =====================================================================

Search Users
    [Documentation]    Saisit un terme dans la recherche (nom, email ou ville).
    [Arguments]    ${term}
    Fill Text    ${USER_SEARCH}    ${term}

Open User From List
    [Documentation]    Clique sur le nom d'un utilisateur dans la liste.
    [Arguments]    ${name}
    Click    ${USER_ROWS} >> text="${name}"

Open User By Id
    [Documentation]    Utilise le formulaire « Accès direct » de la page des utilisateurs.
    [Arguments]    ${user_id}
    Fill Text    ${GOTO_USER_INPUT}    ${user_id}
    Click    ${GOTO_USER_BUTTON}

# =====================================================================
# 4. Actions sur les posts
# =====================================================================

Open Post Creation Form
    [Documentation]    Clique sur « Ajouter » pour afficher le formulaire de création.
    Click    ${ADD_BUTTON}
    Wait For Elements State    ${FORM}    visible

Fill Post Form
    [Documentation]    Remplit le formulaire de post. Un argument vide laisse le champ inchangé ;
    ...    ``title=\${EMPTY}`` explicite permet de tester un champ obligatoire laissé vide.
    [Arguments]    ${user_id}=${None}    ${title}=${None}    ${body}=${None}
    IF    $user_id is not None
        # Playwright exige une chaîne : ${EXISTING_USER_ID} est un entier.
        ${option}=    Convert To String    ${user_id}
        Select Options By    ${FORM} >> css=select[id$="user_id"]    value    ${option}
    END
    IF    $title is not None
        Fill Text    ${FORM} >> css=input[id$="title"]    ${title}
    END
    IF    $body is not None
        Fill Text    ${FORM} >> css=textarea[id$="body"]    ${body}
    END

Submit Form
    [Documentation]    Valide le formulaire affiché (« Créer » ou « Enregistrer »).
    Click    ${FORM_SUBMIT}

Create Post From Form
    [Documentation]    Parcours complet de création d'un post depuis la page des posts.
    [Arguments]    ${user_id}    ${title}    ${body}
    Open Post Creation Form
    Fill Post Form    ${user_id}    ${title}    ${body}
    Submit Form

Edit Displayed Post
    [Documentation]    Sur la page d'un post : « Modifier », nouveau titre, « Enregistrer ».
    [Arguments]    ${new_title}
    ${edit}=    Text    action_edit
    Click    ${CARD_ACTIONS} >> text="${edit}"
    Fill Post Form    title=${new_title}
    Submit Form

Ask To Delete Displayed Post
    [Documentation]    Clique sur « Supprimer » : l'application demande une confirmation sur place.
    ${delete}=    Text    action_delete
    Click    ${CARD_ACTIONS} >> text="${delete}"
    ${question}=    Text    confirm_delete
    Get Text    ${CONFIRM_QUESTION}    ==    ${question}

Confirm Deletion
    [Documentation]    Confirme la suppression demandée par `Ask To Delete Displayed Post`.
    ${delete}=    Text    action_delete
    Click    ${CONFIRM_GROUP} >> text="${delete}"

Cancel Deletion
    [Documentation]    Annule la suppression demandée par `Ask To Delete Displayed Post`.
    ${cancel}=    Text    action_cancel
    Click    ${CONFIRM_GROUP} >> text="${cancel}"

# =====================================================================
# 5. Vérifications
# =====================================================================

Page Title Should Be
    [Documentation]    Vérifie le titre principal (``h1``) de la page.
    [Arguments]    ${expected}
    Get Text    ${PAGE_TITLE}    ==    ${expected}

Users Table Should Have Rows
    [Documentation]    Vérifie le nombre de lignes du tableau des utilisateurs.
    [Arguments]    ${count}
    Get Element Count    ${USER_ROWS}    ==    ${count}

Users Table Should Only Contain
    [Documentation]    Vérifie que le tableau ne contient qu'une ligne, celle de ``name``.
    [Arguments]    ${name}
    Users Table Should Have Rows    1
    Get Text    ${USER_ROWS}    *=    ${name}

Users Table Should Be Empty
    [Documentation]    Vérifie que le tableau affiche « Aucun résultat. ».
    ${message}=    Text    no_results
    Get Text    ${EMPTY_TABLE_MESSAGE}    ==    ${message}

User Page Should Show
    [Documentation]    Vérifie la fiche d'un utilisateur : nom en titre et pseudo ``@username``.
    [Arguments]    ${name}    ${username}
    Page Title Should Be    ${name}
    Get Text    ${SUBTITLE}    ==    @${username}

Listed Items Should Be
    [Documentation]    Vérifie le nombre d'éléments de la liste (posts, albums) affichée.
    [Arguments]    ${count}
    Get Element Count    ${LIST_ROWS}    ==    ${count}

Post Should Be Listed
    [Documentation]    Vérifie qu'un post de ce titre apparaît une fois dans la liste.
    [Arguments]    ${title}
    Get Element Count    ${LIST_ROWS} >> text="${title}"    ==    1

Success Message Should Be
    [Documentation]    Vérifie le message de réussite d'une écriture.
    [Arguments]    ${expected}
    Get Text    ${SUCCESS_MESSAGE}    ==    ${expected}

Simulated Write Notice Should Be Shown
    [Documentation]    Vérifie l'avertissement « Opération simulée par JSONPlaceholder... ».
    ${notice}=    Text    simulated_write
    Get Text    ${SIMULATED_NOTICE}    ==    ${notice}

No Write Message Should Be Shown
    [Documentation]    Vérifie qu'aucun message de réussite n'est affiché.
    Get Element Count    ${WRITE_STATUS}    ==    0

Error Alert Should Be
    [Documentation]    Vérifie le message d'erreur général de la page.
    [Arguments]    ${expected}
    Get Text    ${ERROR_ALERT}    ==    ${expected}

Field Error Should Be
    [Documentation]    Vérifie l'erreur affichée sous un champ du formulaire, et que le champ
    ...    est signalé invalide aux technologies d'assistance (``aria-invalid="true"``).
    [Arguments]    ${field}    ${expected}
    Get Text    ${FORM} >> css=.field:has([id$="${field}"]) .field-error    ==    ${expected}
    Get Attribute    ${FORM} >> css=[id$="${field}"]    aria-invalid    ==    true

Navigation Should Contain
    [Documentation]    Vérifie qu'un libellé figure dans le menu de navigation.
    [Arguments]    ${label}
    Get Text    ${NAVIGATION}    *=    ${label}

Report Should Show Counts
    [Documentation]    Vérifie les compteurs du rapport utilisateur : posts, puis commentaires.
    [Arguments]    ${post_count}    ${comment_count}
    Get Text    ${REPORT_STATS} >> nth=0    ==    ${post_count}
    Get Text    ${REPORT_STATS} >> nth=1    ==    ${comment_count}

Invalid User Id Should Show Error
    [Documentation]    Saisit un identifiant dans « Accès direct » et vérifie le message affiché.
    ...    Conçu pour être utilisé comme ``[Template]`` (identifiant, clé de traduction).
    [Arguments]    ${user_id}    ${expected_key}
    Go To Users Page
    Open User By Id    ${user_id}
    ${message}=    Text    ${expected_key}    value=${user_id}
    Error Alert Should Be    ${message}
