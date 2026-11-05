*** Settings ***
Documentation    Couche technique HTTP partagée par ``api.resource`` (JSONPlaceholder)
...              et ``web_api.resource`` (API web de l'application).
...
...              Ce fichier ne contient aucune notion métier : il ouvre des sessions et envoie
...              des requêtes. Les tests ne l'utilisent jamais directement ; ils passent par
...              les actions métier des fichiers qui l'importent.

Library          RequestsLibrary


*** Keywords ***
Open HTTP Session
    [Documentation]    Ouvre une session HTTP nommée ``alias`` vers ``url``.
    ...
    ...    La session porte l'URL de base, le délai d'attente et les en-têtes communs :
    ...    les mots-clés n'indiquent plus que le chemin (``/users``). Elle réutilise aussi
    ...    la connexion TCP entre les appels, ce qui accélère la suite.
    ...
    ...    ``verify=\${True}`` est indispensable : par défaut, RequestsLibrary ne vérifie
    ...    *pas* le certificat HTTPS du serveur (``verify=False``).
    [Arguments]    ${alias}    ${url}    ${timeout}
    VAR    &{headers}    Accept=application/json
    Create Session    ${alias}    ${url}
    ...    headers=${headers}    timeout=${timeout}    verify=${True}

Send Request On Session
    [Documentation]    Envoie une requête sur une session et renvoie le corps de la réponse.
    ...
    ...    - ``session`` : alias de la session ouverte par `Open HTTP Session` ;
    ...    - ``method`` : GET, POST, PUT, PATCH ou DELETE ;
    ...    - ``endpoint`` : chemin relatif à l'URL de la session, par exemple ``/users/1`` ;
    ...    - ``expected_status`` : code HTTP attendu. RequestsLibrary fait échouer le test,
    ...    avec l'URL et le code reçu, si la réponse en a un autre ;
    ...    - ``options`` : paramètres transmis tels quels (``params=``, ``json=``...).
    ...
    ...    Le corps est renvoyé décodé s'il est en JSON, en texte brut sinon : JSONPlaceholder
    ...    répond par exemple en HTML quand il renvoie une erreur 500.
    [Arguments]    ${session}    ${method}    ${endpoint}    ${expected_status}    &{options}
    ${response}=    Run Keyword    ${method} On Session    ${session}    ${endpoint}
    ...    expected_status=${expected_status}    &{options}
    ${content_type}=    Evaluate    $response.headers.get("Content-Type", "")
    IF    "json" in $content_type    RETURN    ${response.json()}
    RETURN    ${response.text}
