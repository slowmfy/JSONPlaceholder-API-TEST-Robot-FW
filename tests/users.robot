*** Settings ***
Documentation     Scénarios de la ressource ``/users``.
...
...               Les tests n'utilisent que des actions et vérifications métier de
...               ``api.resource`` : aucune URL ni requête HTTP n'apparaît ici.

Resource          ../resources/api.resource

Suite Setup       Open API Session
Suite Teardown    Close API Sessions

Test Tags         jsonplaceholder    users


*** Test Cases ***
Récupérer tous les utilisateurs
    [Documentation]    L'API renvoie les 10 utilisateurs de référence, tous complets.
    [Tags]    nominal    smoke
    ${users}=    Get All Users
    Number Of Items Should Be    ${users}    ${USERS_COUNT}    utilisateurs
    Every User Should Be Valid    ${users}

Récupérer un utilisateur existant
    [Documentation]    L'utilisateur 1 est renvoyé avec son identité et tous ses champs.
    [Tags]    nominal    smoke
    ${user}=    Get User    ${EXISTING_USER_ID}
    User Should Be Valid    ${user}
    User Should Be    ${user}
    ...    id=${EXISTING_USER_ID}
    ...    name=${EXISTING_USER_NAME}
    ...    username=${EXISTING_USER_USERNAME}
    ...    email=${EXISTING_USER_EMAIL}

Rechercher un utilisateur inexistant
    [Documentation]    Un identifiant hors du jeu de données renvoie 404 et un corps vide.
    [Tags]    erreur    ressource-inexistante
    ${body}=    Get User    ${UNKNOWN_USER_ID}    expected_status=404
    Response Body Should Be Empty    ${body}
