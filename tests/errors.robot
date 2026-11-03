*** Settings ***
Documentation     Cas d'erreur transverses : identifiant invalide, ressource inexistante, timeout.
...
...               Ces scénarios sont regroupés dans une suite à part pour pouvoir être lancés
...               ensemble (``robot --include erreur tests``) et pour que les suites ``users`` et
...               ``posts`` restent centrées sur le comportement nominal de chaque ressource.

Resource          ../resources/api.resource

Suite Setup       Open API Session
Suite Teardown    Close API Sessions

Test Tags         erreur


*** Test Cases ***
Identifiant invalide
    [Documentation]    Texte, zéro, négatif ou décimal : chaque identifiant invalide renvoie 404.
    ...    Test piloté par les données : ``[Template]`` exécute le mot-clé pour chaque valeur
    ...    de ``@{INVALID_IDS}`` et continue même si l'une d'elles échoue.
    [Tags]    identifiant-invalide    users
    [Template]    User Id Should Be Rejected
    FOR    ${invalid_id}    IN    @{INVALID_IDS}
        ${invalid_id}
    END

Ressource inexistante : post introuvable
    [Documentation]    Un post absent du jeu de données renvoie 404 et un corps vide.
    [Tags]    ressource-inexistante    posts
    ${body}=    Get Post    ${UNKNOWN_POST_ID}    expected_status=404
    Response Body Should Be Empty    ${body}

Ressource inexistante : route inconnue
    [Documentation]    Une ressource que l'API ne propose pas renvoie 404.
    [Tags]    ressource-inexistante
    ${body}=    Get Resource    ${UNKNOWN_RESOURCE}    expected_status=404
    Response Body Should Be Empty    ${body}

Ressource inexistante : modification d'un post introuvable
    [Documentation]    Limite connue de JSONPlaceholder : un PUT sur un post absent renvoie
    ...    500 (erreur interne, en HTML) au lieu de 404. Le client Python du projet précédent
    ...    vérifiait donc l'existence du post avant de le modifier.
    [Tags]    ressource-inexistante    limite-api    posts
    ${body}=    Update Post    ${UNKNOWN_POST_ID}    ${EXISTING_USER_ID}
    ...    ${UPDATED_POST_TITLE}    ${UPDATED_POST_BODY}    expected_status=500
    Should Contain    ${body}    TypeError

Ressource inexistante : suppression d'un post introuvable
    [Documentation]    Limite connue de JSONPlaceholder : un DELETE sur un post absent renvoie
    ...    200 comme s'il existait. Une suppression réussie ne prouve donc pas que le post existait.
    [Tags]    ressource-inexistante    limite-api    posts
    ${body}=    Delete Post    ${UNKNOWN_POST_ID}    expected_status=200
    Response Body Should Be Empty    ${body}

Timeout simulé
    [Documentation]    Une réponse qui n'arrive pas dans le délai imparti interrompt la requête.
    ...    Le délai est réduit à 1 ms sur une session dédiée : le timeout est réel,
    ...    déclenché par la bibliothèque requests, et non simulé par un faux serveur.
    [Tags]    timeout
    Request Should Time Out    /users
