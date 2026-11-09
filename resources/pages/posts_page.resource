*** Settings ***
Documentation    PAGE « Posts » (adresse : /posts) : liste de tous les posts et création d'un post.

Resource         ../common.resource


*** Variables ***
# Sélecteurs propres à cette page
${ADD_BUTTON}    css=main .card-head > button


*** Keywords ***
# ---------- Aller sur la page ----------

Go To Posts Page
    [Documentation]    Ouvre la page des posts et vérifie son titre.
    Go To    ${WEB_URL}/posts
    ${title}=    Text    res_posts
    Page Title Should Be    ${title}

# ---------- Actions ----------

Open Post Creation Form
    [Documentation]    Clique sur « Ajouter » pour afficher le formulaire de création.
    Click    ${ADD_BUTTON}
    Wait For Elements State    ${FORM}    visible

Create Post From Form
    [Documentation]    Création complète : « Ajouter », remplir le formulaire, « Créer ».
    [Arguments]    ${user_id}    ${title}    ${body}
    Open Post Creation Form
    Fill Post Form    ${user_id}    ${title}    ${body}
    Submit Form

# ---------- Vérifications ----------

Post Should Be Listed
    [Documentation]    Vérifie qu'un post avec ce titre apparaît une fois dans la liste.
    [Arguments]    ${title}
    Get Element Count    ${LIST_ROWS} >> text="${title}"    ==    1
