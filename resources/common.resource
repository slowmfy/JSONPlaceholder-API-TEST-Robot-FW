*** Settings ***
Documentation    COMMUN : le navigateur, et ce qui existe sur TOUTES les pages de l'application
...              (menu, titre, messages, formulaire).
...
...              Les fichiers de ``pages/`` importent ce fichier : un test qui importe une page
...              a donc aussi accès à tous les mots-clés ci-dessous.
...
...              Bon à savoir : ``Get Text    css=h1    ==    Leanne Graham`` *attend* que le texte
...              soit le bon (jusqu'à ``\${UI_TIMEOUT}``). Pas besoin de ``Sleep`` dans les tests.

# L'ordre compte : config.py d'abord, car Browser utilise ${UI_TIMEOUT} qu'il définit.
Variables        ../variables/config.py
Library          Browser    timeout=${UI_TIMEOUT}
Resource         application.resource


*** Variables ***
# ---------- Sélecteurs : comment Playwright trouve les éléments dans la page ----------
# css=...  sélecteur CSS     id=...  attribut id     >>  « à l'intérieur de »
${NAVIGATION}          css=header nav
${LANGUAGE_SELECT}     css=header select
${PAGE_TITLE}          css=main h1
${ERROR_ALERT}         css=main p[role=alert]
${WRITE_STATUS}        css=main [role=status]
${SUCCESS_MESSAGE}     ${WRITE_STATUS} > p >> nth=0
${SIMULATED_NOTICE}    ${WRITE_STATUS} .notice
${LIST_ROWS}           css=main ul.rows > li
${FORM}                css=main form.form
${FORM_SUBMIT}         ${FORM} >> css=button[type=submit]


*** Keywords ***
# =====================================================================
# 1. Navigateur : ouvrir / fermer
# =====================================================================

Open Test Browser
    [Documentation]    Ouvre le navigateur, une fois au début de chaque fichier de tests.
    ...    Fenêtre visible par défaut (ralentie de ``\${SLOW_MO}``) ; ``HEADLESS=True`` la masque.
    ${visible}=    Browser Window Is Visible
    ${slow_mo}=    Set Variable If    ${visible}    ${SLOW_MO}    0s
    New Browser    ${BROWSER}    headless=${{ not $visible }}    channel=${BROWSER_CHANNEL}
    ...    slowMo=${slow_mo}

Open Application
    [Documentation]    Ouvre l'application dans un profil de navigateur neuf, avant chaque test.
    ...    Neuf = sans cookies ni mémoire : aucun test ne dépend du précédent.
    New Context    locale=fr-FR    viewport={'width': 1280, 'height': 900}
    New Page    ${WEB_URL}
    Wait For Elements State    ${NAVIGATION}    visible

Close Application
    [Documentation]    Ferme le profil du test. Fenêtre visible : attend d'abord
    ...    ``\${PAUSE_AFTER_TEST}`` pour qu'on voie le résultat.
    ${visible}=    Browser Window Is Visible
    IF    ${visible}
        Sleep    ${PAUSE_AFTER_TEST}    Temps d'observation du résultat
    END
    Close Context

Close Test Browser
    [Documentation]    Ferme le navigateur, à la fin de chaque fichier de tests.
    Close Browser    ALL

Browser Window Is Visible
    [Documentation]    Vrai si la fenêtre est affichée. ``--variable HEADLESS:True`` donne le
    ...    texte "True" : il est converti en booléen.
    [Tags]    robot:private
    ${headless}=    Convert To Boolean    ${HEADLESS}
    RETURN    ${{ not $headless }}

# =====================================================================
# 2. Actions communes
# =====================================================================

Switch Language To
    [Documentation]    Change la langue avec le menu de l'en-tête (``Français``, ``English``).
    [Arguments]    ${language_name}
    Select Options By    ${LANGUAGE_SELECT}    label    ${language_name}

Fill Post Form
    [Documentation]    Remplit le formulaire d'un post. Un argument non donné laisse le champ tel quel ;
    ...    ``title=\${EMPTY}`` vide le champ (pour tester un champ obligatoire).
    ...    Les champs sont trouvés par la fin de leur ``id`` (``$=``), car Angular génère le début.
    [Arguments]    ${user_id}=${None}    ${title}=${None}    ${body}=${None}
    IF    $user_id is not None
        # Playwright attend du texte : ${EXISTING_USER_ID} est un nombre.
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
    [Documentation]    Valide le formulaire affiché (bouton « Créer » ou « Enregistrer »).
    Click    ${FORM_SUBMIT}

# =====================================================================
# 3. Vérifications communes
# =====================================================================

Page Title Should Be
    [Documentation]    Vérifie le grand titre (``h1``) de la page.
    [Arguments]    ${expected}
    Get Text    ${PAGE_TITLE}    ==    ${expected}

Navigation Should Contain
    [Documentation]    Vérifie qu'un libellé figure dans le menu du haut.
    [Arguments]    ${label}
    Get Text    ${NAVIGATION}    *=    ${label}

Listed Items Should Be
    [Documentation]    Vérifie le nombre d'éléments de la liste affichée (posts, albums...).
    [Arguments]    ${count}
    Get Element Count    ${LIST_ROWS}    ==    ${count}

Success Message Should Be
    [Documentation]    Vérifie le message vert affiché après une création / modification / suppression.
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
    [Documentation]    Vérifie le message d'erreur rouge de la page.
    [Arguments]    ${expected}
    Get Text    ${ERROR_ALERT}    ==    ${expected}

Field Error Should Be
    [Documentation]    Vérifie l'erreur affichée sous un champ du formulaire, et que le champ
    ...    est marqué invalide (``aria-invalid="true"``).
    [Arguments]    ${field}    ${expected}
    Get Text    ${FORM} >> css=.field:has([id$="${field}"]) .field-error    ==    ${expected}
    Get Attribute    ${FORM} >> css=[id$="${field}"]    aria-invalid    ==    true
