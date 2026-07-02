[English](en/protecting-the-hub.md) · **Español** · [Français](fr/protecting-the-hub.md)
&nbsp;&nbsp;|&nbsp;&nbsp; **GitHub** · [GitLab / Bitbucket](protecting-the-hub-gitlab-bitbucket.md)

# Proteger el hub — configuración de GitHub

> La gobernanza *por construcción* del README solo es real si GitHub impone **quién** puede cambiar el hub y **cómo**. El código del hub es la fuente de verdad certificada: esta guía lo blinda para que sus definiciones cambien únicamente mediante un PR revisado, con dueño y auditado, y para que los spokes puedan fijar versiones inmutables.

## Antes de empezar: usa una organización

Para restringir los cambios a un **equipo** concreto —el objetivo real— el repo del hub debería vivir en una **organización** de GitHub (la gratuita basta para repos públicos). Las listas de excepción (*bypass*) por actor, "restringir quién descarta revisiones" y las revisiones requeridas por equipo son **exclusivas de organizaciones**. En una cuenta personal puedes exigir PRs, aprobaciones y CODEOWNERS, pero no restringir por equipo.

**Recomendación:** mueve el hub a una organización y crea un equipo, p. ej. `hub-maintainers`.

## 1. Modelo de acceso (quién puede qué)

El flujo es deliberadamente asimétrico, igual que la arquitectura:

- **Spokes → solo lectura.** Cada spoke consume el hub vía `remote_dependency` con una *deploy key* de **solo lectura**. Da acceso **Read** a los consumidores y, al añadir la clave (**Settings → Deploy keys**), **no** marques *Allow write access*.
- **Equipo del hub → escritura.** Asigna **Write** (o **Maintain**) al equipo `hub-maintainers`. Limita **Admin** a una o dos personas: quien es admin puede saltarse las reglas.

## 2. Declara los dueños del hub (CODEOWNERS)

Crea un archivo `CODEOWNERS` (en la raíz del repo del hub, o en `.github/`). Cada cambio exigirá la revisión de sus dueños. Las rutas son relativas a la raíz del repo del hub:

```
# Todo el hub lo gobierna el equipo de plataforma
*                                @TU_ORG/hub-maintainers

# (Opcional) refuerza la PII y el modelo gobernado con dueños adicionales
/views/users.view.lkml           @TU_ORG/hub-maintainers @TU_ORG/seguridad-datos
/thelook_hub.model.lkml          @TU_ORG/hub-maintainers @TU_ORG/seguridad-datos
```

En una cuenta personal, usa nombres de usuario (`@tu_usuario @colega`) en vez de equipos. Los dueños deben tener acceso de escritura al repo.

## 3. Crea el ruleset de la rama (el blindaje central)

GitHub recomienda **Rulesets** sobre la protección de ramas clásica: varios pueden aplicarse a la vez y ofrecen control más fino.

1. **Settings → Rules → Rulesets → New ruleset → New branch ruleset.**
2. **Ruleset name:** `Proteger main`.
3. **Enforcement status:** `Active`. *(Consejo: prueba primero con `Evaluate` para ver el efecto sin bloquear a nadie.)*
4. **Bypass list:** déjala **vacía** para máximo rigor, o añade `hub-maintainers` como **"Allow for pull requests only"** (las urgencias siguen pasando por un PR). Evita *Always allow*.
5. **Target branches → Add target → Include default branch** (`main`).
6. **Branch protections** — activa:
   - **Require a pull request before merging**
     - **Required approvals:** `1` (o `2`)
     - **Dismiss stale pull request approvals when new commits are pushed**
     - **Require review from Code Owners** — conecta con el CODEOWNERS del paso 2
     - **Require approval of the most recent reviewable push** — nadie aprueba su propio último push
     - **Require conversation resolution before merging**
   - **Block force pushes**
   - **Restrict deletions**
   - **Require status checks to pass** *(si añades validación de LookML; ver paso 5)* + **Require branches to be up to date**
   - *(Opcional)* **Require linear history**, **Require signed commits**
7. **Create.**

Con esto, nadie hace push directo a `main`: todo cambio entra por un PR aprobado por un *code owner*, distinto de quien hizo el último push, con la conversación resuelta y sin poder reescribir la historia.

## 4. Protege los tags de versión (para el *pinning* de los spokes)

Como cada spoke fija la versión del hub (`ref` a un tag o commit SHA), el equipo etiqueta releases (`v1.0.0`, `v1.1.0`). Protege esos tags para que sean **inmutables**:

- **New ruleset → New tag ruleset → Target tags →** patrón `v*`.
- Activa **Restrict deletions**, **Restrict updates** y **Block force pushes**.

Así, un spoke fijado en `ref: "v1.2.0"` apunta siempre exactamente al mismo código: una garantía real para los consumidores.

## 5. (Opcional) Validación automática como status check

El blindaje gana fuerza si cada PR debe pasar una validación de LookML antes de fusionar. Lo habitual es una GitHub Action que valide el proyecto (p. ej. **Spectacles** o `looker validate` vía la API de Looker) y exponga un *check*; luego lo marcas como **requerido** en el paso 3. Requiere credenciales de la API de Looker.

## 6. Verifica

- `git push` directo a `main` → **rechazado**.
- PR que toca el hub sin aprobación de un *code owner* → **no se puede fusionar**.
- Aprobar tu propio último push → **bloqueado**.
- Revisa las reglas activas en `github.com/<tu-org>/<repo>/rules` o en la caja de fusión del PR.

## 7. Todo esto como código (gh CLI + API)

La forma más fiel a *gobernanza por construcción* es versionar hasta las reglas. Con la [GitHub CLI](https://cli.github.com) (`gh auth login`, con permiso de administración sobre el repo) reproduces todo lo anterior desde la terminal. Los dos rulesets ya vienen como JSON en [`docs/rulesets/`](rulesets).

**0. (Si aún no existen) crea y publica los tres repos** — el contenido de cada carpeta va a la raíz de su repo:
```bash
ORG="TU_ORG"          # organización (recomendado) o tu usuario
SRC="thelook-hub-and-spoke"

for pair in "hub:thelook_hub" "spoke-marketing:thelook_marketing" "spoke-operations:thelook_operations"; do
  dir="${pair%%:*}"; repo="${pair##*:}"
  rm -rf "/tmp/$repo" && cp -R "$SRC/$dir" "/tmp/$repo"
  gh repo create "$ORG/$repo" --public
  git -C "/tmp/$repo" init -b main
  git -C "/tmp/$repo" add . && git -C "/tmp/$repo" commit -m "Importación inicial: $repo"
  git -C "/tmp/$repo" remote add origin "git@github.com:$ORG/$repo.git"
  git -C "/tmp/$repo" push -u origin main
done
```

**1. Deploy key de solo lectura para un spoke** (la clave pública la genera el IDE de Looker del spoke):
```bash
gh repo deploy-key add key.pub --repo "$ORG/thelook_hub" --title "thelook_marketing (solo lectura)"
# No pases --allow-write: la clave queda de solo lectura.
```

**2. CODEOWNERS:**
```bash
cd /tmp/thelook_hub
mkdir -p .github
printf '%s\n' "*  @$ORG/hub-maintainers" > .github/CODEOWNERS
git add .github/CODEOWNERS && git commit -m "Añade CODEOWNERS" && git push
```

**3. Aplica los rulesets** (versionados como JSON). `docs/rulesets/protect-main.json`:
```json
{
  "name": "Protect main",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [],
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "pull_request", "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": true,
        "require_last_push_approval": true,
        "required_review_thread_resolution": true
    } }
  ]
}
```
Aplícalos al repo del hub (junto con `protect-tags.json`, que protege los tags `v*`):
```bash
gh api --method POST -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/$ORG/thelook_hub/rulesets --input docs/rulesets/protect-main.json

gh api --method POST -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/$ORG/thelook_hub/rulesets --input docs/rulesets/protect-tags.json
```
> `~DEFAULT_BRANCH` apunta a tu rama por defecto; cámbialo por `"refs/heads/main"` si prefieres fijarlo. El JSON trae `bypass_actors: []` (rigor máximo). Para dar a un equipo excepción *solo en PRs* (solo en organizaciones), obtén su id y añádelo a `bypass_actors`:
> ```bash
> gh api /orgs/$ORG/teams/hub-maintainers --jq '.id'
> # → { "actor_id": <id>, "actor_type": "Team", "bypass_mode": "pull_request" }
> ```

**4. Etiqueta una release certificada** (la versión que fijan los spokes):
```bash
cd /tmp/thelook_hub
git tag -a v1.0.0 -m "Hub v1.0.0 (primera release certificada)"
git push origin v1.0.0
```

**5. Verifica:**
```bash
gh api /repos/$ORG/thelook_hub/rulesets --jq '.[].name'
# Un push directo a main ahora se rechaza; todo cambio entra por PR.
```

---

Esta es la capa de aplicación detrás de *gobernanza por construcción*: las definiciones certificadas del hub solo cambian por un PR revisado, con dueño y auditado; los consumidores fijan versiones inmutables; y nadie —ni por accidente— mete cambios sin gobernar en el núcleo. Es también el sustento técnico del modelo operativo ("¿quién gobierna al hub?") del README.
