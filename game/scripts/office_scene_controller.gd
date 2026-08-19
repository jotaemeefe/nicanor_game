extends Node2D

## Recepción del Ministerio de los Ausentes — active MVP scene controller.
## Owns hotspot wiring, the "constancia de presencia" puzzle flow driven by
## GameState, and the ending sequence. No dialogue/observation text lives
## here — see game/data/dialogues/, game/data/hotspots/, and the exported
## strings on each Hotspot instance in this scene's .tscn.

const RECEPCIONISTA_DIALOGUE_PATH := "res://data/dialogues/recepcionista.json"
const LORO_DIALOGUE_PATH := "res://data/dialogues/loro.json"
const FINAL_DIALOGUE_PATH := "res://data/dialogues/final.json"
const MAQUINA_HOTSPOT_DATA_PATH := "res://data/hotspots/maquina_turnos.json"

const CARP_IDLE := preload("res://assets/characters/recepcionista/carp_idle_new.png")
const CARP_HABLANDO := preload("res://assets/characters/recepcionista/carp_hablando_new.png")
const LORO_IDLE := preload("res://assets/characters/parrot/loro_2_halfopen.png")
const LORO_HABLANDO := preload("res://assets/characters/parrot/loro_4_squawk.png")

const MAQUINA_APAGADA := preload("res://assets/props/maquina_turnos/maquina_apagada.png")
const MAQUINA_ENCENDIDA := preload("res://assets/props/maquina_turnos/maquina_encendida.png")
const MAQUINA_IMPRIMIENDO := preload("res://assets/props/maquina_turnos/maquina_imprimiendo.png")

const PUERTA_CERRADA := preload("res://assets/props/puerta/puerta_cerrada.png")
const PUERTA_DESBLOQUEADA := preload("res://assets/props/puerta/puerta_desbloqueada.png")
const PUERTA_ABIERTA := preload("res://assets/props/puerta/puerta_abierta.png")

const CARTEL_APAGADO := preload("res://assets/props/cartel_estado/cartel_apagado_new.png")
const CARTEL_AMBAR := preload("res://assets/props/cartel_estado/cartel_ambar_new.png")
const CARTEL_ROJO := preload("res://assets/props/cartel_estado/cartel_rojo_new.png")

@onready var _nicanor: NicanorController = $World/Nicanor
@onready var _recepcionista_sprite: Sprite2D = get_node_or_null("World/Recepcionista/Sprite2D")
## Under LoroAnchor, not directly under Hotspots: the parrot sits on the counter
## in front of the window glass, so it needs a sort key past the window overlay
## while staying drawn (and clickable) up at the ledge — same reason as SelloAnchor.
@onready var _loro_sprite: AnimatedSprite2D = get_node_or_null("World/Hotspots/LoroAnchor/Loro/AnimatedSprite2D")
@onready var _formulario: Hotspot = get_node_or_null("World/Hotspots/Formulario")
@onready var _machine_sprite: Sprite2D = get_node_or_null("World/Hotspots/Dispensador/Sprite2D")
@onready var _door_sprite: Sprite2D = get_node_or_null("World/Hotspots/Puerta/Sprite2D")
## A PerspectiveQuad, not a Sprite2D: the board's art is frontal and the wall it
## hangs on recedes, so it needs a projective warp rather than a transform.
@onready var _cartel_estado_sprite: Polygon2D = get_node_or_null("CartelEstado")
@onready var _hotspots: Node2D = $World/Hotspots
@onready var _hover_label: Label = $UI/HoverLabel
@onready var _dialogue_box: DialogueBox = $UI/DialogueBox
@onready var _end_panel: Control = $UI/EndPanel
@onready var _restart_button: Button = $UI/TopBar/Reiniciar
@onready var _menu_button: Button = $UI/TopBar/Menu
@onready var _end_restart_button: Button = $UI/EndPanel/VBoxContainer/Reiniciar
@onready var _end_menu_button: Button = $UI/EndPanel/VBoxContainer/Menu

var _recepcionista_data: Dictionary = {}
var _loro_data: Dictionary = {}
var _final_data: Dictionary = {}
var _machine_data: Dictionary = {}

var _busy: bool = false
var _line_queue: Array = []
var _on_queue_done: Callable = Callable()
var _pending_choice_options: Array = []

func _ready() -> void:
	_recepcionista_data = DialogueManager.load_json(RECEPCIONISTA_DIALOGUE_PATH)
	_loro_data = DialogueManager.load_json(LORO_DIALOGUE_PATH)
	_final_data = DialogueManager.load_json(FINAL_DIALOGUE_PATH)
	_machine_data = DialogueManager.load_json(MAQUINA_HOTSPOT_DATA_PATH)

	_hover_label.hide()
	_dialogue_box.hide()
	_end_panel.hide()

	_dialogue_box.advance_requested.connect(_advance_queue)
	_dialogue_box.choice_selected.connect(_on_choice_selected)
	GameState.state_changed.connect(func(_prev, _cur): _sync_state_visuals())

	# find_children(recursive) instead of get_children(): some hotspots (e.g.
	# Sello) sit under a plain Node2D "sort anchor" that gives them a
	# different y-sort key than their visual/click position — see SelloAnchor
	# in oficina_recepcion.tscn.
	for hotspot in _hotspots.find_children("*", "Hotspot", true, false):
		hotspot.hovered.connect(_on_hotspot_hovered)
		hotspot.unhovered.connect(_on_hotspot_unhovered)
		hotspot.interacted.connect(_on_hotspot_interacted)
		hotspot.observed.connect(_on_hotspot_observed)

	_restart_button.pressed.connect(_restart_scene)
	_menu_button.pressed.connect(_go_to_menu)
	_end_restart_button.pressed.connect(_restart_scene)
	_end_menu_button.pressed.connect(_go_to_menu)

	_sync_state_visuals()

func _restart_scene() -> void:
	get_tree().reload_current_scene()

func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

# --- State-driven prop visuals (independent of any dialogue being shown) ---

func _sync_state_visuals() -> void:
	_sync_formulario(GameState.is_at_least(GameState.State.DECLARACION_OBTENIDA))
	if _machine_sprite:
		_machine_sprite.texture = _machine_texture_for_state(GameState.current)
	if _door_sprite:
		_door_sprite.texture = _door_texture_for_state(GameState.current)
	if _cartel_estado_sprite:
		_cartel_estado_sprite.texture = _cartel_estado_texture_for_state(GameState.current)

## Once Nicanor fills the form in he takes it with him, so it leaves the desk.
## Hiding the sprite is not enough: an Area2D keeps being picked while invisible,
## so the hotspot would still answer to hover and clicks over an empty desk.
## Reversible on purpose — Reiniciar puts the state back to INICIO and this runs
## again from the state, not from a one-way flag.
func _sync_formulario(taken: bool) -> void:
	if not _formulario:
		return
	if _formulario.visible == not taken:
		return
	_formulario.visible = not taken
	_formulario.input_pickable = not taken
	# mouse_exited never fires for an area that stops being pickable, so a name
	# left under the cursor would stay on screen.
	if taken:
		_hover_label.hide()

func _machine_texture_for_state(state: GameState.State) -> Texture2D:
	match state:
		GameState.State.INICIO:
			return MAQUINA_APAGADA
		GameState.State.DECLARACION_USADA:
			return MAQUINA_IMPRIMIENDO
		_:
			return MAQUINA_ENCENDIDA

func _door_texture_for_state(state: GameState.State) -> Texture2D:
	match state:
		GameState.State.ESCENA_TERMINADA:
			return PUERTA_ABIERTA
		GameState.State.ACCESO_AUTORIZADO:
			return PUERTA_DESBLOQUEADA
		_:
			return PUERTA_CERRADA

## Ambient institutional status indicator — not part of the puzzle logic
## itself, just a visual echo of overall progress (apagado/ámbar/rojo).
func _cartel_estado_texture_for_state(state: GameState.State) -> Texture2D:
	if state >= GameState.State.ACCESO_AUTORIZADO:
		return CARTEL_ROJO
	if state >= GameState.State.REQUISITO_DESCUBIERTO:
		return CARTEL_AMBAR
	return CARTEL_APAGADO

# --- Hotspot hover -----------------------------------------------------

func _on_hotspot_hovered(hotspot: Hotspot) -> void:
	_hover_label.text = hotspot.hotspot_name
	_hover_label.show()

func _on_hotspot_unhovered(_hotspot: Hotspot) -> void:
	_hover_label.hide()

# --- Hotspot click routing ----------------------------------------------

func _on_hotspot_observed(hotspot: Hotspot) -> void:
	_start_interaction(hotspot, true)

func _on_hotspot_interacted(hotspot: Hotspot) -> void:
	_start_interaction(hotspot, false)

func _start_interaction(hotspot: Hotspot, is_observe: bool) -> void:
	if _busy or _dialogue_box.visible or GameState.current == GameState.State.ESCENA_TERMINADA:
		return
	_busy = true
	_nicanor.walk_to(hotspot.approach_global_position())
	if _nicanor.is_walking():
		await _nicanor.arrived
	_nicanor.face(hotspot.look_direction)
	_busy = false
	_resolve_hotspot(hotspot, is_observe)

func _resolve_hotspot(hotspot: Hotspot, is_observe: bool) -> void:
	match hotspot.hotspot_name:
		"Máquina de turnos":
			if is_observe:
				_handle_machine_observe()
			else:
				_handle_machine_interact()
		"Recepcionista":
			if is_observe:
				_play_lines([hotspot.observe_text])
			else:
				_handle_recepcionista_interact()
		"Loro":
			_handle_loro()
		"Formulario":
			if is_observe:
				_play_lines([hotspot.observe_text])
			else:
				_handle_formulario_interact(hotspot)
		"Puerta":
			if is_observe:
				_play_lines([hotspot.observe_text])
			else:
				_handle_puerta_interact(hotspot)
		_:
			var text := hotspot.interact_text if not is_observe else hotspot.observe_text
			_play_lines([text])

# --- Máquina de turnos ---------------------------------------------------

func _handle_machine_observe() -> void:
	if GameState.current == GameState.State.INICIO:
		GameState.set_state(GameState.State.MAQUINA_EXAMINADA)
	var text := DialogueManager.pick_state_text(_machine_data.get("observe_by_state", {}), GameState.current)
	_play_lines([text])

func _handle_machine_interact() -> void:
	if GameState.current == GameState.State.DECLARACION_OBTENIDA:
		GameState.set_state(GameState.State.DECLARACION_USADA)
		var sequence: Array = _machine_data.get("interact_resolve_sequence", [])
		_play_lines(sequence, func() -> void:
			GameState.set_state(GameState.State.TURNO_0_RECIBIDO)
		)
	else:
		var text := DialogueManager.pick_state_text(_machine_data.get("interact_by_state", {}), GameState.current)
		_play_lines([text])

# --- Recepcionista ---------------------------------------------------------

func _handle_recepcionista_interact() -> void:
	var branch: Dictionary = DialogueManager.pick_branch(_recepcionista_data.get("branches", []), GameState.current)
	if branch.is_empty():
		return
	var lines: Array = branch.get("lines", [])
	_play_lines(lines, func() -> void:
		var effects: Dictionary = branch.get("effects", {})
		if effects.has("set_state"):
			GameState.set_state(GameState.state_from_name(effects["set_state"]))
	)

# --- Loro ------------------------------------------------------------------

func _handle_loro() -> void:
	var text := DialogueManager.pick_state_text(_loro_data.get("idle_by_state", {}), GameState.current)
	_play_lines([{ "speaker": "Loro", "text": text }])

# --- Formulario --------------------------------------------------------

func _handle_formulario_interact(hotspot: Hotspot) -> void:
	if GameState.is_at_least(GameState.State.DECLARACION_OBTENIDA):
		_play_lines([hotspot.interact_text_alt])
	else:
		_play_lines([hotspot.interact_text], func() -> void:
			GameState.set_state(GameState.State.DECLARACION_OBTENIDA)
		)

# --- Puerta ------------------------------------------------------------

func _handle_puerta_interact(hotspot: Hotspot) -> void:
	if GameState.is_at_least(GameState.State.ACCESO_AUTORIZADO):
		_play_ending()
	else:
		_play_lines([hotspot.interact_text])

func _play_ending() -> void:
	var final_line: String = _final_data.get("nicanor_final", "")
	_play_lines([{ "speaker": "Nicanor", "text": final_line, "pose": "recitado" }], func() -> void:
		var remate: String = _loro_data.get("remate_final", "")
		_play_lines([{ "speaker": "Loro", "text": remate }], func() -> void:
			GameState.set_state(GameState.State.ESCENA_TERMINADA)
			_nicanor.clear_pose()
			_end_panel.show()
		)
	)

# --- Generic line/choice queue ------------------------------------------

func _play_lines(lines: Array, on_done: Callable = Callable()) -> void:
	_line_queue = lines.duplicate()
	_on_queue_done = on_done
	_advance_queue()

func _advance_queue() -> void:
	if _line_queue.is_empty():
		_dialogue_box.close()
		_set_speaker_idle_all()
		if _on_queue_done.is_valid():
			var done := _on_queue_done
			_on_queue_done = Callable()
			done.call()
		return
	var entry: Variant = _line_queue.pop_front()
	if entry is Dictionary and entry.has("choice"):
		_show_choice(entry["choice"])
		return
	var speaker := ""
	var text := ""
	var pose := ""
	if entry is Dictionary:
		speaker = entry.get("speaker", "")
		text = entry.get("text", "")
		pose = entry.get("pose", "")
	elif entry is String:
		text = entry
	_apply_speaker_state(speaker, pose)
	_dialogue_box.show_line(speaker, text, _portrait_for_speaker(speaker))

func _show_choice(options: Array) -> void:
	_pending_choice_options = options
	var texts: Array = []
	for opt in options:
		texts.append(opt.get("text", ""))
	_dialogue_box.show_choices(texts)

## Clicking a choice already showed its full text as the button label —
## re-displaying that same text as a new typewriter-animated line (the old
## behavior) just repeated what the player already read and made them
## click again to get past it. Apply the chosen pose directly and go
## straight to whatever the branch queues next (the NPC's response).
func _on_choice_selected(index: int) -> void:
	var opt: Dictionary = _pending_choice_options[index]
	_apply_speaker_state("Nicanor", opt.get("pose", ""))
	_advance_queue()

func _apply_speaker_state(speaker: String, pose: String) -> void:
	if speaker == "Nicanor":
		_nicanor.set_pose("pose_%s" % (pose if pose != "" else "neutral"))
	elif speaker != "":
		_nicanor.set_pose("pose_neutral")
	_set_recepcionista_texture(CARP_HABLANDO if speaker == "Recepcionista" else CARP_IDLE)
	if _loro_sprite:
		_loro_sprite.play("hablando" if speaker == "Loro" else "idle")

func _set_speaker_idle_all() -> void:
	_nicanor.clear_pose()
	_set_recepcionista_texture(CARP_IDLE)
	if _loro_sprite:
		_loro_sprite.play("idle")

## The two Recepcionista textures were drawn facing opposite ways: carp_idle_new
## looks right, carp_hablando_new looks left. She attends from the far side of
## the window, so she has to face left — towards Nicanor — in both, which means
## the idle one is mirrored and the talking one is not. Mirroring is free here
## (her silhouette fills the canvas symmetrically, so nothing shifts); the only
## tell is the shirt badge swapping pockets, which the pose change hides.
func _set_recepcionista_texture(texture: Texture2D) -> void:
	if not _recepcionista_sprite:
		return
	_recepcionista_sprite.texture = texture
	_recepcionista_sprite.flip_h = texture == CARP_IDLE

func _portrait_for_speaker(speaker: String) -> Texture2D:
	match speaker:
		"Recepcionista":
			return CARP_IDLE
		"Loro":
			return LORO_IDLE
		_:
			return null

# --- Floor click-to-walk -------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _dialogue_box.visible:
			_dialogue_box.handle_click()
			return
		if _busy or GameState.current == GameState.State.ESCENA_TERMINADA:
			return
		_nicanor.walk_to(get_global_mouse_position())
