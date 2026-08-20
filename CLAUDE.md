# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

Two layers live side by side, and it matters which one you are touching:

1. **A workflow scaffold for AI-assisted game development** (everything except `game/`) — a
   coordinated system of rules, agents, commands, skills, and contexts that a coding assistant
   loads to do design, technical design, implementation, QA, release, and live-ops work, while
   keeping the Unity, Unreal, Godot, and web (HTML5) execution layers strictly isolated. Its own
   "code" is a Node.js (>=18, zero runtime deps) tooling layer under `scripts/` that **validates
   and generates** the scaffold's content so it can never drift out of sync.
2. **A real game built with that scaffold**, under `game/` — *Ministerio de los Ausentes*, a 2D
   point-and-click adventure in **Godot 4.7.x, GDScript only** (no C#, no .NET).

Most sessions are game work. The scaffold layer changes only when the workflow itself changes.

## Commands — scaffold tooling (Node)

```bash
npm test            # node tests/run-all.js — scaffold self-tests
npm run validate    # full validation gate (11 validators + markdown lint); this is what CI runs
npm run doctor      # diagnose install: env, hooks, active engine profile, artifact drift
npm run setup:hooks # install the git pre-commit hook (first-time setup)
```

Individual validators (run when iterating on one concern — faster than the full gate):
`validate:manifests`, `validate:engines`, `validate:hooks`, `validate:schemas`,
`validate:structure`, `validate:references`, `validate:generated-assets`,
`validate:structure-artifacts`, `validate:wrappers`, `validate:mcp`, `validate:graph`,
`lint:markdown`.

Run a single test file directly: `node tests/<path>.test.js` (e.g. `node tests/lib/engine-isolation.test.js`).

CI (`.github/workflows/ci.yml`) runs exactly `npm test` then `npm run validate` on Node 18.
The validator list lives **only** in package.json's `validate` script so CI and local runs can't diverge.

`lint:markdown` is stricter than `.markdownlint.json` suggests: no trailing whitespace, no tabs,
at most two consecutive blank lines, file must end with a newline. `samples/` is exempt.

## Commands — the game (Godot)

Godot is not on PATH on this machine. It was installed via winget and lives at:

```text
C:\Users\Julio\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.1-stable_win64.exe
```

The `_console` variant of the same name is the one to use when you need stdout/stderr.

```bash
godot --path game                             # run from the main menu
godot --headless --path game --import         # refresh the import cache (see traps below)
godot --headless --path game res://tests/puzzle_flow_test.tscn --quit-after 60
```

Four headless tests, each printing `... TEST: OK` on success — run them as **scenes**, never via
`--script`: `puzzle_flow_test.tscn` (state machine and dialogue coverage), `intro_flow_test.tscn`,
`walkable_area_test.tscn` (floor polygon, approach points, draw-order invariants),
`status_board_test.tscn` (the status board's projective warp). They cover logic and invariants
only — no real clicks, no physical walking. `game/docs/PLAYTEST.md` is the manual pass.

## Godot workflow traps (each of these has cost a session before)

- **New or overwritten PNGs, and any new `class_name` script, need `--headless --path game
  --import` before a scene referencing them will load.** A plain scene run does not refresh the
  import cache. Symptoms: "No loader found for resource" / "referenced non-existent resource"
  errors that look like broken references, or — for an unregistered `class_name` — *no output at
  all* and a run that never exits.
- **Always pass `--quit-after N`.** Test scenes call `tree.quit()` at the end of `_ready()`, so a
  failure before that line hangs the process instead of failing it.
- **`--headless` cannot screenshot** (dummy renderer; `get_viewport().get_texture()` is null). For
  real pixels, record frames into the scratchpad — never into the repo — with
  `godot --path game scenes/office/oficina_recepcion.tscn --write-movie <scratch>/frame.png
  --fixed-fps 30 --quit-after 20`, then Read a frame. In-script viewport captures produce blank
  gray images here. Don't launch this while the user may have their own session open.
- **Autoloads are unresolvable under `godot --script foo.gd`** — that compiles before autoloads
  register, so anything touching `GameState` (even as a type annotation) must run as a scene.
- **A load-only diagnostic misses player-triggered bugs.** For "right in the data, wrong on screen"
  issues, drive the real action (`walk_to()`, a state change) before trusting a static read.
- The `godot-editor` MCP server relies on the explicit `env.GODOT_PATH` pinned in `.mcp.json` (its
  auto-detection doesn't know about winget installs), and it exposes no screenshot tool — calling
  the binary through Bash stays the way to actually see the game.

## Source of truth vs. generated artifacts

This is the most important thing to understand before editing the scaffold. Several files are
**generated** — editing them by hand is the failure mode CI guards against (a `*:check` validator
re-derives them and fails if they'd change).

| Edit this (source of truth) | Generates this (do NOT hand-edit) | Sync / check |
|---|---|---|
| `commands/*.md` | `.claude/commands/*`, `.codex/commands/*`, `.opencode/*` | `npm run sync:wrappers` / `validate:wrappers` |
| tracked file tree | `STRUCTURE-TREE.txt`, `docs/structure-overview.md` | `npm run sync:structure` / `validate:structure-artifacts` |
| `hooks/hooks.json` | harness hook wiring | `npm run sync:hook-wiring` |
| `mcp-configs/mcp-servers.json` | `mcp-configs/generated/*` | `npm run sync:mcp` / `validate:mcp` |
| scaffold layers | `docs/dependency-graph.*` | `npm run sync:graph` / `validate:graph` |

Workflow when you change a source file: edit the source → run the matching `sync:*` → commit both.
The pre-commit hook (`.githooks/pre-commit`) auto-runs `sync:structure` + structure/markdown
validation and stages the regenerated artifacts, so structure drift is caught before it lands.

Structure artifacts are derived from `git ls-files`, not a filesystem walk — untracked/gitignored
content never leaks in, and local output matches what CI regenerates from a clean checkout.

The repo's own `.mcp.json` is hand-maintained (it carries this machine's `GODOT_PATH`) and is *not*
one of the generated outputs of `mcp-configs/`.

## Architecture — the game (`game/`)

One autoload, all text as data, one controller per scene.

- **`GameState` (`scripts/game_state.gd`, the only autoload)** — the active scene's puzzle state
  machine: an 8-value `State` enum plus a `state_changed` signal. Progress is compared
  **ordinally** (`is_at_least`, and the `min_state`/`max_state` ranges in the dialogue JSON), so
  the enum's order is load-bearing: reordering or inserting a state in the middle silently
  re-targets every JSON range. It holds no text.
- **`DialogueManager` (`scripts/dialogue_manager.gd`)** — static helpers only (a `RefCounted` that
  is never instanced): load JSON, `pick_branch` for stateful conversations, `pick_state_text` for
  per-state lines. `pick_state_value` walks *backward* to the nearest earlier state that has an
  entry, so a state without its own text inherits instead of going blank.
- **All player-visible text is data**: `data/dialogues/*.json`, `data/hotspots/*.json`, or exported
  strings on a `Hotspot` instance in the `.tscn` — never hardcoded into GDScript control flow.
  `game/README.md` documents both JSON shapes and how to add a hotspot or a dialogue.
- **`Hotspot` (`scripts/hotspot.gd` + `scenes/hotspot.tscn`)** — reusable `Area2D` configured
  entirely from the Inspector; hitbox and placeholder polygon are generated at runtime so each
  instance stays a plain property override in the scene file. Left click = interact, right click =
  observe, `approach_point` is where Nicanor walks first.
- **`office_scene_controller.gd`** — the active scene's controller and the only place puzzle logic
  lives (`_resolve_hotspot` switches on `hotspot_name`). It collects hotspots with
  `find_children(recursive)` because some sit under sort anchors rather than directly under
  `Hotspots`.
- **`NicanorController`** — click-to-walk. The floor is a `walkable_polygon`
  (`PackedVector2Array`), not a `Rect2`: a perspective floor with furniture in the near corners is
  a trapezoid with bites taken out of it, and a click outside resolves to the closest point on the
  border. Sprite scale interpolates by Y (`scale_at_back` → `scale_at_front`) so he reads as
  standing on a floor with depth rather than sliding across the screen.
- **Two rendering patterns to know before "fixing" a visual bug**: a prop that must sort by its
  ground-contact line is wrapped in a `*SortAnchor` `Node2D` placed on that line, with the sprite
  offset upward (Godot y-sorts by node Y, not by sprite bottom); and frontal art hanging on a
  receding wall uses `PerspectiveQuad` (`scripts/perspective_quad.gd`), a subdivided `Polygon2D`
  mapped through a real homography — 2D node transforms are affine and can tilt but never
  foreshorten.
- **Retired prototype, do not edit**: `scenes/oficina_licencias_poeticas.tscn` +
  `scripts/scene_controller.gd`. The active scene is `scenes/office/oficina_recepcion.tscn`; the
  entry point is `scenes/main_menu/main_menu.tscn`.
- `ejemplo/` holds the user-supplied reference art; `game/TODO_ASSETS.md` tracks what is still
  placeholder.

## Architecture — the scaffold

**Layered scaffold (engine-neutral core, top of repo):**
- `rules/` — policy and "what good looks like". Resolution order is `rules/common/` first, then
  exactly **one** engine layer (`rules/unity/` | `rules/unreal/` | `rules/godot/` | `rules/web/`).
- `agents/` — flat list of specialized roles (who owns the work).
- `commands/` — flat list of workflow entry points. A slash command like `/gdd` resolves to
  `commands/gdd.md`; read that file and follow its declared agents/skills/output before acting.
- `skills/` — reusable execution patterns, **grouped by category**, each leaf a folder with a `SKILL.md`.
- `contexts/` — phase-specific priority shifts (e.g. prototype vs. release).
- `hooks/` — workflow safety automation (`hooks/hooks.json` is the source).
- `manifests/` — install profiles/components and two key registries: `engines.json` (the single
  source of truth for which engine layers exist; array order is path-detection priority) and
  `asset-providers.json` (capability→model routing for AI asset generation).
- `schemas/` — JSON Schema (ajv) validation for every manifest, hook config, and plugin.
- `docs/templates/` — structured deliverable templates (GDD, TDD, QA plan, etc.).

**Tooling layer (`scripts/`):** generators (`generate-*`, `new-engine`, `sync-*`), validators
(`validate-*`), and `doctor.js`. Shared logic lives in `scripts/lib/` — notably `engines.js`
(all engine lists derive from `manifests/engines.json`), `structure-artifacts.js`, and
`profile-resolution.js`. Per-event hook implementations are in `scripts/hooks/`.

**Harness adapters** (`.claude/`, `.codex/`, `.cursor/`, `.opencode/`, `.kiro/`): each points back
to the shared scaffold rather than being a second source of truth. Their command wrappers are generated.

## Engine isolation (hard rule)

Never combine two engine layers in one implementation pass, and never put engine-specific runtime
details into a `common/` document. Shared docs describe **intent, ownership, and quality bars**;
engine docs describe **implementation conventions inside that one engine only**. This is enforced
by `tests/lib/engine-isolation.test.js` and `engine-content-isolation.test.js` — adding cross-engine
references will fail the suite.

Adding a new engine layer is done via `npm run new:engine` (driven by `manifests/engines.json`),
not by hand-creating directories.

## Conventions to preserve

- Keep `agents/` and `commands/` **flat**; keep `skills/` **grouped** with a `SKILL.md` per leaf.
- Prefer a command if one exists; prefer a reusable skill over one-off instructions; prefer the
  common layer for standards and the engine layer for implementation detail.
- Don't create duplicate sources of truth or invent new top-level structure without justification.
- When a decision changes design/tech/test/telemetry/release expectations, update the relevant
  source-of-truth doc (or recommend it) — keep documents alive.
- Plan before non-trivial (multi-step / multi-role / architectural) work.

## This project: Ministerio de los Ausentes

**`AGENTS.md` is the source of truth for scope, active profile, agent roster, and hard
exclusions** — read it first, every session; do not restate or fork its rules here.
Creative/narrative source of truth lives under `design/` (`game-bible.md`, `art-bible.md`,
`narrative.md`, `characters/nicanor.md`, `puzzles.md`); current build scope and standing decisions
live under `production/` (`current-scope.md`, `decisions.md`). `decisions.md` is newest-first and
records *why* the unusual implementation choices above exist — read the top of it before reversing
one. Both Codex and Claude Code read the same `AGENTS.md` and the same `design/`/`production/`
files — there is no Claude-specific design doc.

Use the local commands in `commands/` (`/scene`, `/puzzle`, `/dialogue`, `/playtest`,
`/art-pass`) for game-content work; they encode this project's reduced scope directly. Do not
default to `/full-game`, `/orchestrate`, or other multi-agent orchestration commands — this
project is intentionally a small, sequential, human-reviewed workflow, not an autonomous one.
Only invoke the six agents AGENTS.md lists as in-scope unless the user explicitly approves
another one for a specific task.

Design and production docs, and all in-game content, are written in Spanish (Rioplatense) even
where the scaffold around them is English — keep new game-facing text in Spanish and match the
voice in `design/characters/nicanor.md`.
