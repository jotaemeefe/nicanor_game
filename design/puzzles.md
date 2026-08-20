# Puzzle Design — Ministerio de los Ausentes

- Status: Active — un puzle diseñado e implementado (ver abajo)
- Related docs: [narrative.md](narrative.md), [../production/current-scope.md](../production/current-scope.md)

## Design rules

- Los puzles se resuelven con objetos, diálogos y acciones concretas — nunca con mecánicas
  abstractas nuevas (sin inventario numérico, sin sistemas de crafteo, sin árboles de habilidades).
- Cada puzle documentado aquí debe definir, antes de implementarse:
  1. Qué quiere conseguir el jugador.
  2. Qué información tiene disponible.
  3. La solución basada en objetos/diálogos/acciones concretas.
  4. Las pistas disponibles y dónde aparecen.
  5. Las respuestas a intentos incorrectos (no deben ser silenciosas ni genéricas).
  6. Estados bloqueados o imposibles a evitar (softlocks).
- No se implementa nada de un puzle hasta que estos seis puntos estén escritos y revisados.
- `/puzzle` es el comando responsable de este proceso — ver `commands/puzzle.md`.
- Principios generales (ver `game-bible.md` §15): objetivo claro, pocos objetos relevantes,
  información distribuida mediante observación y diálogo, soluciones absurdas pero comprensibles,
  consecuencias cómicas, sin combinaciones arbitrarias, sin depender de interpretar poesía
  constantemente, sin castigos graves ni estados imposibles. Los mejores puzles revelan algo del
  mundo.

## Puzle activo — Constancia de presencia

Escena: Recepción del Ministerio de los Ausentes (ver `narrative.md`).

### 1. Qué quiere conseguir el jugador

Un número de turno de la máquina de turnos, para iniciar el trámite de declarar la ausencia de una
persona.

### 2. Qué información tiene disponible

- Examinar la máquina de turnos: no entrega números; un cartel pegado sobre el visor explica el
  motivo en lenguaje administrativo.
- Examinar el cartel de normas: pista visual — toda declaración de ausencia requiere acreditar
  presencia previa.
- Hablar con la Recepcionista: puede preguntársele directamente qué hace falta.
- El loro institucional repite avisos ambientales que mencionan la constancia de presencia como
  requisito obligatorio, reforzando la pista sin resolverla por el jugador.
- El formulario ya está visible sobre el mostrador — no hace falta encontrarlo en otra escena.

### 3. Solución (objetos/diálogos/acciones concretas)

1. Examinar la máquina de turnos → estado `MAQUINA_EXAMINADA`. Da la primera pista textual (no
   entrega números, exige constancia de presencia) sin resolver el paso siguiente.
2. Hablar con la Recepcionista → diálogo corto revela explícitamente el requisito → estado
   `REQUISITO_DESCUBIERTO`.
3. Interactuar con el Formulario sobre el mostrador → Nicanor lo completa in situ (una línea
   cómica sobre la vaguedad del trámite) → estado `DECLARACION_OBTENIDA`. No se implementa como
   objeto de inventario: es una acción puntual con un formulario que ya está en la escena, evitando
   un sistema de inventario que el MVP no necesita.
4. Interactuar con la máquina de turnos (ahora con la declaración conseguida) → la máquina la
   procesa automáticamente → estado `DECLARACION_USADA` → inmediatamente entrega el turno número 0
   → estado `TURNO_0_RECIBIDO`.
5. Hablar otra vez con la Recepcionista → el intercambio "el cero ya fue llamado antes de empezar /
   corresponde a mañana" → una contradicción reglamentaria hace que la Recepcionista autorice el
   paso de todos modos → estado `ACCESO_AUTORIZADO`.
6. Interactuar con la puerta (ahora desbloqueada) → cierra la escena: línea melancólica breve de
   Nicanor + remate del loro → estado `ESCENA_TERMINADA`.

### 4. Pistas disponibles y dónde aparecen

- Cartel de normas (examinar, disponible desde el inicio): pista visual temprana.
- Loro institucional (interactuar/observar, en cualquier momento antes de `REQUISITO_DESCUBIERTO`):
  refuerza ambientalmente la misma pista sin adelantarse a la Recepcionista.
- Recepcionista (hablar, paso 2): confirma el requisito de forma explícita y definitiva.
- Máquina de turnos (examinar, paso 1): plantea el problema que dispara la búsqueda de la pista.

Cada paso del puzle está anticipado por al menos una de estas fuentes — ningún paso depende de
ensayo arbitrario.

### 5. Respuestas a intentos incorrectos

- Interactuar con la máquina antes de `DECLARACION_OBTENIDA`: mensaje específico según el estado
  actual (antes de examinarla explica que no entrega números; después de examinarla pero antes de
  hablar con la Recepcionista reitera el motivo; después de `REQUISITO_DESCUBIERTO` recuerda que
  falta completar el formulario) — nunca un mensaje genérico ni silencio.
- Hablar con la Recepcionista fuera de orden (por ejemplo, antes de examinar la máquina): variante
  de diálogo que igual revela el requisito, sin forzar al jugador a examinar la máquina primero —
  no hay un único orden obligatorio entre "examinar máquina" y "hablar con Recepcionista" para
  llegar a `REQUISITO_DESCUBIERTO`.
- Interactuar con el Formulario una segunda vez: línea distinta reconociendo que ya está completado
  — no repite la primera reacción.
- Hablar con la Recepcionista repetidamente en el mismo estado: variantes cortas de "esperá su
  turno" en vez de repetir la línea o quedar en silencio.

### 6. Estados bloqueados o imposibles a evitar (softlocks)

Ninguno. Todas las interacciones clave son repetibles; no hay objetos consumibles que puedan
perderse ni ventanas de tiempo. El único recurso del puzle (la declaración) es un estado booleano
en `GameState`, no un objeto que pueda tirarse o quedar inaccesible. La puerta permanece bloqueada
con un mensaje informativo hasta `ACCESO_AUTORIZADO`, nunca de forma silenciosa.

## Historial

Este es el primer puzle completo del proyecto. La versión anterior de la escena prototipo (ver
`production/decisions.md`) era deliberadamente lineal, sin puzle, y quedó reemplazada por este
diseño con la aprobación explícita del usuario que amplió el alcance del MVP.
