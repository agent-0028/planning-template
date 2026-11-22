# AGENTS.md

> This repo holds the plans for features that span the service repos checked out beside it. No application code lives here.

Not using Claude Code? Read [INSTRUCTIONS.md](INSTRUCTIONS.md) first — it covers the layout, the commands, and the conventions for writing a plan. Claude Code loads it automatically.

## Orient with `bin/toc`

Run `bin/toc` before anything else. It lists every feature in flight — `active` and `proposed` — by slug, with each top-level document's title, path, and last-commit date. Treat it as the map; do not glob or list `features/` to find your way around.

## Read scope

`bin/toc` lists more than you should read. Listing is cheap; reading is not.

- Read `features/active/` by default.
- Open a `features/proposed/` folder only when drafting or reviewing a not-yet-approved feature.
- Run `bin/toc --shipped` and/or `bin/toc --abandoned` only when the task names a feature there or asks about prior art, and open only the folders you need.
- Never run `bin/toc --all` to orient. On a busy team, shipped and abandoned plans far outnumber live ones, and keeping them out of view is the reason the lifecycle folders exist.

These are the rules here that have no meaning for a human reader. Everything else about working in this repo applies to both, and lives in [INSTRUCTIONS.md](INSTRUCTIONS.md).
