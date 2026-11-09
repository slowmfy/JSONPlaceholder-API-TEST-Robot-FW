*** Settings ***
Documentation    PAGE « Fiche d'un utilisateur » (adresse : /users/<id>) et son rapport
...              (adresse : /users/<id>/report).

Resource         ../common.resource


*** Variables ***
# Sélecteurs propres à cette page
${USER_USERNAME}    css=main .card-head .muted
${REPORT_STATS}     css=main .stat .stat-value


*** Keywords ***
# ---------- Aller sur la page ----------

Go To User Page
    [Documentation]    Ouvre directement la fiche d'un utilisateur.
    [Arguments]    ${user_id}
    Go To    ${WEB_URL}/users/${user_id}

Go To User Report Page
    [Documentation]    Ouvre directement le rapport d'un utilisateur.
    [Arguments]    ${user_id}
    Go To    ${WEB_URL}/users/${user_id}/report

# ---------- Vérifications ----------

User Page Should Show
    [Documentation]    Vérifie la fiche : le nom en titre et le pseudo ``@username`` en dessous.
    [Arguments]    ${name}    ${username}
    Page Title Should Be    ${name}
    Get Text    ${USER_USERNAME}    ==    @${username}

Report Should Show Counts
    [Documentation]    Vérifie les compteurs du rapport : nombre de posts, puis de commentaires.
    ...    ``: str`` convertit les nombres en texte, pour les comparer au texte lu dans la page.
    [Arguments]    ${post_count: str}    ${comment_count: str}
    Get Text    ${REPORT_STATS} >> nth=0    ==    ${post_count}
    Get Text    ${REPORT_STATS} >> nth=1    ==    ${comment_count}
