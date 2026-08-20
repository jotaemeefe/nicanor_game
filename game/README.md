# Ministerio de los Ausentes — juego (Godot)

Vertical slice jugable: **Recepción del Ministerio de los Ausentes**. Ver
`../design/` para la biblia creativa y `../production/current-scope.md` para el alcance activo.

## Versión de Godot

**Godot 4.7.1** (stable, GDScript, sin C#/.NET). El proyecto declara el feature tag `"4.6"` en
`project.godot` (heredado del setup inicial de este repo) — Godot 4.7 lo abre y lo corre sin
problemas, sin necesidad de migración. Si preferís una instalación 4.6.x exacta, cualquier 4.6/4.7
GDScript-only debería funcionar igual; el proyecto no usa ninguna API específica de 4.7.

No había ningún Godot instalado en esta máquina al empezar este trabajo; se instaló vía
`winget install --id GodotEngine.GodotEngine --source winget`, quedando en:

```
C:\Users\<usuario>\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.1-stable_win64.exe
```

Si tu editor (VSCode/Cursor con la extensión Godot Tools, o el MCP `godot-editor`) sigue
apuntando a una ruta vieja, actualizá esa configuración a la ruta de arriba y reiniciá la
extensión/MCP.

## Cómo abrir y ejecutar

1. Abrí Godot 4.7.x.
2. "Import" → seleccioná `game/project.godot`.
3. Play (▶) — el proyecto arranca en `scenes/main_menu/main_menu.tscn`.

También podés correrlo sin abrir el editor:

```bash
godot --path game
```

O verificar que carga sin errores en modo headless (sin GPU/ventana):

```bash
godot --headless --path game scenes/office/oficina_recepcion.tscn --quit-after 60
```

## Controles

- **Clic izquierdo** sobre el piso: caminar hasta ese punto.
- **Clic** sobre un hotspot: la única acción que tiene (mirar/hablar/usar — el juego usa **un solo
  verbo**, y los dos botones del mouse hacen lo mismo). Si Nicanor no está ya en el punto de
  aproximación del hotspot, primero camina hasta ahí.
- Pasar el mouse sobre un hotspot muestra su nombre arriba a la izquierda.
- Durante un diálogo: clic izquierdo completa el texto instantáneamente si todavía se está
  revelando (efecto de máquina de escribir), o avanza a la siguiente línea si ya está completo.
- Botones **Reiniciar** / **Menú** siempre visibles arriba a la derecha durante el juego, y también
  en la pantalla de fin de escena.

## Estructura del proyecto

```
game/
  assets/            # arte (fondos, personajes, props) — ver TODO_ASSETS.md
  scenes/
    main_menu/       # pantalla inicial
    office/          # escena activa: Recepción del Ministerio
    hotspot.tscn      # hotspot reutilizable (Área2D + Inspector)
    dialogue_box.tscn # caja de diálogo reutilizable
    oficina_licencias_poeticas.tscn  # prototipo anterior, retirado — ver production/decisions.md
  scripts/
    game_state.gd              # autoload — máquina de estados del puzle activo
    dialogue_manager.gd        # utilidades estáticas: carga JSON, resuelve ramas/textos por estado
    hotspot.gd                 # hotspot reutilizable (hover/click, punto de aproximación)
    nicanor_controller.gd      # click-to-walk + animación de Nicanor
    dialogue_box.gd            # caja de diálogo (typewriter, opciones, retrato)
    office_scene_controller.gd # controlador de la escena activa (el puzle vive acá)
    main_menu.gd
  data/
    dialogues/       # JSON: recepcionista.json, loro.json, final.json
    hotspots/         # JSON: maquina_turnos.json (textos por estado)
  docs/
    MVP_SCOPE.md
    PLAYTEST.md
  tests/
    puzzle_flow_test.gd / .tscn    # test headless del estado/diálogo (ver abajo)
    intro_flow_test.gd / .tscn     # test headless del video de intro
    walkable_area_test.gd / .tscn  # test headless del piso caminable y orden de dibujado
    status_board_test.gd / .tscn   # test headless de la perspectiva del cartel de estado
  TODO_ASSETS.md
```

## Flujo del MVP

Nicanor necesita un número de turno para declarar la ausencia de una persona, pero la máquina exige
una "constancia de presencia". Diseño completo del puzle (objetivo, pistas, respuestas a intentos
incorrectos, ausencia de softlocks): `../design/puzzles.md`.

Resumen: examinar/hablar para descubrir el requisito → completar el Formulario del atril →
usarlo en la máquina → recibir el turno 0 → volver a hablar con la Recepcionista → autorización por
una contradicción reglamentaria → salir por la Puerta → cierre melancólico + remate del Loro.

## Cómo agregar un hotspot

1. En la escena (`scenes/office/oficina_recepcion.tscn`), instanciá `scenes/hotspot.tscn` dentro de
   `Hotspots`.
2. Configurá en el Inspector: `hotspot_name`, `hitbox_size`, `approach_point` (offset relativo
   desde el hotspot hasta dónde debe pararse Nicanor, sobre el área caminable), `look_direction`
   ("left"/"right"), y `observe_text`/`interact_text` (y `interact_text_alt` si necesitás una
   segunda variante estática, p. ej. "ya hecho").
3. Si el hotspot está sobre un detalle ya pintado en el fondo, marcá `invisible = true` (no dibuja
   el polígono placeholder). Si no tiene arte propio, dejalo en `false` y ajustá `visual_color`.
4. Si necesita texto que varíe según el estado del puzle (como la Máquina de turnos), no lo pongas
   en el Inspector — agregá una entrada en `data/hotspots/` siguiendo el formato de
   `maquina_turnos.json`, y manejalo en `office_scene_controller.gd` (`_resolve_hotspot`).
5. Si dispara conversación en vez de una línea suelta, agregá su lógica en
   `office_scene_controller.gd::_resolve_hotspot` (switch por `hotspot_name`) y su JSON en
   `data/dialogues/`.

## Cómo agregar o modificar un diálogo

Todo el texto vive en JSON (`data/dialogues/`), nunca hardcodeado en GDScript. Acá va el
resumen operativo; el contrato completo (orden de las ramas, vocabularios cerrados de `speaker` y
`pose`, límites de longitud, invariantes y pipeline) está en
[`../design/dialogue-structure.md`](../design/dialogue-structure.md).

- **Conversación con estado** (como la Recepcionista): un archivo con `"branches"`, cada rama con
  `id`, `min_state`/`max_state` opcionales (nombres del enum `GameState.State`, límites inclusive),
  `lines` (array de `{speaker, text, pose?}`, o una entrada `{"choice": [...]}` para una elección
  del jugador — ver `recepcionista.json` para un ejemplo con ambos), y `effects.set_state` opcional.
- **Texto por estado, sin conversación** (como el Loro o la Máquina): un diccionario de
  `NOMBRE_DE_ESTADO -> texto` (o `-> [array de variantes]` para elegir una al azar). Los estados sin
  entrada propia heredan el texto del estado anterior más cercano que sí la tenga.
- `pose` en una línea de Nicanor puede ser `"neutral"`, `"explicacion"`, `"escepticismo"` o
  `"recitado"`.

## Tests automáticos (headless, sin editor)

```bash
godot --headless --path game res://tests/puzzle_flow_test.tscn
godot --headless --path game res://tests/intro_flow_test.tscn
godot --headless --path game res://tests/walkable_area_test.tscn
godot --headless --path game res://tests/status_board_test.tscn
```

Cada uno debe imprimir `... TEST: OK`.

- **`puzzle_flow_test`** — la máquina de estados y que cada archivo de diálogo resuelve texto no
  vacío para cada estado alcanzable.
- **`intro_flow_test`** — que el video de intro está asignado como `VideoStreamTheora` y que la
  transición a la oficina es idempotente.
- **`walkable_area_test`** — que el polígono caminable deja a Nicanor fuera de la huella de la
  mesa y del escritorio del frente, que todos los `approach_point` de los hotspots caen sobre piso
  pisable, y las invariantes de orden de dibujado (la mesa y el sello siempre delante de él, el
  vidrio de la ventanilla siempre detrás).
- **`status_board_test`** — que el cartel de estado sigue siendo un `PerspectiveQuad` y que su
  deformación es un trapecio de verdad (no un paralelogramo, que es lo que da cualquier transformación
  afín), que los vértices generados caen exactamente sobre las esquinas configuradas, y que los tres
  estados del cartel comparten tamaño de textura — la malla no se reconstruye al cambiar de estado,
  así que las UV solo son válidas mientras eso se cumpla.

Ninguno simula clics reales ni la caminata física de Nicanor — eso todavía requiere una pasada
manual, ver `docs/PLAYTEST.md`.

## Build web (WebAssembly)

El juego exporta a navegador. El preset vive en `export_presets.cfg` (versionado a propósito: no
tiene credenciales y es el único registro de cómo se arma la build publicada).

Requisito único: tener instaladas las plantillas de exportación de la **misma versión** de Godot
(`%APPDATA%\Godot\export_templates\4.7.1.stable\`). Se bajan del editor
(Editor → Administrar plantillas de exportación) o del `.tpz` de la release.

```bash
godot --headless --path game --export-release "Web" "../build/web/index.html"
python -m http.server 8099 --directory build/web     # abrir file:// NO funciona
```

`build/` está en `.gitignore`: son artefactos (~72 MB), no fuentes.

### Por qué está exportado sin hilos

`variant/thread_support=false` en el preset. Con hilos, el navegador exige `SharedArrayBuffer`, que
a su vez exige que el servidor mande las cabeceras `COOP`/`COEP` — GitHub Pages no permite
configurarlas. Sin hilos anda en cualquier hosting estático sin tocar nada del servidor, y este
juego es 2D de un solo hilo igual.

### Peso real para el jugador

| Archivo | Crudo | Servido con gzip |
|---|---|---|
| `index.wasm` | 37,7 MB | 9,7 MB |
| `index.pck` | 33,1 MB | 33,0 MB |
| `index.js` | 0,3 MB | 0,1 MB |
| **total** | **71 MB** | **42,7 MB** |

El `.pck` no comprime porque ya son PNG y un `.ogv`. De esos 33 MB, **9,4 MB son el video de
intro**: es la primera pieza a tocar si hay que bajar el peso. La intro ya se puede saltar con un
clic y tiene fallback automático si el video no arranca (ver `scripts/intro.gd`), así que un
navegador que no pueda decodificar Theora igual entra a la escena.

### Verificado en navegador

Chrome headless con renderizado por software (SwiftShader): menú, intro y la escena de recepción
cargan y responden, sin errores de consola.
