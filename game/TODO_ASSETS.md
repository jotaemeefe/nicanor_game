# TODO Assets — Ministerio de los Ausentes

- Status: Active
- Last updated: 2026-08-16

Tracks every art/audio asset used or missing in the current MVP scene (`oficina_recepcion.tscn`),
its source, and known issues. See `design/art-bible.md` for direction and constraints.

## Source

Three batches, all delivered by the user as PNGs at the repo root:

1. `ejemplo/` — first pass. Several files had a dark vignette baked into opaque pixels (not real
   transparency); worked around at the time, now **superseded** by batch 2/3.
2. `ejemplo/mas_imagenes/nuevos_assets/` — second, much cleaner pass (`MANIFIESTO_ASSETS.md` in
   that folder is the user's own manifest). Active source for every character/prop/ambient asset.
   Sliced with the same Python/Pillow connected-component technique as batch 1 (the sheets aren't
   evenly spaced, so blind grid-slicing would still cut into the art). Two files in this batch
   arrived corrupted (`scene_background_clean.png`, `nicanor_master.png`).
3. `ejemplo/mas_imagenes/nuevos_assets_v2/` — re-export of just the background/reference/sello, with
   the batch-2 corruption fixed and confirmation that the background plate has **no interactive
   elements painted in** (door, máquina, cartel, ventilador, sello are all independent overlay
   sprites by design — everything else is byte-identical to batch 2, verified with `cmp`).

## Used assets (batch 2 — active)

| Asset | Path | Source file | Notes |
|---|---|---|---|
| Fondo oficina | `assets/backgrounds/oficina_recepcion.png` | batch 3 (`nuevos_assets_v2/backgrounds/scene_background_clean.png`) | Architecture-only plate with no door/máquina/cartel/ventilador/sello painted in (confirmed by the manifest) — those exist purely as independent overlay sprites now, which is why the door no longer visually collides with a painted one. Batch 2's version of this file was corrupted; batch 3 fixed it. |
| Sello (chained stamp) | `assets/props/sello.png` | batch 3 (`nuevos_assets_v2/props/stamp_and_chain_clean.png`) | Clean alpha, replaces batch 1's vignette-affected version. |
| Cartel de estado — 3 estados | `assets/props/cartel_estado/cartel_apagado.png`, `_ambar.png`, `_rojo.png` | batch 2/3 (`interactive/status_board_3_states_clean.png`, identical file in both) | New — an ambient institutional indicator (not part of puzzle logic, just reflects progress: apagado before `REQUISITO_DESCUBIERTO`, ámbar until `ACCESO_AUTORIZADO`, rojo after). Mounted above the ticket machine, no hotspot. |
| Nicanor — caminata (6) | `assets/characters/nicanor/walk_1..6.png` | `nuevos_assets/characters/nicanor/nicanor_walk_right_6_frames.png` | Clean alpha, uniform 390×685 canvas, feet-anchored. Replaced batch 1's walk set at the same paths. |
| Nicanor — poses (4) | `assets/characters/nicanor/pose_*.png` | `nuevos_assets/characters/nicanor/nicanor_dialogue_4_poses.png` | Clean alpha, uniform 498×812 canvas. Replaced batch 1's set at the same paths. |
| Recepcionista — busto ×6 poses | `assets/characters/recepcionista/carp_1_neutral.png` … `carp_6_neutral_c.png` | `nuevos_assets/characters/carpincho/carpincho_bust_6_poses.png` | **Clean, purpose-built bust** — no manual crop needed (unlike batch 1's full-body sheet, which needed a `region_rect` hack to avoid showing legs). Uniform 377×497 canvas. `idle` = `carp_1_neutral`, `hablando` = `carp_3_hablando`; `carp_4_sellando`/`carp_5_papeles` unused bonus frames. |
| Loro — 6 estados | `assets/characters/parrot/loro_1_sleepy.png` … `loro_6_molting.png` | `nuevos_assets/characters/loro/parrot_6_states_clean.png` | **Clean alpha — finally usable in-scene** (batch 1's loro had a hard black background with only tiny transparent corners; no safe automated fix existed for it). `idle` = `loro_2_halfopen`, `hablando` = `loro_4_squawk`. |
| Máquina de turnos — 3 estados | `assets/props/maquina_turnos/maquina_apagada.png`, `_encendida.png`, `_imprimiendo.png` | `nuevos_assets/interactive/ticket_machine_3_states_clean.png` | Clean alpha. Texture swapped by `office_scene_controller.gd` based on `GameState` (apagada at `INICIO`, imprimiendo during `DECLARACION_USADA`, encendida otherwise). Replaces batch 1's single vignette `dispensador_turnos.png`. |
| Puerta — 3 estados | `assets/props/puerta/puerta_cerrada.png`, `_desbloqueada.png`, `_abierta.png` | `nuevos_assets/interactive/door_3_states_clean.png` | Clean alpha. New — batch 1 had no separate door sprite (relied on the door painted into the background). Swapped by state: cerrada until `ACCESO_AUTORIZADO`, desbloqueada until `ESCENA_TERMINADA`, abierta after. |
| Ventilador de techo — aspa + buje | `assets/props/ventilador/fan_blade.png`, `fan_hub.png` | `nuevos_assets/ambient/ceiling_fan_4_frames.png` (cuadro 4) | Cortados por script del cuadro 4 de la hoja, ambos centrados en el buje. `fan_blade` es **una sola aspa**, instanciada tres veces a 120° en la escena: la hoja dibuja sus tres aspas a radios distintos, así que girarlas como una sola imagen despedazaba el ventilador. `fan_hub` (buje + caño + florón) queda fijo y se dibuja encima, tapando las raíces de las aspas. Reemplaza a `fan_a/fan_b` + `fan_frames.tres`, cuyos recortes tenían el ventilador en puntos distintos del lienzo y lo hacían saltar 42 px cada 1,4 s. El `modulate` de la escena baja el brillo del recorte al del ventilador pintado en el maestro. |
| Formulario | `assets/props/formulario.png` | batch 1 props sheet | Kept from batch 1 (clean already, no batch-2/3 equivalent shipped). |

## Root cause of "Nicanor gigante" (found and fixed 2026-08-16)

Not an asset or scale-number problem — a real bug in `nicanor_controller.gd`. The walk/idle
`AnimatedSprite2D` scale was correctly set to the intended value in the scene file, but
`clear_pose()` and the walk/idle transition code in `_physics_process` reset it to `Vector2.ONE`
(1.0, i.e. the art's native ~685px pixel size) on every single step Nicanor took, instead of
restoring the scene's actual configured scale. A diagnostic that only read the sprite's scale
right after loading the scene (never actually walking) couldn't catch this — it looked correctly
scaled until the moment the player moved. Fixed by capturing the sprite's real starting scale in
`_ready()` and restoring *that* instead of a hardcoded 1.0. Verified with a headless script that
actually calls `walk_to()`, waits for arrival, and re-checks scale.

## Character layering (Nicanor vs. Recepcionista)

Fixed by wrapping `Nicanor`, `Recepcionista`, and `Hotspots` in a `World` node with
`y_sort_enabled = true` — whoever has the lower Y (closer to the bottom of the screen) now
consistently draws in front, instead of a fixed, position-independent draw order.

## Deferred from the new asset pack's prompt (not done this pass, tracked for follow-up)

- `carpincho_master_bust.png`, `props_master_reference.png` — reference-only per the manifest, not
  imported as in-scene assets (by design).
- Contact shadows under moving characters, randomized idle pauses, and the "dim ambient briefly
  during a mention of Nicanor's mother" beat from the new prompt — none of that dialogue exists yet
  in this scene (no mention of the mother happens here), so there's nothing to time it to; noted for
  whenever that content is written.

## Audio

**Provided 2026-08-20** (`assets/sounds/`):

- `fondo_menu.mp3` — title screen music. Loops; fades out over 0.35 s when the player presses
  Comenzar, because the intro video that follows carries its own audio and a hard cut is audible.
- `fondo_escena1.mp3` — reception room tone. Loops; fades out over 1.4 s when the door opens
  (`ESCENA_TERMINADA`).

**Both loop via the mp3 import setting** (`loop=true` in the `.import`), not via script. That flag
is invisible in the scene view and fails silently — the track just stops minutes in — so
`puzzle_flow_test` asserts it on the resource.

Still missing: sonido de máquina and sonido de clic. Their `AudioStreamPlayer` nodes
(`Audio/MaquinaSfx`, `Audio/ClickSfx`) exist with no `stream` set — silent placeholders, per the
brief's fallback. Voices: explicitly out of scope.
