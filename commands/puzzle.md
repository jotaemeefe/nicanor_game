---
description: Design a puzzle for El Ministerio de los Ausentes fully on paper before any implementation, then implement and test the full solve path.
---

# /puzzle

## Purpose
Design one puzzle end to end — goal, known information, concrete solution, clues, wrong-attempt
responses, and softlock checks — and only then implement it. This project's narrowed version of
puzzle/quest design work; see [design/puzzles.md](../design/puzzles.md) for the standing rules.

## Use When
- A new puzzle is needed for the active scene, or an existing one needs revision.
- Never for abstract or systemic mechanics — see Notes.

## Invokes Agents
- level-designer
- narrative-designer

## Required Skills
- quest-design
- level-design
- narrative-design

## Process
1. Define what the player is trying to achieve.
2. Record what information the player already has access to at this point.
3. Design a solution built from concrete objects, dialogue, or actions — never a new abstract
   mechanic.
4. Write the clues that make the solution discoverable, and where each one appears.
5. Write responses to incorrect attempts — never silent failure, never a generic "that doesn't
   work."
6. Actively look for blocked or impossible states (softlocks) the design could produce.
7. Only after steps 1-6 are written down and reviewed, implement the puzzle.
8. Run the full path — correct solve and at least one incorrect attempt — before reporting done.

## Expected Output
- A written puzzle design (goal, known info, solution, clues, wrong-attempt text, softlock
  check) added to or updating [design/puzzles.md](../design/puzzles.md).
- Implementation only after the above is reviewed.
- A verification note confirming the full path (correct + incorrect) was actually run.

## Notes
- Do not incorporate new abstract mechanics. Puzzles stay object/dialogue/action-based, per
  [design/game-bible.md](../design/game-bible.md).
- Coordinate with `/dialogue` when a puzzle depends on conversation state.
- Escalate to the user before implementing anything not already covered by
  [production/current-scope.md](../production/current-scope.md).
