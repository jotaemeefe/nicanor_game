---
description: Work a small placeholder-or-final 2D art asset set for El Ministerio de los Ausentes and verify it in context before approving it.
---

# /art-pass

## Purpose
Work on one small asset or a small related set — placeholder or final — against
[design/art-bible.md](../design/art-bible.md), and verify it inside the actual scene before
approving it. This project's narrowed version of the framework's general `/art-2d-pass`.

## Use When
- A scene needs a placeholder asset it doesn't have yet.
- An existing placeholder is being upgraded toward final art.

## Invokes Agents
- 2d-artist

## Required Skills
- art-bible
- sprite-pipeline
- placeholder-asset-pipeline

## Process
1. Read [design/art-bible.md](../design/art-bible.md) before starting.
2. Work on one asset or one small, related set of assets — not a batch pass across the whole
   scene.
3. Use flat-shape/flat-color placeholders before any final art.
4. Keep scale, silhouette, palette, and perspective consistent with what's already in the scene.
5. Test the asset inside the actual scene — never approve it looking at it in isolation.
6. Record where the asset came from and its version (provenance), even for placeholders.

## Expected Output
- The asset (or asset set) added/updated under `game/` and wired into the relevant scene.
- A short provenance note (source, version, placeholder vs. final).
- Confirmation the asset was checked in-scene, not just in isolation.

## Notes
- No final art is authorized yet — see [production/current-scope.md](../production/current-scope.md).
- Do not imitate a living artist's style, per [design/art-bible.md](../design/art-bible.md).
- Escalate to the user before doing a full-scene art pass; this command is scoped to one asset or
  a small related set at a time.
