# Art Bible — Ministerio de los Ausentes

- Status: Active (biblia creativa completa; primer set de assets reales en integración)
- Related docs: [game-bible.md](game-bible.md), [../production/current-scope.md](../production/current-scope.md)

## Direction

2D ilustrada, expresiva y pictórica — no vectorial moderna, no animación infantil, no pixel art.
Debe transmitir la sensación de una aventura gráfica clásica hecha con ilustraciones artesanales.

Características visuales:

- Línea visible e irregular.
- Texturas de papel, madera, metal pintado y paredes envejecidas.
- Personajes con siluetas claras, legibles a distancia de juego.
- Expresiones faciales legibles.
- Fondos ricos en detalles examinables, sin ocultar los elementos interactivos.
- Perspectiva ligeramente exagerada/deformada (no fotorrealista).
- Objetos cotidianos deformados por décadas de reparación y uso.
- Composición teatral que permita leer claramente los espacios interactivos.
- Animación limitada pero llena de personalidad.
- Iluminación cálida y decadente — admite melancolía, pero deja espacio visual para la comedia; no
  todo debe ser oscuro, lluvioso o miserable.
- Arquitectura pública monumental — el Ministerio debe sentirse más grande que las personas que lo
  habitan.
- Vestuario humano mal adaptado a anatomías animales (uniformes, trajes) — fuente visual de humor y
  de la sátira burocrática.
- Publicidad corporativa invasiva como detalle ambiental recurrente.

## Paleta y luz

- Verdes burocráticos apagados, marrones, ocres, beige de papeles viejos, gris verdoso.
- Rojo oscuro para sellos, corbatas y señales de autoridad.
- Amarillos cálidos de lámparas antiguas.
- Los colores más vivos se reservan para elementos importantes: un documento, una pluma, una
  planta, un objeto ligado a la madre de Nicanor, o una anomalía dentro del sistema — el color es
  señal narrativa, no solo decoración.
- Iluminación imperfecta: tubos fluorescentes que no iluminan uniformemente, lámparas de
  escritorio, ventanas altas con luz exterior, sectores demasiado iluminados junto a rincones casi
  olvidados, pequeños cambios de luz que acompañan los momentos poéticos.

## Arquitectura y ambientación argentina

La identidad argentina aparece integrada en los espacios, nunca por acumulación de banderas,
escarapelas, mates o referencias futbolísticas — se siente en la arquitectura, el lenguaje, los
ritmos laborales, la improvisación y la convivencia cotidiana con sistemas que funcionan de manera
incompleta.

Referencias posibles: edificios públicos de distintas épocas reformados sin coherencia, mármol
gastado, ventanillas con vidrio, mostradores de madera, sillas de sala de espera desparejas,
radiadores antiguos, ventiladores, persianas, ficheros metálicos, matasellos, formularios
fotocopiados muchas veces, carpetas atadas con hilo, carteles impresos corregidos a mano y pegados
sobre carteles anteriores, máquinas expendedoras de números, ascensores con placas de habilitación
vencidas, facturas de servicios, dispensadores de agua vacíos, plantas de oficina resistentes al
abandono, sobres, sellos, papeles carbónicos.

## Diseño visual del Ministerio

El edificio debe parecer más grande que cualquier persona que trabaje allí. Los espacios mezclan
grandiosidad estatal, abandono, reformas corporativas baratas, tecnología moderna instalada sobre
infraestructura antigua, señalética contradictoria, sectores privatizados o patrocinados.

Ejemplos: una placa de bronce junto a una pantalla rota; un busto cubierto con una bolsa para
evitar que acumule polvo; un mostrador histórico convertido en espacio publicitario; una máquina
moderna conectada a una zapatilla eléctrica antigua; un cartel que promete atención personalizada
sobre una ventanilla cerrada; una sala cultural patrocinada por una compañía de gas; una oficina de
"Experiencia del Ausente"; indicadores de productividad que nadie comprende; retratos
institucionales en los que algunos nombres fueron raspados.

## Los nombres borrados

La desaparición de nombres tiene una evolución visual gradual — nunca mágica ni espectacular;
silenciosa, administrativa, casi imperceptible. Eso la vuelve más inquietante. Reservada para
escenas futuras más allá del prototipo actual; no introducir sin aprobación explícita del alcance.

**Primer nivel:** una letra ausente, tinta corrida, una etiqueta despegada, un apellido corregido,
un casillero vacío.

**Segundo nivel:** documentos completos sin nombre, fotografías cuyos epígrafes fueron retirados,
empleados incapaces de recordar a un compañero, puertas que ya no indican quién trabaja detrás,
expedientes que remiten a otros expedientes inexistentes.

**Tercer nivel:** retratos con espacios difíciles de percibir, habitaciones que parecen haber
pertenecido a alguien, conversaciones que se interrumpen al intentar pronunciar ciertos nombres,
registros que modifican retrospectivamente la historia, personajes que comienzan a dudar de sus
propios recuerdos.

## Poesía y metáfora visual

El Ministerio clasifica, define y reduce; la poesía relaciona cosas que el sistema intenta mantener
separadas. Puede expresarse visualmente mediante: papeles que conservan marcas o palabras
borradas, objetos personales dentro de archivos impersonales, pájaros que cantan mientras las
máquinas emiten consignas, una planta que crece en un espacio archivado, luz natural entrando en
habitaciones destinadas a documentos muertos, una palabra manuscrita sobreviviendo debajo de un
sello, fragmentos de poemas usados como separadores/anotaciones/claves, el nombre de una persona
repetido a mano para impedir que desaparezca.

La metáfora no es una mecánica permanente — se concentra en momentos puntuales de verdadero peso
narrativo, no en el prototipo actual.

## Explicit constraints

- No imitar directamente el estilo de un artista vivo.
- No reinterpretar personajes ya definidos una vez el diseño maestro está aprobado.
- Mantener escala, silueta, paleta y perspectiva consistentes entre assets, incluso siendo
  placeholders.
- Todo asset se prueba dentro de la escena antes de aprobarse — nunca aislado.
- No producir elementos decorativos sin considerar su función narrativa o interactiva.

## Indicaciones para generación de arte

Antes de generar cualquier imagen:

1. Revisar todos los diseños maestros aprobados.
2. Mantener constantes especie, anatomía, proporciones, ropa y paleta.
3. No reinterpretar personajes ya definidos.
4. Usar fondos transparentes en sprites.
5. Separar personajes, props y escenarios.
6. Mantener una escala coherente entre assets.
7. Preservar una dirección de luz común.
8. Diseñar siluetas que funcionen dentro del escenario real.
9. Evitar texto generado dentro de las imágenes — la cartelería se agrega después en el motor.
10. No producir elementos decorativos sin considerar su función narrativa o interactiva.

Cada fondo debe incluir tres niveles de lectura: **inmediata** (recorrido, personajes, objetivo),
**interactiva** (hotspots y objetos examinables), **narrativa** (detalles que revelan la historia
del Ministerio).

## Provenance — assets actuales

Fuente: ilustraciones entregadas por el usuario en `ejemplo/` (ver `game/TODO_ASSETS.md` para el
mapeo completo a `game/assets/` y las limitaciones conocidas de cada archivo, incluyendo los que
todavía requieren un recorte de fondo más prolijo). Cada asset nuevo, incluso placeholder, debe
registrar de dónde salió y su versión cuando `/art-pass` lo introduce o reemplaza — ver
`commands/art-pass.md`.
