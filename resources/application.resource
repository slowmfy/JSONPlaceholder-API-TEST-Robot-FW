*** Comments ***
Les variables ${APP_STARTED_BY_TESTS} et ${TEXTS} sont remplies par la Suite Setup de
tests/__init__.robot avec scope=SUITES : toutes les suites du dossier tests/ les voient.
C'est voulu ; la règle Robocop VAR05, qui déconseille les variables de suite, est donc
désactivée sur ces lignes.


*** Settings ***
Documentation    APPLICATION : démarrer / arrêter l'application testée, et lire ses textes traduits.
...
...              Utilisé par ``tests/__init__.robot`` : l'application est démarrée une seule
...              fois avant tous les tests, et arrêtée à la fin.

Library          Collections
Library          OperatingSystem
Library          Process
Library          RequestsLibrary
Variables        ../variables/config.py


*** Variables ***
# Valeurs par défaut, remplacées par `Start Web Application` et `Load Translations`.
${APP_STARTED_BY_TESTS}    ${False}
&{TEXTS}                   &{EMPTY}


*** Keywords ***
Prepare Web Application
    [Documentation]    Démarre l'application si besoin, puis charge ses textes traduits.
    Start Web Application
    Load Translations

Start Web Application
    [Documentation]    Lance ``app/web_api.py`` et attend qu'il réponde.
    ...
    ...    Si l'application tourne déjà (lancée avec ``start-app.ps1``), elle est réutilisée
    ...    et ne sera pas arrêtée à la fin. Sa sortie console est écrite dans ``results/web_app.log``.
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
    [Documentation]    Arrête l'application, seulement si ce sont les tests qui l'ont lancée.
    IF    ${APP_STARTED_BY_TESTS}    Terminate Process    web-app

Web Application Should Respond
    [Documentation]    Vérifie que l'application répond (petite requête ``/api/languages``).
    GET    ${WEB_URL}/api/languages    expected_status=200    timeout=2

Load Translations
    [Documentation]    Charge les textes de l'interface dans la langue ``\${UI_LANGUAGE}``.
    ...
    ...    Les tests ne recopient jamais un texte affiché : ils le demandent à l'application.
    ...    Si un libellé change dans ``app/locales/fr.json``, les tests suivent tout seuls.
    ${response}=    GET    ${WEB_URL}/api/translations/${UI_LANGUAGE}    expected_status=200
    VAR    ${TEXTS}    ${response.json()}    scope=SUITES    # robocop: off=VAR05

Text
    [Documentation]    Renvoie le texte traduit d'une clé, avec ses paramètres remplacés.
    ...
    ...    Exemple : `Text    created_post    id=101` renvoie « Post 101 créé. »
    ...    (dans ``fr.json`` : ``"created_post": "Post {id} créé."``).
    [Arguments]    ${key}    &{params}
    Dictionary Should Contain Key    ${TEXTS}    ${key}    msg=Clé de traduction inconnue : ${key}
    ${text}=    Evaluate    $TEXTS[$key].format(**$params)
    RETURN    ${text}
