# Manifiesto de assets

## Listos o preferidos para uso

| Archivo | Contenido | Uso sugerido |
|---|---|---|
| `backgrounds/scene_master_reference.png` | Composición maestra con personajes | Referencia visual, no fondo jugable |
| `backgrounds/scene_background_clean.png` | Arquitectura sin personajes ni elementos con estado | Único fondo jugable |
| `characters/nicanor/nicanor_master.png` | Diseño aislado | Referencia de identidad y escala |
| `characters/nicanor/nicanor_walk_right_6_frames.png` | Caminata lateral | `SpriteFrames`, seis columnas |
| `characters/nicanor/nicanor_dialogue_4_poses.png` | Cuatro poses de diálogo | Estados de diálogo |
| `characters/carpincho/carpincho_master_bust.png` | Diseño original | Referencia de identidad |
| `characters/carpincho/carpincho_fullbody_6_poses.png` | Seis poses completas | Fuente principal del NPC |
| `characters/carpincho/carpincho_bust_6_poses.png` | Variantes detrás del mostrador | Alternativa para primeros planos |
| `characters/loro/parrot_master_clean.png` | Loro institucional aislado | Pose principal |
| `characters/loro/parrot_6_states_clean.png` | Seis estados del loro | Idle y diálogo |
| `ambient/ceiling_fan_4_frames.png` | Giro del ventilador | Loop ambiental lento |
| `props/props_master_reference.png` | Lámina original de objetos | Referencia de diseño |
| `props/ticket_dispenser_clean.png` | Dispensador aislado | Prop o referencia individual |
| `props/stamp_and_chain_clean.png` | Sello encadenado aislado | Prop interactivo |
| `interactive/ticket_machine_3_states_clean.png` | Apagada, encendida e imprimiendo | Estados del puzzle |
| `interactive/door_3_states_clean.png` | Cerrada, desbloqueada y abierta | Progreso y cierre de demo |
| `interactive/status_board_3_states_clean.png` | Apagado, ámbar y rojo | Feedback institucional |

## Control de calidad realizado

- Se eliminaron las viñetas y píxeles semitransparentes residuales.
- Los PNG se verificaron sobre fondo magenta de alto contraste.
- Se preservaron las dimensiones originales de las láminas para mantener sus celdas.
- Las fuentes defectuosas y variantes con damero no forman parte de este paquete.
- El fondo principal no contiene puerta, máquina, cartel, ventilador ni sello; estos existen solo como capas independientes.

## Reglas

- No usar el damero visible como transparencia.
- Los textos de carteles y pantallas se agregan en Godot.
- No mezclar frames de láminas con escalas distintas sin normalizarlos.
- No volver a recortar ni regenerar los archivos con sufijo `_clean`.
- Mantener las dimensiones originales antes de configurar `SpriteFrames`.
- No usar `scene_master_reference.png` como fondo en ejecución: provocaría duplicación visual de los elementos interactivos.
