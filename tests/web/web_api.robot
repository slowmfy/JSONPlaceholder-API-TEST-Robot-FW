*** Settings ***
Documentation     Scénarios de l'API web de l'application (``web_api.py``), celle qu'appelle l'interface.
...
...               Cette API se place entre l'interface et JSONPlaceholder : elle valide les saisies
...               et vérifie l'existence des ressources *avant* d'appeler JSONPlaceholder. Plusieurs
...               tests montrent qu'elle corrige les limites relevées dans ``tests/errors.robot``.

Resource          ../../resources/web_api.resource

Suite Setup       Open Web API Session
Suite Teardown    Delete All Sessions

Test Tags         web-api


*** Test Cases ***
Lister les langues de l'interface
    [Documentation]    L'interface est proposée en français et en anglais.
    [Tags]    nominal    smoke
    ${languages}=    Get Available Languages
    ${codes}=    Evaluate    [language["code"] for language in $languages]
    Should Be Equal    ${codes}    ${{ ["fr", "en"] }}

Rapport d'un utilisateur
    [Documentation]    Le rapport rassemble l'utilisateur, ses 10 posts et leurs 50 commentaires
    ...    (5 par post), calculés par l'application à partir de trois appels à JSONPlaceholder.
    [Tags]    nominal    smoke    users
    ${report}=    Get User Report    1
    Should Be Equal    ${report}[user][name]    Leanne Graham
    Should Be Equal As Integers    ${report}[post_count]    10
    Should Be Equal As Integers    ${report}[comment_count]    50
    Should Not Be Equal    ${report}[most_commented]    ${None}

Créer un post
    [Documentation]    La création renvoie 201, le post au format de l'application (``user_id``)
    ...    et l'indicateur ``simulated`` que l'interface affiche à l'utilisateur.
    [Tags]    nominal    posts
    ${result}=    Create Web Post    1    Titre    Contenu
    Should Be Equal As Integers    ${result}[item][id]    101
    Should Be Equal As Integers    ${result}[item][user_id]    1
    Write Should Be Simulated    ${result}

Identifiant invalide refusé avant l'appel à JSONPlaceholder
    [Documentation]    L'application refuse elle-même un identifiant mal formé (422) et précise
    ...    pourquoi, là où JSONPlaceholder renvoie un simple 404 (voir ``tests/errors.robot``).
    [Tags]    erreur    identifiant-invalide    users
    [Template]    Web User Id Should Be Rejected
    FOR    ${user_id}    ${expected_key}    IN    &{INVALID_WEB_IDS}
        ${user_id}    ${expected_key}
    END

Utilisateur inexistant
    [Documentation]    404 avec une clé propre à la ressource (``user_not_found``), pas générique.
    [Tags]    erreur    ressource-inexistante    users
    ${error}=    Get Web User    999    expected_status=404
    Error Should Be    ${error}    user_not_found    id=999

Créer un post sans titre
    [Documentation]    Le titre est obligatoire : 422 et le champ en faute, pour que l'interface
    ...    affiche l'erreur sous le bon champ du formulaire.
    [Tags]    erreur    validation    posts
    ${error}=    Create Web Post    1    ${EMPTY}    Contenu    expected_status=422
    Error Should Be    ${error}    error_required    field=title

Créer un post pour un auteur inexistant
    [Documentation]    L'auteur doit exister. JSONPlaceholder, lui, accepterait n'importe quel ``userId``.
    [Tags]    erreur    ressource-inexistante    posts
    ${error}=    Create Web Post    ${UNKNOWN_AUTHOR_ID}    Titre    Contenu    expected_status=404
    Error Should Be    ${error}    user_not_found    field=user_id    id=${UNKNOWN_AUTHOR_ID}

Créer un utilisateur avec un email invalide
    [Documentation]    Le format de l'email est contrôlé par l'application (``validators.py``).
    [Tags]    erreur    validation    users
    ${error}=    Create Web User    expected_status=422
    ...    name=Jean Dupont    username=jdupont    email=${INVALID_EMAIL}
    Error Should Be    ${error}    error_invalid_email    field=email    value=${INVALID_EMAIL}

Modifier un post inexistant
    [Documentation]    404 ``post_not_found`` : l'application vérifie l'existence du post.
    ...    JSONPlaceholder seul renverrait une erreur 500.
    [Tags]    erreur    ressource-inexistante    posts
    ${error}=    Patch Web Post    9999    expected_status=404    title=Nouveau titre
    Error Should Be    ${error}    post_not_found    id=9999

Supprimer un post inexistant
    [Documentation]    404 ``post_not_found``. JSONPlaceholder seul renverrait 200, comme si le post existait.
    [Tags]    erreur    ressource-inexistante    posts
    ${error}=    Delete Web Post    9999    expected_status=404
    Error Should Be    ${error}    post_not_found    id=9999

Route inconnue
    [Documentation]    Une route ``/api/...`` inconnue renvoie une erreur JSON, pas la page Angular.
    [Tags]    erreur    ressource-inexistante
    ${error}=    Get Web Resource    unknown-resource    expected_status=404
    Error Should Be    ${error}    error_not_found    resource=/unknown-resource

Explorateur : relayer une requête vers JSONPlaceholder
    [Documentation]    L'explorateur envoie la requête à JSONPlaceholder et renvoie sa réponse brute.
    [Tags]    nominal    explorateur
    ${result}=    Send Explorer Request    GET    /users/1
    Should Be Equal As Integers    ${result}[status]    200
    Should Be Equal    ${result}[body][name]    Leanne Graham

Explorateur : refuser une adresse externe
    [Documentation]    Sécurité : l'explorateur ne doit interroger que JSONPlaceholder. Sans ce
    ...    contrôle, le serveur pourrait être utilisé pour appeler n'importe quelle adresse (SSRF).
    [Tags]    erreur    securite    explorateur
    ${error}=    Send Explorer Request    GET    ${EXTERNAL_URL}    expected_status=422
    Error Should Be    ${error}    error_invalid_path    field=path    value=${EXTERNAL_URL}
