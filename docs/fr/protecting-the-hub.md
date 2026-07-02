[English](../en/protecting-the-hub.md) · [Español](../protecting-the-hub.md) · **Français**
&nbsp;&nbsp;|&nbsp;&nbsp; **GitHub** · [GitLab / Bitbucket](protecting-the-hub-gitlab-bitbucket.md)

# Protéger le hub — configuration GitHub

> La gouvernance *par construction* du README n'est réelle que si GitHub impose **qui** peut modifier le hub et **comment**. Le code du hub est la source de vérité certifiée : ce guide le verrouille pour que ses définitions ne changent que par une PR revue, avec propriétaire et auditée, et pour que les spokes puissent épingler des versions immuables.

## Avant de commencer : utilisez une organisation

Pour restreindre les changements à une **équipe** précise — l'objectif réel —, le dépôt du hub devrait vivre dans une **organisation** GitHub (l'offre gratuite suffit pour les dépôts publics). Les listes d'exemption (*bypass*) par acteur, « restreindre qui peut rejeter les revues » et les revues requises par équipe sont **réservées aux organisations**. Sur un compte personnel, vous pouvez exiger des PR, des approbations et un CODEOWNERS, mais pas restreindre par équipe.

**Recommandation :** déplacez le hub dans une organisation et créez une équipe, p. ex. `hub-maintainers`.

## 1. Modèle d'accès (qui peut faire quoi)

Le flux est délibérément asymétrique, comme l'architecture :

- **Spokes → lecture seule.** Chaque spoke consomme le hub via `remote_dependency` avec une *deploy key* en **lecture seule**. Donnez l'accès **Read** aux consommateurs et, en ajoutant la clé (**Settings → Deploy keys**), ne cochez **pas** *Allow write access*.
- **Équipe du hub → écriture.** Attribuez **Write** (ou **Maintain**) à l'équipe `hub-maintainers`. Limitez **Admin** à une ou deux personnes : un admin peut contourner les règles.

## 2. Déclarez les propriétaires du hub (CODEOWNERS)

Créez un fichier `CODEOWNERS` (à la racine du dépôt du hub, ou dans `.github/`). Chaque changement exigera la revue de ses propriétaires. Les chemins sont relatifs à la racine du dépôt du hub :

```
# Tout le hub est gouverné par l'équipe plateforme
*                                @VOTRE_ORG/hub-maintainers

# (Optionnel) renforcez la PII et le modèle gouverné avec des propriétaires supplémentaires
/views/users.view.lkml           @VOTRE_ORG/hub-maintainers @VOTRE_ORG/securite-donnees
/thelook_hub.model.lkml          @VOTRE_ORG/hub-maintainers @VOTRE_ORG/securite-donnees
```

Sur un compte personnel, utilisez des noms d'utilisateur (`@votre_user @collegue`) au lieu d'équipes. Les propriétaires doivent avoir l'accès en écriture au dépôt.

## 3. Créez le ruleset de branche (le verrouillage central)

GitHub recommande les **Rulesets** plutôt que la protection de branche classique : plusieurs peuvent s'appliquer à la fois et ils offrent un contrôle plus fin.

1. **Settings → Rules → Rulesets → New ruleset → New branch ruleset.**
2. **Ruleset name :** `Protect main`.
3. **Enforcement status :** `Active`. *(Astuce : essayez d'abord `Evaluate` pour prévisualiser l'effet sans bloquer personne.)*
4. **Bypass list :** laissez-la **vide** pour une rigueur maximale, ou ajoutez `hub-maintainers` en **« Allow for pull requests only »** (les urgences passent quand même par une PR). Évitez *Always allow*.
5. **Target branches → Add target → Include default branch** (`main`).
6. **Branch protections** — activez :
   - **Require a pull request before merging**
     - **Required approvals :** `1` (ou `2`)
     - **Dismiss stale pull request approvals when new commits are pushed**
     - **Require review from Code Owners** — relie le CODEOWNERS de l'étape 2
     - **Require approval of the most recent reviewable push** — personne n'approuve son propre dernier push
     - **Require conversation resolution before merging**
   - **Block force pushes**
   - **Restrict deletions**
   - **Require status checks to pass** *(si vous ajoutez la validation LookML ; voir l'étape 5)* + **Require branches to be up to date**
   - *(Optionnel)* **Require linear history**, **Require signed commits**
7. **Create.**

Avec cela, personne ne pousse directement sur `main` : tout changement entre par une PR approuvée par un *code owner*, par quelqu'un d'autre que l'auteur du dernier push, avec les conversations résolues et sans réécriture de l'historique.

## 4. Protégez les tags de version (pour l'épinglage des spokes)

Comme chaque spoke épingle la version du hub (`ref` vers un tag ou un commit SHA), l'équipe tague ses releases (`v1.0.0`, `v1.1.0`). Protégez ces tags pour qu'ils soient **immuables** :

- **New ruleset → New tag ruleset → Target tags →** motif `v*`.
- Activez **Restrict deletions**, **Restrict updates** et **Block force pushes**.

Ainsi, un spoke épinglé sur `ref: "v1.2.0"` pointe toujours exactement vers le même code : une vraie garantie pour les consommateurs.

## 5. (Optionnel) Validation automatique comme status check

Le verrouillage gagne en force si chaque PR doit passer une validation LookML avant la fusion. L'approche habituelle : une GitHub Action qui valide le projet (p. ex. **Spectacles** ou `looker validate` via l'API Looker) et expose un *check* ; vous le marquez ensuite **requis** à l'étape 3. Nécessite des identifiants de l'API Looker.

## 6. Vérifiez

- Un `git push` direct sur `main` → **rejeté**.
- Une PR qui touche le hub sans approbation d'un *code owner* → **impossible à fusionner**.
- Approuver son propre dernier push → **bloqué**.
- Consultez les règles actives sur `github.com/<votre-org>/<repo>/rules` ou dans la zone de fusion de la PR.

## 7. Tout cela en code (gh CLI + API)

La forme la plus fidèle à la *gouvernance par construction* est de versionner jusqu'aux règles. Avec la [GitHub CLI](https://cli.github.com) (`gh auth login`, avec la permission d'administration sur le dépôt), vous reproduisez tout ce qui précède depuis le terminal. Les deux rulesets sont fournis en JSON dans [`docs/rulesets/`](../rulesets).

**0. (S'ils n'existent pas encore) créez et publiez les trois dépôts** — le contenu de chaque dossier va à la racine de son dépôt :
```bash
ORG="VOTRE_ORG"          # organisation (recommandé) ou votre utilisateur
SRC="thelook-hub-and-spoke"

for pair in "hub:thelook_hub" "spoke-marketing:thelook_marketing" "spoke-operations:thelook_operations"; do
  dir="${pair%%:*}"; repo="${pair##*:}"
  rm -rf "/tmp/$repo" && cp -R "$SRC/$dir" "/tmp/$repo"
  gh repo create "$ORG/$repo" --public
  git -C "/tmp/$repo" init -b main
  git -C "/tmp/$repo" add . && git -C "/tmp/$repo" commit -m "Import initial : $repo"
  git -C "/tmp/$repo" remote add origin "git@github.com:$ORG/$repo.git"
  git -C "/tmp/$repo" push -u origin main
done
```

**1. Deploy key en lecture seule pour un spoke** (la clé publique est générée par l'IDE Looker du spoke) :
```bash
gh repo deploy-key add key.pub --repo "$ORG/thelook_hub" --title "thelook_marketing (lecture seule)"
# Ne passez PAS --allow-write : la clé reste en lecture seule.
```

**2. CODEOWNERS :**
```bash
cd /tmp/thelook_hub
mkdir -p .github
printf '%s\n' "*  @$ORG/hub-maintainers" > .github/CODEOWNERS
git add .github/CODEOWNERS && git commit -m "Ajoute CODEOWNERS" && git push
```

**3. Appliquez les rulesets** (versionnés en JSON). `docs/rulesets/protect-main.json` :
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
Appliquez-les au dépôt du hub (avec `protect-tags.json`, qui protège les tags `v*`) :
```bash
gh api --method POST -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/$ORG/thelook_hub/rulesets --input docs/rulesets/protect-main.json

gh api --method POST -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/$ORG/thelook_hub/rulesets --input docs/rulesets/protect-tags.json
```
> `~DEFAULT_BRANCH` cible votre branche par défaut ; remplacez-le par `"refs/heads/main"` pour l'épingler explicitement. Le JSON est livré avec `bypass_actors: []` (rigueur maximale). Pour accorder à une équipe une exemption *PR uniquement* (organisations seulement), récupérez son id et ajoutez-le à `bypass_actors` :
> ```bash
> gh api /orgs/$ORG/teams/hub-maintainers --jq '.id'
> # → { "actor_id": <id>, "actor_type": "Team", "bypass_mode": "pull_request" }
> ```

**4. Taguez une release certifiée** (la version que les spokes épinglent) :
```bash
cd /tmp/thelook_hub
git tag -a v1.0.0 -m "Hub v1.0.0 (première release certifiée)"
git push origin v1.0.0
```

**5. Vérifiez :**
```bash
gh api /repos/$ORG/thelook_hub/rulesets --jq '.[].name'
# Un push direct sur main est désormais rejeté ; tout changement passe par une PR.
```

---

Voici la couche d'application derrière la *gouvernance par construction* : les définitions certifiées du hub ne changent que par une PR revue, avec propriétaire et auditée ; les consommateurs épinglent des versions immuables ; et personne — même par accident — ne pousse de changements non gouvernés dans le noyau. C'est aussi le socle technique du modèle opérationnel du README (« qui gouverne le hub ? »).
