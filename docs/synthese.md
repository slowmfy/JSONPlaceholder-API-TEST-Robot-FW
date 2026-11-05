# Synthèse : découverte de Robot Framework

**Résultat** : 44 tests automatisés, tous réussis en 27 s environ, aucune alerte Robocop. 15 tests portent sur l'API JSONPlaceholder, 13 sur l'API web de mon application et 16 sur son interface Angular, dans un vrai navigateur. Outils : Robot Framework 7.5, RequestsLibrary, Browser (Playwright), RobotCode.

## 1. Ce que j'ai appris

**Concevoir un vocabulaire plutôt qu'écrire des tests.** En Robot Framework, un test est une suite d'actions nommées (`Get User`, `Create Post`, `User Should Be Valid`). Le vrai travail est de concevoir ces mots-clés en couches :

- une couche HTTP technique (`http.resource`), commune aux deux API ;
- un point d'envoi privé par API (`Call API`) ;
- des actions métier ;
- des vérifications métier.

Aucune URL n'apparaît dans les tests. Si l'API ajoute une authentification, un seul mot-clé change. Le tag `robot:private` fait respecter cette règle par l'outil : un test qui appelle `Call API` directement déclenche un avertissement.

**Les briques du framework.**

- **Suites :** un fichier est une suite, un dossier une suite parente. `__init__.robot` démarre l'application une seule fois pour tout `tests/web`.
- **Resource files :** bibliothèques de mots-clés partagées.
- **Fichiers de variables Python :** ils sont typés et lisent les variables d'environnement. L'option `--variable` permet de changer d'environnement sans modifier le code.
- **Tags :** ils composent une campagne à la demande (`--include smoke`) et donnent des statistiques par tag.
- **Templates :** ils servent aux tests pilotés par les données.

J'ai aussi utilisé la syntaxe de Robot Framework 7 (`VAR`, `RETURN`, arguments typés `${id: int}`).

**Les tests d'interface.** `web_ui.resource` est le seul fichier qui connaît le HTML (*page objects*). Les vérifications de Browser attendent que la condition soit vraie, donc aucun `Sleep` n'est nécessaire. Chaque test s'exécute dans un contexte de navigateur neuf. Les messages attendus viennent des traductions de l'application et ne sont jamais recopiés.

**Tester à plusieurs niveaux.** « Créer un post » est vérifié sur JSONPlaceholder, sur l'API web et dans l'interface : chaque niveau détecte des défauts différents. Les tests de l'API web montrent par exemple que mon application corrige deux limites de JSONPlaceholder. Modifier ou supprimer un post inexistant y renvoie 404, là où JSONPlaceholder renvoie 500 (PUT) et 200 (DELETE).

**Les rapports.** `log.html` trace chaque requête HTTP, chaque action du navigateur, et joint une capture d'écran à chaque échec d'interface, sans aucun code de journalisation. `output.xml` permet de fusionner des campagnes, de relancer les échecs ou de produire un rapport JUnit pour l'intégration continue (voir [rapports.md](rapports.md)).

## 2. Difficultés rencontrées

| Difficulté | Cause | Solution |
|---|---|---|
| `InsecureRequestWarning` à chaque requête | RequestsLibrary **ne vérifie pas le certificat HTTPS par défaut** | `verify=${True}` explicite. C'est un vrai piège de sécurité |
| Le décodage de la réponse plantait sur `PUT /posts/9999` | JSONPlaceholder répond 500 en HTML | Décoder le JSON seulement si le `Content-Type` l'annonce |
| Simuler un timeout | Pas de route lente sur JSONPlaceholder | Délai de 1 ms et `max_retries=0` : un vrai timeout réseau |
| Messages d'échec illisibles | `Length Should Be` affiche toute la liste | Mot-clé dédié (« 11 utilisateurs attendus, 10 reçus »). Découvert en **faisant échouer volontairement** les tests |
| Profil `smoke` ignoré | Clé `include` au lieu de `includes` : erreur **silencieuse** | Vérifier le nombre de tests exécutés |
| Le navigateur ne démarrait pas (`ENOENT`) | Chemin de 279 caractères dans le `venv`, au-delà de la limite Windows de 260 | Utiliser Edge (`channel=msedge`), configurable |
| Erreur parasite en fin de suite quand l'application ne démarrait pas | Variable créée dynamiquement, inconnue du teardown (signalée aussi par RobotCode) | Valeur par défaut dans `*** Variables ***` |

## 3. Comparaison PyTest / Robot Framework

Les deux projets ne testent pas la même chose. Mes **265 tests PyTest** (2,6 s) étaient **unitaires** : ils vérifiaient *mon code* en simulant le réseau avec des `Mock`. Mes **44 tests Robot Framework** (27 s) sont **d'intégration et de bout en bout** : vraie API, vrai serveur, vrai navigateur. En PyTest, je simulais le timeout (`side_effect = Timeout()`) ; en Robot Framework, je le provoque réellement. Surtout, mon interface Angular **n'avait aucun test automatisé**. Elle n'était vérifiée qu'à la main.

| Critère | PyTest | Robot Framework |
|---|---|---|
| Lisibilité par un non-développeur | faible : c'est du Python | **forte** : un test se lit comme une spécification |
| Rapports | console, plugins à ajouter | **inclus** : synthèse, détail HTTP, captures d'écran |
| Logique complexe | **naturelle** | verbeuse (`FOR`, `IF`, `Evaluate`) |
| Fixtures, paramétrage, mocks | **très puissants** | plus simples ; mocks difficiles |
| Typage, refactorisation | **solides** (IDE, mypy) | faibles : beaucoup de texte, conversions explicites |
| Vitesse et stabilité | **très rapide**, sans réseau | plus lent, dépend du réseau et du navigateur |
| Niveaux couverts | surtout unitaire | API, serveur et interface dans une même campagne |

**Avantages de Robot Framework.**

- C'est un **langage commun** : un responsable peut relire `posts.robot` sans connaître Python.
- Les **rapports sont prêts à diffuser**.
- La **structure imposée** pousse vers la factorisation.
- Les **tags** permettent de construire des campagnes sans dupliquer de tests.

**Inconvénients.**

- La logique devient vite lourde.
- La qualité dépend entièrement de la conception des mots-clés : mal structuré, un projet devient verbeux.
- Les **valeurs par défaut des bibliothèques** sont à vérifier (`verify=False`).
- Certaines erreurs de configuration passent **en silence**.

**Conclusion.** Les deux outils sont **complémentaires**. PyTest est le meilleur choix pour les tests unitaires des développeurs : rapides, sans réseau, au plus près du code. Robot Framework convient aux **campagnes d'acceptation et de bout en bout**, partagées avec les testeurs et le métier, et dont les rapports sont lus par d'autres. Dans un contexte comme Alert, j'utiliserais PyTest pour valider le code et Robot Framework pour valider le comportement du système.

**Pistes d'amélioration** : intégration continue (GitHub Actions, rapport JUnit), `json-server` en local pour ne plus dépendre d'Internet, validation des réponses par schéma JSON, exécution parallèle avec `pabot`.
