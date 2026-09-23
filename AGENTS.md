# AGENTS.md

> This repo holds the plans for features that span the service repos checked out beside it. No application code lives here.

## Layout

```
features/<lifecycle>/<slug>/   # one folder per feature
INDEX.md                       # GENERATED, except the title column
README.md                      # hand-written
```

Lifecycle is one of `proposed`, `active`, `shipped`, `abandoned`. **The path is the state.** Nothing inside a folder records it.

`INDEX.md` is rebuilt from the tree, but its title column is free text: a title already in the file wins over the one scraped from the folder, so a bad heading can be corrected in place and it sticks — through a `bin/move` as well. Delete a row to derive it from the folder again.

## What a feature is

A feature is a kebab-case slug directory under `features/<lifecycle>/`. Slugs are semantic — two to four words, no ticket IDs, no dates.

What goes inside is up to whoever writes it. File names and sections are convention at most. Nothing validates them, and a folder is never wrong for holding something unexpected.

## Read scope

- Default to `features/active/` only.
- Read `features/proposed/` when drafting or reviewing a not-yet-approved feature.
- Do NOT read `features/shipped/` or `features/abandoned/` unless the task names a specific feature there, or asks about prior art. `INDEX.md` lists every feature in one line each — use it before opening an archived folder.

## Commands

```bash
# bring a new folder under management
bin/adopt <slug|path>

# change lifecycle, regenerate the index
bin/move <slug> <lifecycle>

# remove a feature folder
bin/delete <slug>

# regenerate INDEX.md from the tree
bin/index

# verify INDEX.md matches the tree
bin/check

# run the test suite
bin/test
```

Never `git mv` a feature folder by hand — `bin/adopt` and `bin/move` regenerate the index in the same commit, and a stale index is the thing most likely to drift. What each command does: [README.md](README.md#commands).

## Producing a feature folder

Test Double's [`han`](https://github.com/testdouble/han) is the default path (`/plan-a-feature`, `/plan-implementation`, `/iterative-plan-review`), and the file names you will usually see come from it. Spec Kit, a plain agent session, or hand-writing are equally fine.

Two habits worth keeping whatever wrote the folder:

- The spec describes outcomes, actors, flows, and edge cases. File paths and library names appear as evidence for a behavioral decision, never as the decision. The plan is where repos, modules, and contracts get named.
- Cross-references stay relative and inside the feature folder (`([D4](artifacts/decision-log.md#d4-export-retention))`) so moving a folder never breaks a link.

Amend a feature in place and re-run whatever tool produced it. Do not fork a `-v2` folder.

## Done means

`bin/test` and `bin/check` both exit zero, and the commit touches exactly one feature folder unless it is a repo-wide convention change.
