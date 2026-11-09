*** Settings ***
Documentation     Pages des utilisateurs : liste, recherche, fiche, rapport et changement de langue.

Resource          ../resources/pages/users_page.resource
Resource          ../resources/pages/user_detail_page.resource
Variables         ../variables/test_data.py

Suite Setup       Open Test Browser
Suite Teardown    Close Test Browser
Test Setup        Open Application
Test Teardown     Close Application

Test Tags         users


*** Test Cases ***
Afficher la liste des utilisateurs
    [Documentation]    La page des utilisateurs affiche les 10 utilisateurs de JSONPlaceholder.
    [Tags]    nominal    smoke
    Go To Users Page
    Users Table Should Have Rows    ${USERS_COUNT}

Rechercher un utilisateur par ville
    [Documentation]    La recherche porte aussi sur la ville et ne tient pas compte des majuscules.
    [Tags]    nominal
    Go To Users Page
    Search Users    ${EXISTING_USER_CITY}
    Users Table Should Only Contain    ${EXISTING_USER_NAME}

Rechercher un utilisateur sans résultat
    [Documentation]    Une recherche qui ne trouve rien affiche « Aucun résultat. ».
    [Tags]    cas-limite
    Go To Users Page
    Search Users    ${NO_RESULT_SEARCH}
    Users Table Should Be Empty

Ouvrir la fiche d'un utilisateur depuis la liste
    [Documentation]    Un clic sur le nom ouvre la fiche : nom, pseudo et ses 10 posts.
    [Tags]    nominal    smoke
    Go To Users Page
    Open User From List    ${EXISTING_USER_NAME}
    User Page Should Show    ${EXISTING_USER_NAME}    ${EXISTING_USER_USERNAME}
    Listed Items Should Be    ${POSTS_PER_USER}

Ouvrir un utilisateur par son identifiant
    [Documentation]    Le formulaire « Accès direct » ouvre la fiche de l'utilisateur saisi.
    [Tags]    nominal
    Go To Users Page
    Open User By Id    ${OTHER_USER_ID}
    User Page Should Show    ${OTHER_USER_NAME}    ${OTHER_USER_USERNAME}

Afficher le rapport d'un utilisateur
    [Documentation]    Le rapport affiche le nombre de posts (10) et de commentaires (50).
    [Tags]    nominal
    Go To User Report Page    ${EXISTING_USER_ID}
    Report Should Show Counts    ${POSTS_PER_USER}    ${COMMENTS_PER_USER}

Changer la langue de l'interface
    [Documentation]    Le menu de langue traduit l'interface sans recharger la page.
    [Tags]    nominal    multilingue
    Go To Users Page
    Switch Language To    English
    Navigation Should Contain    Users
    Page Title Should Be    Users
