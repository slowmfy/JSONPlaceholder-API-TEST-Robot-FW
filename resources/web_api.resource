*** Settings ***
Documentation    Mots-clés d'accès à l'API web de l'application (``web_api.py``, FastAPI).
...
...              C'est l'API qu'appelle l'interface Angular. Contrairement à JSONPlaceholder,
...              elle valide les saisies (422) et renvoie des erreurs structurées :
...              ``{"key": "user_not_found", "params": {"id": 999}, "field": null}``
...              où ``key`` est une clé de traduction et ``field`` le champ de formulaire en faute.
...
...              Même organisation que ``api.resource`` : couche technique privée, actions
...              métier avec ``expected_status``, vérifications métier.

Library          RequestsLibrary
Resource         http.resource
Variables        ../variables/web.py


*** Keywords ***
# =====================================================================
# 1. Session
# =====================================================================

Open Web API Session
    [Documentation]    Ouvre la session HTTP vers l'API web de l'application.
    Open HTTP Session    ${WEB_API_SESSION}    ${WEB_URL}/api    ${WEB_TIMEOUT}

# =====================================================================
# 2. Couche technique (privée)
# =====================================================================

Call Web API
    [Documentation]    Envoie une requête à l'API web et renvoie le corps de la réponse.
    ...    Délègue à `Send Request On Session` (``http.resource``) avec la session de l'API web.
    [Tags]    robot:private
    [Arguments]    ${method}    ${endpoint}    ${expected_status}    &{options}
    ${body}=    Send Request On Session    ${WEB_API_SESSION}    ${method}    ${endpoint}
    ...    ${expected_status}    &{options}
    RETURN    ${body}

# =====================================================================
# 3. Actions métier
# =====================================================================

Get Available Languages
    [Documentation]    ``GET /api/languages`` : langues proposées par l'interface.
    ${languages}=    Call Web API    GET    /languages    200
    RETURN    ${languages}

Get Web User
    [Documentation]    ``GET /api/users/<id>`` : un utilisateur, au format de l'application.
    [Arguments]    ${user_id}    ${expected_status}=200
    ${user}=    Call Web API    GET    /users/${user_id}    ${expected_status}
    RETURN    ${user}

Get User Report
    [Documentation]    ``GET /api/users/<id>/report`` : utilisateur, nombre de posts et de
    ...    commentaires, post le plus commenté. Équivalent de l'option 8 du menu console.
    [Arguments]    ${user_id}    ${expected_status}=200
    ${report}=    Call Web API    GET    /users/${user_id}/report    ${expected_status}
    RETURN    ${report}

Create Web Post
    [Documentation]    ``POST /api/posts`` : crée un post après validation des champs
    ...    et vérification que l'auteur existe.
    [Arguments]    ${user_id}    ${title}    ${body}    ${expected_status}=201
    VAR    &{payload}    user_id=${user_id}    title=${title}    body=${body}
    ${result}=    Call Web API    POST    /posts    ${expected_status}    json=${payload}
    RETURN    ${result}

Patch Web Post
    [Documentation]    ``PATCH /api/posts/<id>`` : modifie seulement les champs donnés
    ...    (``title=...``, ``body=...``). L'existence du post est vérifiée avant l'envoi.
    [Arguments]    ${post_id}    ${expected_status}=200    &{fields}
    ${result}=    Call Web API    PATCH    /posts/${post_id}    ${expected_status}    json=${fields}
    RETURN    ${result}

Delete Web Post
    [Documentation]    ``DELETE /api/posts/<id>`` : supprime un post après avoir vérifié qu'il existe.
    [Arguments]    ${post_id}    ${expected_status}=200
    ${result}=    Call Web API    DELETE    /posts/${post_id}    ${expected_status}
    RETURN    ${result}

Create Web User
    [Documentation]    ``POST /api/users`` : crée un utilisateur (``name=``, ``username=``, ``email=``...).
    [Arguments]    ${expected_status}=201    &{fields}
    ${result}=    Call Web API    POST    /users    ${expected_status}    json=${fields}
    RETURN    ${result}

Get Web Resource
    [Documentation]    ``GET /api/<path>`` générique, pour une route sans action dédiée.
    [Arguments]    ${path}    ${expected_status}=200
    ${body}=    Call Web API    GET    /${path}    ${expected_status}
    RETURN    ${body}

Send Explorer Request
    [Documentation]    ``POST /api/explorer`` : requête libre relayée vers JSONPlaceholder
    ...    par l'explorateur d'API de l'interface.
    [Arguments]    ${method}    ${path}    ${expected_status}=200
    VAR    &{request}    method=${method}    path=${path}
    ${result}=    Call Web API    POST    /explorer    ${expected_status}    json=${request}
    RETURN    ${result}

# =====================================================================
# 4. Vérifications métier
# =====================================================================

Error Should Be
    [Documentation]    Vérifie une erreur de l'API web : clé de traduction, champ en faute
    ...    (``None`` si l'erreur ne concerne pas un champ) et paramètres du message.
    [Arguments]    ${error}    ${key}    ${field}=${None}    &{params}
    Should Be Equal    ${error}[key]    ${key}    msg=Clé d'erreur inattendue
    Should Be Equal    ${error}[field]    ${field}    msg=Champ en faute inattendu
    FOR    ${name}    ${value}    IN    &{params}
        Should Be Equal As Strings    ${error}[params][${name}]    ${value}
        ...    msg=Paramètre "${name}" inattendu
    END

Write Should Be Simulated
    [Documentation]    Vérifie que la réponse d'une écriture signale qu'elle est simulée :
    ...    l'interface affiche alors « rien n'est enregistré sur le serveur ».
    [Arguments]    ${result}
    Should Be True    ${result}[simulated]    msg=L'écriture devrait être signalée comme simulée

Web User Id Should Be Rejected
    [Documentation]    Vérifie qu'un identifiant invalide est refusé avant tout appel à
    ...    JSONPlaceholder : 422, clé d'erreur ``expected_key``, champ ``id``.
    ...    Conçu pour être utilisé comme ``[Template]`` (identifiant, clé attendue).
    [Arguments]    ${user_id}    ${expected_key}
    ${error}=    Get Web User    ${user_id}    expected_status=422
    Error Should Be    ${error}    ${expected_key}    field=id    value=${user_id}
