# Dialogue Structure — El Ministerio de los Ausentes

- Status: Active
- Last updated: 2026-08-19
- Related docs: [narrative.md](narrative.md) (voz y canon), [puzzles.md](puzzles.md) (qué estado
  desbloquea qué), [../game/README.md](../game/README.md) (cómo agregar un diálogo, versión corta),
  [../production/decisions.md](../production/decisions.md)

## 0. Qué vive acá y qué no

Este documento es el **contrato de estructura** de las conversaciones: qué formas de dato existen,
cómo se elige qué se dice, qué variables hay, y cómo el texto viaja de la escritura a la build.

No duplica:

- **la voz de cada personaje** → `narrative.md` §"Perfiles de voz" y `characters/nicanor.md`;
- **qué hito narrativo corresponde a qué estado** → `puzzles.md` §3;
- **el texto canónico** → `game/data/dialogues/`, `game/data/hotspots/` y los strings exportados en
  `game/scenes/office/oficina_recepcion.tscn`. Nunca en este archivo.

Regla que ordena todo lo demás: **el texto es dato, la lógica es GDScript, y ninguno de los dos
invade al otro.** `office_scene_controller.gd` decide *cuándo* se habla; los JSON deciden *qué* se
dice. Un cambio de copy no debería tocar un `.gd` jamás.

## 1. Las tres formas de contenido, y cuándo usar cada una

| Forma | Dónde vive | Resuelve | Usarla cuando |
|---|---|---|---|
| **Conversación con ramas** | JSON con `"branches"` (`recepcionista.json`) | `DialogueManager.pick_branch` | Hay varias líneas seguidas, cambio de hablante, opciones, o la charla **empuja el estado** |
| **Texto por estado** | JSON con un dict `ESTADO -> texto` (`loro.json`, `maquina_turnos.json`) | `DialogueManager.pick_state_text` | Una sola línea que cambia con el progreso, sin conversación ni efectos |
| **String fijo en el `.tscn`** | `observe_text` / `interact_text` / `interact_text_alt` del `Hotspot` | El controlador lo pasa directo | La línea **nunca** cambia con el estado (utilería, chistes de fondo) |

Criterio de ascenso: un hotspot arranca como string fijo; en cuanto necesita **una segunda variante
que dependa del estado**, se muda a `data/hotspots/` (como la Máquina). No hay forma intermedia:
`interact_text_alt` es un escape para un único "ya está hecho", no una máquina de estados de dos
entradas.

Criterio inverso, igual de importante: **no promover a `branches` algo que no ramifica.** El Loro
tiene trece consignas repartidas en siete estados y sigue siendo un dict plano, porque nunca
conversa.

## 2. Esquema — conversación con ramas

```json
{
  "branches": [
    {
      "id": "turno_cero",
      "min_state": "TURNO_0_RECIBIDO",
      "max_state": "TURNO_0_RECIBIDO",
      "lines": [
        { "speaker": "Nicanor", "text": "...", "pose": "escepticismo" },
        { "choice": [ { "text": "...", "pose": "neutral" } ] }
      ],
      "effects": { "set_state": "ACCESO_AUTORIZADO" }
    }
  ]
}
```

| Campo | Obligatorio | Reglas |
|---|---|---|
| `id` | sí por convención | `snake_case`. No lo lee el motor hoy — lo leen los tests y las personas. Único dentro del archivo |
| `min_state` / `max_state` | no | Nombres exactos del enum `GameState.State`. **Límites inclusive.** Omitir = sin límite de ese lado |
| `lines` | sí | Array de líneas, o de una entrada `choice` |
| `effects.set_state` | no | Se aplica **al terminar la rama entera**, no línea por línea |

### Cómo se elige la rama (y por qué el orden del array importa)

`pick_branch` devuelve **la primera rama cuyo rango contiene el estado actual**. No hay prioridad,
ni peso, ni "la más específica gana": gana la que está más arriba en el archivo. Dos ramas con
rangos solapados son legales, y la segunda queda muerta en silencio.

Consecuencias para quien escribe:

- **El archivo se ordena de más temprano a más tardío.** Es la única defensa contra el solapamiento.
- Una rama sin `min_state` ni `max_state` es un catch-all: solo puede ir última.
- `post_autorizado` (`min_state` sin `max_state`) cubre a propósito `ACCESO_AUTORIZADO` **y**
  `ESCENA_TERMINADA`. Si alguna vez hace falta una línea distinta para el final, hay que agregarle
  un `max_state` **y** poner la nueva rama después.

### Líneas

| Campo | Valores |
|---|---|
| `speaker` | Vocabulario **cerrado**: `"Nicanor"`, `"Recepcionista"`, `"Loro"`, o `""` (narrador) |
| `text` | El texto. Ver §6 para longitudes |
| `pose` | Solo tiene efecto si `speaker` es `"Nicanor"`: `"neutral"`, `"explicacion"`, `"escepticismo"`, `"recitado"`. Omitir = `neutral` |

`speaker` no es decorativo: maneja el retrato, pone a la Recepcionista en pose de habla y al Loro en
`hablando`. **Un `speaker` mal escrito no falla: degrada en silencio** — sin retrato, todos en idle,
y Nicanor forzado a `pose_neutral`. Lo mismo un `pose` inválido: `_apply_speaker_state` arma
`"pose_%s"` y una animación inexistente no llega a la pantalla. Ambos vocabularios son cerrados
justamente por eso.

Una línea sin `speaker` es voz de narrador (sin retrato, sin nombre). Es la forma correcta para
descripciones — "La máquina traga la constancia con un crujido satisfecho" — y la forma incorrecta
para algo que un personaje dice en voz alta.

## 3. Esquema — texto por estado

```json
{ "idle_by_state": { "INICIO": ["variante A", "variante B"], "ACCESO_AUTORIZADO": "..." } }
```

- Clave = nombre exacto del enum. Valor = string, **o array de variantes** (se elige una al azar en
  cada interacción).
- **`pick_state_value` camina hacia atrás** hasta el estado anterior más cercano que sí tenga
  entrada. Un estado sin línea propia hereda; nunca queda en blanco. Por eso `loro.json` puede
  omitir `DECLARACION_USADA` sin dejar un hueco.
- La herencia es una comodidad, no una excusa: si el texto heredado **miente** en el estado nuevo
  (ej. "Presente la constancia en la máquina" después de haberla presentado), hay que escribir la
  entrada. Que no esté vacío no significa que sea correcto.
- El array de variantes es para color ambiental repetible (el Loro). No lo uses para información de
  puzle: el jugador no debería tener que hacer clic varias veces para ver la pista.

### Remates del Loro (`remate_by_state`)

Segundo diccionario de `loro.json`, con **semántica distinta al resto de los `*_by_state`**: se
consulta por **coincidencia exacta**, sin el camino hacia atrás de `pick_state_value`. Un estado
sin remate propio tiene que quedarse callado, no repetir el remate del hito anterior.

Lo dispara `office_scene_controller.gd` en `state_changed`, pero **no lo dice en ese momento**: lo
anota y lo suelta cuando la cola de líneas se vacía. Los hitos cambian el estado en dos momentos
distintos — antes de mostrar su propio texto (el observar de la máquina) o después, dentro del
`on_done` de una rama — y esperar a que la cola se vacíe es lo único correcto para los dos.

Reglas de contenido:

- **Uno por hito, y todos distintos.** Un remate repetido se lee como un bug, no como un chiste
  recurrente. El test lo verifica.
- **`INICIO` y `ESCENA_TERMINADA` no llevan remate.** Al primero no se entra nunca; en el segundo
  ya suena `remate_final` y un segundo loro le pisaría el cierre emocional.
- **Nunca información de puzle.** El remate comenta el hito que ya pasó; si el jugador lo saltea de
  un clic no debe perderse nada.

## 4. Variables y estado

**Hay exactamente una variable: `GameState.current`, un enum ordinal de 8 valores.** No hay flags,
ni contadores, ni inventario, ni memoria de conversación. Es una decisión, no una carencia: el MVP
tiene un puzle lineal y una escena, y un sistema de variables sin nada que variar es deuda.

Tres reglas duras que salen de eso:

1. **El orden del enum es carga estructural.** `is_at_least` y todo `min_state`/`max_state` comparan
   ordinalmente. Insertar o reordenar un estado en el medio **re-apunta en silencio todos los rangos
   de todos los JSON**. Los estados nuevos se agregan al final, o se auditan los rangos a mano.
2. **El estado solo avanza.** No hay transición hacia atrás fuera de `reset()`. El contenido puede
   asumirlo: no hace falta escribir una rama para "volvió a un estado anterior".
3. **Nada de estado dentro del JSON.** `effects` solo entiende `set_state`. Si una conversación
   necesita recordar algo que no sea el progreso del puzle, eso es una extensión del sistema, no un
   dato nuevo en el archivo.

### Lo que hoy no se puede expresar (y no se debe simular)

- "Es la primera vez que escucha esto" / "ya lo escuchó tres veces".
- "Eligió la opción sarcástica antes".
- Dos hilos de progreso en paralelo (dos puzles abiertos a la vez).

La tentación es codificarlos como estados extra del enum. **No hacerlo**: el enum es el progreso del
puzle, y ensancharlo con condiciones no lineales rompe la comparación ordinal de la que dependen
todos los rangos. Si alguno hace falta, la extensión correcta está en §8.

## 5. Ramificación real vs. opciones

Conviene ser preciso, porque el sistema tiene dos cosas distintas que parecen la misma:

- **La ramificación real es por estado.** Con qué rama te encontrás depende de cuánto avanzaste. Ahí
  vive toda la variación con consecuencia.
- **Las opciones (`choice`) son de caracterización, no de rama.** Todas las opciones de una entrada
  `choice` convergen: el motor aplica la `pose` elegida y sigue con la misma línea siguiente. No hay
  `effects` por opción, ni saltos, ni memoria de lo elegido.

Esto está bien para lo que el juego quiere — Nicanor se define por *cómo* contesta, no por lo que
consigue contestando — pero hay que escribirlas sabiéndolo:

- **Las opciones nunca prometen consecuencia.** Ninguna puede sugerir información distinta, un
  atajo, ni un riesgo. Si dos opciones no son intercambiables desde el punto de vista del trámite,
  la opción está mintiendo.
- **Dos opciones, dos actitudes.** El par existente ("Si hubiera venido, no sería una ausencia." /
  "No. Por eso estoy acá y no en otro lado.") es el modelo: misma información, distinto grado de
  soberbia.
- **La opción elegida no se vuelve a mostrar.** El texto del botón ya *es* la línea de Nicanor
  (`decisions.md`). Escribila como diálogo terminado, no como resumen de intención: "Pregunto qué
  falta" está mal; "¿Qué me falta?" está bien.
- **Pocas por conversación.** `narrative.md` ya lo pide; acá se fija el número: **como máximo una
  entrada `choice` por rama**, y solo en ramas que el jugador ve una vez.

## 6. Invariantes que el contenido debe cumplir

Chequeos que valen para cualquier diálogo nuevo. Los marcados ✅ ya los verifica
`puzzle_flow_test`; los ⚠️ hoy dependen de la revisión humana.

1. ✅ **Cobertura total de estados.** Todo dict `*_by_state` resuelve texto no vacío para los 8
   estados (herencia incluida).
2. ⚠️ **Ninguna conversación puede quedar muda.** Si `pick_branch` devuelve `{}`,
   `_handle_recepcionista_interact` retorna sin abrir la caja: clic sin respuesta, que `puzzles.md`
   §5 prohíbe explícitamente. **Toda la escala de estados tiene que estar cubierta por alguna
   rama.** Ver §9, hallazgo 1 — hoy no lo está.
3. ⚠️ **Nada se repite palabra por palabra.** `puzzles.md` §5 pide variantes cortas al insistir; el
   motor hoy reproduce la misma rama idéntica. Mientras eso siga así, las ramas repetibles (las de
   recordatorio) se escriben para **tolerar** la repetición: cortas, de una línea, sin chiste que se
   gaste al segundo pase. Las ramas largas van solo en estados de los que se sale al terminarlas.
4. ⚠️ **Ninguna rama larga sin salida.** Una rama de más de dos líneas debería llevar
   `effects.set_state`, o quedar acotada por `max_state` a un estado del que se salga por otra vía.
   Si no, el jugador la puede volver a disparar entera.
5. ⚠️ **Vocabularios cerrados.** `speaker` y `pose` solo con los valores de §2.
6. ⚠️ **Doble verbo respondido.** Todo hotspot contesta al clic izquierdo *y* al derecho. Repetir el
   mismo texto en ambos es legal para utilería (Mostrador, Cartel, Planta, Sello) pero es la opción
   pobre: donde hay un remate físico, la interacción merece línea propia — Ventilador y Reloj son el
   modelo.

### Longitudes (medidas contra la caja real, no estimadas)

Viewport 1280×720. El panel deja ~1004 px de ancho de texto con retrato y ~200 px de alto, a cuerpo
24 → **~83 caracteres por renglón, 6 renglones antes de desbordar**. El texto más largo hoy tiene
106 caracteres (2 renglones).

| | Objetivo | Tope duro |
|---|---|---|
| Línea de diálogo | ≤ 120 caracteres (2 renglones) | 240 |
| Texto de observación | ≤ 120 | 240 |
| Texto de un botón de opción | ≤ 70 (un renglón) | 100 |
| Opciones por `choice` | 2 | 3 |

El tope duro es dónde se rompe la caja; el objetivo es dónde vive la voz. `narrative.md` pide frases
cortas y sin monólogos, y la mediana actual de la Recepcionista son 17 caracteres — el presupuesto
es un techo, no una meta.

### Convenciones de puntuación y forma

- **El Loro va entre comillas dobles escapadas** (`"\"Vuelva mañana.\""`). No es un capricho de
  formato: marca que reproduce un aviso institucional en vez de hablar. Sus repeticiones dobles
  ("Buenas tardes. Buenas tardes.") son parte de la voz, no un error de copiado.
- **La máquina y los carteles también van entre comillas** cuando el texto es lo que está impreso
  ahí (`"\"ERROR: falta constancia de presencia.\""`), y sin comillas cuando es la descripción del
  narrador.
- Español rioplatense. La Recepcionista **ustedea** a Nicanor siempre: es la distancia del
  mostrador, y perderla le saca el chiste a la escena.
- Sin signos de exclamación salvo que un personaje realmente grite. El registro de la escena es
  administrativo.

## 7. Pipeline: de la escritura a la build

1. **Encuadre.** Antes de escribir: qué estado(s) cubre, qué hotspot lo dispara, si empuja el
   estado. Si el diálogo desbloquea progreso, el paso correspondiente ya tiene que estar en
   `puzzles.md` §3 — el texto no inventa pasos de puzle.
2. **Escritura, en el JSON directamente.** No hay documento intermedio: `game/data/` es el original,
   no una copia de algo que vive en `design/`. Un borrador provisional se marca en
   `production/decisions.md`, no dentro del archivo.
3. **Cableado, solo si hace falta.** Texto nuevo en un archivo existente = cero GDScript. Hotspot
   nuevo que conversa = un `case` en `_resolve_hotspot` (`game/README.md` §"Cómo agregar un
   hotspot"). Si escribir una línea obliga a tocar lógica, casi siempre el contenido está en la
   forma equivocada (§1).
4. **Import.** Assets nuevos o `class_name` nuevos: `godot --headless --path game --import` antes de
   correr nada. Un JSON solo no lo necesita.
5. **Validación automática.** `godot --headless --path game res://tests/puzzle_flow_test.tscn
   --quit-after 60` → `PUZZLE FLOW TEST: OK`. Cubre parseo, cobertura de estados, mapa estado→rama,
   y el efecto de `turno_cero`. **No** cubre longitudes, vocabularios, ni repetición.
6. **Extender el test junto con el contenido.** Una rama nueva se agrega a la tabla `expectations`
   de `_check_recepcionista_branches` en el mismo commit. Ese mapa es la especificación ejecutable
   de §2: si el contenido crece y el mapa no, la cobertura de estados se vuelve decorativa.
7. **Playtest manual.** Los tests no hacen clic. Desbordes de caja, retratos que no salen, poses que
   no cambian y repeticiones que molestan solo se ven jugando: `game/docs/PLAYTEST.md`.
8. **Documentos vivos.** Si el diálogo cambió un hito del puzle → `puzzles.md`. Si estableció un
   hecho narrativo → `narrative.md` / `game-bible.md`. Si hubo una decisión de criterio →
   `production/decisions.md`.

Localización: **fuera de alcance** (`current-scope.md`). El sistema no la impide — todo el texto ya
está en dato y fuera de GDScript, que es el 90% del trabajo — pero no se agregan claves, ni tablas
de idioma, ni `tr()` hasta que se apruebe. Ramificar de más hoy multiplica ese costo mañana: es otro
argumento para mantener las opciones convergentes (§5).

## 8. Extensiones evaluadas y no aprobadas

Ninguna de estas está implementada. Se registran acá para que la próxima persona no las rediseñe
desde cero, y **ninguna se construye sin aprobación explícita del usuario**.

- **`effects` por opción** (`{"text": "...", "effects": {...}}`): daría elección con consecuencia.
  Es un cambio chico en `_on_choice_selected`. Se descarta hoy porque ningún puzle aprobado lo
  necesita y porque duplicaría el costo de traducción y de QA de cada conversación.
- **Ramas vistas (`seen_branches`)**: un `Dictionary` en `GameState`, **no ordinal y no
  persistido**, para habilitar variantes de "ya te lo dije" (invariante 3 de §6). Es la extensión
  más chica que cierra la brecha real entre `puzzles.md` §5 y la implementación. Recomendada si se
  vuelve a tocar este sistema.
- **`lines` alternativas dentro de una rama** (array de arrays, se elige uno): más barato que
  `seen_branches`, pero sin control de cuál toca — sirve para color, no para "esto ya lo
  escuchaste".
- **Condiciones compuestas** (`requires`, `unless`, expresiones): rechazada. Introduce un lenguaje
  de scripting dentro del JSON, que es exactamente lo que la separación dato/lógica quiere evitar.

## 9. Hallazgos sobre el contenido actual

Detectados al escribir este contrato. La pasada de revisión de diálogos del 2026-08-19 (ver
`production/decisions.md`) cerró los tres primeros; los dos últimos siguen abiertos.

1. ~~**`DECLARACION_USADA` no tenía rama de la Recepcionista.**~~ **Cerrado.** `pick_branch`
   devolvía `{}` en ese estado y hablarle no hacía absolutamente nada — inalcanzable en la
   práctica, pero el test enumeraba 7 de los 8 estados y omitía justo ese. `reminder_use_machine`
   ahora llega hasta `DECLARACION_USADA` y el test cubre los 8.
2. ~~**`loro.json` no distinguía `DECLARACION_USADA`**~~ **Cerrado de rebote.** Heredába
   "Presente la constancia en la máquina", que en ese instante ya era falso. El texto heredado hoy
   es una consigna atemporal, así que la herencia dejó de mentir.
3. ~~**Cuatro hotspots repetían el mismo texto en ambos verbos.**~~ **Cerrado salvo uno.**
   Mostrador, Planta y Sello tienen línea de interacción propia. El Cartel de normas conserva el
   mismo texto a propósito: es la pista escrita del puzle y tiene que decir lo mismo se lo mire o
   se lo toque.
4. **`interact_text_alt` del Formulario sigue siendo inalcanzable** — el hotspot se apaga al
   completarlo (`decisions.md`, 2026-08-19). Se conserva a propósito como red de seguridad; queda
   anotado para que no se lea como contenido activo.
5. **Ninguna variante de insistencia en la Recepcionista.** `puzzles.md` §5 promete "variantes
   cortas de esperar su turno"; sus ramas de recordatorio se repiten idénticas. El Loro sí tiene
   dos consignas por estado, que cubre el caso ambiental, pero la promesa de `puzzles.md` es sobre
   ella. O se implementa `seen_branches` (§8), o conviene corregir `puzzles.md` para que no prometa
   algo que el sistema no da. **Es la única brecha viva entre diseño e implementación.**
