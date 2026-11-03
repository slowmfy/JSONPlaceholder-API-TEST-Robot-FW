# Synthèse : découverte de Robot Framework

**Projet** : automatisation des tests de l'API JSONPlaceholder avec Robot Framework 7.5 et RequestsLibrary 0.9.7
**Résultat** : 15 tests (3 suites, 4 couches de mots-clés), tous réussis en 3 secondes environ, aucune alerte Robocop.

## 1. Ce que j'ai appris

**La logique « mots-clés ».** En Robot Framework, un test n'est pas du code : c'est une suite d'actions nommées en langage naturel (`Get User`, `User Should Be Valid`). Le travail principal ne consiste donc pas à écrire des tests, mais à concevoir un **vocabulaire** de mots-clés. J'ai organisé `api.resource` en quatre couches : session, couche technique privée (`Call API`, seul point d'envoi des requêtes), actions métier, vérifications métier. Résultat : aucune URL ni requête n'apparaît dans les tests. Si l'API ajoute une authentification demain, seul `Call API` est à modifier.

**Les briques d'un projet Robot Framework** :

- les **suites** : un fichier `.robot` est une suite, un dossier est une suite parente. `Suite Setup` et `Suite Teardown` jouent le rôle des fixtures PyTest de portée module ;
- les **resource files** : bibliothèques de mots-clés partagées ;
- les **fichiers de variables Python** : ils gardent les types (`${USERS_COUNT}` est un entier) et peuvent lire des variables d'environnement. L'option `--variable` de la ligne de commande est prioritaire, ce qui permet de changer d'environnement sans toucher au code ;
- les **tags**, qui permettent de composer une campagne à la demande (`--include smoke`, `--include postsANDnominal`) et produisent des statistiques par tag dans le rapport ;
- les **templates** (`[Template]`), pour les tests pilotés par les données : un mot-clé, plusieurs jeux de valeurs, et l'exécution continue même si une valeur échoue.

**Les nouveautés de Robot Framework 7**, que beaucoup de tutoriels ne montrent pas encore : la syntaxe `VAR` (au lieu de `Create Dictionary`), `RETURN`, le typage des arguments (`${user_id: int}`) et le tag `robot:private`. Avec ce tag, la règle « pas de requête brute dans les tests » n'est plus une simple convention : Robot Framework émet un avertissement si un test appelle `Call API` directement, et RobotCode le signale dans l'éditeur.

**Les rapports.** `log.html` contient chaque requête et chaque réponse HTTP sans que j'aie écrit une ligne de journalisation. `output.xml` est la source de vérité : `rebot` peut fusionner des campagnes, relancer uniquement les tests en échec ou produire un rapport JUnit pour l'intégration continue (voir [rapports.md](rapports.md)).

## 2. Difficultés rencontrées

| Difficulté | Cause | Solution |
|---|---|---|
| Avertissement `InsecureRequestWarning` à chaque requête | `Create Session` de RequestsLibrary **ne vérifie pas le certificat HTTPS par défaut** (`verify=False`) | `verify=${True}` explicite. C'est un vrai piège de sécurité : sur une API interne, des tests pourraient dialoguer avec un faux serveur sans que personne ne le remarque. |
| `PUT /posts/9999` faisait planter le décodage de la réponse | L'API répond 500 avec une page **HTML**, pas du JSON | `Call API` décode le JSON uniquement si le `Content-Type` l'annonce, et renvoie le texte brut sinon |
| Simuler un timeout | JSONPlaceholder n'a pas de route lente | Session dédiée avec un délai de 1 ms et `max_retries=0`, pour éviter les nouvelles tentatives automatiques. Le timeout est réel, déclenché par `requests` |
| Messages d'échec illisibles | `Length Should Be` affiche la liste entière des utilisateurs dans le message | Mot-clé `Number Of Items Should Be` (« 11 utilisateurs attendus, 10 reçus ») et `msg=` sur les comparaisons. Je ne l'ai découvert qu'en **faisant échouer volontairement** les tests : il faut aussi tester ses messages d'erreur. |
| Le profil `smoke` lançait les 15 tests | J'avais écrit `include` au lieu de `includes` dans `robot.toml` : la clé inconnue était **ignorée sans erreur** | Vérifier le nombre de tests exécutés après chaque changement de configuration |
| API sans persistance | Les écritures sont simulées : un post créé n'existe pas | Tests indépendants, sans enchaînement *créer → relire → supprimer*. Un test `limite-api` documente ce comportement |
| Syntaxe sensible aux espaces | Le séparateur est « au moins 2 espaces » : `Get User 1` (un seul espace) est un mot-clé inconnu | RobotCode le signale à la saisie ; `robocop format` normalise l'alignement |
| Outillage | Conflit entre RobotCode et une ancienne extension Robot Framework déjà installée ; faux positif de Robocop (MISC04) sur la syntaxe `VAR` ; accents illisibles dans la console Git Bash | Extension désactivée (`.vscode/extensions.json`), règle ignorée avec un commentaire dans `robocop.toml`, `PYTHONUTF8=1` |

## 3. Comparaison PyTest / Robot Framework

Une précision d'abord : les deux projets ne testent pas la même chose. Mes **150 tests PyTest** étaient des tests **unitaires** : ils vérifiaient *mon code Python* (client, validateurs, menu) en remplaçant le réseau par des `Mock`. Mes **15 tests Robot Framework** sont des tests **d'intégration en boîte noire** : ils vérifient *l'API réelle*, sans connaître son code. Le timeout illustre bien la différence : en PyTest, je simulais l'exception (`side_effect = Timeout()`) ; en Robot Framework, je provoque un vrai timeout réseau.

| Critère | PyTest | Robot Framework |
|---|---|---|
| Lisibilité par un non-développeur | faible : c'est du Python | **forte** : un test se lit comme une spécification |
| Rapports | console, ou plugins à ajouter (pytest-html) | **inclus** : `report.html` pour la synthèse, `log.html` pour le détail de chaque requête, `output.xml` pour les outils |
| Logique complexe (calculs, conditions, structures de données) | **naturelle** | laborieuse : `FOR`, `IF` et `Evaluate` deviennent vite verbeux |
| Fixtures et paramétrage | **très puissants** : portées, injection de dépendances, `parametrize`, `conftest.py` | plus simples : setup et teardown par suite ou par test, templates |
| Simulation (mocks) | **native** (`unittest.mock`) | difficile : il faut écrire une bibliothèque Python |
| Sélection des tests | marqueurs `-m`, expressions `-k` | tags combinables (`AND`, `OR`, `NOT`) et statistiques par tag dans le rapport |
| Refactorisation et typage | **excellents** : IDE Python, mypy | corrects avec RobotCode, mais moins sûrs |
| Erreurs de syntaxe | signalées par Python dès l'import | une faute de frappe ou un espace manquant n'apparaît souvent qu'à l'exécution (ou grâce à RobotCode) |
| Réutilisation | fonctions et classes Python | mots-clés en couches, partageables entre projets, et bibliothèques Python si nécessaire |
| Débogage | `pdb`, points d'arrêt, pile d'appels Python | `log.html` très complet ; débogueur pas à pas de RobotCode |

**Avantages de Robot Framework** selon moi :

- un **langage commun** entre développeurs, testeurs et métier : un responsable peut relire `posts.robot` et valider les scénarios sans connaître Python ;
- les **rapports prêts à diffuser**, avec la trace complète des échanges HTTP : c'est un gain énorme pour analyser un échec ou prouver une exécution ;
- une **structure imposée** (suites, resources, variables) qui pousse naturellement vers la factorisation et la maintenabilité ;
- les **tags**, qui permettent de construire des campagnes (smoke, régression, erreurs) sans dupliquer de tests ;
- l'**extensibilité** : ce qui est difficile en mots-clés peut être écrit en Python et exposé comme bibliothèque.

**Inconvénients** :

- dès qu'il y a de la logique, la syntaxe devient lourde : ce qui tient en une ligne de Python peut demander une boucle et plusieurs mots-clés ;
- la **frontière entre « lisible » et « verbeux »** est fine : un projet mal structuré produit des tests longs et difficiles à maintenir. La qualité dépend entièrement de la conception des mots-clés ;
- les **valeurs par défaut des bibliothèques** doivent être vérifiées (le `verify=False` de RequestsLibrary) ;
- le typage est faible : beaucoup de valeurs sont du texte, et les conversions (`Should Be Equal As Integers`, `${id: int}`) sont à penser explicitement ;
- les configurations erronées peuvent être ignorées silencieusement (clé `include` du `robot.toml`).

**Ma conclusion** : les deux outils sont **complémentaires** plutôt que concurrents. PyTest reste le meilleur choix pour les tests unitaires écrits par les développeurs : rapides, sans réseau, au plus près du code. Robot Framework est plus adapté aux **campagnes d'acceptation et d'intégration**, partagées avec les testeurs et le métier, exécutées sur un environnement réel et dont les rapports doivent être lus par d'autres personnes. Dans un contexte professionnel comme Alert, j'utiliserais PyTest pour valider le code et Robot Framework pour valider le comportement du système de bout en bout.

## 4. Pistes d'amélioration

- **Intégration continue** : exécuter la campagne à chaque *push* (GitHub Actions) et publier `report.html` et le fichier JUnit (`--xunit`).
- **Indépendance vis-à-vis d'Internet** : lancer `json-server` en local et le cibler avec `--variable BASE_URL:http://localhost:3000`.
- **Validation de schéma** : vérifier la structure complète des réponses avec un schéma JSON (mot-clé `Validate Json By Schema` de `robotframework-jsonlibrary`) plutôt que champ par champ.
- **Exécution parallèle** avec `pabot` quand la campagne grandira.
