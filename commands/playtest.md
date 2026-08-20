---
description: Play Ministerio de los Ausentes from a clean state and report technical errors separately from design problems — never declare success just because it compiles.
---

# /playtest

## Purpose
Actually play the current scene from a clean state, attempt both the correct path and incorrect
attempts, and report findings with technical issues clearly separated from design issues. This
project's narrowed version of the framework's general `/playtest-report`.

## Use When
- A scene or puzzle has been implemented or changed and needs a real playthrough, not just a
  compile check.

## Invokes Agents
- qa-lead
- playtest-analyst

## Required Skills
- playtest-analysis
- qa-test-matrix

## Process
1. Start from a clean state (reload the scene fresh).
2. Run the game.
3. Attempt to complete the scene.
4. Check both the correct path and deliberate incorrect attempts.
5. Actively look for softlocks.
6. Evaluate whether objectives and clues are clear enough without external explanation.
7. Record evidence, errors, and observations as they happen, not from memory afterward.
8. Separate technical errors (crashes, script errors, broken signals) from design problems
   (unclear goals, unfair puzzles, pacing issues).
9. Never declare success solely because the project compiled or opened without errors.

## Expected Output
- A playtest note listing: what was tried, what worked, what didn't, technical vs. design issues,
  and whether a softlock was found.
- Explicit statement of what was verified by actually playing vs. what still needs a human to
  check in the editor.

## Notes
- If Godot is not available in the current environment, say so explicitly and report only what
  static review of scripts/scenes can support — do not claim a playthrough happened.
- Feed confirmed design issues back into [design/puzzles.md](../design/puzzles.md) or
  [design/narrative.md](../design/narrative.md) rather than silently patching around them.
