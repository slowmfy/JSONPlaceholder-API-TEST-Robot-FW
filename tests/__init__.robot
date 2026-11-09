*** Settings ***
Documentation     Fichier d'initialisation du dossier ``tests/``.
...
...               Il s'exécute UNE fois, avant tous les fichiers de tests du dossier :
...               il démarre l'application web, puis l'arrête à la fin.
...
...               Pour lancer un seul fichier sans perdre cette étape, passer par le dossier :
...               ``robot --outputdir results --suite users tests``

Resource          ../resources/application.resource

Suite Setup       Prepare Web Application
Suite Teardown    Stop Web Application
