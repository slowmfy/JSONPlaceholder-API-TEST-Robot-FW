"""CONFIGURATION : où se trouve l'application et comment ouvrir le navigateur.

Chaque nom en MAJUSCULES devient une variable Robot Framework :
    WEB_URL = "http://..."   ->   ${WEB_URL} dans les fichiers .robot et .resource

Tout se change sans modifier ce fichier, par exemple :
    robot --variable HEADLESS:True tests       navigateur masqué
    $env:BROWSER_CHANNEL = "chrome"            Google Chrome au lieu d'Edge (PowerShell)

Les noms qui commencent par _ ne sont pas visibles dans Robot Framework.
"""
import sys as _sys
from os import environ as _environ
from os import name as _os_name
from pathlib import Path as _Path

# ---------- Application testée ----------

# Adresse de l'application (API FastAPI + interface Angular).
WEB_URL = _environ.get("WEB_APP_URL", "http://127.0.0.1:8000")

# Dossier de l'application : app/ à la racine du projet.
APP_DIR = _environ.get("WEB_APP_DIR", str(_Path(__file__).resolve().parents[1] / "app"))

# Python qui lance l'application : celui de son propre venv si elle en a un,
# sinon celui qui exécute Robot Framework (le venv/ du projet).
_app_venv = _Path(APP_DIR) / ("venv/Scripts/python.exe" if _os_name == "nt" else "venv/bin/python")
APP_PYTHON = str(_app_venv) if _app_venv.is_file() else _sys.executable

APP_START_TIMEOUT = "30s"  # temps maximal pour que l'application démarre

# ---------- Navigateur (bibliothèque Browser / Playwright) ----------

BROWSER = "chromium"

# Navigateur installé sur la machine : "msedge" (défaut sous Windows) ou "chrome".
# Vide : Chromium téléchargé par « rfbrowser init chromium ».
BROWSER_CHANNEL = _environ.get("BROWSER_CHANNEL", "msedge" if _os_name == "nt" else "") or None

# False = on voit la fenêtre du navigateur. True = fenêtre masquée (plus rapide).
HEADLESS = _environ.get("HEADLESS", "false").lower() == "true"

# Fenêtre visible seulement : pause entre chaque action, et à la fin de chaque test,
# pour avoir le temps de suivre à l'œil.
SLOW_MO = _environ.get("SLOW_MO", "500ms")
PAUSE_AFTER_TEST = _environ.get("PAUSE_AFTER_TEST", "2s")

UI_TIMEOUT = "10s"  # temps maximal d'attente d'un élément de la page
UI_LANGUAGE = "fr"  # langue des textes attendus (fichier app/locales/fr.json)
