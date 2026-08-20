# Playtest — Recepción del Ministerio de los Ausentes

- Status: Active
- Last updated: 2026-08-16

## Parte A — Verificación técnica (quien prueba conoce el proyecto)

Checklist para correr manualmente en el editor (esta sesión no tuvo acceso a una GUI de Godot; ver
`../../production/decisions.md` para qué se verificó en modo headless y qué queda pendiente acá).

1. **Carga de escenas y recursos**: abrir `main_menu.tscn` y `office/oficina_recepcion.tscn` en el
   editor — no debería haber íconos de error en el árbol de nodos ni en el panel de salida.
2. **Transiciones de estado**: jugar la secuencia completa del puzle (ver Parte C) y confirmar que
   cada paso ocurre una sola vez y en el orden esperado — usar el depurador remoto o un `print` (ya
   hay una prueba headless de esto en `tests/`, pero no reemplaza verlo correr con clics reales).
3. **Interacción fuera de alcance**: hacer clic en zonas del fondo sin hotspot — no debe pasar nada
   (Nicanor debe caminar hacia ahí si es piso caminable, o quedarse quieto si no lo es).
4. **Clics durante diálogos**: hacer clic repetidamente mientras hay texto en pantalla — no debe
   mover a Nicanor, disparar otro hotspot, ni saltar más de una línea por clic salvo el primer clic
   (que completa el typewriter) seguido de un segundo clic (que avanza).
5. **Texto acelerado**: confirmar que un clic durante la revelación del texto lo completa
   instantáneamente en vez de esperar a que termine solo.
6. **Reinicio**: usar el botón "Reiniciar" en cualquier momento (mitad de diálogo, mitad de puzle,
   pantalla final) y confirmar que la escena vuelve exactamente al estado inicial.
7. **Resolución completa del puzle**: seguir los pasos de la Parte C de punta a punta sin usar el
   editor ni la consola.
8. **Errores del depurador**: revisar el panel "Debugger → Errors" después de una partida completa
   — no debería haber errores ni warnings.

## Parte B — Guion de playtest con usuarios

No expliques de antemano cómo resolver el puzle. Sentá al jugador frente al juego después de la
pantalla de "Comenzar" y observá en silencio, tomando nota de dónde duda, dónde repite un clic sin
efecto, y qué dice en voz alta (si algo le hizo gracia, o lo confundió).

**Antes de empezar**, preguntá:
- ¿Jugaste antes alguna aventura point-and-click? ¿Cuáles?

**Durante la partida**, observá sin intervenir:
- ¿Cuánto tarda en entender que puede caminar haciendo clic en el piso?
- ¿En qué momento se da cuenta de que la máquina necesita algo? ¿Lo descubre por el cartel, por el
  loro, o hablando con la recepcionista?
- ¿Duda en algún punto sobre qué hacer a continuación? ¿Dónde exactamente?
- ¿Hace clic repetidamente en el mismo lugar esperando un resultado distinto?

**Después de terminar (o de 10 minutos, lo que pase primero)**, preguntá:
1. ¿En algún momento no supiste qué hacer? ¿Dónde?
2. ¿Hubo algún chiste que no entendiste, o que te pareció que no funcionaba?
3. Del 1 al 5, ¿qué tan claro te resultó el sistema de clics (caminar / interactuar)?
4. ¿Qué personaje te generó más curiosidad o simpatía? ¿Por qué?
5. ¿El tono del lugar (burocrático, absurdo) te resultó claro? ¿Cómo lo describirías con tus
   propias palabras?
6. ¿Hubo algún momento que te pareció triste o te cambió el tono de golpe? ¿Cuál?
7. ¿Reiniciarías para volver a ver algo puntual? ¿Qué?

## Parte C — Solución de referencia (no mostrar al jugador de prueba)

1. Hacer clic en la Máquina de turnos.
2. Hablar con la Recepcionista — revela que hace falta una constancia de presencia.
3. Interactuar con el Formulario del atril.
4. Interactuar con la Máquina de turnos — entrega el turno 0.
5. Hablar de nuevo con la Recepcionista.
6. Interactuar con la Puerta.

El Cartel de normas y el Loro dan la misma pista de forma ambiental antes del paso 2, así que el
orden 1↔2 no es estricto.
