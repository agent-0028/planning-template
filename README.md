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

Conventions for agents (and humans) working in here: [AGENTS.md](AGENTS.md).

<!-- BEGIN GENERATED INDEX — edited by bin/index, do not hand-edit -->

## Active

_None._

## Proposed

| Feature | Updated |
| --- | --- |
| [Static site HTTPS](features/proposed/static-site-https/) | 2026-08-25 |

## Shipped

_None._

## Abandoned

_None._

<!-- END GENERATED INDEX -->

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

# regenerate the index block above
bin/index

# verify the index block matches the tree
bin/check
```

`bin/adopt` gets a folder into the tree, in whichever lifecycle folder you dropped it — it never asks which, because the path already says. `bin/move` changes that lifecycle afterward, and nothing else should.

Neither validates or edits anything inside a folder — the path is the only thing that carries state. The one thing anything here reads from inside a folder is the single heading the index needs for a title.

`bin/move` is strictly a `git mv`, so it refuses a folder git does not track yet and points you at `bin/adopt`. Moving a folder to the lifecycle it is already in is an error, not a quiet no-op — that case is what `bin/adopt` is for.

`bin/delete` removes a folder outright. Content that is already committed goes without ceremony, because history still has it — the check compares blob hashes rather than paths, so a folder you have only moved still counts as committed. Content in no commit refuses until you pass `--force`, which names every file it is about to destroy.

`bin/adopt`, `bin/move`, and `bin/delete` all take `--commit` to make the commit rather than leaving it staged; `bin/move` and `bin/delete` also take `--dry-run`.

## How the index is built

A feature is any directory under `features/<lifecycle>/`. For each one:

- **Title** comes from the first `#` heading in `feature-specification.md`, or failing that the first top-level `.md` in the folder, with a leading `Something: ` label stripped. A folder with no heading to find shows its slug.
- **Updated** is the date of the last commit touching the folder, or today's date when the folder has uncommitted changes.

Neither lookup requires a file to exist. A folder holding one scratch note gets an index row the same as a fully worked feature.

Because the date follows git, `bin/check` will ask you to re-run `bin/index` after you edit a feature and before you commit. That is the drift it exists to catch.

## Trying it out

The feature in `features/proposed/` is a placeholder, and running it through its whole life is the quickest way to see what these scripts do. It doubles as a smoke test on a fresh clone — every command below is copy-pasteable, because the slug is known.

```bash
# nothing to do yet: the index already matches the tree
bin/check

# the work got approved
bin/move static-site-https active

# it landed
bin/move static-site-https shipped

# and it has outlived its usefulness
bin/delete static-site-https --commit
```

The first three steps only stage. The folder move and the regenerated `README.md` sit in the index together, and each step prints the `git commit` line that would finish it — run `git diff --cached` between them to see exactly what moved. The last step takes `--commit`, so the whole tour lands as one commit and leaves you an empty tree ready for real work.

Would rather keep the example? Drop the `--commit`, and `git checkout . && git clean -fd` puts everything back.
