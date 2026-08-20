# Current Scope — Ministerio de los Ausentes

- Status: Active
- Last updated: 2026-08-19
- Related docs: [../design/game-bible.md](../design/game-bible.md), [decisions.md](decisions.md)

## Active scope — vertical slice MVP

The user explicitly extended the scope on 2026-08-16 from the earlier linear demo to a playable
5–10 minute vertical slice, with real character/background art supplied in `ejemplo/`. Active
deliverable: one runnable scene, **Recepción del Ministerio de los Ausentes**, at
`game/scenes/office/oficina_recepcion.tscn`, replacing the earlier "Oficina de Licencias
Poéticas" placeholder (see `decisions.md`).

It implements, and nothing more:

- Fondo real (arte provisto por el usuario, `game/assets/backgrounds/oficina_recepcion.png`).
- Nicanor controlable: clic-para-caminar sobre área caminable, ciclo de caminata real (6 frames),
  4 poses de diálogo reales (neutral, explicación, escepticismo, recitado).
- Recepcionista (carpincho) y Loro institucional como NPCs interactuables.
- Hotspots: Máquina de turnos, Recepcionista, Loro, Cartel de normas, Puerta, Planta de oficina,
  Cesto de basura, Sello, Formulario, y dos objetos puramente cómicos (Ventilador, Reloj) que
  reutilizan detalles ya pintados en el fondo. El Mostrador dejó de ser clickeable el 2026-08-20.
- Nombre del hotspot al pasar el cursor (hover); **un solo verbo** — los dos botones del mouse
  hacen lo mismo; acercamiento automático de Nicanor al punto de aproximación del hotspot antes
  de resolver la interacción.
- Un puzle completo con seis estados (`GameState`) — ver `design/puzzles.md` para el diseño
  aprobado antes de implementarse.
- Diálogo basado en datos (JSON), con variantes por estado, opciones simples, y cambio de pose del
  personaje.
- Pantalla inicial ("Comenzar") y pantalla final con reinicio.
- Texto de diálogo saltable/acelerable.
- Soporte de audio mínimo (ambiente de oficina, sonido de máquina, sonido de clic) — placeholders
  silenciosos donde no hay asset, documentados en `game/TODO_ASSETS.md`.
- **Build web (WebAssembly) para playtest cerrado** (agregado el 2026-08-19 a pedido del usuario).
  Export de Godot a la plataforma Web, sin soporte de hilos, publicable en itch.io en modo
  Restricted (con contraseña) para que solo lo prueben las personas que el usuario elija. El preset
  vive en `game/export_presets.cfg`, versionado a propósito. La build en sí no se versiona: son
  ~72 MB de wasm + pck, artefactos, no fuentes.
  Esto **no** habilita distribución pública, ni tienda, ni versión de descarga para escritorio.

## Explicitly deferred (do not build without a new approval)

Inventario complejo, sistema de guardado, múltiples resoluciones, voces, localización, cinemáticas
extensas, mapa/múltiples habitaciones más allá de esta escena, arte final para los hotspots que hoy
usan placeholder (ver `game/TODO_ASSETS.md`), mecánica de nombres borrados (`art-bible.md` §13),
Concurso de Poesía Productiva como sistema jugable.

## Permanently out of scope for this project

Multiplayer, networking, live ops, monetización, economías virtuales, combate, balance
competitivo, 3D, Unity, Unreal, desarrollo móvil, generación procedural, desarrollo autónomo
continuo, `/full-game`, orquestaciones con decenas de agentes, producción masiva de
documentación, generación masiva de assets.

## Gate

Nothing beyond "Active scope" above is authorized until the user explicitly extends this
document.
