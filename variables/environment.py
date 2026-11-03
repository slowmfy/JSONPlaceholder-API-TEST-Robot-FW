"""Variables de la campagne de tests : environnement ciblé et jeu de données de référence.

Robot Framework lit ce fichier grâce à la ligne `Variables` de api.resource.
Chaque nom en MAJUSCULES devient une variable Robot :
    BASE_URL = "..."      ->  ${BASE_URL}
    INVALID_IDS = [...]   ->  @{INVALID_IDS} (liste) ou ${INVALID_IDS}

Les valeurs gardent leur type Python : ${USERS_COUNT} est un entier, pas le texte "10".

Changer d'environnement sans modifier ce fichier :
    robot --variable BASE_URL:http://localhost:3000 tests     (ligne de commande, prioritaire)
    set API_BASE_URL=http://localhost:3000                    (variable d'environnement système)

Les noms qui commencent par _ ne sont pas exportés vers Robot Framework.
"""
from os import environ as _environ

# ---------- Environnement ciblé ----------

BASE_URL = _environ.get("API_BASE_URL", "https://jsonplaceholder.typicode.com")
TIMEOUT = float(_environ.get("API_TIMEOUT", "5"))  # attente maximale d'une réponse, en secondes

# Nom (alias) des sessions HTTP de RequestsLibrary.
API_SESSION = "jsonplaceholder"
TIMEOUT_SESSION = "jsonplaceholder-timeout"

# Délai volontairement impossible à tenir (1 ms) pour provoquer un timeout réel.
# JSONPlaceholder n'a pas de route « lente » : c'est le client qui abandonne trop tôt.
SIMULATED_TIMEOUT = 0.001

# ---------- Jeu de données de référence de JSONPlaceholder ----------
# Ces données sont fixes : l'API ne conserve aucune écriture (POST, PUT, DELETE simulés).

USERS_COUNT = 10
POSTS_PER_USER = 10

EXISTING_USER_ID = 1
EXISTING_USER_NAME = "Leanne Graham"
EXISTING_USER_USERNAME = "Bret"
EXISTING_USER_EMAIL = "Sincere@april.biz"

EXISTING_POST_ID = 1
UNKNOWN_USER_ID = 999
UNKNOWN_POST_ID = 9999
UNKNOWN_RESOURCE = "unknown-resource"

# Identifiant attribué par l'API à tout post créé (elle contient 100 posts).
CREATED_POST_ID = 101

# Identifiants refusés par l'API (404) : texte, zéro, négatif, décimal.
INVALID_IDS = ["abc", "0", "-1", "1.5"]

# Champs que tout utilisateur et tout post doivent contenir.
USER_FIELDS = ["id", "name", "username", "email", "address", "phone", "website", "company"]
POST_FIELDS = ["id", "userId", "title", "body"]

# Contenus utilisés pour la création et la modification.
NEW_POST_TITLE = "Titre créé par Robot Framework"
NEW_POST_BODY = "Contenu créé par Robot Framework"
UPDATED_POST_TITLE = "Titre modifié par Robot Framework"
UPDATED_POST_BODY = "Contenu modifié par Robot Framework"
