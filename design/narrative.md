# Narrative — El Ministerio de los Ausentes

- Status: Active (biblia creativa completa — ver [game-bible.md](game-bible.md) para el canon
  narrativo íntegro)
- Related docs: [game-bible.md](game-bible.md), [characters/nicanor.md](characters/nicanor.md),
  [puzzles.md](puzzles.md), [dialogue-structure.md](dialogue-structure.md)

## Canonical premise

Nicanor Sosa es una calandria que trabaja en el Ministerio de los Ausentes e intenta resolver un
trámite relacionado con su madre ausente. En este mundo las personas no desaparecen solo de manera
física: primero desaparecen de los registros — un nombre borrado de una ficha, un expediente, una
placa, una fotografía o la memoria administrativa. Ver [game-bible.md §2](game-bible.md) para el
desarrollo completo; no explicar esta metáfora mediante discurso directo dentro de una escena — se
comprende observando sus consecuencias.

`/dialogue` no debe inventar hechos narrativos que contradigan `game-bible.md` sin aprobación, pero
sí puede escribir texto provisional dentro de los hechos ya establecidos, marcado como provisional.

## Voice rules

- Frases cortas; evitar monólogos explicativos.
- Pocas opciones de diálogo por conversación.
- Voz particular para cada personaje (ver perfiles abajo y en `characters/`).
- Dejar que el jugador descubra el mundo — no explicar los símbolos.
- Alternar humor, información y pequeños silencios; no convertir a todos los personajes en
  comediantes.
- Evitar solemnidad constante y referencias políticas demasiado directas.
- Evitar exposición política directa — la sátira funciona por implicación.
- Diálogos separados de la lógica de juego (ver `game/resources/dialogue/` y `game/data/dialogues/`)
  para que se puedan reescribir sin tocar GDScript.
- Cuando exista una duda entre una idea compleja y una solución sencilla, elegir la solución que
  produzca una escena más clara, jugable y memorable.

## Perfiles de voz — escena activa

- **Nicanor**: seco, contenido, precisión sobre chiste explícito; cobarde y vanidoso — eso es lo
  que lo vuelve gracioso, no su ingenio. Ver `characters/nicanor.md`.
- **Recepcionista (carpincho)**: agotado, correcto, trata cada regla delirante como un
  procedimiento normal. Nunca explica el sentido político de la escena.
- **Loro institucional**: repite consignas oficiales, avisos y frases contradictorias como si
  fueran verdades naturales — no comenta, no razona, solo reproduce. Sus consignas cambian con
  los hitos del puzle, y **cierra cada hito con un remate propio sin que el jugador lo toque**:
  es el altoparlante de la sala, no un personaje al que haya que ir a buscar. Nunca es un puzle
  independiente ni da información que el jugador necesite para avanzar — si su línea desapareciera,
  el puzle seguiría siendo resoluble.

## Escena activa: Recepción del Ministerio de los Ausentes

Reemplaza la escena de demostración anterior ("Oficina de Licencias Poéticas"), que era un
placeholder lineal sin puzle — ver `production/decisions.md` para el registro del cambio. Debe
establecer inmediatamente: quién es Nicanor, qué necesita, cómo funciona el humor, qué clase de
institución es el Ministerio, la existencia de nombres o personas que dejan de figurar (apenas
insinuada, no explicada), y el contraste entre lenguaje administrativo y pérdida humana.

**Nicanor entra diciendo que viene a inscribirse en el concurso de poesía** — la Recepcionista le
pregunta si es el de Poesía Productiva ([game-bible.md §4](game-bible.md)) y lo despacha en dos
líneas: hubo otro concurso y no rindió, y las inscripciones son por Cultura, que cerró por
improductiva. Recién después de ese desaire dice a qué vino en serio. Es caracterización y siembra
de la subtrama, **no un segundo objetivo**: el concurso no se puede tramitar en esta escena y no
toca el puzle. Que Nicanor no arranque por la ausencia es deliberado — la vanidad va primero y lo
que de verdad le importa queda segundo, que es exactamente su carácter
([characters/nicanor.md](characters/nicanor.md)).

**Objetivo inmediato de Nicanor:** conseguir un número de la máquina de turnos para iniciar un
trámite relacionado con una persona ausente.

**Obstáculo:** la máquina exige una "constancia de presencia" para tramitar una ausencia.

**Resolución:** ver el diseño de puzle completo, con las seis secciones requeridas por
`puzzles.md`, en [puzzles.md](puzzles.md#puzle-activo--constancia-de-presencia).

**Cierre de la escena:** una línea melancólica y sutil de Nicanor que sugiere el tema de la
ausencia (sin explicarlo), seguida de un remate breve del loro. No debe explicar todavía la
conspiración completa ni la historia de la madre — esta escena es la puerta de entrada, no la
revelación.

El **contrato de estructura** de esas conversaciones — esquema de los JSON, cómo se elige la rama,
qué variables existen, presupuestos de longitud y pipeline de escritura — vive en
[dialogue-structure.md](dialogue-structure.md). Acá va la voz; allá, la forma.

Texto canónico completo (líneas de diálogo, variantes, condiciones) vive en
`game/data/dialogues/` — no en este archivo ni en GDScript. Ver `game/data/dialogues/recepcionista.json`
y `game/data/dialogues/loro.json`.

## Elementos retirados de la escena anterior

La conversación "licencia poética" (`game/resources/dialogue/oficina_licencias.json`) queda
retirada del flujo activo — no era canon narrativo, era contenido de demostración explícitamente
marcado como provisional en `production/decisions.md`. El archivo se conserva sin usar como
referencia histórica; no se borra sin que el usuario lo pida.
