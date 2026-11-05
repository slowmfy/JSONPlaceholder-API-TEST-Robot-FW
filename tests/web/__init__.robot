*** Settings ***
Documentation     Tests de l'application web du projet précédent (JSONPlaceholder-API-TEST) :
...               son API web FastAPI (``web_api.robot``) et son interface Angular (``ui_*.robot``).
...
...               Ce fichier d'initialisation s'applique à tout le dossier ``tests/web`` :
...               l'application est démarrée une seule fois avant toutes les suites et arrêtée
...               après elles, et toutes les suites reçoivent le tag ``web``.
...
...               Pour lancer une seule suite sans perdre cette initialisation, sélectionner la
...               suite depuis le dossier : ``robot --suite ui_posts tests/web``.

Resource          ../../resources/web_app.resource

Suite Setup       Prepare Web Application
Suite Teardown    Stop Web Application

Test Tags         web
