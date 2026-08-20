---
description: Write or revise dialogue for Ministerio de los Ausentes in each character's voice, kept as data separate from game logic.
---

# /dialogue

## Purpose
Write or revise dialogue lines for this project, staying inside each character's established
voice and inside the narrative facts already approved in [design/narrative.md](../design/narrative.md).
This project's narrowed version of the framework's general `/dialogue-design`.

## Use When
- A scene needs new or revised dialogue lines, observation text, or conversation branches.

## Invokes Agents
- narrative-designer

## Required Skills
- narrative-design
- dialogue-content-pipeline

## Process
1. Read the relevant character sheet(s) under
   [design/characters/](../design/characters/) before writing a single line.
2. Keep each character's established voice (see [design/characters/nicanor.md](../design/characters/nicanor.md)
   for the only character sheet that exists so far).
3. Favor humor and subtext over direct exposition.
4. Avoid direct political exposition — the satire works through implication.
5. Write the text into data files under `game/resources/dialogue/`, never inline in GDScript.
6. Do not change narrative facts established in [design/narrative.md](../design/narrative.md)
   without the user's explicit approval.
7. Clearly mark any provisional line (placeholder tone/timing, not yet approved as final) as
   provisional in the commit or hand-off notes.

## Expected Output
- Dialogue/observation text written or updated in `game/resources/dialogue/`.
- [design/narrative.md](../design/narrative.md) updated only if the user approved a new fact.
- Explicit callouts for any line that is provisional.

## Notes
- Keep dialogue text separate from control-flow logic at all times.
- Do not invent new characters, backstory, or plot beats — flag the gap to the user instead.
- Coordinate with `/puzzle` when a line gates or reveals puzzle-relevant information.
