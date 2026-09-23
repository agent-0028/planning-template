# Instructions

How this repo works, for humans and agents alike. The template maintains this file — see [What this repo owns, and what you own](#what-this-repo-owns-and-what-you-own) before editing it.

## Layout

```
features/<lifecycle>/<slug>/   # one folder per feature
INDEX.md                       # GENERATED, except the title column
README.md                      # yours
```

Lifecycle is one of `proposed`, `active`, `shipped`, `abandoned`. **The path is the state.** Nothing inside a folder records it, so state cannot drift from reality — there is no status field to forget to update.

## What a feature is

A feature is a kebab-case slug directory under `features/<lifecycle>/`. Slugs are semantic — two to four words, no ticket IDs, no dates.

What goes inside is up to whoever writes it. File names and sections are convention at most. Nothing validates them, and a folder is never wrong for holding something unexpected.

## Workflow

1. Put a feature folder in `features/proposed/<slug>/` — or in any lifecycle folder, if it already belongs somewhere else
2. `bin/adopt <slug>` to track it and put it in the index
3. `bin/move <slug> active` when the work is approved
4. Build. Each PR body carries `Spec: planning@<sha> <slug>`
5. `bin/move <slug> shipped` when it lands, or `abandoned` if it does not

Step 3 is a file move, which means it can be a pull request — an approval gate for a plan, reviewed with the same machinery as code. It can equally be one person running one command. The repo makes review possible without requiring it.

## Commands

```bash
# adopt a folder where it sits
bin/adopt <slug>

# import a folder or file from anywhere else
bin/adopt <path> [slug]

# change lifecycle, regenerate the index
bin/move <slug> <lifecycle>

# remove a feature folder
bin/delete <slug>

# regenerate INDEX.md
bin/index

# verify INDEX.md matches the tree
bin/check
```

`bin/adopt` gets a folder into the tree, in whichever lifecycle folder you dropped it — it never asks which, because the path already says. `bin/move` changes that lifecycle afterward, and nothing else should.

Never `git mv` a feature folder by hand. `bin/adopt` and `bin/move` regenerate the index in the same commit, and a stale index is the thing most likely to drift.

Neither validates or edits anything inside a folder — the path is the only thing that carries state. The one thing anything here reads from inside a folder is the single heading the index needs for a title.

`bin/move` is strictly a `git mv`, so it refuses a folder git does not track yet and points you at `bin/adopt`. Moving a folder to the lifecycle it is already in is an error, not a quiet no-op — that case is what `bin/adopt` is for.

`bin/delete` removes a folder outright. Content that is already committed goes without ceremony, because history still has it — the check compares blob hashes rather than paths, so a folder you have only moved still counts as committed. Content in no commit refuses until you pass `--force`, which names every file it is about to destroy.

`bin/adopt`, `bin/move`, and `bin/delete` all take `--commit` to make the commit rather than leaving it staged; `bin/move` and `bin/delete` also take `--dry-run`.

There is a seventh script, `bin/test`, which runs the test suite over `bin/lib/planning.rb`. You need it in one situation: right after applying an upgrade from the template, to confirm the scripts still work. Writing tests is template-development work and lives in [upgrades/README.md](upgrades/README.md).

## Before you commit

`bin/check` exits zero, and the commit touches exactly one feature folder unless it is a repo-wide convention change.

Since the index records the date of the last commit touching each folder, that means re-running `bin/index` after you edit a feature and before you commit it.

## How the index is built

`INDEX.md` is generated in full from the feature tree. A feature is any directory under `features/<lifecycle>/`. For each one:

- **Title** comes from the first `#` heading in `feature-specification.md`, or failing that the first top-level `.md` in the folder, with a leading `Something: ` label stripped. A folder with no heading to find shows its slug.
- **Updated** is the date of the last commit touching the folder, or today's date when the folder has uncommitted changes.

Neither lookup requires a file to exist. A folder holding one scratch note gets an index row the same as a fully worked feature.

The title is only a starting guess, so it is yours to overwrite. **A title already in `INDEX.md` wins over the one scraped from the folder**, which means a bad heading can be corrected in place and it sticks — through a `bin/move` as well, because rows are matched on slug as well as path. Delete a row to derive it from the folder again. That is the whole reason the file is worth having: plan folders are messy, and their headings are often written for a different audience than the index.

Because titles are seeded from the file it is comparing against, `bin/check` cannot fail on the title column. It fails when a feature folder is missing from the index or indexed but gone from disk, and when the date has drifted. That is the drift it exists to catch.

## Producing a feature folder

Test Double's [`han`](https://github.com/testdouble/han) is the default path (`/plan-a-feature`, `/plan-implementation`, `/iterative-plan-review`), and the file names you will usually see come from it. Spec Kit, a plain agent session, or hand-writing are equally fine. Nothing here validates what a planning tool produced, which is deliberate: adopting this repo should not mean changing how you plan.

Three habits worth keeping whatever wrote the folder:

- The spec describes outcomes, actors, flows, and edge cases. File paths and library names appear as evidence for a behavioral decision, never as the decision. The plan is where repos, modules, and contracts get named.
- Cross-references stay relative and inside the feature folder (`([D4](artifacts/decision-log.md#d4-export-retention))`) so moving a folder never breaks a link.
- Do not hard-wrap prose. One paragraph is one line; let your editor soft-wrap it. Hard wraps make diffs noisy — a word added early reflows the whole paragraph — and they fight every editor that wraps on its own. Nothing enforces this, deliberately: no linter, no formatter, no CI check.

Amend a feature in place and re-run whatever tool produced it. Do not fork a `-v2` folder.

## What this repo owns, and what you own

Every path falls into exactly one of three categories.

| Category | Paths | Rule |
| --- | --- | --- |
| **Arrives once, never updated** | `upgrades/` | copied in when the repo was created. It is history from before this repo existed, and no upgrade adds to it |
| **Upgraded by patches** | `bin/`, `test/`, `AGENTS.md`, `INSTRUCTIONS.md`, `CLAUDE.md`, `VERSION`, `CHANGELOG.md` | the template owns these and may rewrite them in any release. Edit one and your next upgrade conflicts |
| **Yours** | `README.md`, `features/`, `INDEX.md` | no upgrade will ever touch them |

`README.md` is yours outright. The template seeded it once, when this repo was created, and will not write to it again.

`INDEX.md` is generated rather than written, but it belongs to you: `bin/index` derives it from your feature folders and supplies no content of its own.

`CLAUDE.md` is an import manifest, not a place for your own instructions — an upgrade that adds a top-level document rewrites it. `AGENTS.md` is template-owned for the same reason. If your team needs agent instructions of its own, put them in a file you own and add a line to `README.md` pointing at it; anything you write into the two template-owned files will be overwritten by an upgrade.

## Upgrading from the template

`VERSION` records which version of the template this repo is on. `CHANGELOG.md` records what each version brought.

Upgrades are applied from the template repository on GitHub, never from anything local. Open the template, find the `upgrades/v<yours>-v<next>/` folder for your version, and follow its README. The `upgrades/` directory in *this* repo only holds releases from before this repo existed, so it will never contain the one you need.

## Trying it out

The feature in `features/proposed/` is a placeholder, and running it through its whole life is the quickest way to see what these scripts do. It doubles as a smoke test on a fresh clone — every command below is copy-pasteable, because the slug is known.

```bash
# remember where you started, so the reset at the end is exact
START=$(git rev-parse HEAD)

# nothing to do yet: the index already matches the tree
bin/check

# the work got approved — staged, not committed, so look at it first
bin/move static-site-https active
git diff --cached --stat
git commit -m "Move static-site-https to active"

# the rest finish on their own
bin/move static-site-https shipped --commit
bin/delete static-site-https --commit

# put everything back
git reset --hard $START && git clean -fd
```

The first step is left uncommitted on purpose. That these commands *stage* rather than commit is the one genuinely surprising thing about them — the folder move and the regenerated `INDEX.md` sit in the index together, and the script prints the `git commit` line that would finish it. Every later step passes `--commit` so the index is empty between steps; without that, each `bin/move` warns that it is about to sweep up the previous one's leftovers.

Use `git reset --hard`, not `git checkout .`, to put things back. `git checkout .` restores the working tree *from the index*, and the index is exactly where `git mv` already recorded the move — so it faithfully reproduces the thing you are trying to undo. `git clean -fd` then clears untracked leftovers, like an `INDEX.md` generated before it was ever committed.

One caution on that last line: `git clean -fd` removes **every** untracked file in the repo, not only what the tour created. If you have scratch work in progress, run `git clean -nd` first to see what would go.
