*** Settings ***
Documentation     Interface web : lister, créer, modifier et supprimer des posts.
...
...               Les écritures sont simulées par JSONPlaceholder ; l'interface le signale à
...               l'utilisateur et conserve le résultat localement, le temps de la page.

Resource          ../../resources/web_ui.resource
Variables         ../../variables/environment.py

Suite Setup       Open Test Browser
Suite Teardown    Close Test Browser
Test Setup        Open Application
Test Teardown     Close Application

Test Tags         ui    posts


*** Test Cases ***
Lister les posts d'un utilisateur
    [Documentation]    L'onglet « Posts » de la fiche affiche les 10 posts de l'utilisateur.
    [Tags]    nominal    smoke
    Go To User Page    ${EXISTING_USER_ID}
    Listed Items Should Be    ${POSTS_PER_USER}

Créer un post
    [Documentation]    Le formulaire crée le post, affiche « Post 101 créé. », signale que
    ...    l'opération est simulée et ajoute le post à la liste.
    [Tags]    nominal    smoke
    Go To Posts Page
    Create Post From Form    ${EXISTING_USER_ID}    ${NEW_POST_TITLE}    ${NEW_POST_BODY}
    ${message}=    Text    created_post    id=${CREATED_POST_ID}
    Success Message Should Be    ${message}
    Simulated Write Notice Should Be Shown
    Post Should Be Listed    ${NEW_POST_TITLE}

Modifier un post
    [Documentation]    La modification affiche « Post 1 modifié. » et le nouveau titre.
    [Tags]    nominal
    Go To Post Page    ${EXISTING_POST_ID}
    Edit Displayed Post    ${UPDATED_POST_TITLE}
    ${message}=    Text    updated_post    id=${EXISTING_POST_ID}
    Success Message Should Be    ${message}
    Page Title Should Be    ${UPDATED_POST_TITLE}

Supprimer un post après confirmation
    [Documentation]    La suppression demande une confirmation, puis affiche « Post 1 supprimé. ».
    [Tags]    nominal
    Go To Post Page    ${EXISTING_POST_ID}
    Ask To Delete Displayed Post
    Confirm Deletion
    ${message}=    Text    deleted_post    id=${EXISTING_POST_ID}
    Success Message Should Be    ${message}
    Simulated Write Notice Should Be Shown

Annuler une suppression
    [Documentation]    Annuler la confirmation laisse le post affiché, sans aucun appel d'écriture.
    [Tags]    cas-limite
    Go To Post Page    ${EXISTING_POST_ID}
    ${title}=    Get Text    ${PAGE_TITLE}
    Ask To Delete Displayed Post
    Cancel Deletion
    Page Title Should Be    ${title}
    No Write Message Should Be Shown
