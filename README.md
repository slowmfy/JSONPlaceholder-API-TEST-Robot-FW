# JSONPlaceholder API — Tests Robot Framework

Campagne de tests automatisés de l'API REST publique [JSONPlaceholder](https://jsonplaceholder.typicode.com), écrite avec [Robot Framework](https://robotframework.org) et [RequestsLibrary](https://github.com/MarketSquare/robotframework-requests).

Ce dépôt ne contient que les tests. Il reprend les scénarios API du projet Python/PyTest précédent ([JSONPlaceholder-API-TEST](https://github.com/slowmfy/JSONPlaceholder-API-TEST)), réécrits sous forme de mots-clés métier réutilisables.

**État actuel : 15 tests, 15 réussis, en 3 secondes environ.**

## Sommaire

1. [Installation](#1-installation)
2. [Exécution des tests](#2-exécution-des-tests)
3. [Structure du projet](#3-structure-du-projet)
4. [Architecture des mots-clés](#4-architecture-des-mots-clés)
5. [Scénarios couverts](#5-scénarios-couverts)
6. [Rapports d'exécution](#6-rapports-dexécution)
7. [Qualité du code](#7-qualité-du-code)
8. [Ajouter un test](#8-ajouter-un-test)
9. [Limites connues de JSONPlaceholder](#9-limites-connues-de-jsonplaceholder)

---

## 1. Installation

### Prérequis

| Outil | Version testée | Rôle |
|---|---|---|
| Python | 3.14.8 (3.10 minimum) | Robot Framework est écrit en Python |
| Git | toute version récente | récupération du dépôt |
| Visual Studio Code | toute version récente | éditeur, avec l'extension RobotCode |
| Accès Internet | — | les tests appellent la vraie API JSONPlaceholder |

### Étape 1 : installer Python

1. Télécharger Python sur <https://www.python.org/downloads/>.
2. **Windows** : dans l'installateur, cocher **« Add python.exe to PATH »**.
3. Vérifier dans un nouveau terminal :

   ```powershell
   python --version     # Python 3.14.8 attendu (3.10 minimum)
   ```

### Étape 2 : récupérer le dépôt

```powershell
git clone https://github.com/slowmfy/JSONPlaceholder-API-TEST-Robot-FW.git
cd JSONPlaceholder-API-TEST-Robot-FW
```

### Étape 3 : créer un environnement virtuel

Un environnement virtuel (`venv`) isole les bibliothèques de ce projet de celles du reste de la machine : deux projets peuvent utiliser deux versions différentes de Robot Framework sans conflit.

```powershell
python -m venv venv
```

Puis l'activer (à refaire dans chaque nouveau terminal) :

| Système | Commande |
|---|---|
| Windows PowerShell | `.\venv\Scripts\Activate.ps1` |
| Windows cmd | `venv\Scripts\activate.bat` |
| Linux / macOS / Git Bash | `source venv/bin/activate` (Git Bash : `source venv/Scripts/activate`) |

Le préfixe `(venv)` apparaît alors devant l'invite de commande.

> **PowerShell refuse d'exécuter `Activate.ps1` ?** Autoriser les scripts locaux pour l'utilisateur courant, une seule fois :
> `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

### Étape 4 : installer Robot Framework et RequestsLibrary

```powershell
python -m pip install --upgrade pip
pip install -r requirements.txt
```

`requirements.txt` fixe les versions exactes, ce qui garantit le même environnement pour tous les développeurs :

| Paquet | Rôle |
|---|---|
| `robotframework` | moteur d'exécution des tests (`robot`) |
| `robotframework-requests` | RequestsLibrary : mots-clés HTTP (`GET On Session`...), basée sur la bibliothèque Python `requests` |
| `robotcode-runner` | commande `robotcode` : exécution avec la configuration `robot.toml` |
| `robotframework-robocop` | analyse statique et formatage du code Robot |

Vérifier l'installation :

```powershell
robot --version                                   # Robot Framework 7.5.1 (Python 3.14.8 ...)
python -c "import RequestsLibrary; print('RequestsLibrary OK')"
```

### Étape 5 : configurer Visual Studio Code et RobotCode

1. Ouvrir le dossier du projet dans VS Code : `code .`
2. Installer l'extension **RobotCode** (éditeur `d-biehl`). VS Code la propose automatiquement grâce à `.vscode/extensions.json`. Sinon, depuis un terminal :

   ```powershell
   code --install-extension d-biehl.robotcode
   ```

3. Sélectionner l'interpréteur Python du projet : `Ctrl+Maj+P` → **Python: Select Interpreter** → `.\venv\Scripts\python.exe`. Le fichier `.vscode/settings.json` le préconfigure déjà sous Windows.
4. **Désactiver les anciennes extensions Robot Framework** (par exemple *Robot Framework Intellisense*, `vivainio.robotframework`). Elles analysent aussi les fichiers `.robot` et entrent en conflit avec RobotCode (doubles diagnostics, complétion incohérente).
5. Recharger la fenêtre : `Ctrl+Maj+P` → **Developer: Reload Window**.

RobotCode apporte alors :

- coloration syntaxique, complétion des mots-clés et des variables ;
- `Ctrl+clic` sur un mot-clé pour ouvrir sa définition dans `api.resource` ;
- documentation des mots-clés au survol ;
- erreurs signalées dès la saisie (mot-clé inconnu, variable non définie, mot-clé privé utilisé dans un test...) ;
- boutons ▶ devant chaque test et vue **Testing** (icône fiole) pour lancer un test, une suite ou tout le projet, et déboguer pas à pas avec des points d'arrêt.

RobotCode lit `robot.toml` : les tests lancés depuis VS Code écrivent leurs rapports dans `results/`, comme en ligne de commande.

---

## 2. Exécution des tests

Toutes les commandes se lancent à la racine du projet, environnement virtuel activé.

### Commandes de base

```powershell
# Tous les tests (rapports dans results/)
robot --outputdir results tests

# Une seule suite
robot --outputdir results tests/users.robot

# Un seul test, par son nom
robot --outputdir results --test "Créer un post" tests
```

### Sélection par tags

Chaque test porte des tags qui permettent de composer une campagne à la demande :

| Tag | Signification |
|---|---|
| `users`, `posts` | ressource testée |
| `nominal` | comportement attendu, sans erreur |
| `smoke` | tests rapides de bon fonctionnement, à lancer en premier |
| `erreur` | cas d'erreur |
| `identifiant-invalide`, `ressource-inexistante`, `timeout` | type d'erreur |
| `cas-limite` | situation particulière mais valide |
| `limite-api` | documente un comportement surprenant de JSONPlaceholder |

```powershell
robot --outputdir results --include smoke tests          # tests de bon fonctionnement
robot --outputdir results --include erreur tests         # cas d'erreur
robot --outputdir results --include postsANDnominal tests
robot --outputdir results --exclude limite-api tests
```

### Avec la configuration `robot.toml` (RobotCode)

`robotcode robot` applique automatiquement les options de `robot.toml` (dossier `tests`, sortie dans `results/`, nom de la campagne). Des **profils** regroupent des sélections prêtes à l'emploi :

```powershell
robotcode robot                 # équivalent de : robot --outputdir results tests
robotcode -p smoke robot        # tag smoke
robotcode -p erreurs robot      # tag erreur
robotcode profiles list         # liste des profils
```

### Changer d'environnement

L'URL et le délai d'attente viennent de `variables/environment.py`. On peut les changer sans modifier le code :

```powershell
# Option de ligne de commande (prioritaire sur le fichier de variables)
robot --outputdir results --variable BASE_URL:http://localhost:3000 tests

# Variable d'environnement système, pratique en intégration continue
$env:API_BASE_URL = "http://localhost:3000"
robot --outputdir results tests
```

### Code de retour

`robot` renvoie le **nombre de tests en échec** (0 si tout passe, plafonné à 250). Un outil d'intégration continue (GitHub Actions, GitLab CI, Jenkins) s'en sert directement pour marquer le build en échec.

### Accents mal affichés dans la console Windows ?

Certains terminaux (Git Bash, anciennes consoles) affichent `R�cup�rer` au lieu de `Récupérer`. Seule la console est concernée : les rapports HTML sont corrects. Pour corriger l'affichage, forcer Python en UTF-8 :

```powershell
$env:PYTHONUTF8 = 1          # PowerShell
export PYTHONUTF8=1          # Git Bash
```

---

## 3. Structure du projet

```
JSONPlaceholder-API-TEST-Robot-FW/
├── tests/                     Suites de tests : un fichier = une suite
│   ├── users.robot            Ressource /users
│   ├── posts.robot            Ressource /posts : lecture, création, modification, suppression
│   └── errors.robot           Cas d'erreur transverses : identifiant invalide, 404, timeout
├── resources/
│   └── api.resource           Tous les mots-clés : session, appels métier, vérifications
├── variables/
│   └── environment.py         Environnement ciblé (URL, timeout) et données de référence
├── docs/
│   ├── rapports.md            Rôle et lecture de log.html, report.html, output.xml
│   └── synthese.md            Bilan : apprentissages, difficultés, comparaison PyTest / Robot
├── .vscode/                   Extensions recommandées et interpréteur Python
├── robot.toml                 Configuration RobotCode (chemins, sortie, profils)
├── robocop.toml               Configuration du linter Robocop
├── requirements.txt           Dépendances aux versions figées
└── README.md
```

Par rapport à l'arborescence demandée, une suite `errors.robot` a été ajoutée. Les cas d'erreur sont transverses (ils concernent `/users`, `/posts` et des routes inconnues) : les regrouper permet de les lancer ensemble et garde `users.robot` et `posts.robot` centrés sur le comportement de chaque ressource. Les tags `users` et `posts` permettent tout de même de sélectionner toute une ressource, cas d'erreur compris : `robot --include posts tests`.

### Les quatre notions de Robot Framework utilisées

| Notion | Où | Rôle |
|---|---|---|
| **Suite de tests** | `tests/*.robot`, et le dossier `tests/` lui-même | Un fichier `.robot` est une suite ; un dossier de suites est une suite parente. Chaque suite a son `Suite Setup` (ouverture de la session HTTP) et son `Suite Teardown` (fermeture). |
| **Resource file** | `resources/api.resource` | Bibliothèque de mots-clés écrite en Robot Framework, importée par `Resource` dans chaque suite. Ne contient pas de tests. |
| **Variables** | `variables/environment.py` | Fichier de variables Python : chaque nom en majuscules devient une variable `${NOM}`. Les données de test ne sont écrites qu'une fois. |
| **Keywords** | `resources/api.resource` | Actions réutilisables, documentées, avec arguments et valeurs par défaut. Les tests ne sont qu'un enchaînement de mots-clés. |

---

## 4. Architecture des mots-clés

L'objectif est qu'**aucune requête HTTP ni URL n'apparaisse dans les tests**. `api.resource` est organisé en quatre couches :

```
 Tests (*.robot)            Get User    1          User Should Be Valid    ${user}
                                  │                         │
 ─────────────────────────────────┼─────────────────────────┼──────────────────────────
 3. Actions métier          Get All Users           4. Vérifications métier
                            Get User                   User Should Be Valid
                            Get User Posts             User Should Be
                            Get Post                   Every User Should Be Valid
                            Create Post                Post Should Contain
                            Update Post                Every Post Should Belong To User
                            Delete Post                Number Of Items Should Be
                            Get Resource               Response Body Should Be Empty
                                  │                    User Id Should Be Rejected
                                  ▼                    Request Should Time Out
 2. Couche technique        Call API               (privé : seul point d'envoi des requêtes)
    (robot:private)         Build Post Payload     (privé : format JSON d'un post)
                                  │
 1. Session                 Open API Session / Close API Sessions
                                  │
                                  ▼
                            RequestsLibrary  →  requests  →  JSONPlaceholder
```

### Choix de conception

- **Un seul point d'envoi** : `Call API` est le seul mot-clé qui envoie des requêtes. Ajouter un en-tête d'authentification, un jeton ou une journalisation supplémentaire se fait à un seul endroit.
- **Mots-clés privés** : `Call API` et `Build Post Payload` portent le tag `robot:private`. Si un test les appelle directement, Robot Framework affiche un avertissement et RobotCode le signale dans l'éditeur. La règle « pas de requête brute dans les tests » est donc vérifiée par l'outil.
- **Un mot-clé pour le cas nominal et les cas d'erreur** : chaque action a un argument `expected_status` avec une valeur par défaut (200, ou 201 pour la création). Le même `Get User` sert pour l'utilisateur existant (`Get User    1`) et inexistant (`Get User    999    expected_status=404`). Si le code reçu est différent, RequestsLibrary fait échouer le test en indiquant l'URL et le code obtenu.
- **Actions et vérifications séparées** : les actions renvoient des données ; les vérifications les contrôlent. Un test se lit comme une spécification : *je récupère, je vérifie*.
- **Messages d'échec lisibles** : `Number Of Items Should Be` remplace `Length Should Be`, qui afficherait la liste entière des utilisateurs en cas d'échec. Les comparaisons portent un message explicite (`Nom inattendu: Ervin Howell != Leanne Graham`).
- **Session HTTP partagée et sécurisée** : une session par suite réutilise la connexion TCP. La vérification du certificat HTTPS est activée explicitement (`verify=${True}`) car RequestsLibrary la **désactive par défaut**.
- **Typage des arguments** (Robot Framework 7.3 et plus) : `Build Post Payload` déclare `${user_id: int}`. Le `userId` est ainsi envoyé comme nombre JSON (`1`) et non comme texte (`"1"`), même si le test écrit `1` en dur.
- **Données centralisées** : identifiants, nombres attendus et textes viennent de `environment.py`. Si le jeu de données change, un seul fichier est à modifier.

### Exemple : un test complet

```robotframework
Récupérer un utilisateur existant
    [Documentation]    L'utilisateur 1 est renvoyé avec son identité et tous ses champs.
    [Tags]    nominal    smoke
    ${user}=    Get User    ${EXISTING_USER_ID}
    User Should Be Valid    ${user}
    User Should Be    ${user}
    ...    id=${EXISTING_USER_ID}
    ...    name=${EXISTING_USER_NAME}
    ...    username=${EXISTING_USER_USERNAME}
    ...    email=${EXISTING_USER_EMAIL}
```

La documentation de tous les mots-clés peut être générée en HTML :

```powershell
libdoc resources/api.resource results/api-keywords.html
```

---

## 5. Scénarios couverts

| Suite | Test | Requête | Attendu |
|---|---|---|---|
| users | Récupérer tous les utilisateurs | `GET /users` | 200, 10 utilisateurs complets |
| users | Récupérer un utilisateur existant | `GET /users/1` | 200, Leanne Graham |
| users | Rechercher un utilisateur inexistant | `GET /users/999` | 404, `{}` |
| posts | Lister les posts d'un utilisateur | `GET /posts?userId=1` | 200, 10 posts, tous de l'utilisateur 1 |
| posts | Lister les posts d'un utilisateur inexistant | `GET /posts?userId=999` | 200, `[]` |
| posts | Créer un post | `POST /posts` | 201, post renvoyé avec l'id 101 |
| posts | Modifier un post | `PUT /posts/1` | 200, nouvelles valeurs |
| posts | Supprimer un post | `DELETE /posts/1` | 200, `{}` |
| posts | Un post créé n'est pas conservé par l'API | `POST /posts` puis `GET /posts/101` | 404 : écriture simulée |
| errors | Identifiant invalide | `GET /users/abc`, `/0`, `/-1`, `/1.5` | 404 pour chacun |
| errors | Ressource inexistante : post introuvable | `GET /posts/9999` | 404, `{}` |
| errors | Ressource inexistante : route inconnue | `GET /unknown-resource` | 404 |
| errors | Ressource inexistante : modification d'un post introuvable | `PUT /posts/9999` | 500 (limite de l'API) |
| errors | Ressource inexistante : suppression d'un post introuvable | `DELETE /posts/9999` | 200 (limite de l'API) |
| errors | Timeout simulé | `GET /users`, délai de 1 ms | exception `Timeout` levée |

**Identifiant invalide** est un test **piloté par les données** : `[Template]` exécute `User Id Should Be Rejected` pour chaque valeur de `@{INVALID_IDS}`. Une valeur en échec n'arrête pas les suivantes ; ajouter un cas revient à ajouter une valeur dans `environment.py`.

**Timeout simulé** : JSONPlaceholder ne propose pas de route lente. Le test ouvre donc une session dédiée avec un délai d'attente de 1 ms, impossible à tenir, et sans nouvelle tentative (`max_retries=0`). Le timeout est réel : c'est la bibliothèque `requests` qui abandonne la requête (`ReadTimeout`). La session principale n'est pas modifiée, les autres tests ne sont donc pas affectés.

---

## 6. Rapports d'exécution

Chaque exécution produit trois fichiers dans `results/` :

| Fichier | Pour qui | Contenu |
|---|---|---|
| `report.html` | responsable, équipe, client | vue d'ensemble : statut global, statistiques par suite et par tag, liste filtrable des tests |
| `log.html` | développeur, testeur | détail pas à pas : chaque mot-clé, ses arguments, les requêtes et réponses HTTP, le message d'erreur exact |
| `output.xml` | outils | données brutes de l'exécution, au format XML : fusion de campagnes (`rebot`), intégration continue, relance des seuls tests en échec |

L'explication détaillée (contenu, lecture, cas d'usage) est dans [docs/rapports.md](docs/rapports.md).

```powershell
start results\report.html      # ouvrir le rapport (Windows)
```

---

## 7. Qualité du code

[Robocop](https://robocop.dev) analyse et formate le code Robot Framework (configuration dans `robocop.toml`) :

```powershell
robocop check          # analyse : règles de nommage, longueur, syntaxe dépréciée...
robocop format         # reformatage selon le style officiel
```

État actuel : `No issues found`.

---

## 8. Ajouter un test

1. Si l'appel API n'existe pas encore, ajouter une **action métier** dans la section 3 de `api.resource`, en passant par `Call API`, avec un argument `expected_status` et une `[Documentation]`.
2. Si la vérification est réutilisable, l'ajouter dans la section 4 (**vérifications métier**).
3. Mettre les données de test (identifiants, textes, nombres attendus) dans `variables/environment.py`.
4. Écrire le test dans la suite de la ressource concernée, avec une `[Documentation]` qui explique **pourquoi** le test existe, et des `[Tags]`.
5. Lancer `robocop check`, puis les tests.

Exemple, pour tester les commentaires d'un post :

```robotframework
# resources/api.resource, section 3
Get Post Comments
    [Documentation]    ``GET /comments?postId=<id>`` : renvoie les commentaires d'un post.
    [Arguments]    ${post_id}    ${expected_status}=200
    VAR    &{params}    postId=${post_id}
    ${comments}=    Call API    GET    /comments    ${expected_status}    params=${params}
    RETURN    ${comments}
```

---

## 9. Limites connues de JSONPlaceholder

JSONPlaceholder est une API de démonstration. Ses comportements surprenants sont documentés par des tests tagués `limite-api` : si l'un d'eux échoue un jour, c'est que l'API a changé et que d'autres tests sont à revoir.

- **Les écritures ne sont pas conservées** : `POST`, `PUT` et `DELETE` renvoient la réponse attendue, mais rien n'est enregistré. Un post créé (id 101) est introuvable juste après. Les tests ne peuvent donc pas enchaîner *créer → relire → supprimer* : chaque test est indépendant.
- **`DELETE` sur un post inexistant renvoie 200** : une suppression réussie ne prouve pas que le post existait.
- **`PUT` sur un post inexistant renvoie 500** (erreur interne, en HTML), au lieu de 404.
- **Les identifiants invalides** (`abc`, `0`, `-1`, `1.5`) renvoient 404 et non 400 : l'API ne distingue pas un identifiant mal formé d'un identifiant inconnu.
- **Les tests dépendent du réseau** : sans Internet, ils échouent tous. Pour une campagne stable en intégration continue, on pourrait lancer [json-server](https://github.com/typicode/json-server), le serveur sur lequel repose JSONPlaceholder, en local, et le cibler avec `--variable BASE_URL:http://localhost:3000`.
