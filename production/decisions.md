# Decisions Log — El Ministerio de los Ausentes

- Status: Active
- Last updated: 2026-08-16

Chronological log of judgment calls made where the request left a genuine gap. Newest first.

## 2026-08-16 — Real screenshot verification found the actual root causes

Got `godot --write-movie` working (see `feedback-godot-self-screenshot` memory) and used it to
actually see the scene instead of guessing from coordinates. That surfaced three real bugs the
coordinate-only approach had missed entirely:

- **Idle animation used a mid-stride walk frame** (`walk_1.png`) instead of a neutral standing
  pose — this, not a position bug, was the "Nicanor queda suspendido" look. Fixed by generating
  `assets/characters/nicanor/idle_1.png` from `pose_neutral.png` (rescaled to match the walk
  canvas height so the feet-anchor offset stays valid) and pointing the `idle` animation at it.
- **`walkable_bounds`'s back edge (Y 470) overlapped the painted rope stanchion's base** (measured
  at Y≈505-515 in the actual background) — any hotspot approached near the back of the walkable
  area put Nicanor's feet visually on/behind the rope posts. Fixed by moving the back edge to
  Y 540, past the rope, and recomputing every approach point from that.
- **Door/máquina/sello vertical anchoring was inconsistent** — some used a `Sprite2D.offset`
  trick, some didn't, and one round of "fixing" the offset math (converting to unscaled
  half-canvas-height, which is correct for `AnimatedSprite2D`) actually produced identical results
  to before for plain `Sprite2D` when re-verified by screenshot, because the real issue was the
  *target* Y values, not the offset formula. Replaced all three with plain `position`-based
  centering (no `offset` at all) and picked the position values by directly measuring where the
  cart's surface sits in the actual background (Y≈460-490, tilted plane) instead of estimating.
- **Cesto de basura removed** — the flat gray placeholder box read as a visible bug to the user
  ("horrible"), and it's not required for the puzzle. Simpler to drop it than defend a bad
  placeholder; `design/puzzles.md`/`current-scope.md` still list the fuller hotspot set from the
  original brief, flagged here as the one hotspot not currently implemented.

## 2026-08-16 — Depth scaling, approach-point occlusion, precise re-measurement, dialogue UI fixes

Fourth round of user playtest feedback (with screenshots) surfaced five more real problems:

- **Nicanor didn't respect the floor/perspective** — a single fixed scale everywhere in
  `walkable_bounds` made him look like he was walking across the whole screen rather than on a
  floor with depth. Fixed by adding linear depth scaling to `nicanor_controller.gd`
  (`scale_at_back`/`scale_at_front`, interpolated by Y within `walkable_bounds`) — he's now smaller
  near the back of the room and larger near the front. Verified headlessly: 0.43 near the back vs.
  0.63 near the front for the same walk.
- **Nicanor occluded whatever he was interacting with.** Every hotspot's `approach_point` had him
  stop centered on/right in front of the object. Recomputed every approach point to stand to the
  side of each object instead (offset chosen relative to his depth-scaled width at that spot), so
  the object he's examining stays visible.
- **Object placement/sizes were measured against the wrong reference.** Positions were computed
  from `ejemplo/mas_imagenes/maestro.png`, but that composite image is a *different* generation
  than the actual background in use (`game/assets/backgrounds/oficina_recepcion.png`) — close but
  not pixel-identical, most visibly on the door (painted at a different position/size than
  `maestro.png` implied). Re-measured every hotspot directly against the real background this time
  (gridded crops at 1:1–2:1, not the reference composite) — door, window, fan, clock, cabinets, and
  every prop position/scale in `oficina_recepcion.tscn` were redone from those measurements. The
  painted door and the new door sprite still won't align pixel-perfectly (different aspect ratios
  — the source door art and painted door aren't the same asset), but they're now much closer in
  both position and scale.
- **Loro's dialogue mixed the quoted phrase with a narrator aside** in the same text box (e.g. a
  quote followed by "Lo repite igual que la Recepcionista, con menos paciencia" in one string).
  Fixed by stripping every idle line down to just what the parrot actually says — no
  narrator/description text mixed in. `game/data/dialogues/loro.json`.
- **The dialogue box overlapped its own choice buttons** when a line had player options — the
  panel's fixed height (140px) was sized for text alone, too short once 2 buttons were added below
  it. Grew the panel to 290px and gave the dynamically-created option buttons a real minimum size
  instead of relying on default auto-sizing. `game/scenes/dialogue_box.tscn`,
  `game/scripts/dialogue_box.gd`.

## 2026-08-16 — Second asset pack, root-cause fix for "Nicanor gigante", Y-sort

- **Root cause of the recurring oversized-Nicanor bug found.** Not a scale value problem — every
  previous fix was correct on paper (confirmed by a headless diagnostic reading the sprite's scale
  right after scene load) but the diagnostic never actually made Nicanor walk. `nicanor_controller.gd`
  reset the sprite's scale to a hardcoded `Vector2.ONE` on every walk/idle transition and on
  `clear_pose()`, instead of the scene's real configured scale — invisible until the player actually
  took a step, which is immediate in real play. Fixed by capturing the sprite's real starting scale
  in `_ready()` and restoring that instead of `1.0`; verified with a headless script that calls
  `walk_to()`, waits for arrival, and re-checks scale (not just reads it once at load).
- **Y-sorting added** (`World` node, `y_sort_enabled = true`, wrapping Nicanor/Recepcionista/Hotspots)
  to fix Nicanor and the Recepcionista drawing in front of/behind each other inconsistently — the
  scene had no dynamic depth ordering before, just fixed tree order.
- **Second, much cleaner asset pack integrated** from `ejemplo/mas_imagenes/nuevos_assets/`
  (user-provided, own manifest at `MANIFIESTO_ASSETS.md`), superseding most of the first pass — see
  `game/TODO_ASSETS.md` for the full per-asset mapping. Notably: the Recepcionista's full-body
  crop-hack is gone (the new pack ships a purpose-built bust sheet), the Loro finally has real
  in-scene art (the old one had zero safe way to remove its vignette), and the Máquina de turnos and
  Puerta are now real 3-state sprites (apagada/encendida/imprimiendo; cerrada/desbloqueada/abierta)
  driven by `GameState`, replacing a static prop and a painted-into-the-background door respectively.
  Ceiling fan is now a 4-frame ambient animation instead of the static painted one.
- **Two files in the new pack arrived corrupted** (`scene_background_clean.png`,
  `nicanor_master.png` — both fail to load in PIL and in Godot's importer). The scene keeps using
  the first pack's background as a fallback; flagged for the user to re-export those two
  specifically. Not blocking, since the first pack's background is a working equivalent and
  `nicanor_master.png` is reference-only (not used in-engine).
- **Self-testing note.** Repeated attempts this session to auto-capture a real in-engine screenshot
  (needed since `--headless` can't render real pixels) failed and also interfered with the user
  manually testing the game (window opening/closing on its own). Abandoned — see the
  `feedback-godot-self-screenshot` memory. Verification for anything visual now relies on headless
  logic/diagnostic scripts (confirmed scale, position, texture assignment via code, not pixels) plus
  the user's own screenshots.

## 2026-08-16 — Scene layout recalibrated against `maestro.png`

First pass at character scale/hotspot placement was eyeballed and came out wrong once the user
actually ran it: Nicanor rendered far too large, the Recepcionista showed full-body instead of
seated-behind-the-counter, and every hotspot/prop was positioned differently from
`ejemplo/mas_imagenes/maestro.png` (the composited reference the user provided showing where
everything should sit). Fixed by measuring `maestro.png` directly (pixel-gridded crops, converted
via the 1280/1672≈0.7654 scale factor to scene coordinates) instead of estimating:

- **Nicanor scale corrected 0.38 → 0.62** (target on-screen height ~425px, cross-checked against
  the door's height in the reference — a person standing near a door should be close to but
  shorter than it, which 425px vs. the door's ~448px measured height satisfies).
- **Recepcionista is no longer a full-body `AnimatedSprite2D`.** She's a plain `Sprite2D` with
  `region_rect` cropped to the top ~300px of the 356×624 `carp_*.png` canvas (bust only — head,
  shoulders, hands), texture-swapped between `carp_1_neutral`/`carp_3_hablando` for
  idle/speaking instead of an animated loop, so she reads as seated behind the ventanilla instead
  of standing on the counter. `office_scene_controller.gd`'s `_recepcionista_sprite` type changed
  from `AnimatedSprite2D` to `Sprite2D` accordingly.
- **Every hotspot, approach point, and prop sprite repositioned/rescaled** from measured
  `maestro.png` coordinates (dispensador, mostrador, recepcionista, loro, cartel, puerta, planta,
  formulario, sello, ventilador, reloj) — see `game/scenes/office/oficina_recepcion.tscn`.
  `walkable_bounds` also recalculated from the reference's floor line.
- Verified the corrected on-screen sizes match the target measurements (424.7px / 141px) with a
  throwaway headless diagnostic script before deleting it — not left in the repo.

## 2026-08-16 — MVP scope expansion, real art integration, biblia creativa

- **Explicit scope extension.** The user directly requested a full 5–10 minute playable vertical
  slice (real art, NPCs, complete puzzle, UI, audio hooks, docs) — this supersedes the earlier
  linear-demo-only gate in `current-scope.md` per that document's own "nothing beyond Active scope
  is authorized until the user explicitly extends this document" rule. Updated `current-scope.md`
  accordingly.
- **Biblia creativa integrated as canon.** The user pasted a full 20-section creative bible;
  distributed it across `design/game-bible.md`, `design/art-bible.md`,
  `design/characters/nicanor.md`, and `design/narrative.md` following the existing file
  boundaries, rather than creating new top-level docs.
- **Scene renamed and re-scoped.** `game/scenes/oficina_licencias_poeticas.tscn` (the "licencia
  poética" placeholder conversation, never canon — see the 2026-08-16 initial-setup entry below)
  is replaced by `game/scenes/office/oficina_recepcion.tscn`, matching the "declarar una ausencia /
  constancia de presencia / turno cero" flow the user specified directly, which fits the Ministry
  premise better than the placeholder subplot it replaces. The old scene file and its dialogue JSON
  are left on disk, unused, as history — not deleted, since they weren't ours to discard without
  being asked and cost nothing to keep.
- **Puzzle designed before implementation**, per `design/puzzles.md`'s own required six-point
  process — see `design/puzzles.md#puzle-activo--constancia-de-presencia`.
- **No inventory system for "usar declaración en la máquina."** The brief's step "usa esa
  declaración en la máquina" is implemented as a `GameState` boolean flag
  (`DECLARACION_OBTENIDA`), not a pick-up/drag inventory item — the brief explicitly excludes
  building inventory for this MVP ("no desarrollar todavía inventario complejo"), and a boolean
  flag satisfies the same puzzle beat without the extra system.
- **Godot was not installed on this machine.** Installed Godot 4.7.1 via
  `winget install --id GodotEngine.GodotEngine` (user's explicit choice among winget/portable/
  existing-install/skip) — see `game/README.md` for the exact path and how to point an editor
  integration at it. `AGENTS.md` names Godot "4.6.x"; 4.7.1 is the current stable winget package
  and opens the project's `config_version=5`/`config/features=("4.6", ...)` file without a format
  migration, so it was used as-is rather than pinned to an older 4.6 build — flagged here in case
  an exact 4.6.x install is later required for a build/export target.
- **Art asset slicing.** `ejemplo/*.png` sliced/organized into `game/assets/` with a Python/Pillow
  script (connected-component detection on the alpha channel, since the sheets aren't evenly
  spaced). Three source images (Nicanor portrait, Loro, Recepcionista bust) and two props
  (dispensador de turnos, sello) have a dark painted vignette baked into opaque pixels around the
  subject, not real transparency — a first automated attempt to strip it destructively ate real
  content (parrot feathers) and was reverted. Final approach and the per-asset limitation list are
  in `game/TODO_ASSETS.md`; do not re-attempt an automated background removal without a proper
  matting tool.

## 2026-08-16 — Initial repo setup

- **Local folder / repo name:** `nicanor_game`, matching the GitHub repo the user had already
  created (`jotaemeefe/nicanor_game`), even though the setup instructions elsewhere referenced
  `ministerio-ausentes` as a fallback name. The explicit, already-created repo took precedence
  over the generic template default. Local `origin` remote points at that repo; nothing has been
  pushed.
- **Git history:** started a fresh `git init` instead of keeping `MRCalderon3D/everything-game-dev-code`'s
  commit history, so the user's repo doesn't carry an unrelated party's authorship history. The
  scaffold's LICENSE and README attribution were kept as files, per the setup instructions.
- **No custom `godot-point-and-click` manifest profile.** `manifests/install-profiles.json` has
  no built-in way to derive a local profile without editing the shared manifest file, and doing so
  would complicate ever pulling upstream scaffold updates. Per the setup instructions' own
  fallback clause, the project stays on the unmodified `godot-indie-2d` profile and encodes the
  reduced 6-responsibility scope through `AGENTS.md`/`CLAUDE.md`/this `production/` folder
  instead.
- **Files staged but not committed.** The framework's own tooling (`install-profile.js`,
  `doctor`, structure/wrapper sync) resolves the file set via `git ls-files`, which only sees
  staged/committed files. To get accurate tool output without violating "no commits automáticos,"
  everything was `git add`-ed (staged) but no commit was created — that first commit is left for
  the user to make deliberately.
- **Engine project lives in `game/`,** not at the repo root, matching the framework's own
  documented convention (`guides/Dash & Collect/chapter-00-scaffold-onboarding.md`): the scaffold
  root is the AI workspace, the engine project is a subfolder.
- **Renderer: `gl_compatibility`.** Chosen for broad hardware compatibility on a 2D game with no
  advanced rendering needs; can be changed later without affecting gameplay code.
- **Stretch mode: `canvas_items` + `keep` aspect.** Matches "resolución base 1280×720 con
  escalado que conserve la relación de aspecto" literally.
- **Hotspot interact vs. observe fallback:** only the Funcionaria's left-click is wired to the
  real conversation (source of truth: `design/narrative.md`). For the other five hotspots (Loro,
  Dispensador, Sello, Puerta, Formulario), no left-click text was specified in the brief, so
  left-click currently shows the same text as right-click (the given observation line) rather than
  inventing new dialogue. This is a placeholder behavior, not new narrative content — flag it if a
  distinct primary-interaction line is wanted later.
- **No Godot install.** Godot 4.6.x is not installed in this environment and was not installed
  automatically, per instruction. The project was authored to be structurally valid for Godot
  4.6.x but has not been opened or run in the actual editor — see the final setup report for what
  still needs manual verification.
- **Where hotspot text lives.** Short observation/interaction one-liners (Loro, Dispensador,
  Sello, Puerta, Formulario) are set as exported Inspector properties on each `hotspot.tscn`
  instance in `oficina_licencias_poeticas.tscn` — this satisfies both "hotspots configurables
  desde el Inspector" and "texto separado de la lógica" at once, since they're plain node data,
  never embedded in GDScript control flow. The one genuinely sequential, stateful piece of
  content — the Funcionaria conversation — lives in
  `game/resources/dialogue/oficina_licencias.json` instead, since a linear multi-line exchange
  doesn't fit a single exported string.
- **Invented line: Funcionaria's observe text.** The brief gave observation lines for five props
  but not for the Funcionaria herself; right-click needed to do *something* for her too. Added one
  short, tone-consistent placeholder line ("Lleva veinte años en el mismo escritorio. No sonríe,
  pero tampoco parece triste.") in `oficina_licencias_poeticas.tscn`. This is new (if minor)
  content beyond what was given — flagged here for approval/replacement via `/dialogue`, not
  silently treated as canon.
- **El piso caminable de la recepción es un polígono, no un rectángulo.** `NicanorController`
  tenía `walkable_bounds: Rect2` más una lista de `excluded_zones: Array[Rect2]`. Un piso en
  perspectiva con muebles en las esquinas cercanas es un trapecio con mordiscos: los rectángulos
  alineados a los ejes no lo describen, y en la práctica las zonas de exclusión quedaron cubriendo
  solo 45px de una banda de 100, dejando libre justo la mitad donde Nicanor se paraba encima de la
  mesa y del escritorio del frente. Ahora se define `walkable_polygon: PackedVector2Array` y un
  click fuera resuelve al punto más cercano del borde (`Geometry2D`). `walkable_bounds` queda como
  fallback para las escenas viejas de prototipo que no definen polígono.
- **Los props ordenan profundidad por su punto de apoyo, no por el centro del sprite.** Godot
  ordena por el Y global del nodo; un `Sprite2D` centrado usa el medio de su imagen, que en la mesa
  con ruedas estaba 106px por encima de donde las ruedas tocan el piso. Resultado: Nicanor se
  dibujaba delante de una mesa que en realidad está más cerca de cámara que cualquier punto donde
  él puede pararse. El patrón adoptado es envolver el prop en un `*SortAnchor` (`Node2D`) colocado
  en su línea de contacto con el piso, con el sprite desplazado hacia arriba para no moverse
  visualmente — igual que `SelloAnchor` y `ServiceWindowSortAnchor`. Las invariantes quedan
  cubiertas por `game/tests/walkable_area_test.tscn`.
- **Los props de primer plano pintados en el fondo no pueden tapar a nadie.** El escritorio del
  frente izquierdo está dentro de `scene_background_counterless.png`, que se dibuja antes que todo
  `World`, así que ninguna corrección de orden puede hacer que ocluya a Nicanor. Por ahora se
  resuelve por distancia (el polígono lo mantiene a ~30px de despeje del borde del escritorio).
  La solución de raíz es recortarlo como overlay transparente sobre el mismo lienzo 1672×941, igual
  que se hizo con la ventanilla — ese asset todavía no existe y no se improvisa recortando el fondo
  a mano.
