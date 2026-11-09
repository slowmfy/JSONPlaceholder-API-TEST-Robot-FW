*** Settings ***
Documentation     Posts : lister, créer, modifier et supprimer.
...
...               JSONPlaceholder ne garde rien : l'application le signale à l'utilisateur
...               (« opération simulée ») et garde le résultat seulement dans la page ouverte.

Resource          ../resources/pages/posts_page.resource
Resource          ../resources/pages/post_detail_page.resource
Resource          ../resources/pages/user_detail_page.resource
Variables         ../variables/test_data.py

Suite Setup       Open Test Browser
Suite Teardown    Close Test Browser
Test Setup        Open Application
Test Teardown     Close Application

Test Tags         posts


*** Test Cases ***
Lister les posts d'un utilisateur
    [Documentation]    La fiche d'un utilisateur affiche ses 10 posts.
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
    [Documentation]    « Annuler » laisse le post affiché, sans message de réussite.
    [Tags]    cas-limite
    Go To Post Page    ${EXISTING_POST_ID}
    ${title}=    Get Text    ${PAGE_TITLE}
    Ask To Delete Displayed Post
    Cancel Deletion
    Page Title Should Be    ${title}
    No Write Message Should Be Shown
