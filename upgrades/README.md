# Upgrades

Repos made from this template share no git history with it, so `git pull` and `git cherry-pick` are not available. Changes travel as patches instead.

`VERSION` at the repo root says which contract a repo is on. **No `VERSION` file means v0** — the unversioned state every repo built from this template before the scheme existed is in. There is no other marker to look for.

Each folder here is one step, named `v<from>-v<to>`, and holds the patch plus a README with the manual steps around it. Apply them in order. Every folder is self-contained, so read the one you are applying and ignore the rest.

**Upgrades are applied from this repository, on GitHub — never from a local copy.** A repo created from this template received whatever upgrade folders existed at the time, which are by definition ones it has already applied. The upgrade it needs next is the one that did not exist yet. So start here, find the folder matching your `VERSION`, and follow it.

| Upgrade | What it does |
| --- | --- |
| [v0-v1](v0-v1/) | Moves the generated index out of `README.md` into `INDEX.md`, makes the title column hand-editable, adds tests |
| [v1-v2](v1-v2/) | Splits the docs into `README.md` (yours), `INSTRUCTIONS.md` and `AGENTS.md`; names which paths upgrades may rewrite; ships `CHANGELOG.md`; drops `adr/` |

## What earns a release

**Only a change downstream repos must adopt to keep working.** Script behavior and the file contract, yes. Doc fixes, added tests, README prose, and comment cleanups, no.

Most commits to this template will never bump `VERSION` or produce a folder here. That is the intended ratio, and the rule above is what keeps it — without it written down, every edit to `bin/` reopens the question of whether to cut a release.

## Developing the template

`bin/test` runs the suite over `bin/lib/planning.rb`. It is stdlib-only Minitest, hand-run, with no CI — the risk is low enough that a pipeline would cost more than it protects, and keeping it hand-run keeps the dependency count at zero. Run it before you commit a change to `bin/`, and add tests in the same commit as the behavior they cover.

**Every plan that changes this template includes producing the upgrade as part of its own scope.** A plan that edits managed files and stops when the template looks right has left the spawned repos behind, which is the failure this directory exists to prevent. Cutting the release means: bump `VERSION`, add the `CHANGELOG.md` entry, and write the `v<from>-v<to>` folder below.

Two habits that make that cheap:

- Keep one commit per change on the working branch. The patch is generated from those commits, so a history that mixes several changes into one blob is harder to scope and review.
- Generate the patch across managed paths only — `bin/`, `test/`, `AGENTS.md`, `INSTRUCTIONS.md`, `CLAUDE.md`, `VERSION`, `CHANGELOG.md`. Never `README.md`, `features/`, `INDEX.md`, or `upgrades/` itself.

Every upgrade's README ends by telling the reader to run `bin/test`. It is the one moment someone who never touches the scripts has a reason to run them, and it confirms the patch landed intact.

## What this deliberately is not

No script applies or generates these. No manifest, no multi-patch folders, no way to jump v0→v2 in one go — chain the steps instead. A patch and prose is the ceiling here, and it should stay there until enough upgrades exist to prove a pattern worth automating.
