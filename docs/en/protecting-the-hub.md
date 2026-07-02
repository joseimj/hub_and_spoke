**English** · [Español](../protecting-the-hub.md) · [Français](../fr/protecting-the-hub.md)
&nbsp;&nbsp;|&nbsp;&nbsp; **GitHub** · [GitLab / Bitbucket](protecting-the-hub-gitlab-bitbucket.md)

# Protecting the hub — GitHub configuration

> The README's governance *by construction* is only real if GitHub enforces **who** can change the hub and **how**. The hub's code is the certified source of truth: this guide locks it down so its definitions change only through a reviewed, owned, audited pull request, and so spokes can pin immutable versions.

## Before you start: use an organization

To restrict changes to a specific **team** —the real goal— the hub repo should live in a GitHub **organization** (the free tier is enough for public repos). Per-actor bypass lists, "restrict who can dismiss reviews," and team-required reviews are **organization-only**. On a personal account you can require PRs, approvals, and CODEOWNERS, but you can't restrict by team.

**Recommendation:** move the hub into an organization and create a team, e.g. `hub-maintainers`.

## 1. Access model (who can do what)

The flow is deliberately asymmetric, just like the architecture:

- **Spokes → read-only.** Each spoke consumes the hub via `remote_dependency` with a **read-only** deploy key. Grant consumers **Read** access and, when adding the key (**Settings → Deploy keys**), do **not** check *Allow write access*.
- **Hub team → write.** Grant **Write** (or **Maintain**) to the `hub-maintainers` team. Limit **Admin** to one or two people: an admin can bypass the rules.

## 2. Declare the hub's owners (CODEOWNERS)

Add a `CODEOWNERS` file (at the root of the hub repo, or in `.github/`). Every change will require its owners' review. Paths are relative to the hub repo root:

```
# The whole hub is governed by the platform team
*                                @YOUR_ORG/hub-maintainers

# (Optional) reinforce PII and the governed model with extra owners
/views/users.view.lkml           @YOUR_ORG/hub-maintainers @YOUR_ORG/data-security
/thelook_hub.model.lkml          @YOUR_ORG/hub-maintainers @YOUR_ORG/data-security
```

On a personal account, use usernames (`@your_user @colleague`) instead of teams. Owners must have write access to the repo.

## 3. Create the branch ruleset (the core lockdown)

GitHub recommends **Rulesets** over classic branch protection: multiple can apply at once and they offer finer control.

1. **Settings → Rules → Rulesets → New ruleset → New branch ruleset.**
2. **Ruleset name:** `Protect main`.
3. **Enforcement status:** `Active`. *(Tip: try `Evaluate` first to preview the effect without blocking anyone.)*
4. **Bypass list:** leave it **empty** for maximum strictness, or add `hub-maintainers` as **"Allow for pull requests only"** (emergencies still go through a PR). Avoid *Always allow*.
5. **Target branches → Add target → Include default branch** (`main`).
6. **Branch protections** — enable:
   - **Require a pull request before merging**
     - **Required approvals:** `1` (or `2`)
     - **Dismiss stale pull request approvals when new commits are pushed**
     - **Require review from Code Owners** — wires up the CODEOWNERS from step 2
     - **Require approval of the most recent reviewable push** — no one approves their own last push
     - **Require conversation resolution before merging**
   - **Block force pushes**
   - **Restrict deletions**
   - **Require status checks to pass** *(if you add LookML validation; see step 5)* + **Require branches to be up to date**
   - *(Optional)* **Require linear history**, **Require signed commits**
7. **Create.**

With this, nobody pushes directly to `main`: every change enters through a PR approved by a code owner, by someone other than the last pusher, with conversations resolved and no history rewrites.

## 4. Protect release tags (for spoke version pinning)

Since each spoke pins the hub version (`ref` to a tag or commit SHA), the team tags releases (`v1.0.0`, `v1.1.0`). Protect those tags so they're **immutable**:

- **New ruleset → New tag ruleset → Target tags →** pattern `v*`.
- Enable **Restrict deletions**, **Restrict updates**, and **Block force pushes**.

That way a spoke pinned at `ref: "v1.2.0"` always points to exactly the same code: a real guarantee for consumers.

## 5. (Optional) Automated validation as a status check

The lockdown gets stronger if every PR must pass LookML validation before merging. The usual approach is a GitHub Action that validates the project (e.g. **Spectacles** or `looker validate` via the Looker API) and exposes a check; then you mark it **required** in step 3. Requires Looker API credentials.

## 6. Verify

- A direct `git push` to `main` → **rejected**.
- A PR touching the hub without a code owner's approval → **can't be merged**.
- Approving your own last push → **blocked**.
- Review the active rules at `github.com/<your-org>/<repo>/rules` or in the PR's merge box.

## 7. All of this as code (gh CLI + API)

The truest form of *governance by construction* is to version even the rules. With the [GitHub CLI](https://cli.github.com) (`gh auth login`, with admin permission on the repo) you can reproduce everything above from the terminal. Both rulesets ship as JSON in [`docs/rulesets/`](../rulesets).

**0. (If they don't exist yet) create and publish the three repos** — each folder's contents go at the root of its repo:
```bash
ORG="YOUR_ORG"          # organization (recommended) or your username
SRC="thelook-hub-and-spoke"

for pair in "hub:thelook_hub" "spoke-marketing:thelook_marketing" "spoke-operations:thelook_operations"; do
  dir="${pair%%:*}"; repo="${pair##*:}"
  rm -rf "/tmp/$repo" && cp -R "$SRC/$dir" "/tmp/$repo"
  gh repo create "$ORG/$repo" --public
  git -C "/tmp/$repo" init -b main
  git -C "/tmp/$repo" add . && git -C "/tmp/$repo" commit -m "Initial import: $repo"
  git -C "/tmp/$repo" remote add origin "git@github.com:$ORG/$repo.git"
  git -C "/tmp/$repo" push -u origin main
done
```

**1. Read-only deploy key for a spoke** (the public key is generated by the spoke's Looker IDE):
```bash
gh repo deploy-key add key.pub --repo "$ORG/thelook_hub" --title "thelook_marketing (read-only)"
# Do NOT pass --allow-write: the key stays read-only.
```

**2. CODEOWNERS:**
```bash
cd /tmp/thelook_hub
mkdir -p .github
printf '%s\n' "*  @$ORG/hub-maintainers" > .github/CODEOWNERS
git add .github/CODEOWNERS && git commit -m "Add CODEOWNERS" && git push
```

**3. Apply the rulesets** (version-controlled as JSON). `docs/rulesets/protect-main.json`:
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
Apply them to the hub repo (along with `protect-tags.json`, which protects `v*` tags):
```bash
gh api --method POST -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/$ORG/thelook_hub/rulesets --input docs/rulesets/protect-main.json

gh api --method POST -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/$ORG/thelook_hub/rulesets --input docs/rulesets/protect-tags.json
```
> `~DEFAULT_BRANCH` targets your default branch; swap it for `"refs/heads/main"` to pin it explicitly. The JSON ships with `bypass_actors: []` (maximum strictness). To grant a team a *pull-request-only* exception (organizations only), get its id and add it to `bypass_actors`:
> ```bash
> gh api /orgs/$ORG/teams/hub-maintainers --jq '.id'
> # → { "actor_id": <id>, "actor_type": "Team", "bypass_mode": "pull_request" }
> ```

**4. Tag a certified release** (the version spokes pin to):
```bash
cd /tmp/thelook_hub
git tag -a v1.0.0 -m "Hub v1.0.0 (first certified release)"
git push origin v1.0.0
```

**5. Verify:**
```bash
gh api /repos/$ORG/thelook_hub/rulesets --jq '.[].name'
# A direct push to main is now rejected; every change goes through a PR.
```

---

This is the enforcement layer behind *governance by construction*: the hub's certified definitions change only through a reviewed, owned, audited PR; consumers pin immutable versions; and no one —not even by accident— pushes ungoverned changes into the core. It's also the technical backbone of the README's operating model ("who governs the hub?").
