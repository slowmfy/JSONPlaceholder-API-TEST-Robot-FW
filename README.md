# JSONPlaceholder — Tests Robot Framework

Campagne de tests automatisés écrite avec [Robot Framework](https://robotframework.org). Elle couvre deux cibles :

1. **L'API REST publique [JSONPlaceholder](https://jsonplaceholder.typicode.com)**, testée avec [RequestsLibrary](https://github.com/MarketSquare/robotframework-requests).
2. **L'application web du projet précédent**, incluse dans le dossier [`app/`](app/README.md) :
   - son **API web FastAPI** (`web_api.py`), testée avec RequestsLibrary ;
   - son **interface Angular**, testée dans un vrai navigateur avec la bibliothèque [Browser](https://robotframework-browser.org) (Playwright).

Le dépôt est **autonome** : l'application testée est copiée dans `app/` depuis le projet précédent ([JSONPlaceholder-API-TEST](https://github.com/slowmfy/JSONPlaceholder-API-TEST), commit `a8f3def`). On la lance avec `.\start-app.ps1`, et les tests la démarrent eux-mêmes. Les scénarios du projet Python/PyTest précédent sont réécrits sous forme de mots-clés métier réutilisables.

> La consigne demandait un dépôt contenant uniquement les tests. L'application est donc isolée dans `app/` : les tests Robot Framework restent dans `tests/`, `resources/` et `variables/`, et ne dépendent d'`app/` que par l'URL du serveur. Pour tester une autre copie de l'application, il suffit de définir `WEB_APP_DIR`.

**État actuel : 44 tests, 44 réussis**, en 27 secondes environ fenêtre masquée, 1 min 30 environ fenêtre visible (démarrage de l'application compris).

| Campagne | Dossier | Tests | Durée |
|---|---|---|---|
| API JSONPlaceholder | `tests/*.robot` | 15 | ~3 s |
| API web de l'application | `tests/web/web_api.robot` | 13 | ~1 s |
| Interface Angular | `tests/web/ui_*.robot` | 16 | ~20 s masquée, ~1 min 20 visible (ralentie) |

## Sommaire

1. [Installation](#1-installation)
2. [Exécution des tests](#2-exécution-des-tests)
3. [Structure du projet](#3-structure-du-projet)
4. [Architecture des mots-clés](#4-architecture-des-mots-clés)
5. [Scénarios couverts](#5-scénarios-couverts)
6. [Rapports d'exécution](#6-rapports-dexécution)
7. [Qualité du code](#7-qualité-du-code)
8. [Ajouter un test](#8-ajouter-un-test)
9. [Limites connues](#9-limites-connues)

---

## 1. Installation

### Prérequis

| Outil | Version testée | Rôle |
|---|---|---|
| Python | 3.14.8 (3.10 minimum) | Robot Framework est écrit en Python |
| Node.js | 26.13 (LTS recommandée) | compilation de l'interface Angular, bibliothèque Browser (Playwright) |
| Git | toute version récente | récupération du dépôt |
| Visual Studio Code | toute version récente | éditeur, avec l'extension RobotCode |
| Microsoft Edge | préinstallé sous Windows | navigateur des tests d'interface (voir étape 6) |
| Accès Internet | — | les tests appellent la vraie API JSONPlaceholder |

Les tests de l'API JSONPlaceholder (`tests/*.robot`) n'ont besoin que de Python. Node.js et l'application web ne servent qu'aux tests de `tests/web/`.

### Étape 1 : installer Python et Node.js

1. Python : <https://www.python.org/downloads/>. **Windows** : cocher **« Add python.exe to PATH »** dans l'installateur.
2. Node.js : <https://nodejs.org/> (version LTS).
3. Vérifier dans un nouveau terminal :

   ```powershell
   python --version     # Python 3.10 ou plus
   node --version       # v20 ou plus
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

### Étape 4 : installer Robot Framework et les bibliothèques

```powershell
python -m pip install --upgrade pip
pip install -r requirements.txt
```

`requirements.txt` fixe les versions exactes, ce qui garantit le même environnement pour tous les développeurs :

| Paquet | Rôle |
|---|---|
| `robotframework` | moteur d'exécution des tests (`robot`) |
| `robotframework-requests` | RequestsLibrary : mots-clés HTTP (`GET On Session`...), basée sur la bibliothèque Python `requests` |
| `robotframework-browser` | Browser : pilotage d'un navigateur avec Playwright, pour les tests d'interface |
| `robotcode-runner` | commande `robotcode` : exécution avec la configuration `robot.toml` |
| `robotframework-robocop` | analyse statique et formatage du code Robot |

### Étape 5 : lancer l'application web (le front)

L'application testée (API FastAPI + interface Angular) est dans `app/`. Ses dépendances Python (FastAPI, uvicorn) sont déjà installées par `requirements.txt`, dans le même `venv`.

```powershell
.\start-app.ps1          # interface sur http://127.0.0.1:8000 (Ctrl+C pour arrêter)
.\start-app.ps1 dev      # mode développement Angular : http://localhost:4200, rechargement automatique
.\start-app.bat          # même chose si PowerShell refuse d'exécuter le script (ou double-clic)
```

Au premier lancement, le script installe les dépendances Angular (`npm ci`, quelques minutes) et compile l'interface. Les lancements suivants sont immédiats ; l'interface n'est recompilée que si ses sources ont changé (`-Rebuild` pour forcer).

Lancer l'application à la main n'est pas nécessaire pour les tests : ils la démarrent eux-mêmes. En revanche, **l'interface doit avoir été compilée une fois** (par `start-app.ps1`, ou `npm ci` puis `npm run build` dans `app/frontend`).

### Étape 6 : initialiser la bibliothèque Browser

Browser s'appuie sur Playwright, un programme Node.js qu'il faut installer à part :

```powershell
# Windows : les tests utilisent Microsoft Edge, déjà installé
rfbrowser init --skip-browsers

# Linux / macOS / intégration continue : télécharger Chromium (~700 Mo)
rfbrowser init chromium
```

> **Pourquoi Edge sous Windows ?** Playwright range son propre Chromium très profondément dans `venv\Lib\site-packages\Browser\wrapper\node_modules\playwright-core\.local-browsers\...`. Si le projet se trouve dans un dossier au nom long (par exemple dans OneDrive), le chemin du navigateur dépasse **260 caractères**, la limite historique de Windows (`MAX_PATH`). Le lancement échoue alors avec `spawn ... chrome-headless-shell.exe ENOENT`, alors que le fichier existe bien (le chemin mesurait 279 caractères ici). Edge, basé sur Chromium et toujours présent sous Windows, évite le problème. Le navigateur se change avec la variable d'environnement `BROWSER_CHANNEL` : `chrome`, `msedge`, ou vide pour le Chromium de Playwright.

Vérifier l'installation :

```powershell
robot --version                                   # Robot Framework 7.5.1 (Python 3.14.8 ...)
python -c "import RequestsLibrary, Browser; print('Bibliothèques OK')"
```

### Étape 7 : configurer Visual Studio Code et RobotCode

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
- `Ctrl+clic` sur un mot-clé pour ouvrir sa définition dans `resources/` ;
- documentation des mots-clés au survol ;
- erreurs signalées dès la saisie (mot-clé inconnu, variable non définie, mot-clé privé utilisé dans un test...) ;
- boutons ▶ devant chaque test et vue **Testing** (icône fiole) pour lancer un test, une suite ou tout le projet, et déboguer pas à pas avec des points d'arrêt.

RobotCode lit `robot.toml` : les tests lancés depuis VS Code écrivent leurs rapports dans `results/`, comme en ligne de commande.

---

## 2. Exécution des tests

Toutes les commandes se lancent à la racine du projet, environnement virtuel activé.

### Commandes de base

```powershell
# Toute la campagne : JSONPlaceholder, API web et interface
robot --outputdir results tests

# Seulement l'API JSONPlaceholder (pas besoin de l'application web)
robot --outputdir results --include jsonplaceholder tests

# Seulement l'application web (API FastAPI + interface)
robot --outputdir results tests/web

# Une suite web, en gardant l'initialisation du dossier (démarrage de l'application)
robot --outputdir results --suite ui_posts tests/web

# Un seul test, par son nom
robot --outputdir results --test "Créer un post" tests
```

**L'application web est démarrée automatiquement.** `tests/web/__init__.robot` la lance avant les suites web et l'arrête après. Si elle répond déjà sur `http://127.0.0.1:8000` (lancée avec `start-app.ps1`, par exemple), elle est réutilisée et laissée en marche. Sa sortie console est enregistrée dans `results/web_app.log`.

> Lancer directement un fichier web (`robot tests/web/ui_posts.robot`) ignore `__init__.robot` : l'application n'est alors pas démarrée et les traductions ne sont pas chargées. Il faut passer par le dossier et `--suite`, comme ci-dessus. RobotCode le fait automatiquement depuis VS Code.

### Voir le navigateur pendant les tests

Ce sont les tests qui ouvrent la fenêtre du navigateur : par défaut, elle est **visible**, et on voit chaque test naviguer, remplir les formulaires et cliquer. Chaque suite d'interface ouvre sa fenêtre au début et la ferme à la fin.

Pour qu'on puisse suivre les changements à l'œil, la fenêtre visible est **ralentie** : 0,5 s entre chaque action (`SLOW_MO`) et 2 s à la fin de chaque test (`PAUSE_AFTER_TEST`), le temps de voir le résultat. Les 16 tests d'interface prennent alors environ 1 min 20 au lieu de 20 s. Pour régler la vitesse :

```powershell
robot --outputdir results --variable SLOW_MO:1s --variable PAUSE_AFTER_TEST:3s tests/web   # plus lent
robot --outputdir results --variable SLOW_MO:0s --variable PAUSE_AFTER_TEST:0s tests/web   # pleine vitesse
```

Pour la masquer (intégration continue, serveur sans écran), utiliser le mode *headless* ; les ralentissements sont alors ignorés :

```powershell
robot --outputdir results --variable HEADLESS:True tests/web
$env:HEADLESS = "true"        # ou par variable d'environnement
```

Les tests démarrent l'application eux-mêmes. Pour continuer à naviguer dans l'application après les tests, lance-la d'abord avec `.\start-app.ps1` : les tests la réutilisent et la laissent en marche.

> Les modifications faites par un test (post créé, modifié, supprimé) ne sont visibles que dans la fenêtre de ce test. JSONPlaceholder ne conserve aucune écriture, et l'interface garde le résultat localement, le temps de la page : un autre onglet ou un autre navigateur ne les verra pas.

### Sélection par tags

Chaque test porte des tags qui permettent de composer une campagne à la demande :

| Tag | Signification |
|---|---|
| `jsonplaceholder` | API publique JSONPlaceholder |
| `web` | application web de `app/` (`web-api` : son API, `ui` : son interface) |
| `users`, `posts` | ressource testée |
| `nominal` | comportement attendu, sans erreur |
| `smoke` | tests rapides de bon fonctionnement, à lancer en premier |
| `erreur` | cas d'erreur |
| `identifiant-invalide`, `ressource-inexistante`, `validation`, `timeout` | type d'erreur |
| `cas-limite` | situation particulière mais valide |
| `limite-api` | documente un comportement surprenant de JSONPlaceholder |
| `securite`, `explorateur`, `multilingue` | thème transverse |

```powershell
robot --outputdir results --include smoke tests          # tests de bon fonctionnement
robot --outputdir results --include erreur tests         # tous les cas d'erreur, API et interface
robot --outputdir results --include postsANDui tests     # les posts dans l'interface
robot --outputdir results --exclude ui tests             # tout sauf le navigateur
```

### Avec la configuration `robot.toml` (RobotCode)

`robotcode robot` applique automatiquement les options de `robot.toml` (dossier `tests`, sortie dans `results/`, nom de la campagne). Des **profils** regroupent des sélections prêtes à l'emploi :

```powershell
robotcode robot                       # toute la campagne
robotcode -p jsonplaceholder robot    # API JSONPlaceholder uniquement
robotcode -p web robot                # application web
robotcode -p ui robot                 # interface uniquement
robotcode -p ui -p invisible robot    # interface, navigateur masqué
robotcode -p smoke robot              # tag smoke
robotcode -p erreurs robot            # tag erreur
robotcode profiles list               # liste des profils
```

### Changer d'environnement

Les URL et réglages viennent de `variables/environment.py` (JSONPlaceholder) et `variables/web.py` (application web). On peut les changer sans modifier le code :

| Besoin | Variable d'environnement | ou option `robot` |
|---|---|---|
| Autre URL de JSONPlaceholder | `API_BASE_URL` | `--variable BASE_URL:http://localhost:3000` |
| Application web déjà déployée ailleurs | `WEB_APP_URL` | `--variable WEB_URL:http://recette:8000` |
| Tester une autre copie de l'application (son dépôt d'origine, par exemple) | `WEB_APP_DIR` | — (variable d'environnement uniquement : le Python de son `venv` est alors utilisé) |
| Autre navigateur | `BROWSER_CHANNEL` (`chrome`, `msedge`, vide) | `--variable BROWSER_CHANNEL:chrome` |
| Navigateur masqué (visible par défaut) | `HEADLESS=true` | `--variable HEADLESS:True` |
| Vitesse de la fenêtre visible | `SLOW_MO` (500ms), `PAUSE_AFTER_TEST` (2s) | `--variable SLOW_MO:1s --variable PAUSE_AFTER_TEST:3s` |

```powershell
$env:WEB_APP_URL = "http://recette:8000"    # PowerShell
robot --outputdir results tests/web
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
├── tests/                       Suites de tests : un fichier = une suite, un dossier = une suite parente
│   ├── users.robot              JSONPlaceholder : ressource /users
│   ├── posts.robot              JSONPlaceholder : lecture, création, modification, suppression de posts
│   ├── errors.robot             JSONPlaceholder : identifiant invalide, 404, timeout
│   └── web/                     Application web de app/
│       ├── __init__.robot       Démarre l'application avant le dossier, l'arrête après
│       ├── web_api.robot        API web FastAPI : validation, erreurs, rapport, explorateur
│       ├── ui_users.robot       Interface : utilisateurs, recherche, rapport, langue
│       ├── ui_posts.robot       Interface : lister, créer, modifier, supprimer des posts
│       └── ui_errors.robot      Interface : messages d'erreur affichés à l'utilisateur
├── resources/
│   ├── http.resource            Couche HTTP technique partagée (sessions, envoi des requêtes)
│   ├── api.resource             Mots-clés de l'API JSONPlaceholder
│   ├── web_api.resource         Mots-clés de l'API web de l'application
│   ├── web_app.resource         Démarrage/arrêt de l'application, traductions
│   └── web_ui.resource          Pilotage de l'interface : sélecteurs, actions, vérifications
├── variables/
│   ├── environment.py           JSONPlaceholder : URL, timeout, données de référence
│   └── web.py                   Application web : URL, emplacement, navigateur, données
├── docs/
│   ├── rapports.md              Rôle et lecture de log.html, report.html, output.xml
│   └── synthese.md              Bilan : apprentissages, difficultés, comparaison PyTest / Robot
├── app/                         Application web testée : API FastAPI + interface Angular (voir app/README.md)
├── .vscode/                     Extensions recommandées et interpréteur Python
├── start-app.ps1, start-app.bat Lancement de l'application (le front) sur http://127.0.0.1:8000
├── robot.toml                   Configuration RobotCode (chemins, sortie, profils)
├── robocop.toml                 Configuration du linter Robocop
├── requirements.txt             Dépendances aux versions figées
└── README.md
```

Par rapport à l'arborescence demandée :

- **`errors.robot`** regroupe les cas d'erreur de JSONPlaceholder. Ils sont transverses (`/users`, `/posts`, routes inconnues) : les regrouper permet de les lancer ensemble et garde `users.robot` et `posts.robot` centrés sur chaque ressource. Les tags `users` et `posts` permettent tout de même de sélectionner toute une ressource, cas d'erreur compris.
- **`tests/web/`** et ses ressources testent le reste du projet actuel, son API web et son interface. Ces tests sont isolés dans un dossier pour que la campagne JSONPlaceholder reste exécutable sans l'application (`--include jsonplaceholder`).
- **`app/`** contient l'application testée, pour que le dépôt soit autonome. Elle est séparée des tests : aucun fichier de `tests/`, `resources/` ou `variables/` n'importe son code, les tests ne communiquent avec elle que par HTTP et par le navigateur.

### Les notions de Robot Framework utilisées

| Notion | Où | Rôle |
|---|---|---|
| **Suite de tests** | `tests/*.robot`, `tests/web/*.robot` | Un fichier `.robot` est une suite ; un dossier de suites est une suite parente. Chaque suite a son `Suite Setup` et son `Suite Teardown`. |
| **Fichier d'initialisation** | `tests/web/__init__.robot` | Setup et teardown d'un *dossier* entier : l'application web n'est démarrée qu'une fois pour les 4 suites web. |
| **Resource file** | `resources/*.resource` | Bibliothèque de mots-clés écrite en Robot Framework, importée par `Resource`. Ne contient pas de tests. |
| **Variables** | `variables/*.py` | Fichiers de variables Python : chaque nom en majuscules devient une variable `${NOM}`, avec son type. |
| **Keywords** | `resources/*.resource` | Actions réutilisables, documentées, avec arguments et valeurs par défaut. Les tests ne sont qu'un enchaînement de mots-clés. |
| **Setup / teardown de test** | suites `ui_*.robot` | `Test Setup` ouvre un contexte de navigateur neuf pour chaque test, `Test Teardown` le ferme. |
| **Templates** | `errors.robot`, `web_api.robot`, `ui_errors.robot` | Tests pilotés par les données : un mot-clé, plusieurs jeux de valeurs. |

---

## 4. Architecture des mots-clés

L'objectif est qu'**aucune requête HTTP, URL ni sélecteur HTML n'apparaisse dans les tests**.

```
 Tests            tests/*.robot                 tests/web/web_api.robot       tests/web/ui_*.robot
                       │                                  │                            │
 ──────────────────────┼──────────────────────────────────┼────────────────────────────┼────────────
 Métier          api.resource                     web_api.resource             web_ui.resource
                 Get User, Create Post...         Get Web User,                Go To Users Page,
                 User Should Be Valid...          Create Web Post...           Create Post From Form,
                       │                          Error Should Be...           Success Message Should Be...
                       │ Call API (privé)                 │ Call Web API (privé)       │
 Technique             └──────────────┬───────────────────┘                            │ sélecteurs
                                http.resource                                          │ (*** Variables ***)
                       Open HTTP Session, Send Request On Session                      │
                                      │                     web_app.resource ◄─────────┤ textes traduits
                                      ▼                     (démarrage, Text)          ▼
 Bibliothèques                 RequestsLibrary                                  Browser (Playwright)
                                      │                                                │
 Cibles                 JSONPlaceholder   API web FastAPI  ◄───────────────  Interface Angular
```

### Choix de conception

- **Une seule couche HTTP pour deux API** : `http.resource` ouvre les sessions et envoie les requêtes. `api.resource` et `web_api.resource` n'ont chacun qu'un mot-clé privé (`Call API`, `Call Web API`) qui lui délègue en fixant la session. Ajouter un en-tête, un jeton ou une journalisation se fait à un seul endroit, pour les deux API.
- **Mots-clés privés** : `Call API`, `Call Web API` et `Build Post Payload` portent le tag `robot:private`. Si un test les appelle directement, Robot Framework affiche un avertissement et RobotCode le signale dans l'éditeur. La règle « pas de requête brute dans les tests » est donc vérifiée par l'outil.
- **Un mot-clé pour le cas nominal et les cas d'erreur** : chaque action a un argument `expected_status` avec une valeur par défaut (200, ou 201 pour la création). Le même `Get User` sert pour l'utilisateur existant (`Get User    1`) et inexistant (`Get User    999    expected_status=404`).
- **Page objects pour l'interface** : `web_ui.resource` est le seul fichier qui connaît le HTML. Ses sélecteurs sont regroupés dans sa section `*** Variables ***` : si une page change, c'est là qu'on les met à jour. Seule exception : les champs de formulaire, trouvés par leur nom (`title`, `body`) car Angular génère leur `id`. Les tests décrivent ce que fait l'utilisateur (`Create Post From Form`, `Ask To Delete Displayed Post`, `Confirm Deletion`).
- **Aucun texte de l'interface recopié** : les messages attendus (« Post 101 créé. », « Utilisateur 999 introuvable. ») viennent des traductions de l'application, chargées depuis `/api/translations/fr`. Le mot-clé `Text    created_post    id=101` produit le texte exact. Si un libellé change dans `locales/fr.json`, les tests suivent sans modification.
- **Aucune pause fixe** : les mots-clés de vérification de Browser (`Get Text    css=h1    ==    Leanne Graham`) attendent que la condition soit vraie, jusqu'à 10 secondes. Pas de `Sleep`, donc des tests à la fois rapides et stables.
- **Tests isolés** : chaque test d'interface s'exécute dans un *contexte* de navigateur neuf (pas de cookies ni de `localStorage`). La langue choisie dans un test n'affecte donc pas le suivant.
- **Application démarrée à la demande** : `__init__.robot` démarre l'application si elle ne répond pas, et ne l'arrête que s'il l'a lancée lui-même.
- **Messages d'échec lisibles** : `Number Of Items Should Be` remplace `Length Should Be`, qui afficherait la liste entière des utilisateurs en cas d'échec. Les comparaisons portent un message explicite (`Nom inattendu: Ervin Howell != Leanne Graham`).
- **Session HTTP sécurisée** : la vérification du certificat HTTPS est activée explicitement (`verify=${True}`), car RequestsLibrary la **désactive par défaut**.
- **Typage des arguments** (Robot Framework 7.3 et plus) : `Build Post Payload` déclare `${user_id: int}`, pour envoyer `userId` comme nombre JSON (`1`) et non comme texte (`"1"`).
- **Données centralisées** : identifiants, nombres attendus et textes viennent de `variables/`. Les tests d'interface réutilisent les données de `environment.py`.

### Exemple : le même scénario à trois niveaux

```robotframework
# tests/posts.robot : API JSONPlaceholder
Créer un post
    ${post}=    Create Post    ${EXISTING_USER_ID}    ${NEW_POST_TITLE}    ${NEW_POST_BODY}
    Post Should Contain    ${post}    ${EXISTING_USER_ID}    ${NEW_POST_TITLE}    ${NEW_POST_BODY}

# tests/web/web_api.robot : API web de l'application
Créer un post
    ${result}=    Create Web Post    1    Titre    Contenu
    Should Be Equal As Integers    ${result}[item][id]    101
    Write Should Be Simulated    ${result}

# tests/web/ui_posts.robot : interface, dans le navigateur
Créer un post
    Go To Posts Page
    Create Post From Form    ${EXISTING_USER_ID}    ${NEW_POST_TITLE}    ${NEW_POST_BODY}
    ${message}=    Text    created_post    id=${CREATED_POST_ID}
    Success Message Should Be    ${message}
    Simulated Write Notice Should Be Shown
    Post Should Be Listed    ${NEW_POST_TITLE}
```

La documentation de tous les mots-clés peut être générée en HTML :

```powershell
libdoc resources/api.resource results/api-keywords.html
libdoc resources/web_ui.resource results/web-ui-keywords.html
```

---

## 5. Scénarios couverts

### API JSONPlaceholder (`tests/*.robot`, tag `jsonplaceholder`)

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

**Identifiant invalide** est un test **piloté par les données** : `[Template]` exécute `User Id Should Be Rejected` pour chaque valeur de `@{INVALID_IDS}`. Une valeur en échec n'arrête pas les suivantes.

**Timeout simulé** : JSONPlaceholder ne propose pas de route lente. Le test ouvre une session dédiée avec un délai de 1 ms, impossible à tenir, et sans nouvelle tentative (`max_retries=0`). Le timeout est réel : c'est `requests` qui abandonne la requête (`ReadTimeout`).

### API web de l'application (`tests/web/web_api.robot`, tag `web-api`)

| Test | Requête | Attendu |
|---|---|---|
| Lister les langues de l'interface | `GET /api/languages` | `fr`, `en` |
| Rapport d'un utilisateur | `GET /api/users/1/report` | 10 posts, 50 commentaires, post le plus commenté |
| Créer un post | `POST /api/posts` | 201, id 101, `simulated: true` |
| Identifiant invalide refusé avant l'appel à JSONPlaceholder | `GET /api/users/abc`, `/0`, `/-1` | 422, `error_not_integer` ou `error_not_positive`, champ `id` |
| Utilisateur inexistant | `GET /api/users/999` | 404, `user_not_found` |
| Créer un post sans titre | `POST /api/posts` | 422, `error_required`, champ `title` |
| Créer un post pour un auteur inexistant | `POST /api/posts`, `user_id: 11` | 404, `user_not_found`, champ `user_id` |
| Créer un utilisateur avec un email invalide | `POST /api/users` | 422, `error_invalid_email`, champ `email` |
| Modifier un post inexistant | `PATCH /api/posts/9999` | 404 (JSONPlaceholder seul : 500) |
| Supprimer un post inexistant | `DELETE /api/posts/9999` | 404 (JSONPlaceholder seul : 200) |
| Route inconnue | `GET /api/unknown-resource` | 404, erreur JSON et non la page Angular |
| Explorateur : relayer une requête | `POST /api/explorer` `GET /users/1` | réponse de JSONPlaceholder |
| Explorateur : refuser une adresse externe | `POST /api/explorer` `https://example.com/` | 422 `error_invalid_path` (protection SSRF) |

Ces tests montrent que l'application **corrige les limites de JSONPlaceholder** relevées dans `errors.robot` : elle valide les saisies et vérifie l'existence des ressources avant de les modifier ou de les supprimer.

### Interface Angular (`tests/web/ui_*.robot`, tag `ui`)

| Suite | Test | Parcours | Attendu à l'écran |
|---|---|---|---|
| ui_users | Afficher la liste des utilisateurs | page d'accueil | tableau de 10 lignes |
| ui_users | Rechercher un utilisateur par ville | recherche « gwenborough » | une seule ligne : Leanne Graham |
| ui_users | Rechercher un utilisateur sans résultat | recherche sans correspondance | « Aucun résultat. » |
| ui_users | Ouvrir la fiche d'un utilisateur depuis la liste | clic sur le nom | nom, `@Bret`, 10 posts dans l'onglet |
| ui_users | Ouvrir un utilisateur par son identifiant | « Accès direct » : 2 | fiche d'Ervin Howell |
| ui_users | Afficher le rapport d'un utilisateur | `/users/1/report` | 10 posts, 50 commentaires |
| ui_users | Changer la langue de l'interface | sélecteur : English | menu et titre en anglais |
| ui_posts | Lister les posts d'un utilisateur | fiche de l'utilisateur 1 | 10 posts |
| ui_posts | Créer un post | Ajouter → formulaire → Créer | « Post 101 créé. », mention « opération simulée », post ajouté à la liste |
| ui_posts | Modifier un post | Modifier → nouveau titre → Enregistrer | « Post 1 modifié. », nouveau titre |
| ui_posts | Supprimer un post après confirmation | Supprimer → confirmer | question de confirmation, puis « Post 1 supprimé. » |
| ui_posts | Annuler une suppression | Supprimer → Annuler | post toujours affiché, aucun message |
| ui_errors | Identifiant invalide | « Accès direct » : `abc`, `0`, `-1` | message d'erreur explicite pour chacun |
| ui_errors | Utilisateur inexistant | `/users/999` | « Utilisateur 999 introuvable. » |
| ui_errors | Post inexistant | `/posts/9999` | « Post 9999 introuvable. » |
| ui_errors | Créer un post sans titre | formulaire, titre vide | « Ce champ est obligatoire. » sous le champ, marqué `aria-invalid` |

Plusieurs tests d'interface automatisent, côté web, des cas de tests manuels du projet précédent (`docs/cas_de_tests.md` : TC001, TC002, TC003, TC004, TC007, TC009, TC015, TC016, TC019, TC021).

---

## 6. Rapports d'exécution

Chaque exécution produit trois fichiers dans `results/` :

| Fichier | Pour qui | Contenu |
|---|---|---|
| `report.html` | responsable, équipe, client | vue d'ensemble : statut global, statistiques par suite et par tag, liste filtrable des tests |
| `log.html` | développeur, testeur | détail pas à pas : chaque mot-clé, ses arguments, les requêtes et réponses HTTP, les actions dans le navigateur, une **capture d'écran** en cas d'échec d'un test d'interface |
| `output.xml` | outils | données brutes de l'exécution, au format XML : fusion de campagnes (`rebot`), intégration continue, relance des seuls tests en échec |

S'y ajoutent, pour les tests web : `web_app.log` (sortie de l'application quand les tests l'ont démarrée), `browser/screenshot/` (captures d'écran des échecs) et `playwright-log.txt` (journal technique de Playwright).

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

État actuel : `No issues found`. Deux règles sont désactivées, avec leur justification en commentaire : MISC04 (faux positif sur la syntaxe `VAR`) et, sur trois lignes de `web_app.resource`, VAR05 (variables de suite voulues, partagées par `__init__.robot`).

---

## 8. Ajouter un test

1. Si l'appel API n'existe pas encore, ajouter une **action métier** dans `api.resource` ou `web_api.resource`, en passant par `Call API` / `Call Web API`, avec un argument `expected_status` et une `[Documentation]`.
2. Pour l'interface : ajouter le **sélecteur** dans la section `*** Variables ***` de `web_ui.resource`, puis un mot-clé qui décrit l'action de l'utilisateur. Utiliser `Text` pour les libellés plutôt que de les recopier.
3. Si la vérification est réutilisable, l'ajouter dans la section **vérifications** du fichier.
4. Mettre les données de test (identifiants, textes, nombres attendus) dans `variables/`.
5. Écrire le test dans la suite concernée, avec une `[Documentation]` qui explique **pourquoi** le test existe, et des `[Tags]`.
6. Lancer `robocop check`, puis les tests.

Exemple, pour tester les commentaires d'un post via JSONPlaceholder :

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

## 9. Limites connues

### JSONPlaceholder

JSONPlaceholder est une API de démonstration. Ses comportements surprenants sont documentés par des tests tagués `limite-api` : si l'un d'eux échoue un jour, c'est que l'API a changé et que d'autres tests sont à revoir.

- **Les écritures ne sont pas conservées** : `POST`, `PUT` et `DELETE` renvoient la réponse attendue, mais rien n'est enregistré. Un post créé (id 101) est introuvable juste après. Les tests ne peuvent donc pas enchaîner *créer → relire → supprimer* : chaque test est indépendant.
- **`DELETE` sur un post inexistant renvoie 200** : une suppression réussie ne prouve pas que le post existait.
- **`PUT` sur un post inexistant renvoie 500** (erreur interne, en HTML), au lieu de 404.
- **Les identifiants invalides** (`abc`, `0`, `-1`, `1.5`) renvoient 404 et non 400.
- **Les tests dépendent du réseau** : sans Internet, ils échouent. Pour une campagne stable en intégration continue, on pourrait lancer [json-server](https://github.com/typicode/json-server), le serveur sur lequel repose JSONPlaceholder, en local, et le cibler avec `--variable BASE_URL:http://localhost:3000`.

### Application web

- **Elle dépend aussi de JSONPlaceholder** : ses tests échouent sans Internet.
- **Les erreurs réseau** (API JSONPlaceholder injoignable, 502 ; délai dépassé, 504) ne sont pas testées de bout en bout : il faudrait couper JSONPlaceholder pendant l'exécution. Elles restent couvertes par les tests PyTest du projet précédent, qui simulent le réseau.
- **L'interface doit être compilée** (`npm run build` dans `app/frontend/`, fait par `start-app.ps1`) : sans cela, l'application affiche « Interface non compilée » et les tests d'interface échouent.
- **`app/` est une copie** : une correction faite dans le projet d'origine doit y être reportée (et inversement). Le commit d'origine (`a8f3def`) est indiqué dans `app/README.md`.
- **Les tests vérifient les textes en français**, la langue par défaut de l'interface. Les textes attendus sont chargés depuis l'application (`UI_LANGUAGE`), mais rejouer la campagne en anglais demanderait aussi de choisir la langue à l'ouverture de chaque contexte de navigateur.
