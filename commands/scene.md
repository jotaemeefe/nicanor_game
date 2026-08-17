---
description: Implement or revise one scene of El Ministerio de los Ausentes end to end, in place, and verify it runs before stopping.
---

# /scene

## Purpose
Implement or revise a single scene of this project — reading current scope, defining the
scene's narrative goal, listing its characters/hotspots/states, making small implementation
changes, running the game, and reporting what still needs manual verification. This command is
this project's narrowed version of the framework's general `/scene-bootstrap`.

## Use When
- A scene in [production/current-scope.md](../production/current-scope.md) needs to be built or
  changed.
- Never to start a second scene — see Notes.

## Invokes Agents
- gameplay-programmer
- godot-reviewer
- level-designer

## Required Skills
- godot-project-structure
- godot-scene-architecture
- godot-gdscript-standards
- placeholder-asset-pipeline

## Process
1. Read [production/current-scope.md](../production/current-scope.md) to confirm this scene (and
   only this scene) is active.
2. State the scene's narrative goal in one or two sentences, sourced from
   [design/narrative.md](../design/narrative.md) — do not invent new narrative facts here.
3. List the scene's characters, hotspots, and states (idle / interacting / conversation
   in-progress / finished) before touching code.
4. Implement small, reversible changes in `game/`.
5. Run the Godot project (editor or headless, whichever is available).
6. Review the run for errors or warnings.
7. Capture visual evidence (screenshot) when the available tools allow it.
8. Report explicitly what was verified automatically vs. what needs manual confirmation in the
   editor.

## Expected Output
- Scene implementation or revision applied under `game/`.
- A short goal/characters/hotspots/states summary as described above.
- A run/verify report distinguishing automatic checks from manual ones.

## Notes
- Do not advance to another scene. [production/current-scope.md](../production/current-scope.md)
  currently authorizes exactly one: "Oficina de Licencias Poéticas."
- Do not add mechanics beyond what [design/puzzles.md](../design/puzzles.md) and
  [production/current-scope.md](../production/current-scope.md) already authorize.
- If Godot is not installed in the current environment, say so explicitly instead of claiming the
  scene was run.
