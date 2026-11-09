*** Settings ***
Documentation    PAGE « Utilisateurs » (adresse : /users) : tableau des utilisateurs,
...              recherche, et formulaire « Accès direct » par identifiant.

Resource         ../common.resource


*** Variables ***
# Sélecteurs propres à cette page
${USER_ROWS}              css=main table tbody tr
${USER_SEARCH}            css=main input[type=search]
${EMPTY_TABLE_MESSAGE}    css=main table tbody td.muted
${GOTO_USER_INPUT}        id=goto-users
${GOTO_USER_BUTTON}       css=form:has(#goto-users) button[type=submit]


*** Keywords ***
# ---------- Aller sur la page ----------

Go To Users Page
    [Documentation]    Ouvre la page des utilisateurs et vérifie son titre.
    Go To    ${WEB_URL}/users
    ${title}=    Text    nav_users
    Page Title Should Be    ${title}

# ---------- Actions ----------

Search Users
    [Documentation]    Tape un mot dans la recherche (nom, email ou ville).
    [Arguments]    ${term}
    Fill Text    ${USER_SEARCH}    ${term}

Open User From List
    [Documentation]    Clique sur le nom d'un utilisateur dans le tableau.
    [Arguments]    ${name}
    Click    ${USER_ROWS} >> text="${name}"

Open User By Id
    [Documentation]    Tape un identifiant dans « Accès direct » et valide.
    [Arguments]    ${user_id}
    Fill Text    ${GOTO_USER_INPUT}    ${user_id}
    Click    ${GOTO_USER_BUTTON}

# ---------- Vérifications ----------

Users Table Should Have Rows
    [Documentation]    Vérifie le nombre de lignes du tableau.
    [Arguments]    ${count}
    Get Element Count    ${USER_ROWS}    ==    ${count}

Users Table Should Only Contain
    [Documentation]    Vérifie que le tableau n'a qu'une ligne, celle de ``name``.
    [Arguments]    ${name}
    Users Table Should Have Rows    1
    Get Text    ${USER_ROWS}    *=    ${name}

Users Table Should Be Empty
    [Documentation]    Vérifie que le tableau affiche « Aucun résultat. ».
    ${message}=    Text    no_results
    Get Text    ${EMPTY_TABLE_MESSAGE}    ==    ${message}

Invalid User Id Should Show Error
    [Documentation]    Tape un identifiant invalide dans « Accès direct » et vérifie le message.
    ...    Prévu pour un ``[Template]`` : une ligne (identifiant, clé du message) par cas.
    [Arguments]    ${user_id}    ${expected_key}
    Go To Users Page
    Open User By Id    ${user_id}
    ${message}=    Text    ${expected_key}    value=${user_id}
    Error Alert Should Be    ${message}
