"""Variables des tests de l'application web (API FastAPI et interface Angular).

L'application testée est celle du projet précédent, JSONPlaceholder-API-TEST :
    web_api.py   API web FastAPI, sur http://127.0.0.1:8000/api/...
    frontend/    interface Angular, compilée et servie par web_api.py sur http://127.0.0.1:8000

Elle est copiée dans le dossier app/ de ce dépôt (voir app/README.md), et lancée avec
le Python de l'environnement virtuel du projet (venv/), qui contient FastAPI et uvicorn.

Tout se change sans modifier ce fichier :
    robot --variable HEADLESS:True tests/web            navigateur invisible (intégration continue)
    set BROWSER_CHANNEL=chrome                              utiliser Google Chrome au lieu d'Edge
    set WEB_APP_DIR=D:\\projets\\JSONPlaceholder-API-TEST   autre emplacement de l'application
    set WEB_APP_URL=http://serveur-de-recette:8000          application déjà déployée ailleurs
"""
from os import environ as _environ
from os import name as _os_name
import sys as _sys
from pathlib import Path as _Path

# ---------- Application testée ----------

WEB_URL = _environ.get("WEB_APP_URL", "http://127.0.0.1:8000")
WEB_TIMEOUT = 10  # secondes : l'API web interroge elle-même JSONPlaceholder

APP_DIR = _environ.get("WEB_APP_DIR", str(_Path(__file__).resolve().parents[1] / "app"))

# Python qui lance l'application : celui de son propre venv s'il en a un (autre copie
# désignée par WEB_APP_DIR), sinon celui qui exécute Robot Framework (venv/ du projet).
_app_venv = _Path(APP_DIR) / ("venv/Scripts/python.exe" if _os_name == "nt" else "venv/bin/python")
APP_PYTHON = str(_app_venv) if _app_venv.is_file() else _sys.executable
APP_START_TIMEOUT = "30s"  # délai maximal de démarrage du serveur
WEB_API_SESSION = "web-api"

# ---------- Navigateur (bibliothèque Browser / Playwright) ----------

BROWSER = "chromium"
# Navigateur installé sur la machine, de la famille Chromium : "msedge" ou "chrome".
# Vide : Chromium téléchargé par « rfbrowser init chromium ».
# Edge est le choix par défaut sous Windows : il est toujours présent, et le Chromium de
# Playwright, rangé très profondément dans venv/, dépasse la limite Windows de 260 caractères
# par chemin quand le projet est dans un dossier au nom long (OneDrive...).
BROWSER_CHANNEL = _environ.get("BROWSER_CHANNEL", "msedge" if _os_name == "nt" else "") or None
# Par défaut, le test ouvre une fenêtre de navigateur visible : on voit chaque action.
# HEADLESS=true (variable d'environnement) la masque, par exemple en intégration continue.
HEADLESS = _environ.get("HEADLESS", "false").lower() == "true"
# Fenêtre visible : pause entre chaque action (clic, saisie...) et à la fin de chaque test,
# pour suivre les changements à l'œil. Ignorées quand la fenêtre est masquée (HEADLESS).
SLOW_MO = _environ.get("SLOW_MO", "500ms")
PAUSE_AFTER_TEST = _environ.get("PAUSE_AFTER_TEST", "2s")
UI_TIMEOUT = "10s"  # attente maximale d'un élément de la page
UI_LANGUAGE = "fr"  # langue des textes attendus, chargés depuis /api/translations/<code>

# ---------- Jeu de données ----------

UNKNOWN_AUTHOR_ID = 11  # JSONPlaceholder n'a que 10 utilisateurs

# Identifiant invalide -> clé d'erreur renvoyée par validators.py.
INVALID_WEB_IDS = {
    "abc": "error_not_integer",
    "0": "error_not_positive",
    "-1": "error_not_positive",
}

INVALID_EMAIL = "pas-un-email"
EXTERNAL_URL = "https://example.com/"  # l'explorateur ne doit interroger que JSONPlaceholder

USER_SEARCH_TERM = "gwenborough"  # ville de Leanne Graham, recherche insensible à la casse
