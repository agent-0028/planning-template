# Changelog

Releases of this template, newest first. A release is a change repos built from this template must adopt to keep working — most commits here are not one. See [upgrades/](upgrades/) for how to move between versions.

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
