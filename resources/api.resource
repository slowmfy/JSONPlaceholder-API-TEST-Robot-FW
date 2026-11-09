*** Settings ***
Documentation    Mots-clés d'accès à l'API JSONPlaceholder.
...
...              Le fichier est organisé en quatre couches, de la plus technique à la plus métier :
...
...              1. *Session* : ouverture et fermeture de la connexion HTTP.
...              2. *Couche technique* (privée) : `Call API` est le seul mot-clé qui envoie
...              des requêtes. En-têtes, journalisation ou authentification se changent ici,
...              à un seul endroit.
...              3. *Actions métier* : un mot-clé par action (`Get User`, `Create Post`...).
...              Ce sont les seuls que les tests utilisent : aucune URL n'apparaît dans les tests.
...              4. *Vérifications métier* : contrôles réutilisables sur les données renvoyées.
...
...              Chaque action accepte un argument ``expected_status`` : le même mot-clé sert
...              au cas nominal (200, 201) et aux cas d'erreur (404, 500).

Library          Collections
Library          RequestsLibrary
Variables        ../variables/environment.py


*** Keywords ***
# =====================================================================
# 1. Session
# =====================================================================

Open API Session
    [Documentation]    Ouvre la session HTTP partagée par tous les tests d'une suite.
    ...
    ...    La session porte l'URL de base, le délai d'attente et les en-têtes communs :
    ...    les mots-clés n'indiquent plus que le chemin (``/users``). Elle réutilise aussi
    ...    la connexion TCP entre les appels, ce qui accélère la suite.
    ...
    ...    ``verify=\${True}`` est indispensable : par défaut, RequestsLibrary ne vérifie
    ...    *pas* le certificat HTTPS du serveur (``verify=False``).
    VAR    &{headers}    Accept=application/json
    Create Session    ${API_SESSION}    ${BASE_URL}
    ...    headers=${headers}    timeout=${TIMEOUT}    verify=${True}

Close API Sessions
    [Documentation]    Ferme toutes les sessions HTTP ouvertes par la suite.
    Delete All Sessions

# =====================================================================
# 2. Couche technique (privée)
# =====================================================================

Call API
    [Documentation]    Envoie une requête sur la session et renvoie le corps de la réponse.
    ...
    ...    - ``method`` : GET, POST, PUT, PATCH ou DELETE ;
    ...    - ``endpoint`` : chemin relatif à ``\${BASE_URL}``, par exemple ``/users/1`` ;
    ...    - ``expected_status`` : code HTTP attendu. RequestsLibrary fait échouer le test,
    ...    avec l'URL et le code reçu, si la réponse en a un autre ;
    ...    - ``options`` : paramètres transmis tels quels (``params=``, ``json=``...).
    ...
    ...    Le corps est renvoyé décodé s'il est en JSON, en texte brut sinon : l'API répond
    ...    par exemple en HTML quand elle renvoie une erreur 500.
    ...
    ...    Mot-clé privé (tag ``robot:private``) : Robot Framework émet un avertissement
    ...    si un test l'appelle directement au lieu de passer par une action métier.
    [Tags]    robot:private
    [Arguments]    ${method}    ${endpoint}    ${expected_status}    &{options}
    ${response}=    Run Keyword    ${method} On Session    ${API_SESSION}    ${endpoint}
    ...    expected_status=${expected_status}    &{options}
    ${content_type}=    Evaluate    $response.headers.get("Content-Type", "")
    IF    "json" in $content_type    RETURN    ${response.json()}
    RETURN    ${response.text}

Build Post Payload
    [Documentation]    Construit le corps JSON d'un post au format attendu par l'API
    ...    (``userId`` et non ``user_id``). L'identifiant est converti en entier pour être
    ...    envoyé comme un nombre JSON et non comme le texte "1".
    [Tags]    robot:private
    [Arguments]    ${user_id: int}    ${title}    ${body}    &{extra_fields}
    VAR    &{payload}    userId=${user_id}    title=${title}    body=${body}    &{extra_fields}
    RETURN    ${payload}

# =====================================================================
# 3. Actions métier
# =====================================================================

Get All Users
    [Documentation]    ``GET /users`` : renvoie la liste de tous les utilisateurs.
    [Arguments]    ${expected_status}=200
    ${users}=    Call API    GET    /users    ${expected_status}
    RETURN    ${users}
Get User
    [Documentation]    ``GET /users/<id>`` : renvoie un utilisateur (``{}`` si introuvable).
    [Arguments]    ${user_id}    ${expected_status}=200
    ${user}=    Call API    GET    /users/${user_id}    ${expected_status}
    RETURN    ${user}
Get User Posts
    [Documentation]    ``GET /posts?userId=<id>`` : renvoie les posts d'un utilisateur.
    ...    Sans le filtre, l'API renverrait les 100 posts de tous les utilisateurs.
    [Arguments]    ${user_id}    ${expected_status}=200
    VAR    &{params}    userId=${user_id}
    ${posts}=    Call API    GET    /posts    ${expected_status}    params=${params}
    RETURN    ${posts}

Get Post
    [Documentation]    ``GET /posts/<id>`` : renvoie un post (``{}`` si introuvable).
    [Arguments]    ${post_id}    ${expected_status}=200
    ${post}=    Call API    GET    /posts/${post_id}    ${expected_status}
    RETURN    ${post}

Create Post
    [Documentation]    ``POST /posts`` : crée un post et renvoie le post créé (avec son ``id``).
    [Arguments]    ${user_id}    ${title}    ${body}    ${expected_status}=201
    ${payload}=    Build Post Payload    ${user_id}    ${title}    ${body}
    ${post}=    Call API    POST    /posts    ${expected_status}    json=${payload}
    RETURN    ${post}

Update Post
    [Documentation]    ``PUT /posts/<id>`` : remplace entièrement un post.
    ...    PUT remplace tout l'élément : tous les champs sont donc envoyés.
    [Arguments]    ${post_id: int}    ${user_id}    ${title}    ${body}    ${expected_status}=200
    ${payload}=    Build Post Payload    ${user_id}    ${title}    ${body}    id=${post_id}
    ${post}=    Call API    PUT    /posts/${post_id}    ${expected_status}    json=${payload}
    RETURN    ${post}

Delete Post
    [Documentation]    ``DELETE /posts/<id>`` : supprime un post et renvoie le corps de la réponse.
    [Arguments]    ${post_id}    ${expected_status}=200
    ${body}=    Call API    DELETE    /posts/${post_id}    ${expected_status}
    RETURN    ${body}

Get Resource
    [Documentation]    ``GET /<resource>`` générique, pour une ressource sans action dédiée.
    [Arguments]    ${resource}    ${expected_status}=200
    ${body}=    Call API    GET    /${resource}    ${expected_status}
    RETURN    ${body}

# =====================================================================
# 4. Vérifications métier
# =====================================================================

Number Of Items Should Be
    [Documentation]    Vérifie la taille d'une liste avec un message lisible.
    ...    ``Length Should Be`` afficherait la liste entière dans le message d'erreur,
    ...    ce qui rend le rapport illisible pour une liste de 10 utilisateurs.
    [Arguments]    ${items}    ${expected_count}    ${label}=éléments
    ${count}=    Get Length    ${items}
    Should Be Equal As Integers    ${count}    ${expected_count}
    ...    msg=${expected_count} ${label} attendus, ${count} reçus    values=False

User Should Be Valid
    [Documentation]    Vérifie la structure d'un utilisateur : champs obligatoires présents,
    ...    nom non vide et email au format ``x@y.z``.
    [Arguments]    ${user}
    FOR    ${field}    IN    @{USER_FIELDS}
        Dictionary Should Contain Key    ${user}    ${field}
        ...    msg=Champ "${field}" absent de l'utilisateur ${user}[id]
    END
    Should Not Be Empty    ${user}[name]
    Should Match Regexp    ${user}[email]    ^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$

Every User Should Be Valid
    [Documentation]    Applique `User Should Be Valid` à chaque utilisateur de la liste.
    [Arguments]    ${users}
    Should Not Be Empty    ${users}
    FOR    ${user}    IN    @{users}
        User Should Be Valid    ${user}
    END

User Should Be
    [Documentation]    Vérifie l'identité d'un utilisateur : identifiant, nom, pseudo et email.
    [Arguments]    ${user}    ${id}    ${name}    ${username}    ${email}
    Should Be Equal As Integers    ${user}[id]    ${id}    msg=Identifiant inattendu
    Should Be Equal    ${user}[name]    ${name}    msg=Nom inattendu
    Should Be Equal    ${user}[username]    ${username}    msg=Pseudo inattendu
    Should Be Equal    ${user}[email]    ${email}    msg=Email inattendu

Post Should Be Valid
    [Documentation]    Vérifie qu'un post contient tous les champs obligatoires.
    [Arguments]    ${post}
    FOR    ${field}    IN    @{POST_FIELDS}
        Dictionary Should Contain Key    ${post}    ${field}    msg=Champ "${field}" absent du post
    END

Post Should Contain
    [Documentation]    Vérifie l'auteur, le titre et le contenu d'un post.
    [Arguments]    ${post}    ${user_id}    ${title}    ${body}
    Post Should Be Valid    ${post}
    Should Be Equal As Integers    ${post}[userId]    ${user_id}
    Should Be Equal    ${post}[title]    ${title}
    Should Be Equal    ${post}[body]    ${body}

Every Post Should Belong To User
    [Documentation]    Vérifie que chaque post de la liste est valide et appartient à ``user_id``.
    [Arguments]    ${posts}    ${user_id}
    Should Not Be Empty    ${posts}
    FOR    ${post}    IN    @{posts}
        Post Should Be Valid    ${post}
        Should Be Equal As Integers    ${post}[userId]    ${user_id}
        ...    msg=Le post ${post}[id] appartient à l'utilisateur ${post}[userId], pas à ${user_id}
    END

Response Body Should Be Empty
    [Documentation]    Vérifie que l'API a renvoyé un corps vide (``{}`` ou ``[]``).
    [Arguments]    ${body}
    Should Be Empty    ${body}    msg=Corps vide attendu, reçu : ${body}

User Id Should Be Rejected
    [Documentation]    Vérifie qu'un identifiant d'utilisateur invalide est refusé (404, corps vide).
    ...    Conçu pour être utilisé comme ``[Template]`` : une ligne de données par identifiant.
    [Arguments]    ${user_id}
    ${body}=    Get User    ${user_id}    expected_status=404
    Response Body Should Be Empty    ${body}

Request Should Time Out
    [Documentation]    Vérifie qu'une requête trop lente est interrompue par un timeout.
    ...
    ...    Une session dédiée est ouverte avec un délai impossible à tenir (1 ms par défaut)
    ...    et sans nouvelle tentative (``max_retries=0``). La session principale n'est pas
    ...    modifiée : les autres tests de la suite ne sont pas affectés.
    [Arguments]    ${endpoint}    ${timeout}=${SIMULATED_TIMEOUT}
    Create Session    ${TIMEOUT_SESSION}    ${BASE_URL}
    ...    timeout=${timeout}    max_retries=0    verify=${True}
    Run Keyword And Expect Error    GLOB:*Timeout*
    ...    GET On Session    ${TIMEOUT_SESSION}    ${endpoint}
