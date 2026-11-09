*** Settings ***
Documentation     Messages d'erreur affichés à l'utilisateur.
...
...               On vérifie le message *vu à l'écran* (traduit), pas un code HTTP :
...               c'est la différence entre un test d'interface et un test d'API.

Resource          ../resources/pages/users_page.resource
Resource          ../resources/pages/user_detail_page.resource
Resource          ../resources/pages/posts_page.resource
Resource          ../resources/pages/post_detail_page.resource
Variables         ../variables/test_data.py

Suite Setup       Open Test Browser
Suite Teardown    Close Test Browser
Test Setup        Open Application
Test Teardown     Close Application

Test Tags         erreur


*** Test Cases ***
Identifiant invalide
    [Documentation]    « Accès direct » avec un identifiant invalide (abc, 0, -1) : un message
    ...    explique l'erreur. Test piloté par les données : le [Template] est exécuté une fois
    ...    par ligne de ``\${INVALID_USER_IDS}`` (fichier ``variables/test_data.py``).
    [Tags]    identifiant-invalide    users
    [Template]    Invalid User Id Should Show Error
    FOR    ${user_id}    ${expected_key}    IN    &{INVALID_USER_IDS}
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
    [Documentation]    Le titre est obligatoire : l'erreur s'affiche sous le champ et aucun
    ...    message de réussite n'apparaît.
    [Tags]    validation    posts
    Go To Posts Page
    Open Post Creation Form
    Fill Post Form    user_id=${EXISTING_USER_ID}    title=${EMPTY}    body=${NEW_POST_BODY}
    Submit Form
    ${message}=    Text    error_required
    Field Error Should Be    title    ${message}
    No Write Message Should Be Shown
