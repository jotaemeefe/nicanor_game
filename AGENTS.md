# AGENTS.md

This file defines the root operating guidance for AI agents working in this repository.

## Purpose

Agents in this repository are expected to behave like **specialized collaborators**, not generic assistants.
They should route work through the correct role, use the correct skills, respect engine isolation, and keep documentation synchronized with implementation decisions.

## Primary Responsibilities

Agents should:

- respect the layered rules model
- keep Unity, Unreal, Godot, and web guidance isolated
- route work to the correct role or command
- use templates for high-value deliverables
- preserve source-of-truth discipline across GDD, TDD, QA, telemetry, and release docs
- surface risks early when quality, scope, performance, or platform constraints are threatened

## Behavioral Rules

### 1. Do not skip planning for non-trivial work
For anything involving multiple steps, multiple roles, design ambiguity, or architectural impact:

- plan before implementation
- define the expected deliverable
- identify dependencies and risks
- make the next responsible role explicit

### 2. Keep common and engine-specific guidance separate
Agents must not:

- put Unity implementation details into common documents
- suggest Unreal framework-specific patterns inside Godot or Unity work
- mix engine-specific runtime assumptions across packs

Shared design intent belongs in common layers.
Engine execution belongs in engine-specific layers.

### 3. Use the right layer for the right job
- `rules/` define standards
- `skills/` define reusable execution patterns
- `agents/` define ownership
- `commands/` define workflow entry points
- `docs/templates/` define deliverable structure
- `docs/orchestration/` define routing and sequencing

### 4. Treat commands as portable workflow contracts
When a user invokes a slash-style command such as `/plan`, `/gdd`, or `/unity-review`, agents should:

- resolve the command to `commands/<name>.md`
- read the command before acting
- follow its declared agents, skills, expected output, and notes
- use adapter-specific command wrappers only as routing hints

Harnesses that do not provide native slash-command execution should still treat these command names as workflow entry points.

### 5. Prefer explicit ownership
Every substantial task should identify:

- owning agent or role
- source-of-truth document
- expected output
- quality bar
- validation path

### 6. Keep documents alive
Agents must update or recommend updating the relevant documents when:

- design intent changes
- technical architecture changes
- testing expectations change
- telemetry requirements change
- release criteria change

## Quality Expectations

Agents should aim for outputs that are:

- actionable
- structured
- aligned with project constraints
- testable
- reviewable
- appropriate to the active engine profile

## Escalation Rules

Agents should escalate when they detect:

- design intent conflicting with implementation reality
- milestone scope drift
- performance budget risk
- save/load or serialization risk
- engine upgrade or package/plugin instability
- multiplayer authority ambiguity
- documentation conflicts
- unclear ownership between design, engineering, QA, or release

## Multi-Agent Coordination

The default orchestration pattern is:

1. planner or command routes the task
2. design or technical lead defines intent
3. implementation role executes
4. reviewer or QA validates
5. documentation and release state are updated

Use `docs/orchestration/` as the source for routing and handoff expectations.

## Engine Routing Rules

- Unity tasks should route through Unity rules and Unity-specialized roles when implementation is engine-specific.
- Unreal tasks should route through Unreal rules and Unreal-specialized roles when implementation is engine-specific.
- Godot tasks should route through Godot rules and Godot-specialized roles when implementation is engine-specific.
- Web (HTML5) tasks should route through web rules and web-specialized roles when implementation is engine-specific.

If the work is engine-neutral, stay in common layers.

## Deliverable Discipline

Prefer structured outputs such as:

- plans
- design docs
- technical docs
- review checklists
- test plans
- release checklists
- telemetry plans
- patch notes

Avoid vague advice when a template-backed deliverable is expected.

## Anti-Patterns

Agents must avoid:

- improvising architecture without source-of-truth updates
- giving engine-specific advice in common layers
- answering design problems with only code-level solutions
- treating QA as a final step rather than part of the workflow
- producing polished-looking outputs that are operationally vague

## Final Rule

If a task touches multiple domains, the agent should optimize for **clarity of ownership and decision traceability**, not just speed of completion.

---

## Project: Ministerio de los Ausentes

This repository is not a generic scaffold checkout — it is the working repository for a real
project. Everything below narrows the framework above to this project's scope. It does not
replace the framework; it constrains which parts of it apply here.

### What this project is

- A 2D point-and-click adventure, **Godot 4.6.x, GDScript only** (no C#, no .NET).
- Title: **Ministerio de los Ausentes** (named on 2026-08-19; the article is not part of it).
- Structural inspiration: classic LucasArts-style adventures — verbs reduced to two: a primary
  interaction (left click) and observe (right click).
- Puzzles are built from concrete objects, conversations, and actions — never abstract or
  systemic mechanics. See [design/puzzles.md](design/puzzles.md).
- Poetry is narrative content in this game, not a magic system or a reusable mechanic.
- Full creative brief: [design/game-bible.md](design/game-bible.md),
  [design/narrative.md](design/narrative.md), [design/characters/nicanor.md](design/characters/nicanor.md).

### Active profile and reduced mode

The installed manifest profile is **`godot-indie-2d`** (unmodified — see
`manifests/install-profiles.json`). There is no separate `godot-point-and-click` manifest
profile: editing `manifests/install-profiles.json` for a single project would make it harder to
pull future updates from the upstream scaffold, so instead this project narrows scope through
this file and [production/current-scope.md](production/current-scope.md) rather than through the
manifest layer. If a genuine need to fork the manifest ever appears, treat that as a deliberate,
separately-discussed decision — not a default.

Within that profile, this project uses **only six responsibilities**, each mapped to existing
scaffold agents. Do not route work to agents outside this list without the user's explicit
approval:

| Responsibility | Agent(s) |
|---|---|
| Creative direction | `producer` |
| Adventure & puzzle design | `level-designer` |
| Narrative writing & dialogue | `narrative-designer` |
| Godot/GDScript development | `gameplay-programmer`, `godot-reviewer` |
| 2D art direction | `2d-artist` |
| QA & playtesting | `qa-lead`, `playtest-analyst` |

`planner`, `architect`, and `doc-updater` remain available for cross-cutting planning and
documentation upkeep, since the framework's own behavioral rules (non-trivial work should be
planned, documents should be kept alive) still apply. All other agents in `agents/` — combat,
economy, liveops, mobile/F2P, multiplayer/network, Unity/Unreal/web/console-specific roles — are
**out of scope** for this project and should not be invoked.

### Hard exclusions

The following are explicitly out of scope for this project and must not be introduced without a
new, explicit approval from the user:

multiplayer, networking, live ops, monetization, virtual economies, combat, competitive
balancing, 3D, Unity, Unreal, mobile builds, procedural generation, continuous autonomous
development, `/full-game`, orchestrations involving dozens of agents, mass documentation
production, mass asset generation.

### Working rules specific to this project

- **No scope expansion without approval.** Do not add mechanics, systems, rooms, or characters
  beyond what [production/current-scope.md](production/current-scope.md) declares as active.
- **Every modified scene must be run and checked**, not just left compiling. If Godot itself is
  unavailable in the current environment, say so explicitly instead of claiming it was verified.
- **Placeholders during prototyping.** Use flat shapes/colors for art and short provisional text
  for dialogue until a scene's structure is approved; never block on final art or final copy.
- **Separate content from logic.** Dialogue and observation text live in data (see
  `game/resources/dialogue/`), not hardcoded inside GDScript control flow.
- **Small, reversible changes.** Prefer several small verified steps over one large unverified one.
- **Current scope is a single prototype scene** — "Oficina de Licencias Poéticas." Do not start a
  second scene, a map, an inventory system, or a save system until that scope is explicitly
  extended.

### Local commands for this project

Five reduced-scope commands live in `commands/` for this project, one per responsibility area
that produces or touches game content directly: `/scene`, `/puzzle`, `/dialogue`, `/playtest`,
`/art-pass`. They are deliberately narrower than the framework's general-purpose equivalents
(`/scene-bootstrap`, `/dialogue-design`, `/playtest-report`, `/art-2d-pass`) — read the command
file before invoking it, per the framework's own rule above ("read the command before acting").
