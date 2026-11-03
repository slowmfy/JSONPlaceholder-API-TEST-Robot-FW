# Analyse des rapports d'exécution

Chaque lancement de `robot --outputdir results tests` produit trois fichiers dans `results/`. Ils décrivent la même exécution, mais pour trois publics différents.

```
                         robot
                           │
                           ▼
                      output.xml   ← source de vérité : tout est enregistré ici
                       │       │
          (généré depuis)     (généré depuis)
                       ▼       ▼
                 log.html     report.html
```

`log.html` et `report.html` sont **générés à partir de `output.xml`**. La commande `rebot` peut donc les recréer plus tard, sans relancer les tests : `rebot --outputdir results results/output.xml`.

---

## 1. `report.html` : le rapport de synthèse

**Rôle** : dire en un coup d'œil si la campagne est réussie, et où sont les problèmes.

**Contenu** :

- **couleur de fond** : verte si tous les tests passent, rouge si au moins un échoue ;
- **résumé** : date, durée totale (environ 2,7 s pour nos 15 tests), nombre de tests réussis, échoués et ignorés ;
- **statistiques par tag** : `smoke` 4/4, `erreur` 7/7, `limite-api` 3/3... Ce découpage n'existe que grâce aux tags mis sur les tests. Il répond à des questions comme « les cas d'erreur sont-ils tous couverts ? » ;
- **statistiques par suite** : `Tests.Users` 3/3, `Tests.Posts` 6/6, `Tests.Errors` 6/6 ;
- **liste des tests**, filtrable par suite, tag ou statut, avec leur documentation, leurs tags, leur durée et leur message d'échec. Un clic sur un test ouvre son détail dans `log.html`.

**Contexte d'utilisation** :

- le fichier à envoyer à un responsable, un chef de projet ou un client après une campagne ;
- la page publiée par l'intégration continue après chaque build ;
- le support d'une réunion de validation : « 15 tests sur 15, aucun échec, 3 limites de l'API documentées ».

---

## 2. `log.html` : le journal détaillé

**Rôle** : comprendre **pourquoi** un test a échoué, sans relancer ni déboguer.

**Contenu** : l'arbre complet de l'exécution, que l'on déplie niveau par niveau :

```
Suite Tests.Users
├── SETUP  Open API Session
│   └── Create Session  jsonplaceholder  https://jsonplaceholder.typicode.com ...
├── TEST   Récupérer un utilisateur existant
│   ├── ${user} = Get User  ${EXISTING_USER_ID}
│   │   └── ${user} = Call API  GET  /users/1  200
│   │       └── GET On Session  jsonplaceholder  /users/1  expected_status=200
│   │           ├── INFO  GET Request : url=https://jsonplaceholder.typicode.com/users/1
│   │           │                       headers={'Accept': 'application/json', ...}
│   │           └── INFO  GET Response : status=200, reason=OK
│   │                                    body={"id": 1, "name": "Leanne Graham", ...}
│   ├── User Should Be Valid  ${user}
│   └── User Should Be  ${user}  id=1  name=Leanne Graham ...
└── TEARDOWN  Close API Sessions
```

Pour chaque mot-clé : ses arguments, sa valeur de retour (`${user} = {...}`), sa durée, son statut, et les messages qu'il a écrits. RequestsLibrary y journalise **chaque requête et chaque réponse HTTP** (URL, en-têtes, corps, code), sans aucun code de journalisation de notre part.

En cas d'échec, le mot-clé en faute est en rouge et le chemin qui y mène est déplié automatiquement. Exemple obtenu en forçant volontairement des valeurs fausses (`--variable USERS_COUNT:11 --variable EXISTING_USER_ID:2`) :

```
Récupérer tous les utilisateurs      FAIL   11 utilisateurs attendus, 10 reçus
Récupérer un utilisateur existant    FAIL   Nom inattendu: Ervin Howell != Leanne Graham
```

Ce test d'échec volontaire m'a d'ailleurs montré que `Length Should Be` affichait la liste entière des 10 utilisateurs dans son message d'erreur, ce qui le rendait illisible. Je l'ai remplacé par le mot-clé `Number Of Items Should Be`.

Le niveau de détail se règle avec `--loglevel` : `INFO` par défaut, `TRACE` pour journaliser en plus les arguments reçus et la valeur renvoyée par chaque mot-clé.

**Contexte d'utilisation** :

- analyse d'un échec par le développeur ou le testeur : la requête envoyée, la réponse reçue et l'assertion en faute sont au même endroit ;
- distinguer un bug de l'application d'un problème d'environnement : un `ConnectionError` ou un `Timeout` pointe vers le réseau ou le serveur, une assertion en échec pointe vers les données ;
- preuve d'exécution : l'horodatage de chaque étape montre ce qui a réellement été fait.

**Attention** : `log.html` contient les corps des requêtes et des réponses. Avec une vraie API, il peut contenir des jetons, des mots de passe ou des données personnelles. Il ne faut pas le publier sans précaution ; réduire le détail des mots-clés sensibles (`Set Log Level    NONE` autour de l'appel, option `--removekeywords` de `rebot`) avant de le diffuser.

---

## 3. `output.xml` : les résultats bruts

**Rôle** : conserver toute l'exécution sous une forme lisible par les machines.

**Contenu** : un fichier XML (schéma version 5 pour Robot Framework 7) qui reprend la même hiérarchie que `log.html` :

```xml
<robot generator="Robot 7.5.1 (Python 3.14.8 on win32)" generated="2026-11-03T09:36:17" schemaversion="5">
  <suite id="s1" name="Tests" source="...\tests">
    <suite id="s1-s1" name="Errors" source="...\tests\errors.robot">
      <kw name="Open API Session" owner="api" type="SETUP"> ... </kw>
      <test id="s1-s1-t1" name="Identifiant invalide" line="17">
        <for flavor="IN">                                  <!-- la boucle du [Template] -->
          <iter>
            <kw name="User Id Should Be Rejected" owner="api">
              <kw name="Get User" owner="api">
                ...
                <msg time="..." level="INFO">GET Request : url=https://jsonplaceholder.typicode.com/users/abc ...</msg>
                <msg time="..." level="INFO">${user} = {}</msg>
        ...
        <status status="PASS" start="..." elapsed="..."/>
      </test>
  ...
  <statistics>
    <total><stat pass="15" fail="0" skip="0">All Tests</stat></total>
    <tag><stat pass="7" fail="0" skip="0">erreur</stat> ...</tag>
    <suite><stat name="Users" pass="3" fail="0" skip="0">Tests.Users</stat> ...</suite>
  </statistics>
  <errors> ... </errors>      <!-- avertissements et erreurs de l'exécution -->
</robot>
```

On y trouve les suites, tests, mots-clés, arguments, messages, statuts, horodatages et durées, les statistiques, ainsi que les avertissements de l'exécution (par exemple l'appel d'un mot-clé privé).

**Contexte d'utilisation** :

| Besoin | Commande |
|---|---|
| Regénérer `log.html` et `report.html` sans relancer les tests | `rebot results/output.xml` |
| Relancer uniquement les tests en échec | `robot --rerunfailed results/output.xml --output rerun.xml tests` |
| Fusionner la première exécution et la relance | `rebot --merge results/output.xml rerun.xml` |
| Fusionner plusieurs campagnes (plusieurs machines, plusieurs environnements) | `rebot --name Campagne results/*.xml` |
| Fournir un rapport JUnit à Jenkins, GitLab ou GitHub Actions | `rebot --xunit junit.xml results/output.xml` (ou `robot --xunit junit.xml` directement) |
| Exploiter les résultats en Python (tableau de bord, historique des durées...) | `from robot.api import ExecutionResult` |

C'est le fichier à **archiver** : à partir de lui, on peut tout recréer. Les fichiers HTML ne sont qu'une présentation.

---

## Résumé

| | `report.html` | `log.html` | `output.xml` |
|---|---|---|---|
| Question | La campagne est-elle réussie ? | Pourquoi ce test a-t-il échoué ? | Que faire automatiquement de ces résultats ? |
| Public | responsable, équipe, client | développeur, testeur | outils : CI, `rebot`, scripts |
| Détail | statistiques, liste des tests | chaque mot-clé, chaque requête HTTP | tout, au format XML |
| Taille (nos 15 tests) | ~250 Ko | ~310 Ko | ~210 Ko |
| Moment | après la campagne | pendant l'analyse d'un échec | dans le pipeline, archivage |
