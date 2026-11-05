*** Settings ***
Documentation     Interface web : affichage des erreurs à l'utilisateur.
...
...               Les tests vérifient le message *vu par l'utilisateur*, traduit, et non
...               le code HTTP : c'est ce qui distingue un test d'interface d'un test d'API.

Resource          ../../resources/web_ui.resource
Variables         ../../variables/environment.py

Suite Setup       Open Test Browser
Suite Teardown    Close Test Browser
Test Setup        Open Application
Test Teardown     Close Application

Test Tags         ui    erreur


*** Test Cases ***
Identifiant invalide
    [Documentation]    « Accès direct » avec un identifiant invalide : le message explique l'erreur
    ...    (« « abc » n'est pas un nombre entier. », « L'identifiant doit être strictement positif. »).
    [Tags]    identifiant-invalide    users
    [Template]    Invalid User Id Should Show Error
    FOR    ${user_id}    ${expected_key}    IN    &{INVALID_WEB_IDS}
        ${user_id}    ${expected_key}
    END

Utilisateur inexistant
    [Documentation]    La fiche d'un utilisateur inconnu affiche « Utilisateur 999 introuvable. ».
    [Tags]    ressource-inexistante    users
    Go To User Page    ${UNKNOWN_USER_ID}
    ${message}=    Text    user_not_found    id=${UNKNOWN_USER_ID}
    Error Alert Should Be    ${message}

Post inexistant
    [Documentation]    La page d'un post inconnu affiche « Post 9999 introuvable. ».
    [Tags]    ressource-inexistante    posts
    Go To Post Page    ${UNKNOWN_POST_ID}
    ${message}=    Text    post_not_found    id=${UNKNOWN_POST_ID}
    Error Alert Should Be    ${message}

Créer un post sans titre
    [Documentation]    Le titre est obligatoire : l'erreur s'affiche sous le champ, qui est
    ...    signalé invalide, et aucun message de réussite n'apparaît.
    [Tags]    validation    posts
    Go To Posts Page
    Open Post Creation Form
    Fill Post Form    user_id=${EXISTING_USER_ID}    title=${EMPTY}    body=${NEW_POST_BODY}
    Submit Form
    ${message}=    Text    error_required
    Field Error Should Be    title    ${message}
    No Write Message Should Be Shown
