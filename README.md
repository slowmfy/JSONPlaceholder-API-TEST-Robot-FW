# Tests de l'interface web avec Robot Framework

Ce projet teste **l'interface web** d'une application (dossier [`app/`](app/README.md)) dans un vrai navigateur, avec [Robot Framework](https://robotframework.org) et la bibliothèque [Browser](https://robotframework-browser.org).

L'application affiche les utilisateurs et les posts de l'API publique [JSONPlaceholder](https://jsonplaceholder.typicode.com). Les tests ouvrent le navigateur, cliquent, remplissent des formulaires et vérifient ce qui s'affiche à l'écran.

**État actuel : 16 tests, 16 réussis.**

> **Versions** : la branche [`V1`](https://github.com/slowmfy/JSONPlaceholder-API-TEST-Robot-FW/tree/V1) contient la première version, qui testait l'API JSONPlaceholder (sans navigateur).

---

## 1. Selenium ou Browser ?

Robot Framework a deux bibliothèques principales pour piloter un navigateur :

| | **SeleniumLibrary** | **Browser** (utilisée ici) |
|---|---|---|
| Moteur | Selenium WebDriver | Playwright (Microsoft) |
| Ouvrir le navigateur | `Open Browser    url    chrome` | `New Browser` + `New Page    url` |
| Cliquer | `Click Element    id=btn` | `Click    id=btn` |
| Saisir du texte | `Input Text    id=champ    texte` | `Fill Text    id=champ    texte` |
| Lire et vérifier un texte | `Element Text Should Be    css=h1    Bonjour` | `Get Text    css=h1    ==    Bonjour` |
| Attendre un élément | souvent à la main (`Wait Until Element Is Visible`) | **automatique** : chaque mot-clé attend que l'élément soit prêt |
| Installation | Python seulement (+ un driver de navigateur) | Python **et** Node.js (`rfbrowser init`) |

**Ce projet n'utilise pas Selenium**, il utilise **Browser**. Les idées sont les mêmes ; seuls les noms des mots-clés changent.

---

## 2. Structure du projet

```
JSONPlaceholder-API-TEST-Robot-FW/
│
├── tests/                          ① LES TESTS : ce que l'on vérifie
│   ├── __init__.robot              démarre l'application avant tous les tests, l'arrête après
│   ├── users.robot                 7 tests : liste, recherche, fiche, rapport, langue
│   ├── posts.robot                 5 tests : lister, créer, modifier, supprimer un post
│   └── errors.robot                4 tests : messages d'erreur affichés à l'utilisateur
│
├── resources/                      ② LES MOTS-CLÉS : comment on le fait
│   ├── application.resource        démarrer / arrêter l'application, lire ses textes traduits
│   ├── common.resource             ouvrir / fermer le navigateur + ce qui existe sur toutes les pages
│   └── pages/                      un fichier par page de l'application
│       ├── users_page.resource         page « Utilisateurs »         (/users)
│       ├── user_detail_page.resource   fiche et rapport d'un utilisateur (/users/1)
│       ├── posts_page.resource         page « Posts »               (/posts)
│       └── post_detail_page.resource   détail d'un post              (/posts/1)
│
├── variables/                      ③ LES VALEURS : avec quoi on le fait
│   ├── config.py                   adresse de l'application, navigateur, délais
│   └── test_data.py                données de test : identifiants, noms, nombres attendus
│
├── app/                            l'application testée (API FastAPI + interface Angular)
├── docs/                           explications : rapports, bilan du projet
├── results/                        créé à chaque exécution : report.html, log.html (non versionné)
├── start-app.ps1 / .bat            lancer l'application à la main
├── requirements.txt                bibliothèques Python à installer
├── robot.toml                      configuration pour VS Code (RobotCode)
└── robocop.toml                    configuration du vérificateur de code Robocop
```

### La règle à retenir : 3 niveaux

| Dossier | Répond à la question | Contient | Exemple |
|---|---|---|---|
| `tests/` | **Quoi** vérifier ? | des phrases lisibles, pas de technique | `Go To Users Page` |
| `resources/` | **Comment** le faire ? | les sélecteurs HTML et les mots-clés Browser | `Click    css=main table tbody tr` |
| `variables/` | **Avec quelles valeurs** ? | des données, sans logique | `EXISTING_USER_NAME = "Leanne Graham"` |

Un test ne contient **jamais** de sélecteur HTML (`css=...`) ni de valeur en dur : s'il faut changer un bouton ou une donnée, on le change à **un seul** endroit.

### Pourquoi un fichier par page ? (le modèle *Page Object*)

Chaque fichier de `resources/pages/` décrit **une page** de l'application, toujours avec le même plan :

```robotframework
*** Variables ***
# 1. Les sélecteurs : comment trouver les éléments de CETTE page
${USER_SEARCH}    css=main input[type=search]

*** Keywords ***
# 2. Aller sur la page
Go To Users Page
# 3. Les actions possibles sur la page
Search Users
# 4. Les vérifications possibles sur la page
Users Table Should Have Rows
```

Si la page « Utilisateurs » change, on ne modifie que `users_page.resource`. Les tests, eux, ne bougent pas.

Ce qui est présent sur **toutes** les pages (le menu, le titre `h1`, les messages vert/rouge, le formulaire) est dans `common.resource`, pour ne pas le répéter.

### Qui importe quoi ?

```
tests/users.robot
   │  Resource   pages/users_page.resource ─┐
   │  Resource   pages/user_detail_page.resource ─┤
   │  Variables  variables/test_data.py        │
   │                                            ▼
   │                                  common.resource ── Library Browser   (Playwright)
   │                                     │      └────── Variables config.py
   │                                     ▼
   │                              application.resource  (mot-clé Text)
   │
tests/__init__.robot ──► application.resource  (démarrage de l'application)
```

Un test qui importe une page reçoit donc automatiquement tous les mots-clés de `common.resource` et de `application.resource`.

---

## 3. Suivre un exemple de bout en bout

Prenons le test **« Rechercher un utilisateur par ville »** et descendons niveau par niveau.

**① Le test** — [`tests/users.robot`](tests/users.robot) : il se lit comme une phrase.

```robotframework
Rechercher un utilisateur par ville
    [Documentation]    La recherche porte aussi sur la ville et ne tient pas compte des majuscules.
    [Tags]    nominal
    Go To Users Page
    Search Users    ${EXISTING_USER_CITY}
    Users Table Should Only Contain    ${EXISTING_USER_NAME}
```

**② Les valeurs** — [`variables/test_data.py`](variables/test_data.py) : chaque nom en MAJUSCULES devient une variable `${...}`.

```python
EXISTING_USER_NAME = "Leanne Graham"
EXISTING_USER_CITY = "gwenborough"
```

**③ Les mots-clés de la page** — [`resources/pages/users_page.resource`](resources/pages/users_page.resource) : ici seulement, on sait où cliquer.

```robotframework
*** Variables ***
${USER_ROWS}      css=main table tbody tr
${USER_SEARCH}    css=main input[type=search]

*** Keywords ***
Search Users
    [Arguments]    ${term}
    Fill Text    ${USER_SEARCH}    ${term}              # mot-clé de la bibliothèque Browser

Users Table Should Only Contain
    [Arguments]    ${name}
    Users Table Should Have Rows    1
    Get Text    ${USER_ROWS}    *=    ${name}           # *= veut dire « contient »
```

**④ La bibliothèque Browser** exécute `Fill Text` et `Get Text` dans le navigateur. `Get Text ... *= ...` **attend** (jusqu'à 10 s) que le texte apparaisse : pas besoin de `Sleep`.

### Le déroulement complet d'un fichier de tests

```
tests/__init__.robot     Suite Setup     → Prepare Web Application   (démarre l'application)
│
├── users.robot          Suite Setup     → Open Test Browser         (ouvre le navigateur)
│   ├── test 1           Test Setup      → Open Application          (onglet neuf, sans cookies)
│   │                    ... étapes du test ...
│   │                    Test Teardown   → Close Application         (ferme l'onglet)
│   ├── test 2           (pareil)
│   └──                  Suite Teardown  → Close Test Browser        (ferme le navigateur)
├── posts.robot          (pareil)
├── errors.robot         (pareil)
│
└──                      Suite Teardown  → Stop Web Application      (arrête l'application)
```

Chaque test démarre dans un onglet **neuf** : aucun test ne dépend du précédent.

### Les textes ne sont jamais recopiés

Les messages attendus (« Post 101 créé. ») ne sont pas écrits dans les tests. Le mot-clé `Text` (dans `application.resource`) les lit dans les traductions de l'application (`app/locales/fr.json`) :

```robotframework
${message}=    Text    created_post    id=101        # → « Post 101 créé. »
Success Message Should Be    ${message}
```

Si l'application change ce libellé, les tests suivent sans modification.

---

## 4. Installation (une seule fois)

Prérequis : **Python 3.10+**, **Node.js** (LTS), **Git**, **VS Code**, **Microsoft Edge** (déjà présent sous Windows).

```powershell
# 1. Récupérer le projet
git clone https://github.com/slowmfy/JSONPlaceholder-API-TEST-Robot-FW.git
cd JSONPlaceholder-API-TEST-Robot-FW

# 2. Créer et activer l'environnement virtuel Python
python -m venv venv
.\venv\Scripts\Activate.ps1          # si refusé : Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

# 3. Installer Robot Framework et les bibliothèques
pip install -r requirements.txt

# 4. Installer Playwright pour la bibliothèque Browser (utilise Edge sous Windows)
rfbrowser init --skip-browsers

# 5. Compiler l'interface de l'application (indispensable, sinon page blanche)
.\start-app.ps1                      # compile puis lance l'application ; Ctrl+C pour l'arrêter
```

| Paquet (`requirements.txt`) | Rôle |
|---|---|
| `robotframework` | le moteur : commande `robot` |
| `robotframework-browser` | bibliothèque **Browser** : piloter le navigateur |
| `robotframework-requests` | requêtes HTTP : vérifier que l'application répond, lire ses traductions |
| `fastapi`, `uvicorn` | font tourner l'application testée |
| `robotcode-runner`, `robotframework-robocop` | outils : exécution depuis VS Code, vérification du code |

**VS Code** : installer l'extension **RobotCode** (proposée automatiquement). Elle ajoute la complétion, `Ctrl+clic` sur un mot-clé pour ouvrir sa définition, et un bouton ▶ devant chaque test.

> **Pourquoi Edge ?** Le Chromium téléchargé par Playwright est rangé très profondément dans `venv\`. Dans un dossier au nom long (OneDrive), son chemin dépasse 260 caractères, la limite de Windows, et le navigateur ne démarre pas. Edge évite le problème. Pour Chrome : `$env:BROWSER_CHANNEL = "chrome"`.

---

## 5. Lancer les tests

À la racine du projet, environnement virtuel activé. **Pas besoin de lancer l'application** : `tests/__init__.robot` la démarre et l'arrête (si elle tourne déjà, elle est réutilisée).

```powershell
robot --outputdir results tests                                  # tous les tests (navigateur visible et ralenti)
robot --outputdir results --variable HEADLESS:True tests         # navigateur masqué : ~20 s
robot --outputdir results --suite users tests                    # un seul fichier (users.robot)
robot --outputdir results --test "Créer un post" tests           # un seul test
robot --outputdir results --include smoke tests                  # par tag
```

> Pour lancer un seul fichier, utiliser `--suite` sur le **dossier** `tests` (et non `robot tests/users.robot`), sinon `__init__.robot` est ignoré et l'application n'est pas démarrée.

Ensuite, ouvrir le rapport : `start results\report.html` (détail pas à pas, avec capture d'écran en cas d'échec, dans `results\log.html`). Voir [docs/rapports.md](docs/rapports.md).

### Tags disponibles

| Tag | Signification |
|---|---|
| `users`, `posts` | page testée |
| `nominal` | cas normal, sans erreur |
| `smoke` | tests rapides à lancer en premier |
| `erreur` | message d'erreur attendu |
| `cas-limite` | situation particulière mais valide |
| `identifiant-invalide`, `ressource-inexistante`, `validation`, `multilingue` | précision sur le cas testé |

### Régler le navigateur

| Besoin | Option |
|---|---|
| Masquer le navigateur | `--variable HEADLESS:True` |
| Ralentir / accélérer la fenêtre visible | `--variable SLOW_MO:1s --variable PAUSE_AFTER_TEST:3s` (ou `0s`) |
| Utiliser Chrome | `--variable BROWSER_CHANNEL:chrome` |
| Tester une application déjà lancée ailleurs | `$env:WEB_APP_URL = "http://serveur:8000"` |

Avec RobotCode : `robotcode robot`, `robotcode -p smoke robot`, `robotcode -p smoke -p invisible robot` (profils dans `robot.toml`).

---

## 6. Ajouter un test : exemple pas à pas

Objectif : vérifier que la page « Posts » affiche 100 posts.

**1. La donnée** dans [`variables/test_data.py`](variables/test_data.py) :

```python
POSTS_COUNT = 100
```

**2. Le mot-clé** dans la page concernée, [`resources/pages/posts_page.resource`](resources/pages/posts_page.resource), section vérifications. `${LIST_ROWS}` existe déjà dans `common.resource` :

```robotframework
Posts List Should Have
    [Documentation]    Vérifie le nombre de posts affichés.
    [Arguments]    ${count}
    Get Element Count    ${LIST_ROWS}    ==    ${count}
```

**3. Le test** dans [`tests/posts.robot`](tests/posts.robot) :

```robotframework
Afficher tous les posts
    [Documentation]    La page des posts affiche les 100 posts de JSONPlaceholder.
    [Tags]    nominal
    Go To Posts Page
    Posts List Should Have    ${POSTS_COUNT}
```

**4. Vérifier** : `robocop check`, puis `robot --outputdir results --test "Afficher tous les posts" tests`.

> Pour trouver un sélecteur : dans le navigateur, clic droit sur l'élément → **Inspecter**. Préférer un `id`, un `name` ou un rôle stable plutôt qu'une longue chaîne de classes CSS.

---

## 7. Qualité du code

```powershell
robocop check      # vérifie le code (nommage, longueur, syntaxe) : « No issues found »
robocop format     # remet en forme selon le style officiel
```

## 8. Limites connues

- **Internet est nécessaire** : l'application interroge JSONPlaceholder en direct.
- **Rien n'est vraiment enregistré** : JSONPlaceholder simule les créations, modifications et suppressions. L'application l'indique (« opération simulée ») et garde le résultat seulement dans l'onglet ouvert.
- **L'interface doit être compilée** une fois (`.\start-app.ps1`) ; sinon la page reste blanche et tous les tests échouent en attendant le menu (`waiting for locator('header nav')`).
- Les tests vérifient les textes **en français**, la langue par défaut.
