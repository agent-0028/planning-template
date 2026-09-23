# Changelog

Releases of this template, newest first. A release is a change repos built from this template must adopt to keep working — most commits here are not one. See [upgrades/](upgrades/) for how to move between versions.

## v2 — 2026-09-23

**Upgrading requires manual steps.** → [upgrades/v1-v2/](upgrades/v1-v2/)

- `README.md` belongs to the repo that adopted this template. The template seeds it once and never writes to it again — this release is the last patch that will ever touch it. What it holds now is the case for keeping plans in the repo at all, not documentation of the scripts.
- New `INSTRUCTIONS.md` holds the layout, the workflow, the commands, how the index is built, and the conventions for writing a plan folder. These had been split across `README.md` and `AGENTS.md`, described twice in different words; there is one copy now.
- `AGENTS.md` keeps read scope and nothing else. In a repo this simple, what an agent needs to know and what a human needs to know are the same text, so only the rule about an agent's context budget is genuinely agent-specific.
- `CLAUDE.md` imports `AGENTS.md` and `INSTRUCTIONS.md`. The import syntax is Claude Code's, so it stays in Claude Code's file; `AGENTS.md` carries an ordinary link for harnesses that do not resolve imports.
- `INSTRUCTIONS.md` states which paths an upgrade may rewrite. `bin/`, `test/`, `AGENTS.md`, `INSTRUCTIONS.md`, `CLAUDE.md`, `VERSION` and `CHANGELOG.md` belong to the template; `README.md`, `features/` and `INDEX.md` belong to you; `upgrades/` arrives once and is never updated.
- `CHANGELOG.md` now ships to repos made from this template, so a repo can see what its `VERSION` got it. Its absence before was an oversight, not a decision.
- The `adr/` folder is gone. It was empty, unreferenced by any script, and ambiguous about whether an ADR in it described the planning repo or the services being planned.
- Prose is no longer hard-wrapped. One paragraph is one line, enforced by nothing.

## v1 — 2026-08-30

**Upgrading requires manual steps.** → [upgrades/v0-v1/](upgrades/v0-v1/)

- The generated feature index moves out of `README.md` into a new `INDEX.md`. `README.md` is hand-written from now on; nothing writes to it. The old marker block has to be removed by hand, which is the manual step.
- The index's title column is free text. A title already in `INDEX.md` wins over the heading scraped from the folder, so a bad title can be corrected in place and survives regeneration — including across a `bin/move`. Delete a row to derive it from the folder again.
- `bin/check` no longer fails on the title column. Paths and dates still fail it, unchanged.
- `bin/test` runs a Minitest suite over `bin/lib/planning.rb`. Stdlib only, no Gemfile.
- `VERSION` records the contract version, so later upgrades do not have to be identified by grepping `bin/`.
- Fixes the `README.md` walkthrough, which did not work as written: it staged three steps without committing, and the restore it documented (`git checkout .`) replays the `git mv` it was meant to undo instead of reverting it.

## v0

The template as originally published. No `VERSION` file — that absence is what identifies it.
