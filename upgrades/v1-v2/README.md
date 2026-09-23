# v1 → v2

Splits the documentation three ways: a `README.md` your repo owns outright, a new `INSTRUCTIONS.md` the template maintains, and an `AGENTS.md` reduced to the one rule that means nothing to a human reader. Also names which paths an upgrade may rewrite, ships `CHANGELOG.md` downstream, drops the unused `adr/` folder, and stops hard-wrapping prose.

You are on v1 if `VERSION` contains `1`.

**This upgrade needs manual work.** Steps 3 and 4 copy two files the patch deliberately leaves alone.

## 1. Get the patch

```bash
curl -O https://raw.githubusercontent.com/agent-0028/planning-template/main/upgrades/v1-v2/planning.patch
```

Use the raw file — the `curl` above, or GitHub's **Raw** button. Copy-pasting from GitHub's rendered view of a `.patch` mangles whitespace, and `git apply` will reject the result with an error that does not mention whitespace at all.

## 2. Apply it

```bash
git apply --3way planning.patch
```

Drop `--3way` if it complains. If you have edited anything under `bin/`, use `git apply --reject planning.patch` and resolve the `.rej` files by hand.

The patch touches `bin/`, `test/`, `AGENTS.md`, `CLAUDE.md`, `VERSION`, the new `INSTRUCTIONS.md`, and it deletes `adr/.gitkeep`. It does **not** touch `README.md` or `CHANGELOG.md` — those are steps 3 and 4.

If you filed anything in `adr/`, the patch leaves it alone; only the `.gitkeep` goes. Move those documents somewhere you own before the empty directory confuses anyone.

## 3. Copy in `CHANGELOG.md`

```bash
curl -O https://raw.githubusercontent.com/agent-0028/planning-template/main/CHANGELOG.md
```

This file should have shipped with v1 and did not. It records what each version of the template brought, so `VERSION` alone is no longer the only thing telling you where you are. From v2 on it is template-owned and arrives by patch like everything else.

If you already keep a `CHANGELOG.md` of your own, this one will collide with it. Keep yours and rename the template's to something else — nothing reads either file.

## 4. Deal with your README, by hand

Your `README.md` currently holds the template's documentation of its own scripts. All of that now lives in `INSTRUCTIONS.md`, which the patch installed in step 2.

**This is the last upgrade that has any opinion about your README.** From v2 on the file is yours and no patch will touch it.

So pick one:

**Path A — take the template's new README.** Right if you never customized yours, and the fastest way to see what the file is for now. It is written as the case for keeping plans in a repo at all, which is what a README earns its place doing once the mechanics live elsewhere.

```bash
curl -O https://raw.githubusercontent.com/agent-0028/planning-template/main/README.md
```

Then edit it. It closes by telling you it is yours; that is meant literally.

**Path B — keep your README.** Right if you have made it your own. Delete anything in it that documents `bin/`, the lifecycle folders, or how `INDEX.md` is built, since `INSTRUCTIONS.md` now covers all of it and two copies is one copy that goes stale. Add a link to `INSTRUCTIONS.md` so a reader can find the mechanics.

Either way, `README.md` stays out of every future patch. It is not that patching it is hard; it is that the file stopped being the template's business in this release.

## 5. Run the tests

```bash
bin/test
```

Confirms the patch landed intact. This is the one moment someone who never touches the scripts has a reason to run them.

## What changed

- `README.md` is yours. The template seeded it once and will not write to it again.
- `INSTRUCTIONS.md` is new, and holds the layout, workflow, commands, index behavior, and authoring conventions that `README.md` and `AGENTS.md` had been describing in parallel.
- `AGENTS.md` keeps read scope and nothing else, plus a link for harnesses that do not resolve `CLAUDE.md` imports.
- `CLAUDE.md` imports `AGENTS.md` and `INSTRUCTIONS.md`.
- `INSTRUCTIONS.md` states which paths an upgrade may rewrite: `bin/`, `test/`, `AGENTS.md`, `INSTRUCTIONS.md`, `CLAUDE.md`, `VERSION` and `CHANGELOG.md` are the template's; `README.md`, `features/` and `INDEX.md` are yours; `upgrades/` arrives once and is never updated.
- `adr/` is gone.
- Prose is no longer hard-wrapped, in this repo and in the template. Nothing enforces it.
