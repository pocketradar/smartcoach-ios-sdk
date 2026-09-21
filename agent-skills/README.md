# SmartCoach Agent Skills

Task-scoped recipes that help an AI coding assistant integrate specific SmartCoach SDK
capabilities into a consumer's app — e.g. "add device scanning to this view model." The
agent applies a recipe into the user's existing code (or code it scaffolds), following
the SDK's required call sequences instead of improvising the API.

## Layout

```
agent-skills/
  recipes/          Neutral, vendor-agnostic recipes — the source of truth.
    conventions.md  Shared view-model structure the capability recipes build on.
    configure.md    App bootstrap: API key, Bluetooth permission, configure() at launch.
    scan.md         Device discovery.
    connect.md      Connect / disconnect.
    measure.md      Live measurement streaming.
    settings.md     Radar settings: units, speed range, sensitivity.
  claude/
    smartcoach/     Claude adapter (SKILL.md) that points at the recipes.
  install.sh        Assembles a self-contained skill into your agent's skills folder.
```

The recipes mirror the official sample app's `FullWorkflowViewModel`, so composing
scan + connect + measure into one view model reproduces that proven pattern.

The recipes contain **no vendor-specific instructions**. Adapters (like `claude/`) are
thin wrappers that add a tool's triggering metadata and reference the same recipes. That
keeps the knowledge in one place and makes future adapters (Codex `AGENTS.md`, Gemini,
Cursor) cheap to add.

## Supported agents

| Agent | Status |
|-------|--------|
| Claude (Claude Code, Claude.ai, API) | Supported — install via `install.sh` |
| Codex / Gemini / Cursor | Not yet packaged — the `recipes/` files can be used manually (point the agent at the relevant recipe) |

## Install (Claude)

User-level (available in all your projects):

```bash
./install.sh
```

Project-level (committed with one app):

```bash
./install.sh /path/to/your/app
```

This copies `SKILL.md` and `recipes/` into `~/.claude/skills/smartcoach` (or
`<project>/.claude/skills/smartcoach`). Restart your Claude session to pick it up.

## Use

Ask your agent naturally, e.g.:

> Add SmartCoach device scanning to `DeviceListViewModel`.

or, from scratch:

> Build a SwiftUI MVVM screen that scans for SmartCoach devices and lists them.

The agent scaffolds/locates the view model, then applies the scanning recipe.

> **Prerequisite:** the app must already have the `SmartCoachSDK` package added and
> `SmartCoach.configure()` called once at launch.

## Maintainer notes

- **Authoring home is the dev repo** (`ios-smartcoach-sdk-dev/agent-skills/`). On each
  SDK release, copy the folder into the distribution repo (`smartcoach-ios-sdk/`,
  top-level) so partners get it version-locked via
  `git clone --branch <tag>` + `install.sh`. Do not edit the distribution copy directly.
- Recipes are the source of truth and must stay **vendor-neutral** (no "in Claude
  Code…" phrasing) — that's what keeps additional adapters trivial.
- Keep recipes consistent with the SDK's DocC catalog and `docs/INTEGRATION.md`; they
  describe the same behavior from an action-oriented angle. The canonical view-model
  structure mirrors the sample app's `FullWorkflowViewModel` — if one changes, change
  both.
- Recipes encode version-specific SDK behavior — ship them version-locked to the SDK
  (same release tag).
