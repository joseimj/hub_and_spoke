**English** · [Español](../protecting-the-hub-gitlab-bitbucket.md)
&nbsp;&nbsp;|&nbsp;&nbsp; [GitHub](protecting-the-hub.md) · **GitLab / Bitbucket**

# Protecting the hub — GitLab and Bitbucket

> The goal is identical to [the GitHub guide](protecting-the-hub.md): the hub's certified definitions change only through a reviewed, owned, audited PR/MR, and spokes can pin immutable versions. What changes are the names, the plans, and the APIs.

## Cross-platform equivalences

| Governance control | GitHub | GitLab | Bitbucket Cloud |
|---|---|---|---|
| Force a PR/MR (no direct push) | Ruleset · *Require a pull request* | Protected branch · *Allowed to push and merge → No one* | Branch restriction · *push* with no one |
| Required approvals | Ruleset PR · *Required approvals: N* | Approval rules · *Approvals required: N* · **Premium** | Merge check · *Minimum approvals: N* (blocks with **Premium**) |
| Owner approval | `CODEOWNERS` + *Require review from Code Owners* | `CODEOWNERS` + *Require approval from code owners* · **Premium** | *Default reviewers* + *Min. approvals from default reviewers* (no native `CODEOWNERS`) |
| No self-approval of last push | *Require approval of most recent push* | *Prevent approval by author* / *by committers* | via default reviewers |
| Reset approvals on push | *Dismiss stale approvals on push* | *Remove all approvals when commits added* | *Reset approvals on change* · **Premium** |
| Block force push | *Block force pushes* | *Allowed to force push → off* | *Prevent rewriting history* |
| Prevent branch deletion | *Restrict deletions* | (branch protection prevents it) | *Prevent deletion* |
| Immutable tags (pinning) | Tag ruleset | *Protected tags* | ⚠️ no native tag protection |
| Read-only access (spokes) | Deploy key without write | Read-only deploy key | Read-only access key |
| "As code" (API) | `POST /repos/…/rulesets` | `POST …/protected_branches`, `…/protected_tags`, `…/approval_rules` | `POST …/branch-restrictions` (by `kind`) |

---

## GitLab

**Plan note:** **Code Owner approval** and **MR approval rules** (required count, eligible approvers, preventing the author from approving) are **Premium/Ultimate**. On **Free** you can protect branches by role and protect tags; to require approvals you need Premium.

1. **Access (who can do what).** Give spokes a **read-only** deploy key (**Settings → Repository → Deploy keys**, leave *Grant write permissions* unchecked). The hub team gets the **Maintainer** role; **Owner** limited to one or two people.
2. **CODEOWNERS.** Create the file at the root, in `docs/`, or in `.gitlab/`:
   ```
   *  @your-group/hub-maintainers
   ```
3. **Protected branch** (**Settings → Repository → Protected branches**): branch `main` (or `*`).
   - **Allowed to merge:** Developers + Maintainers (or Maintainers only).
   - **Allowed to push and merge:** **No one** — this forces every change through an MR.
   - **Allowed to force push:** off.
   - **Require approval from code owners:** on *(Premium)*.
4. **Approvals** (**Settings → Merge requests → Merge request approvals**, *Premium*): an approval rule with **Approvals required ≥ 1**; under **Approval settings** enable *Prevent approval by author*, *Prevent approvals by users who add commits*, and *Remove all approvals when commits are added*.
5. **Protected tags** (**Settings → Repository → Protected tags**): pattern `v*`, **Allowed to create: Maintainers**. A spoke pinned at `ref: "v1.2.0"` stays stable.
6. *(Optional, Premium)* **Push rules** (**Settings → Repository → Push rules**): reject unsigned commits, message regex, block secrets, etc.

**As code** (API v4; token with the `api` scope). Access levels: `0` = no one, `30` = Developer, `40` = Maintainer.
```bash
GL="https://gitlab.com/api/v4"; PID="<project-id>"; TOKEN="<token>"

# Protected branch: no direct pushes, devs can merge, code owners required
curl --request POST --header "PRIVATE-TOKEN: $TOKEN" \
  "$GL/projects/$PID/protected_branches?name=main&push_access_level=0&merge_access_level=30&allow_force_push=false&code_owner_approval_required=true"

# Tags v* can only be created by Maintainers
curl --request POST --header "PRIVATE-TOKEN: $TOKEN" \
  "$GL/projects/$PID/protected_tags?name=v*&create_access_level=40"

# Approval rule: at least 1
curl --request POST --header "PRIVATE-TOKEN: $TOKEN" \
  "$GL/projects/$PID/approval_rules" --data "name=hub-maintainers&approvals_required=1"
```
> `PID` can be the numeric id or the URL-encoded path (e.g. `my-group%2Fthelook_hub`).

---

## Bitbucket Cloud

**Plan note:** without **Premium**, merge checks (minimum approvals, builds, tasks) only **warn** — merging is still possible. To **block**, you must be on Premium and enable *Prevent a merge with unresolved merge checks*. *Reset approvals on change* is also Premium. Bitbucket uses **Default reviewers** instead of a native `CODEOWNERS` file.

1. **Access.** Give spokes a read-only **Access key** (**Repository settings → Access keys**) or read access to the repo. The hub team gets write; admin limited.
2. **Owners = Default reviewers** (**Repository settings → Default reviewers**): add the hub team as default reviewers.
3. **Branch restrictions** (**Repository settings → Branch restrictions → Add a branch restriction**), pattern `main`:
   - *Branch permissions:* **Write access** → only specific people/groups (the hub team); everyone else goes through a PR. Enable **Prevent deletion** and **Prevent rewriting history** (no force push).
   - *Merge settings:* **Minimum number of approvals** = 1–2; **Minimum approvals from default reviewers** ≥ 1; **No unresolved pull request tasks**; **No changes requested**.
   - *(Premium)* **Prevent a merge with unresolved merge checks** (so they *block*) and **Reset approvals when the source branch is modified**.
4. **Tags.** ⚠️ Bitbucket Cloud has **no native tag protection** like GitHub/GitLab. Mitigation: restrict write access and create releases through a controlled process (e.g. tags created only by Pipelines), or use Bitbucket Data Center, which does have *ref* restrictions covering tags.

**As code** (API 2.0; authenticate with email + **API token**). One branch restriction per `kind`:
```bash
BB="https://api.bitbucket.org/2.0/repositories/<workspace>/thelook_hub/branch-restrictions"
AUTH="<your-email>:<api_token>"

# Force a PR: no direct pushes to main (empty users/groups list)
curl -u "$AUTH" -X POST "$BB" -H 'Content-Type: application/json' \
  -d '{"kind":"push","pattern":"main","users":[],"groups":[]}'

# Require 1 approval, forbid deletion and history rewrites
curl -u "$AUTH" -X POST "$BB" -H 'Content-Type: application/json' -d '{"kind":"require_approvals_to_merge","pattern":"main","value":1}'
curl -u "$AUTH" -X POST "$BB" -H 'Content-Type: application/json' -d '{"kind":"delete","pattern":"main"}'
curl -u "$AUTH" -X POST "$BB" -H 'Content-Type: application/json' -d '{"kind":"force","pattern":"main"}'

# (Premium) block the merge if any checks are unresolved
curl -u "$AUTH" -X POST "$BB" -H 'Content-Type: application/json' -d '{"kind":"enforce_merge_checks","pattern":"main"}'
```
> Other useful `kind`s: `require_default_reviewer_approvals_to_merge`, `require_passing_builds_to_merge`, `require_tasks_to_be_completed`, `require_no_changes_requested`, `reset_pullrequest_approvals_on_change`.

---

The underlying idea doesn't change across platforms: the certified core changes only through a reviewed, owned, audited change, and consumers pin stable versions. Where a platform falls short (tags on Bitbucket Cloud, or approvals on free plans), cover the gap with process or with the right plan — and say so, just like the README's costs-and-limits section.
