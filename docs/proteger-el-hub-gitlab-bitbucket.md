[English](en/protecting-the-hub-gitlab-bitbucket.md) · **Español**
&nbsp;&nbsp;|&nbsp;&nbsp; [GitHub](protecting-the-hub.md) · **GitLab / Bitbucket**

# Proteger el hub — GitLab y Bitbucket

> El objetivo es idéntico al de [la guía de GitHub](protecting-the-hub.md): que las definiciones certificadas del hub solo cambien por un PR/MR revisado, con dueño y auditado, y que los spokes puedan fijar versiones inmutables. Cambian los nombres, los planes y las APIs.

## Equivalencias entre plataformas

| Control de gobernanza | GitHub | GitLab | Bitbucket Cloud |
|---|---|---|---|
| Forzar PR/MR (sin push directo) | Ruleset · *Require a pull request* | Rama protegida · *Allowed to push and merge → No one* | Branch restriction · *push* sin nadie |
| Aprobaciones requeridas | Ruleset PR · *Required approvals: N* | Approval rules · *Approvals required: N* · **Premium** | Merge check · *Minimum approvals: N* (bloquea con **Premium**) |
| Aprobación de dueños | `CODEOWNERS` + *Require review from Code Owners* | `CODEOWNERS` + *Require approval from code owners* · **Premium** | *Default reviewers* + *Min. approvals from default reviewers* (sin `CODEOWNERS` nativo) |
| No auto-aprobar el último push | *Require approval of most recent push* | *Prevent approval by author* / *by committers* | vía default reviewers |
| Resetear aprobaciones al hacer push | *Dismiss stale approvals on push* | *Remove all approvals when commits added* | *Reset approvals on change* · **Premium** |
| Bloquear force push | *Block force pushes* | *Allowed to force push → off* | *Prevent rewriting history* |
| Impedir borrado de rama | *Restrict deletions* | (la protección de rama lo impide) | *Prevent deletion* |
| Tags inmutables (pinning) | Tag ruleset | *Protected tags* | ⚠️ sin protección de tags nativa |
| Acceso de solo lectura (spokes) | Deploy key sin write | Deploy key de solo lectura | Access key de lectura |
| "Como código" (API) | `POST /repos/…/rulesets` | `POST …/protected_branches`, `…/protected_tags`, `…/approval_rules` | `POST …/branch-restrictions` (por `kind`) |

---

## GitLab

**Aviso de plan:** la **aprobación de Code Owners** y las **reglas de aprobación de MR** (número requerido, aprobadores elegibles, impedir que el autor apruebe) son de **Premium/Ultimate**. En **Free** sí puedes proteger ramas por rol y proteger tags; para exigir aprobaciones necesitas Premium.

1. **Acceso (quién puede qué).** Da a los spokes una *deploy key* de **solo lectura** (**Settings → Repository → Deploy keys**, sin marcar *Grant write permissions*). El equipo del hub con rol **Maintainer**; **Owner** limitado a una o dos personas.
2. **CODEOWNERS.** Crea el archivo en la raíz, en `docs/` o en `.gitlab/`:
   ```
   *  @tu-grupo/hub-maintainers
   ```
3. **Rama protegida** (**Settings → Repository → Protected branches**): branch `main` (o `*`).
   - **Allowed to merge:** Developers + Maintainers (o solo Maintainers).
   - **Allowed to push and merge:** **No one** — esto fuerza que todo cambio pase por un MR.
   - **Allowed to force push:** off.
   - **Require approval from code owners:** on *(Premium)*.
4. **Aprobaciones** (**Settings → Merge requests → Merge request approvals**, *Premium*): una *approval rule* con **Approvals required ≥ 1**; en **Approval settings** activa *Prevent approval by author*, *Prevent approvals by users who add commits* y *Remove all approvals when commits are added*.
5. **Tags protegidos** (**Settings → Repository → Protected tags**): patrón `v*`, **Allowed to create: Maintainers**. Un spoke fijado en `ref: "v1.2.0"` queda estable.
6. *(Opcional, Premium)* **Push rules** (**Settings → Repository → Push rules**): rechazar commits sin firmar, regex de mensaje, bloquear secretos, etc.

**Como código** (API v4; token con scope `api`). Niveles de acceso: `0` = nadie, `30` = Developer, `40` = Maintainer.
```bash
GL="https://gitlab.com/api/v4"; PID="<id-del-proyecto>"; TOKEN="<token>"

# Rama protegida: nadie hace push directo, devs pueden hacer merge, code owners requeridos
curl --request POST --header "PRIVATE-TOKEN: $TOKEN" \
  "$GL/projects/$PID/protected_branches?name=main&push_access_level=0&merge_access_level=30&allow_force_push=false&code_owner_approval_required=true"

# Tags v* solo los crean Maintainers
curl --request POST --header "PRIVATE-TOKEN: $TOKEN" \
  "$GL/projects/$PID/protected_tags?name=v*&create_access_level=40"

# Regla de aprobación: al menos 1
curl --request POST --header "PRIVATE-TOKEN: $TOKEN" \
  "$GL/projects/$PID/approval_rules" --data "name=hub-maintainers&approvals_required=1"
```
> `PID` puede ser el id numérico o la ruta URL-encoded (p. ej. `mi-grupo%2Fthelook_hub`).

---

## Bitbucket Cloud

**Aviso de plan:** sin **Premium**, los *merge checks* (aprobaciones mínimas, builds, tareas) solo **avisan**: el merge sigue siendo posible. Para **bloquear** hay que estar en Premium y activar *Prevent a merge with unresolved merge checks*. *Reset approvals on change* también es Premium. Bitbucket usa **Default reviewers** en lugar de un archivo `CODEOWNERS` nativo.

1. **Acceso.** Da a los spokes una **Access key** de solo lectura (**Repository settings → Access keys**) o acceso de lectura al repo. El equipo del hub con escritura; admin limitado.
2. **Dueños = Default reviewers** (**Repository settings → Default reviewers**): añade al equipo del hub como revisores por defecto.
3. **Branch restrictions** (**Repository settings → Branch restrictions → Add a branch restriction**), patrón `main`:
   - *Branch permissions:* **Write access** → solo personas/grupos concretos (el equipo del hub); el resto entra por PR. Marca **Prevent deletion** y **Prevent rewriting history** (sin force push).
   - *Merge settings:* **Minimum number of approvals** = 1–2; **Minimum approvals from default reviewers** ≥ 1; **No unresolved pull request tasks**; **No changes requested**.
   - *(Premium)* **Prevent a merge with unresolved merge checks** (para que *bloqueen*) y **Reset approvals when the source branch is modified**.
4. **Tags.** ⚠️ Bitbucket Cloud **no protege tags de forma nativa** como GitHub/GitLab. Mitigación: restringe el acceso de escritura y crea las versiones por un proceso controlado (p. ej. tags generados solo por Pipelines), o usa Bitbucket Data Center, que sí tiene restricciones de *ref* sobre tags.

**Como código** (API 2.0; autentícate con email + **API token**). Una *branch restriction* por `kind`:
```bash
BB="https://api.bitbucket.org/2.0/repositories/<workspace>/thelook_hub/branch-restrictions"
AUTH="<tu-email>:<api_token>"

# Forzar PR: nadie hace push directo a main (lista de usuarios/grupos vacía)
curl -u "$AUTH" -X POST "$BB" -H 'Content-Type: application/json' \
  -d '{"kind":"push","pattern":"main","users":[],"groups":[]}'

# Exigir 1 aprobación, prohibir borrar y reescribir historia
curl -u "$AUTH" -X POST "$BB" -H 'Content-Type: application/json' -d '{"kind":"require_approvals_to_merge","pattern":"main","value":1}'
curl -u "$AUTH" -X POST "$BB" -H 'Content-Type: application/json' -d '{"kind":"delete","pattern":"main"}'
curl -u "$AUTH" -X POST "$BB" -H 'Content-Type: application/json' -d '{"kind":"force","pattern":"main"}'

# (Premium) bloquear el merge si quedan checks sin resolver
curl -u "$AUTH" -X POST "$BB" -H 'Content-Type: application/json' -d '{"kind":"enforce_merge_checks","pattern":"main"}'
```
> Otros `kind` útiles: `require_default_reviewer_approvals_to_merge`, `require_passing_builds_to_merge`, `require_tasks_to_be_completed`, `require_no_changes_requested`, `reset_pullrequest_approvals_on_change`.

---

La idea de fondo no cambia entre plataformas: el núcleo certificado solo se modifica por un cambio revisado, con dueño y auditado, y los consumidores fijan versiones estables. Donde una plataforma no llega (los tags en Bitbucket Cloud, o las aprobaciones en planes gratuitos), conviene cubrir el hueco con el proceso o con el plan adecuado — y dejarlo dicho, igual que en la sección de costes y límites del README.
