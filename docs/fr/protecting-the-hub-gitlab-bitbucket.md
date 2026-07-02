[English](../en/protecting-the-hub-gitlab-bitbucket.md) · [Español](../protecting-the-hub-gitlab-bitbucket.md) · **Français**
&nbsp;&nbsp;|&nbsp;&nbsp; [GitHub](protecting-the-hub.md) · **GitLab / Bitbucket**

# Protéger le hub — GitLab et Bitbucket

> L'objectif est identique à celui du [guide GitHub](protecting-the-hub.md) : les définitions certifiées du hub ne changent que par une PR/MR revue, avec propriétaire et auditée, et les spokes peuvent épingler des versions immuables. Ce qui change : les noms, les offres et les API.

## Équivalences entre plateformes

| Contrôle de gouvernance | GitHub | GitLab | Bitbucket Cloud |
|---|---|---|---|
| Imposer la PR/MR (pas de push direct) | Ruleset · *Require a pull request* | Branche protégée · *Allowed to push and merge → No one* | Branch restriction · *push* sans personne |
| Approbations requises | Ruleset PR · *Required approvals: N* | Approval rules · *Approvals required: N* · **Premium** | Merge check · *Minimum approvals: N* (bloque avec **Premium**) |
| Approbation des propriétaires | `CODEOWNERS` + *Require review from Code Owners* | `CODEOWNERS` + *Require approval from code owners* · **Premium** | *Default reviewers* + *Min. approvals from default reviewers* (pas de `CODEOWNERS` natif) |
| Pas d'auto-approbation du dernier push | *Require approval of most recent push* | *Prevent approval by author* / *by committers* | via les default reviewers |
| Réinitialiser les approbations au push | *Dismiss stale approvals on push* | *Remove all approvals when commits added* | *Reset approvals on change* · **Premium** |
| Bloquer le force push | *Block force pushes* | *Allowed to force push → off* | *Prevent rewriting history* |
| Empêcher la suppression de la branche | *Restrict deletions* | (la protection de branche l'empêche) | *Prevent deletion* |
| Tags immuables (épinglage) | Tag ruleset | *Protected tags* | ⚠️ pas de protection de tags native |
| Accès en lecture seule (spokes) | Deploy key sans écriture | Deploy key en lecture seule | Access key en lecture |
| « En code » (API) | `POST /repos/…/rulesets` | `POST …/protected_branches`, `…/protected_tags`, `…/approval_rules` | `POST …/branch-restrictions` (par `kind`) |

---

## GitLab

**Note d'offre :** l'**approbation des Code Owners** et les **règles d'approbation de MR** (nombre requis, approbateurs éligibles, empêcher l'auteur d'approuver) relèvent de **Premium/Ultimate**. En **Free**, vous pouvez protéger des branches par rôle et protéger des tags ; pour exiger des approbations, il faut Premium.

1. **Accès (qui peut faire quoi).** Donnez aux spokes une *deploy key* en **lecture seule** (**Settings → Repository → Deploy keys**, sans cocher *Grant write permissions*). L'équipe du hub avec le rôle **Maintainer** ; **Owner** limité à une ou deux personnes.
2. **CODEOWNERS.** Créez le fichier à la racine, dans `docs/` ou dans `.gitlab/` :
   ```
   *  @votre-groupe/hub-maintainers
   ```
3. **Branche protégée** (**Settings → Repository → Protected branches**) : branche `main` (ou `*`).
   - **Allowed to merge :** Developers + Maintainers (ou Maintainers seulement).
   - **Allowed to push and merge :** **No one** — cela force tout changement à passer par une MR.
   - **Allowed to force push :** off.
   - **Require approval from code owners :** on *(Premium)*.
4. **Approbations** (**Settings → Merge requests → Merge request approvals**, *Premium*) : une *approval rule* avec **Approvals required ≥ 1** ; dans **Approval settings**, activez *Prevent approval by author*, *Prevent approvals by users who add commits* et *Remove all approvals when commits are added*.
5. **Tags protégés** (**Settings → Repository → Protected tags**) : motif `v*`, **Allowed to create: Maintainers**. Un spoke épinglé sur `ref: "v1.2.0"` reste stable.
6. *(Optionnel, Premium)* **Push rules** (**Settings → Repository → Push rules**) : rejeter les commits non signés, regex de message, blocage de secrets, etc.

**En code** (API v4 ; token avec le scope `api`). Niveaux d'accès : `0` = personne, `30` = Developer, `40` = Maintainer.
```bash
GL="https://gitlab.com/api/v4"; PID="<id-du-projet>"; TOKEN="<token>"

# Branche protégée : pas de push direct, les devs peuvent fusionner, code owners requis
curl --request POST --header "PRIVATE-TOKEN: $TOKEN" \
  "$GL/projects/$PID/protected_branches?name=main&push_access_level=0&merge_access_level=30&allow_force_push=false&code_owner_approval_required=true"

# Les tags v* ne peuvent être créés que par les Maintainers
curl --request POST --header "PRIVATE-TOKEN: $TOKEN" \
  "$GL/projects/$PID/protected_tags?name=v*&create_access_level=40"

# Règle d'approbation : au moins 1
curl --request POST --header "PRIVATE-TOKEN: $TOKEN" \
  "$GL/projects/$PID/approval_rules" --data "name=hub-maintainers&approvals_required=1"
```
> `PID` peut être l'id numérique ou le chemin encodé URL (p. ex. `mon-groupe%2Fthelook_hub`).

---

## Bitbucket Cloud

**Note d'offre :** sans **Premium**, les *merge checks* (approbations minimales, builds, tâches) ne font qu'**avertir** — la fusion reste possible. Pour **bloquer**, il faut être en Premium et activer *Prevent a merge with unresolved merge checks*. *Reset approvals on change* est aussi Premium. Bitbucket utilise les **Default reviewers** au lieu d'un fichier `CODEOWNERS` natif.

1. **Accès.** Donnez aux spokes une **Access key** en lecture seule (**Repository settings → Access keys**) ou un accès en lecture au dépôt. L'équipe du hub en écriture ; admin limité.
2. **Propriétaires = Default reviewers** (**Repository settings → Default reviewers**) : ajoutez l'équipe du hub comme relecteurs par défaut.
3. **Branch restrictions** (**Repository settings → Branch restrictions → Add a branch restriction**), motif `main` :
   - *Branch permissions :* **Write access** → uniquement des personnes/groupes précis (l'équipe du hub) ; tous les autres passent par une PR. Cochez **Prevent deletion** et **Prevent rewriting history** (pas de force push).
   - *Merge settings :* **Minimum number of approvals** = 1–2 ; **Minimum approvals from default reviewers** ≥ 1 ; **No unresolved pull request tasks** ; **No changes requested**.
   - *(Premium)* **Prevent a merge with unresolved merge checks** (pour qu'ils *bloquent*) et **Reset approvals when the source branch is modified**.
4. **Tags.** ⚠️ Bitbucket Cloud **ne protège pas les tags nativement** comme GitHub/GitLab. Atténuation : restreignez l'accès en écriture et créez les releases via un processus contrôlé (p. ex. des tags générés uniquement par Pipelines), ou utilisez Bitbucket Data Center, qui dispose de restrictions de *ref* couvrant les tags.

**En code** (API 2.0 ; authentifiez-vous avec email + **API token**). Une *branch restriction* par `kind` :
```bash
BB="https://api.bitbucket.org/2.0/repositories/<workspace>/thelook_hub/branch-restrictions"
AUTH="<votre-email>:<api_token>"

# Imposer la PR : personne ne pousse directement sur main (liste users/groups vide)
curl -u "$AUTH" -X POST "$BB" -H 'Content-Type: application/json' \
  -d '{"kind":"push","pattern":"main","users":[],"groups":[]}'

# Exiger 1 approbation, interdire suppression et réécriture de l'historique
curl -u "$AUTH" -X POST "$BB" -H 'Content-Type: application/json' -d '{"kind":"require_approvals_to_merge","pattern":"main","value":1}'
curl -u "$AUTH" -X POST "$BB" -H 'Content-Type: application/json' -d '{"kind":"delete","pattern":"main"}'
curl -u "$AUTH" -X POST "$BB" -H 'Content-Type: application/json' -d '{"kind":"force","pattern":"main"}'

# (Premium) bloquer la fusion s'il reste des checks non résolus
curl -u "$AUTH" -X POST "$BB" -H 'Content-Type: application/json' -d '{"kind":"enforce_merge_checks","pattern":"main"}'
```
> Autres `kind` utiles : `require_default_reviewer_approvals_to_merge`, `require_passing_builds_to_merge`, `require_tasks_to_be_completed`, `require_no_changes_requested`, `reset_pullrequest_approvals_on_change`.

---

L'idée de fond ne change pas d'une plateforme à l'autre : le noyau certifié ne se modifie que par un changement revu, avec propriétaire et audité, et les consommateurs épinglent des versions stables. Là où une plateforme ne suit pas (les tags sur Bitbucket Cloud, ou les approbations sur les offres gratuites), comblez l'écart par le processus ou par la bonne offre — et dites-le, comme dans la section coûts et limites du README.
