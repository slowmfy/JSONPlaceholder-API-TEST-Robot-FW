# app/ — application web testée

Ce dossier contient l'application web testée par `tests/web/` : une **API FastAPI** (`web_api.py`) qui sert aussi l'**interface Angular** (`frontend/`). Elle appelle l'API publique JSONPlaceholder.

Elle est copiée du projet précédent [JSONPlaceholder-API-TEST](https://github.com/slowmfy/JSONPlaceholder-API-TEST) (commit `a8f3def`) pour que ce dépôt soit **autonome** : on peut lancer l'application et toute la campagne Robot Framework sans autre dépôt. Seule la partie web est reprise : le menu console et les tests PyTest restent dans le projet d'origine. Le code qui ne servait qu'au menu console a été retiré des fichiers copiés : raccourcis `get_users`, `create_post`, `update_post`... d'`api_client.py`, validateurs `parse_yes_no`, `parse_menu_choice`... de `validators.py`, journal `app.log` de `config.py`.

## Lancer l'application

Depuis la racine du dépôt, une fois l'installation du README principal faite (`venv`, `pip install -r requirements.txt`, Node.js) :

```powershell
.\start-app.ps1          # compile l'interface si besoin, puis ouvre http://127.0.0.1:8000
.\start-app.ps1 dev      # mode développement Angular, rechargement automatique sur http://localhost:4200
.\start-app.bat          # même chose, si PowerShell refuse d'exécuter le script
```

`Ctrl+C` arrête le serveur. Au premier lancement, le script installe les dépendances Angular (`npm ci`) et compile l'interface.

Les tests n'ont pas besoin qu'elle soit lancée : `tests/web/__init__.robot` la démarre avec le Python de `venv/` et l'arrête à la fin. Si elle tourne déjà (lancée avec `start-app.ps1`), les tests la réutilisent.

## Contenu

```
web_api.py         API web FastAPI : routes /api/..., sert aussi l'interface compilée
api_client.py      Client HTTP de JSONPlaceholder
resources.py       Description des ressources (champs, validateurs, filtres)
models.py          User, Post, Comment, Album, Photo, Todo, UserReport
validators.py      Contrôle des saisies (identifiants, textes, emails, URL, téléphones)
exceptions.py      Hiérarchie d'exceptions
i18n.py            Chargement des traductions
logging_config.py  Journalisation (web.log)
config.py          Paramètres (URL, timeout, port 8000, limites)
locales/           Traductions fr.json et en.json, aussi utilisées par les tests d'interface
frontend/          Interface Angular (sources ; node_modules/ et dist/ sont générés)
```
