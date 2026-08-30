# planning

Plans for features that span the service repos in this workspace. It holds no application code of its own.

Clone it as a sibling of the repos it plans for:

```
~/workspace/
├── planning/       ← you are here
├── svc-billing/
├── svc-notify/
└── web/
```

Working a feature means reading here and writing there, so whatever agent or editor you use needs read access to this directory from inside a service repo. How you grant that is your tooling's business.

Point it at `features/active/` rather than at the repo root. That is what the lifecycle folders are for — finished and abandoned work stays discoverable without competing for attention with live work.

Every feature in one line each, newest first: [INDEX.md](INDEX.md).

Conventions for agents (and humans) working in here: [AGENTS.md](AGENTS.md).

## Workflow

1. Put a feature folder in `features/proposed/<slug>/` — or in any lifecycle folder, if it already belongs somewhere else
2. `bin/adopt <slug>` to track it and put it in the index
3. `bin/move <slug> active` when the work is approved
4. Build. Each PR body carries `Spec: planning@<sha> <slug>`
5. `bin/move <slug> shipped` when it lands, or `abandoned` if it does not

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

# run the test suite
bin/test
```

`bin/adopt` gets a folder into the tree, in whichever lifecycle folder you dropped it — it never asks which, because the path already says. `bin/move` changes that lifecycle afterward, and nothing else should.

Neither validates or edits anything inside a folder — the path is the only thing that carries state. The one thing anything here reads from inside a folder is the single heading the index needs for a title.

`bin/move` is strictly a `git mv`, so it refuses a folder git does not track yet and points you at `bin/adopt`. Moving a folder to the lifecycle it is already in is an error, not a quiet no-op — that case is what `bin/adopt` is for.

`bin/delete` removes a folder outright. Content that is already committed goes without ceremony, because history still has it — the check compares blob hashes rather than paths, so a folder you have only moved still counts as committed. Content in no commit refuses until you pass `--force`, which names every file it is about to destroy.

`bin/adopt`, `bin/move`, and `bin/delete` all take `--commit` to make the commit rather than leaving it staged; `bin/move` and `bin/delete` also take `--dry-run`.

## How the index is built

`INDEX.md` is generated in full from the feature tree. A feature is any directory under `features/<lifecycle>/`. For each one:

- **Title** comes from the first `#` heading in `feature-specification.md`, or failing that the first top-level `.md` in the folder, with a leading `Something: ` label stripped. A folder with no heading to find shows its slug.
- **Updated** is the date of the last commit touching the folder, or today's date when the folder has uncommitted changes.

Neither lookup requires a file to exist. A folder holding one scratch note gets an index row the same as a fully worked feature.

The title is only a starting guess, so it is yours to overwrite. **A title already in `INDEX.md` wins over the one scraped from the folder**, which means a bad heading can be corrected in place and it sticks — through a `bin/move` as well, because rows are matched on slug as well as path. Delete a row to derive it from the folder again. That is the whole reason the file is worth having: plan folders are messy, and their headings are often written for a different audience than the index.

Because titles are seeded from the file it is comparing against, `bin/check` cannot fail on the title column. It fails when a feature folder is missing from the index or indexed but gone from disk, and when the date has drifted. Since the date follows git, that means re-running `bin/index` after you edit a feature and before you commit. That is the drift it exists to catch.

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
