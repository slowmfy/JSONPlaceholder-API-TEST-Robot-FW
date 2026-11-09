"""DONNÉES DE TEST : les valeurs utilisées et attendues par les tests.

Les données viennent de JSONPlaceholder (https://jsonplaceholder.typicode.com),
l'API qu'utilise l'application. Elles ne changent jamais : JSONPlaceholder ne
conserve aucune création, modification ou suppression.

Chaque nom en MAJUSCULES devient une variable Robot Framework :
    EXISTING_USER_ID = 1          ->   ${EXISTING_USER_ID}
    INVALID_USER_IDS = {...}      ->   &{INVALID_USER_IDS} (dictionnaire)
"""

# ---------- Utilisateurs ----------

USERS_COUNT = 10  # nombre d'utilisateurs dans JSONPlaceholder

# Utilisateur n°1
EXISTING_USER_ID = 1
EXISTING_USER_NAME = "Leanne Graham"
EXISTING_USER_USERNAME = "Bret"
EXISTING_USER_CITY = "gwenborough"  # en minuscules : la recherche ignore les majuscules

# Utilisateur n°2
OTHER_USER_ID = 2
OTHER_USER_NAME = "Ervin Howell"
OTHER_USER_USERNAME = "Antonette"

UNKNOWN_USER_ID = 999
NO_RESULT_SEARCH = "zzz-aucun-utilisateur"

# Identifiant invalide  ->  clé du message d'erreur attendu (app/locales/fr.json)
INVALID_USER_IDS = {
    "abc": "error_not_integer",
    "0": "error_not_positive",
    "-1": "error_not_positive",
}

# ---------- Posts ----------

POSTS_PER_USER = 10
COMMENTS_PER_USER = 50  # 10 posts x 5 commentaires

EXISTING_POST_ID = 1
UNKNOWN_POST_ID = 9999
CREATED_POST_ID = 101  # JSONPlaceholder contient 100 posts : un nouveau post reçoit l'id 101

NEW_POST_TITLE = "Titre créé par Robot Framework"
NEW_POST_BODY = "Contenu créé par Robot Framework"
UPDATED_POST_TITLE = "Titre modifié par Robot Framework"
