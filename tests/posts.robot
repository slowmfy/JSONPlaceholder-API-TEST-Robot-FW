*** Settings ***
Documentation     Scénarios de la ressource ``/posts`` : lecture, création, modification, suppression.
...
...               JSONPlaceholder simule les écritures : il renvoie la réponse attendue mais
...               ne conserve rien. Chaque test est donc indépendant des autres et peut être
...               lancé seul ou dans n'importe quel ordre.

Resource          ../resources/api.resource

Suite Setup       Open API Session
Suite Teardown    Close API Sessions

Test Tags         jsonplaceholder    posts


*** Test Cases ***
Lister les posts d'un utilisateur
    [Documentation]    Le filtre ``userId`` renvoie les 10 posts de l'utilisateur, et seulement les siens.
    [Tags]    nominal    smoke
    ${posts}=    Get User Posts    ${EXISTING_USER_ID}
    Number Of Items Should Be    ${posts}    ${POSTS_PER_USER}    posts
    Every Post Should Belong To User    ${posts}    ${EXISTING_USER_ID}

Lister les posts d'un utilisateur inexistant
    [Documentation]    Un filtre ne trouvant rien renvoie 200 et une liste vide, pas une erreur 404.
    [Tags]    cas-limite
    ${posts}=    Get User Posts    ${UNKNOWN_USER_ID}
    Response Body Should Be Empty    ${posts}

Créer un post
    [Documentation]    La création renvoie 201 et le post envoyé, complété par son nouvel identifiant.
    [Tags]    nominal    smoke
    ${post}=    Create Post    ${EXISTING_USER_ID}    ${NEW_POST_TITLE}    ${NEW_POST_BODY}
    Post Should Contain    ${post}    ${EXISTING_USER_ID}    ${NEW_POST_TITLE}    ${NEW_POST_BODY}
    Should Be Equal As Integers    ${post}[id]    ${CREATED_POST_ID}

Modifier un post
    [Documentation]    PUT remplace le post : la réponse contient les nouvelles valeurs et garde l'identifiant.
    [Tags]    nominal
    ${post}=    Update Post    ${EXISTING_POST_ID}    ${EXISTING_USER_ID}
    ...    ${UPDATED_POST_TITLE}    ${UPDATED_POST_BODY}
    Post Should Contain    ${post}    ${EXISTING_USER_ID}    ${UPDATED_POST_TITLE}    ${UPDATED_POST_BODY}
    Should Be Equal As Integers    ${post}[id]    ${EXISTING_POST_ID}

Supprimer un post
    [Documentation]    La suppression d'un post existant renvoie 200 et un corps vide.
    [Tags]    nominal
    ${body}=    Delete Post    ${EXISTING_POST_ID}
    Response Body Should Be Empty    ${body}

Un post créé n'est pas conservé par l'API
    [Documentation]    Limite connue de JSONPlaceholder : le post 101 renvoyé par la création
    ...    n'existe pas réellement. Ce test documente ce comportement : s'il échoue un jour,
    ...    c'est que l'API conserve désormais les écritures et que d'autres tests sont à revoir.
    [Tags]    limite-api
    ${post}=    Create Post    ${EXISTING_USER_ID}    ${NEW_POST_TITLE}    ${NEW_POST_BODY}
    ${body}=    Get Post    ${post}[id]    expected_status=404
    Response Body Should Be Empty    ${body}
