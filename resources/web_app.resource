*** Comments ***
Les variables ${APP_STARTED_BY_TESTS} et ${TEXTS} sont renseignées par la Suite Setup de
tests/web/__init__.robot avec scope=SUITES : elles sont visibles de toutes les sous-suites
du dossier, et seulement d'elles. C'est voulu ; la règle Robocop VAR05, qui déconseille les
variables de suite en général, est donc désactivée sur ces lignes.

Leur valeur par défaut est déclarée dans *** Variables *** :
- RobotCode les connaît dès l'écriture du code (sinon : « Variable not found ») ;
- si le démarrage échoue avant leur affectation (Python de l'application introuvable...),
    le teardown `Stop Web Application` s'exécute quand même sans erreur, et le rapport
    n'affiche que la vraie cause de l'échec.


*** Settings ***
Documentation    Cycle de vie de l'application web testée et accès à ses traductions.
...
...              Utilisé par ``tests/web/__init__.robot`` : l'application est démarrée une seule
...              fois avant toutes les suites web et arrêtée après elles.

Library          Collections
Library          OperatingSystem
Library          Process
Library          RequestsLibrary
Variables        ../variables/web.py


*** Variables ***
# Valeurs par défaut, remplacées par `Start Web Application` et `Load Translations`.
${APP_STARTED_BY_TESTS}    ${False}
&{TEXTS}                   &{EMPTY}


*** Keywords ***
Prepare Web Application
    [Documentation]    Démarre l'application si besoin et charge ses traductions.
    Start Web Application
    Load Translations

Start Web Application
    [Documentation]    Démarre ``web_api.py`` et attend qu'il réponde.
    ...
    ...    Si l'application répond déjà sur ``\${WEB_URL}`` (lancée par ``start-app.ps1`` ou déployée
    ...    sur un serveur de recette), elle est réutilisée et ne sera pas arrêtée à la fin.
    ...    Sinon elle est lancée avec le Python de son environnement virtuel ; sa sortie est
    ...    enregistrée dans ``results/web_app.log`` pour le diagnostic.
    ${running}=    Run Keyword And Return Status    Web Application Should Respond
    IF    ${running}
        Log    Application déjà lancée sur ${WEB_URL} : elle est réutilisée.    console=True
        VAR    ${APP_STARTED_BY_TESTS}    ${False}    scope=SUITES    # robocop: off=VAR05
        RETURN
    END
    File Should Exist    ${APP_PYTHON}
    ...    msg=Python de l'application introuvable (${APP_PYTHON}). Installer l'application ou définir WEB_APP_DIR.
    Start Process    ${APP_PYTHON}    web_api.py    cwd=${APP_DIR}    alias=web-app
    ...    stdout=${OUTPUT DIR}${/}web_app.log    stderr=STDOUT    env:PYTHONUTF8=1
    VAR    ${APP_STARTED_BY_TESTS}    ${True}    scope=SUITES    # robocop: off=VAR05
    Wait Until Keyword Succeeds    ${APP_START_TIMEOUT}    500ms    Web Application Should Respond

Stop Web Application
    [Documentation]    Arrête l'application, seulement si c'est `Start Web Application` qui l'a lancée.
    IF    ${APP_STARTED_BY_TESTS}    Terminate Process    web-app

Web Application Should Respond
    [Documentation]    Vérifie que l'API web répond (route légère ``/api/languages``).
    GET    ${WEB_URL}/api/languages    expected_status=200    timeout=2

Load Translations
    [Documentation]    Charge les textes de l'interface dans la langue ``\${UI_LANGUAGE}``.
    ...
    ...    Les tests d'interface ne recopient aucun texte affiché : ils utilisent les mêmes
    ...    traductions que l'application (``locales/fr.json``), servies par ``/api/translations``.
    ...    Si un libellé change dans l'application, les tests suivent sans modification.
    ${response}=    GET    ${WEB_URL}/api/translations/${UI_LANGUAGE}    expected_status=200
    VAR    ${TEXTS}    ${response.json()}    scope=SUITES    # robocop: off=VAR05

Text
    [Documentation]    Renvoie le texte traduit de la clé ``key``, avec ses paramètres remplacés.
    ...
    ...    Exemple : `Text    created_post    id=101` renvoie « Post 101 créé. »
    ...    (traduction ``"created_post": "Post {id} créé."``).
    [Arguments]    ${key}    &{params}
    Dictionary Should Contain Key    ${TEXTS}    ${key}    msg=Clé de traduction inconnue : ${key}
    ${text}=    Evaluate    $TEXTS[$key].format(**$params)
    RETURN    ${text}
