# Instructions

How this repo works, for humans and agents alike. The template maintains this file — see [What this repo owns, and what you own](#what-this-repo-owns-and-what-you-own) before editing it.

## Layout

```
features/<lifecycle>/<slug>/   # one folder per feature
README.md                      # yours
```

Lifecycle is one of `proposed`, `active`, `shipped`, `abandoned`. **The path is the state.** Nothing inside a folder records it, so state cannot drift from reality — there is no status field to forget to update.

## What a feature is

A feature is a kebab-case slug directory under `features/<lifecycle>/`. Slugs are semantic — two to four words, no ticket IDs, no dates.

What goes inside is up to whoever writes it. File names and sections are convention at most. Nothing validates them, and a folder is never wrong for holding something unexpected.

## Workflow

1. Put a feature folder in `features/proposed/<slug>/` — or in any lifecycle folder, if it already belongs somewhere else — and `git add` it
2. `bin/move <slug> active` when the work is approved
3. Build. Each PR body carries `Spec: planning@<sha> <slug>`
4. `bin/move <slug> shipped` when it lands, or `abandoned` if it does not

Step 2 is a file move, which means it can be a pull request — an approval gate for a plan, reviewed with the same machinery as code. It can equally be one person running one command. The repo makes review possible without requiring it.

## Commands

```bash
# list what is in flight: active and proposed
bin/toc

# list finished plans instead — either flag alone, or both together
bin/toc --shipped
bin/toc --abandoned

# list every lifecycle
bin/toc --all

# change lifecycle
bin/move <slug> <lifecycle>

# remove a feature folder
bin/delete <slug>

# run the repo-level checks
bin/check
```

There is no command for adding a feature. Put the folder under `features/<lifecycle>/` and `git add` it; a folder or file from elsewhere is `mv` and then `git add`. Nothing needs to be regenerated afterward, because nothing is generated.

`bin/move` moves the folder on disk and stages the whole of it, so it works the same whether the folder is committed, partly committed, or not yet tracked at all — committed files show as a rename, everything else is added. Moving a folder to the lifecycle it is already in is an error. A hand `git mv` is fine too; `bin/move` just saves typing the paths and checks the lifecycle name.

Neither `bin/move` nor `bin/delete` validates or edits anything inside a folder — the path is the only thing that carries state.

`bin/delete` removes a folder outright. Content that is already committed goes without ceremony, because history still has it — the check compares blob hashes rather than paths, so a folder you have only moved still counts as committed. Content in no commit refuses until you pass `--force`, which names every file it is about to destroy.

`bin/move` and `bin/delete` both take `--commit` to make the commit rather than leaving it staged, and `--dry-run` to report what they would do.

`bin/check` prints warnings and never fails on them. Today it warns about a top-level document with no `#` heading in an active or proposed feature, and about a missing `CHANGELOG.md`. It exits non-zero only when a check reports an error, and none does yet.

There is a fifth script, `bin/test`, which runs the test suite over `bin/lib/planning.rb`. You need it in one situation: right after applying an upgrade from the template, to confirm the scripts still work. Writing tests is template-development work and lives in [upgrades/README.md](upgrades/README.md).

## Before you commit

`bin/check` runs clean or you have read its warnings, and the commit touches exactly one feature folder unless it is a repo-wide convention change.

## How plans are listed

`bin/toc` reads the feature tree every time it runs and prints a table of contents. Nothing is written and nothing is committed, so the listing is always current and can never conflict in a merge.

- **Scope.** With no arguments it shows `active` and `proposed` — the work in flight. `--shipped` and `--abandoned` show those lifecycles instead, alone or together. `--all` shows all four. Finished plans pile up with every feature a team ships, and keeping them out of the default view is the reason the lifecycle folders exist.
- **Features** are listed by slug, alphabetically within each lifecycle. The slug is a feature's only identifier; no title is derived for the feature as a whole.
- **Documents** are the `.md` files directly inside a feature folder, listed alphabetically by filename. Anything in a subfolder, such as `artifacts/`, is not listed. A folder with no top-level documents shows `_Empty._` or `_No top-level documents._`, so nothing in the tree is invisible.
- **A document's title is its first `#` heading**, exactly as written. Headings inside fenced code blocks are skipped. A document with no heading shows the first 125 characters of its text instead, and `bin/check` warns about it.
- **Each document's date** is the last commit touching that file, or `uncommitted` if it has changes git has not committed. Dates are shown but never affect the order, so editing a document moves nothing.

To change how a document appears, change its heading. There is nowhere else to set a title.

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
| **Yours** | `README.md`, `features/` | no upgrade will ever touch them |

`README.md` is yours outright. The template seeded it once, when this repo was created, and will not write to it again.

A repo created before v3 may still have an `INDEX.md`, the generated index that `bin/toc` replaced. It is yours like any other file you created: nothing reads or writes it any more, and you can delete it whenever you like.

`CLAUDE.md` is an import manifest, not a place for your own instructions — an upgrade that adds a top-level document rewrites it. `AGENTS.md` is template-owned for the same reason. If your team needs agent instructions of its own, put them in a file you own and add a line to `README.md` pointing at it; anything you write into the two template-owned files will be overwritten by an upgrade.

## Upgrading from the template

`VERSION` records which version of the template this repo is on. `CHANGELOG.md` records what each version brought.

Upgrades are applied from the template repository on GitHub, never from anything local. Open the template, find the `upgrades/v<yours>-v<next>/` folder for your version, and follow its README. The `upgrades/` directory in *this* repo only holds releases from before this repo existed, so it will never contain the one you need.

## Trying it out

The feature in `features/proposed/` is a placeholder, and running it through its whole life is the quickest way to see what these scripts do. It doubles as a smoke test on a fresh clone — every command below is copy-pasteable, because the slug is known.

```bash
# remember where you started, so the reset at the end is exact
START=$(git rev-parse HEAD)

# what is in flight right now
bin/toc

# the work got approved — staged, not committed, so look at it first
bin/move static-site-https active
git diff --cached --stat
git commit -m "Move static-site-https to active"

# the rest finish on their own
bin/move static-site-https shipped --commit
bin/toc --shipped
bin/delete static-site-https --commit

# put everything back
git reset --hard $START && git clean -fd
```

The first move is left uncommitted on purpose. That these commands *stage* rather than commit is the one genuinely surprising thing about them, and the script prints the `git commit` line that would finish it. Every later step passes `--commit` so nothing is left staged between steps; without that, each `bin/move` warns that it is about to sweep up the previous one's leftovers.

Use `git reset --hard`, not `git checkout .`, to put things back. `git checkout .` restores the working tree *from the staging area*, and the staging area is exactly where the move was already recorded — so it faithfully reproduces the thing you are trying to undo. `git clean -fd` then clears untracked leftovers.

One caution on that last line: `git clean -fd` removes **every** untracked file in the repo, not only what the tour created. If you have scratch work in progress, run `git clean -nd` first to see what would go.
