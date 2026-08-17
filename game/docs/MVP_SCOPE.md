# MVP Scope — Recepción del Ministerio de los Ausentes

- Status: Active
- Last updated: 2026-08-16
- Related: [../TODO_ASSETS.md](../TODO_ASSETS.md), [../../design/puzzles.md](../../design/puzzles.md), [../../production/current-scope.md](../../production/current-scope.md)

## Alcance incluido

- Una escena jugable: recepción del Ministerio, con arte real (fondo + personajes + props
  provistos por el usuario en `ejemplo/`).
- Nicanor controlable: click-to-walk, animación de caminata (6 frames), 4 poses de diálogo.
- Dos NPCs: Recepcionista (carpincho, cuerpo completo animado) y Loro institucional (placeholder
  visual, arte real usado como retrato de diálogo — ver `TODO_ASSETS.md`).
- 12 hotspots (supera el mínimo de la consigna): Máquina de turnos, Mostrador, Recepcionista, Loro,
  Cartel de normas, Puerta, Planta de oficina, Cesto de basura, Formulario, Sello (bonus, con arte
  real), Ventilador de techo y Reloj (los dos objetos puramente cómicos, reutilizando detalles ya
  pintados en el fondo).
- Un puzle completo con seis estados (`GameState`), diseñado primero en
  `design/puzzles.md` según su propio proceso de seis puntos.
- Diálogo basado en datos (JSON), con ramas por estado, una elección real del jugador (dentro de la
  conversación inicial con la Recepcionista), cambio de pose de Nicanor, y texto acelerable/saltable
  (typewriter con skip al clic).
- Pantalla inicial ("Comenzar") y pantalla de fin de escena con "Reiniciar" / "Menú principal";
  además, botones de reinicio/menú siempre visibles durante el juego.
- Soporte de audio (3 `AudioStreamPlayer`) sin asset — ver `TODO_ASSETS.md`.
- Test automático headless (`tests/puzzle_flow_test.tscn`) para el estado del puzle y el contenido
  de diálogo.

## Decisiones tomadas

- El puzle "usar la declaración en la máquina" se resuelve con un flag booleano en `GameState`
  (`DECLARACION_OBTENIDA`), no con un sistema de inventario — la consigna excluye explícitamente
  construir inventario todavía, y un flag cubre el mismo beat sin el sistema adicional.
- La escena de demostración anterior ("Oficina de Licencias Poéticas") se retiró del flujo activo,
  reemplazada por esta — ver `production/decisions.md` para el detalle completo de esa decisión y
  las de integración de arte.
- Tres assets de personaje (retrato de Nicanor, busto del Loro, y dos props: dispensador de turnos
  y sello) tienen una viñeta oscura pintada de fondo que no se pudo recortar de forma segura sin
  arriesgar destruir el arte real (un primer intento automatizado comió plumas del loro y se
  revirtió) — ver `TODO_ASSETS.md` para el tratamiento de cada uno y la prioridad de un recorte
  prolijo futuro.

## Funciones descartadas por ahora (no construir sin nueva aprobación)

Inventario complejo, sistema de guardado, múltiples resoluciones, voces, localización, cinemáticas
extensas, mapa o múltiples habitaciones más allá de esta escena, mecánica de nombres borrados
(`design/art-bible.md`), Concurso de Poesía Productiva como sistema jugable, arte final para los
hotspots hoy placeholder.

## Criterios de aceptación

Ver la lista completa en la consigna original del usuario (14 puntos). Estado de cada uno tras esta
sesión:

| # | Criterio | Estado |
|---|---|---|
| 1 | Abre sin errores en la versión declarada de Godot | ✅ Verificado headless (ver `docs/PLAYTEST.md`) |
| 2 | Inicia desde el menú | ✅ `main_menu.tscn` es la escena principal |
| 3 | Nicanor camina con clic en zona válida | ⚠️ Implementado; no verificado con clics reales (sin GUI en este entorno) |
| 4 | No atraviesa obstáculos principales | ⚠️ `walkable_bounds` los excluye; no verificado visualmente |
| 5 | Ciclo de caminata se reproduce | ⚠️ Implementado (SpriteFrames real); no verificado visualmente |
| 6 | Hotspots muestran nombre y responden | ⚠️ Implementado; no verificado con mouse real |
| 7 | Se puede hablar con el recepcionista | ✅ Verificado por lógica (test headless); no verificado visualmente |
| 8 | Opciones y estados de diálogo funcionan | ✅ Verificado por test headless (75 checks) |
| 9 | El puzle tiene principio, desarrollo y resolución | ✅ Diseñado (`design/puzzles.md`) e implementado; verificado por lógica |
| 10 | Se completa sin editor ni consola | ⚠️ Diseñado para eso (UI completa, sin dependencias de debug); no verificado end-to-end con input real |
| 11 | Se puede reiniciar | ✅ Implementado (`reload_current_scene`), estructura verificada |
| 12 | Sin errores/warnings críticos en una partida completa | ⚠️ Sin errores en las cargas headless verificadas; una partida completa con mouse real queda pendiente |
| 13 | Lógica narrativa no hardcodeada de forma imposible de extender | ✅ Todo el texto vive en JSON/Inspector, ver `README.md` |
| 14 | Instrucciones claras para ejecutar y editar | ✅ `README.md` |

Los ⚠️ son exactamente lo que falta probar a mano — ver `docs/PLAYTEST.md`.
