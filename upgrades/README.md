# Upgrades

Repos made from this template share no git history with it, so `git pull` and
`git cherry-pick` are not available. Changes travel as patches instead.

`VERSION` at the repo root says which contract a repo is on. **No `VERSION` file
means v0** — the unversioned state every repo built from this template before
the scheme existed is in. There is no other marker to look for.

Each folder here is one step, named `v<from>-v<to>`, and holds the patch plus a
README with the manual steps around it. Apply them in order. Every folder is
self-contained, so read the one you are applying and ignore the rest.

| Upgrade | What it does |
| --- | --- |
| [v0-v1](v0-v1/) | Moves the generated index out of `README.md` into `INDEX.md`, makes the title column hand-editable, adds tests |

## What earns a release

**Only a change downstream repos must adopt to keep working.** Script behavior
and the file contract, yes. Doc fixes, added tests, README prose, and comment
cleanups, no.

Most commits to this template will never bump `VERSION` or produce a folder
here. That is the intended ratio, and the rule above is what keeps it — without
it written down, every edit to `bin/` reopens the question of whether to cut a
release.

## What this deliberately is not

No script applies or generates these. No manifest, no multi-patch folders, no
way to jump v0→v2 in one go — chain the steps instead. A patch and prose is the
ceiling here, and it should stay there until enough upgrades exist to prove a
pattern worth automating.
