*** Settings ***
Documentation    PAGE « Détail d'un post » (adresse : /posts/<id>) : modifier et supprimer le post.

Resource         ../common.resource


*** Variables ***
# Sélecteurs propres à cette page
${POST_ACTIONS}        css=main .card-head .inline
${CONFIRM_GROUP}       css=main .confirm-inline
${CONFIRM_QUESTION}    ${CONFIRM_GROUP} > span >> nth=0


*** Keywords ***
# ---------- Aller sur la page ----------

Go To Post Page
    [Documentation]    Ouvre directement la page d'un post.
    [Arguments]    ${post_id}
    Go To    ${WEB_URL}/posts/${post_id}

# ---------- Actions ----------

Edit Displayed Post
    [Documentation]    « Modifier », taper le nouveau titre, « Enregistrer ».
    [Arguments]    ${new_title}
    ${edit}=    Text    action_edit
    Click    ${POST_ACTIONS} >> text="${edit}"
    Fill Post Form    title=${new_title}
    Submit Form

Ask To Delete Displayed Post
    [Documentation]    Clique sur « Supprimer » et vérifie que l'application demande confirmation.
    ${delete}=    Text    action_delete
    Click    ${POST_ACTIONS} >> text="${delete}"
    ${question}=    Text    confirm_delete
    Get Text    ${CONFIRM_QUESTION}    ==    ${question}

Confirm Deletion
    [Documentation]    Répond « Supprimer » à la question de confirmation.
    ${delete}=    Text    action_delete
    Click    ${CONFIRM_GROUP} >> text="${delete}"

Cancel Deletion
    [Documentation]    Répond « Annuler » à la question de confirmation.
    ${cancel}=    Text    action_cancel
    Click    ${CONFIRM_GROUP} >> text="${cancel}"
