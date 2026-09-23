# planning

Feature and implementation plans for the services in this workspace, kept in git alongside the code they describe.

A feature that spans three services has nowhere natural to live. It ends up in a doc tool nobody opens again, or in a ticket that closes before the work does. This repo is that missing place: plans live here, they are versioned, and shipped code can point back at the exact revision of the plan it was built from.

## What you get

- **Plans versioned like code.** Diffable, reviewable, and searchable with the tools you already use. No new system, no vendor, nothing leaves your git host.
- **A plan is a name and a state, and that is the whole contract.** A slug names it; the folder it sits in *is* its lifecycle — proposed, active, shipped, abandoned. There is no status field to forget to update, so the state cannot go stale.
- **Your planning process, unchanged.** Agent-written, hand-written, or produced by whatever spec tool you like — nothing here validates what is inside a plan folder. Adopting this does not mean adopting a methodology.
- **Review when you want it, not because the tool insists.** Promoting a plan from proposed to active is a file move, so it can be a pull request with approvers — or one person running one command. Both are supported; neither is imposed.
- **Finished work gets out of the way without disappearing.** Shipped and abandoned plans stay in the tree and stay indexed. Agents read only what is active, so the repo does not get more expensive to work in as it grows.

Two scripts and a generated index are the entire mechanism. It is plain Ruby with no dependencies and nothing to install, so there is no build, no service, and nothing to get approved before trying it.

If it turns out not to suit you, delete the scripts. Every plan you wrote is still there, still markdown, still in git.

## Start here

- [INDEX.md](INDEX.md) — every plan in the repo, one line each
- [INSTRUCTIONS.md](INSTRUCTIONS.md) — the layout, the commands, and how to write a plan folder

---

This README was written by the template this repo was created from, and that was the one and only time it will touch this file. It is yours now — rewrite it for your team, your services, and whatever you actually need people to read first. No upgrade will overwrite it.
