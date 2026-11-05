*** Settings ***
Documentation     Interface web : pages des utilisateurs, rapport et changement de langue.
...
...               Chaque test s'exécute dans un contexte de navigateur neuf (``Test Setup``) :
...               aucun test ne dépend de l'état laissé par un autre.

Resource          ../../resources/web_ui.resource

Suite Setup       Open Test Browser
Suite Teardown    Close Test Browser
Test Setup        Open Application
Test Teardown     Close Application

Test Tags         ui    users


*** Test Cases ***
Afficher la liste des utilisateurs
    [Documentation]    La page d'accueil affiche les 10 utilisateurs de JSONPlaceholder.
    [Tags]    nominal    smoke
    Go To Users Page
    Users Table Should Have Rows    10

Rechercher un utilisateur par ville
    [Documentation]    La recherche porte aussi sur la ville et ne tient pas compte des majuscules.
    [Tags]    nominal
    Go To Users Page
    Search Users    ${USER_SEARCH_TERM}
    Users Table Should Only Contain    Leanne Graham

Rechercher un utilisateur sans résultat
    [Documentation]    Une recherche qui ne trouve rien affiche un message plutôt qu'un tableau vide.
    [Tags]    cas-limite
    Go To Users Page
    Search Users    zzz-aucun-utilisateur
    Users Table Should Be Empty

Ouvrir la fiche d'un utilisateur depuis la liste
    [Documentation]    Un clic sur le nom ouvre la fiche : identité et onglet des 10 posts.
    [Tags]    nominal    smoke
    Go To Users Page
    Open User From List    Leanne Graham
    User Page Should Show    Leanne Graham    Bret
    Listed Items Should Be    10

Ouvrir un utilisateur par son identifiant
    [Documentation]    Le formulaire « Accès direct » ouvre la fiche de l'utilisateur saisi.
    [Tags]    nominal
    Go To Users Page
    Open User By Id    2
    User Page Should Show    Ervin Howell    Antonette

Afficher le rapport d'un utilisateur
    [Documentation]    Le rapport affiche le nombre de posts (10) et de commentaires (50).
    [Tags]    nominal
    Go To User Report Page    1
    Report Should Show Counts    10    50

Changer la langue de l'interface
    [Documentation]    Le sélecteur de langue traduit l'interface sans recharger la page.
    [Tags]    nominal    multilingue
    Go To Users Page
    Switch Language To    English
    Navigation Should Contain    Users
    Page Title Should Be    Users
