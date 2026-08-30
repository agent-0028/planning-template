# v0 → v1

Moves the generated feature index out of `README.md` and into a new `INDEX.md`,
makes the index's title column hand-editable, and adds a test suite.

You are on v0 if your repo has no `VERSION` file.

**This upgrade needs manual work.** Step 5 cannot be automated, and skipping it
leaves a stale table in your README that still looks live.

## 1. Get the patch

```bash
curl -O https://raw.githubusercontent.com/agent-0028/planning-template/main/upgrades/v0-v1/planning.patch
```

Use the raw file — the `curl` above, or GitHub's **Raw** button. Copy-pasting
from GitHub's rendered view of a `.patch` mangles whitespace, and `git apply`
will reject the result with an error that does not mention whitespace at all.

## 2. Apply it

```bash
git apply --3way planning.patch
```

Drop `--3way` if it complains. If you have edited anything under `bin/`, use
`git apply --reject planning.patch` and resolve the `.rej` files by hand.

The patch touches `bin/`, `test/`, `AGENTS.md`, and `VERSION`. It does **not**
touch `README.md` — that is step 5, and deliberately yours.

## 3. Run the tests

```bash
bin/test
```

New in this version, and worth running before anything rewrites your files.

## 4. Generate the index

```bash
bin/index
```

This creates `INDEX.md`. It is not in the patch, because every repo's index is
different. Commit it — `bin/check` expects it to exist from here on.

## 5. Deal with your README, by hand

Your `README.md` still holds a generated block between these two markers:

```
<!-- BEGIN GENERATED INDEX — edited by bin/index, do not hand-edit -->
<!-- END GENERATED INDEX -->
```

Nothing writes to it any more. Left alone it becomes a table that never updates
again but still reads as though it is current, which is worse than having no
index in the README at all. So pick one:

**Path A — keep your README, remove the block.** The right choice if you have
customized your README, which by now you probably have. Delete everything from
the `BEGIN` marker through the `END` marker, inclusive, and put a link to
`INDEX.md` where the table used to be so the new file is discoverable.

**Path B — take the template's README.** Simpler if you never customized yours.
Copy `README.md` from the template repo over your own. Skim yours first —
anything you added is lost.

### Why this step is manual

The block holds a different feature table in every repo built from this
template, so a patch hunk anchored on those lines would conflict for everyone.
It is not that patching the README is hard; it cannot work. That is why
`README.md` sits outside the patch entirely.

The markers themselves are identical everywhere, which is why the instruction
above can be exact even though what sits between them cannot be.

## 6. Check

```bash
bin/check   # exits 0
cat VERSION # 1
```

Commit the result. `INDEX.md` and `VERSION` are both new files.

## What changed, in short

- `INDEX.md` is generated in full and replaces the marker block in `README.md`.
  `README.md` is hand-written from now on and nothing writes to it.
- The index's **title column is free text**. A title already in `INDEX.md` beats
  the heading scraped from the folder, so a bad title can be corrected in place
  and it survives regeneration — and survives `bin/move`, because rows are
  matched on slug as well as path. Delete a row to derive it from the folder
  again.
- `bin/check` no longer fails on the title column. It still fails on a feature
  missing from the index, an indexed feature gone from disk, and a stale date.
- `bin/test` runs a Minitest suite over `bin/lib/planning.rb`. Minitest ships
  with Ruby, so there is nothing to install.
