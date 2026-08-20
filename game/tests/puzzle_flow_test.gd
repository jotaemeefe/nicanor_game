extends Node

## Headless content/logic check for the "constancia de presencia" puzzle
## (design/puzzles.md). Does not simulate mouse clicks or Nicanor's physical
## walk — see game/docs/PLAYTEST.md for the manual click-through test that
## covers the full point-and-click flow. This checks:
##   1. GameState transitions and comparisons behave correctly.
##   2. Every dialogue/hotspot-text JSON resolves a non-empty string for
##      every reachable puzzle state (catches typos in state names and gaps
##      in branch coverage without needing the editor open).
##   3. Props that appear or disappear with the puzzle state actually do, and
##      go back when the scene is reset.
## Run as a scene (not --script — autoloads aren't available to a bare
## SceneTree --script entry point): godot --headless --path . res://tests/puzzle_flow_test.tscn

var _failures: Array[String] = []
var _pass_count: int = 0

func _ready() -> void:
	_check_state_machine()
	_check_recepcionista_branches()
	_check_state_text("res://data/hotspots/maquina_turnos.json", "observe_by_state")
	_check_state_text("res://data/hotspots/maquina_turnos.json", "interact_by_state")
	_check_state_text("res://data/dialogues/loro.json", "idle_by_state")
	_check_final_dialogue()
	_check_parrot_remates()
	await _check_formulario_sequence()
	await _check_single_verb()
	await _check_parrot_speaks_after_a_beat()
	await _check_restart_resets_state()
	await _check_formulario_disappears()
	await _check_dialogue_click_routing()

	if _failures.is_empty():
		print("PUZZLE FLOW TEST: OK — %d checks passed, no failures." % _pass_count)
	else:
		print("PUZZLE FLOW TEST: FAILED (%d failures):" % _failures.size())
		for f in _failures:
			print(" - %s" % f)
	get_tree().quit(1 if not _failures.is_empty() else 0)

func _expect(condition: bool, message: String) -> void:
	if condition:
		_pass_count += 1
	else:
		_failures.append(message)

## A hotspot's Area2D marks a click as handled before _unhandled_input can hand
## it to the dialogue box, so a click on the character you are talking to used
## to do nothing at all — the player had to move the cursor off them to advance.
## Also checks the grace period that stops the click after the last line, or a
## reflex second one, from immediately replaying the same conversation.
func _check_dialogue_click_routing() -> void:
	GameState.reset()
	var office: Node2D = load("res://scenes/office/oficina_recepcion.tscn").instantiate()
	add_child(office)
	await get_tree().process_frame

	var box: DialogueBox = office.get_node("UI/DialogueBox")
	var loro: Hotspot = office.get_node("World/Hotspots/LoroAnchor/Loro")

	office._play_lines(["uno", "dos"])
	await get_tree().process_frame
	_expect(box.visible and box._full_text == "uno", "the first line should be on screen")

	# first click completes the typewriter, second one advances
	office._on_hotspot_interacted(loro)
	_expect(box._full_text == "uno" and not box._revealing,
		"a click over a hotspot should complete the reveal, not be swallowed")
	office._on_hotspot_interacted(loro)
	await get_tree().process_frame
	_expect(box.visible and box._full_text == "dos",
		"a second click over a hotspot should advance to the next line")

	office._on_hotspot_interacted(loro)
	office._on_hotspot_interacted(loro)
	await get_tree().process_frame
	_expect(not box.visible, "the box should close after the last line")

	# the reflex click right after it closes must not replay the same branch
	office._on_hotspot_interacted(loro)
	await get_tree().process_frame
	_expect(not box.visible, "a click inside the grace period should not reopen the dialogue")

	office.queue_free()

## Nicanor takes the form with him once he fills it in, so it has to leave the
## desk — and it has to come back on Reiniciar, since the scene is reset by
## putting GameState back to INICIO rather than by reloading. `input_pickable`
## is checked as well as `visible`: an invisible Area2D still answers to hover
## and clicks, which would leave a phantom hotspot over an empty desk.
func _check_formulario_disappears() -> void:
	GameState.reset()
	var office: Node2D = load("res://scenes/office/oficina_recepcion.tscn").instantiate()
	add_child(office)
	await get_tree().process_frame

	var formulario: Hotspot = office.get_node_or_null("World/Hotspots/Formulario")
	_expect(formulario != null, "the scene should still have a Formulario hotspot")
	if formulario == null:
		return

	_expect(formulario.visible and formulario.input_pickable,
		"the form should be on the desk at INICIO")

	for state in [GameState.State.DECLARACION_OBTENIDA, GameState.State.TURNO_0_RECIBIDO,
			GameState.State.ESCENA_TERMINADA]:
		GameState.set_state(state)
		await get_tree().process_frame
		_expect(not formulario.visible and not formulario.input_pickable,
			"the form should be gone at %s" % GameState.state_name(state))

	GameState.reset()
	await get_tree().process_frame
	_expect(formulario.visible and formulario.input_pickable,
		"the form should be back on the desk after a reset")

	office.queue_free()

## Filling the form is where the poetry contest enters the game, so that beat
## grew from a single .tscn string into a multi-speaker sequence with a choice,
## living in data/hotspots/formulario.json. Two things can silently break: the
## data file going missing (the form would fill in in total silence) and the
## choice stalling the queue so DECLARACION_OBTENIDA never lands, which would
## make the puzzle unfinishable. This drives the whole sequence to the end.
func _check_formulario_sequence() -> void:
	var data := DialogueManager.load_json("res://data/hotspots/formulario.json")
	var sequence: Array = data.get("interact_resolve_sequence", [])
	_expect(sequence.size() > 0, "formulario.json should have a non-empty interact_resolve_sequence")

	var choices := 0
	for entry in sequence:
		if entry is Dictionary and entry.has("choice"):
			choices += 1
			_expect((entry["choice"] as Array).size() == 2, "the formulario choice should offer 2 options")
		else:
			_expect(str(entry.get("text", "")) != "", "every formulario line should have text")
	_expect(choices == 1, "the formulario sequence should contain exactly 1 choice, has %d" % choices)

	GameState.reset()
	var office: Node2D = load("res://scenes/office/oficina_recepcion.tscn").instantiate()
	add_child(office)
	await get_tree().process_frame

	var box: DialogueBox = office.get_node("UI/DialogueBox")
	var formulario: Hotspot = office.get_node("World/Hotspots/Formulario")
	GameState.set_state(GameState.State.REQUISITO_DESCUBIERTO)
	await get_tree().process_frame

	office._handle_formulario_interact(formulario)
	await get_tree().process_frame
	_expect(box.visible, "filling the form should open the dialogue box")

	# Drain it the way a player would, picking the first option at the choice.
	# The cap is a guard against a stall, not an expected length.
	var guard := 0
	while box.visible and guard < 50:
		guard += 1
		if box.is_choice_mode():
			office._on_choice_selected(0)
		else:
			office._advance_queue()
		await get_tree().process_frame
	_expect(guard < 50, "the formulario sequence should end, not stall at the choice")
	_expect(GameState.current == GameState.State.DECLARACION_OBTENIDA,
		"finishing the formulario sequence should reach DECLARACION_OBTENIDA, got %s"
			% GameState.state_name(GameState.current))

	office.queue_free()

## The scene runs on one verb (2026-08-20): both mouse buttons do the same
## thing. The failure this guards against is a silent one — a right click that
## resolves to nothing, or a prop that says its single line twice because its
## two old verbs carried identical strings on purpose (the Cartel is the
## puzzle's written clue and reads the same either way).
func _check_single_verb() -> void:
	GameState.reset()
	var office: Node2D = load("res://scenes/office/oficina_recepcion.tscn").instantiate()
	add_child(office)
	await get_tree().process_frame

	_expect(office.get_node_or_null("World/Hotspots/Mostrador") == null,
		"the Mostrador should no longer be a hotspot")

	var by_name := {}
	for hotspot in office.get_node("World/Hotspots").find_children("*", "Hotspot", true, false):
		by_name[hotspot.hotspot_name] = hotspot

	# Every prop must answer with at least one line, and never repeat itself.
	for prop_name in ["Cartel de normas", "Planta de oficina", "Sello",
			"Ventilador de techo", "Reloj"]:
		var hotspot = by_name.get(prop_name)
		_expect(hotspot != null, "the scene should still have a %s hotspot" % prop_name)
		if hotspot == null:
			continue
		var lines: Array = office._prop_lines(hotspot)
		_expect(lines.size() >= 1, "%s should answer a click with at least one line" % prop_name)
		_expect(lines.size() == lines.size() - _duplicate_count(lines),
			"%s repeats a line inside one beat" % prop_name)

	_expect(office._prop_lines(by_name["Cartel de normas"]).size() == 1,
		"the Cartel carries the same string in both verbs, so it should collapse to one line")
	_expect(office._prop_lines(by_name["Sello"]).size() == 2,
		"the Sello's two different strings should both survive as one beat")
	_expect(office._prop_lines(by_name["Ventilador de techo"]).size() == 1,
		"the Ventilador should be down to its one remaining line")

	# Right click has to land somewhere, not nowhere. Nicanor is parked on the
	# approach point first so walk_to() has nothing to do and the whole thing
	# resolves in one frame — otherwise this would be racing a real walk.
	var reloj: Hotspot = by_name["Reloj"]
	var box: DialogueBox = office.get_node("UI/DialogueBox")
	office._nicanor.global_position = reloj.approach_global_position()
	await get_tree().process_frame

	office._on_hotspot_observed(reloj)
	await get_tree().process_frame
	_expect(box.visible, "right click on a prop should still say something")
	_expect(box._full_text == str(office._prop_lines(reloj)[0]),
		"right click should open the prop's own first line, got '%s'" % box._full_text)

	office.queue_free()

func _duplicate_count(lines: Array) -> int:
	var seen: Array = []
	var dupes := 0
	for line in lines:
		if seen.has(line):
			dupes += 1
		else:
			seen.append(line)
	return dupes

func _check_state_machine() -> void:
	var order := [
		GameState.State.INICIO,
		GameState.State.MAQUINA_EXAMINADA,
		GameState.State.REQUISITO_DESCUBIERTO,
		GameState.State.DECLARACION_OBTENIDA,
		GameState.State.DECLARACION_USADA,
		GameState.State.TURNO_0_RECIBIDO,
		GameState.State.ACCESO_AUTORIZADO,
		GameState.State.ESCENA_TERMINADA,
	]
	_expect(GameState.current == GameState.State.INICIO, "GameState should start at INICIO")
	# A two-element array whose *contents* the lambda mutates in place —
	# GDScript lambdas capture outer locals by value, so reassigning the
	# outer variable itself from inside the lambda would not be visible here.
	var last_change: Array = [null, null]
	GameState.state_changed.connect(func(prev, cur):
		last_change[0] = prev
		last_change[1] = cur
	)
	for i in range(1, order.size()):
		GameState.set_state(order[i])
		_expect(GameState.current == order[i], "set_state should move to %s" % GameState.State.keys()[order[i]])
		_expect(last_change == [order[i - 1], order[i]], "state_changed should fire with (prev, cur) for %s" % GameState.State.keys()[order[i]])
		_expect(GameState.is_at_least(order[i - 1]), "%s should be >= previous state" % GameState.State.keys()[order[i]])
	_expect(GameState.state_from_name("TURNO_0_RECIBIDO") == GameState.State.TURNO_0_RECIBIDO, "state_from_name should round-trip a valid name")
	GameState.reset()
	_expect(GameState.current == GameState.State.INICIO, "reset() should return to INICIO")

func _check_recepcionista_branches() -> void:
	var data := DialogueManager.load_json("res://data/dialogues/recepcionista.json")
	_expect(not data.is_empty(), "recepcionista.json should parse")
	var branches: Array = data.get("branches", [])
	_expect(branches.size() == 5, "recepcionista.json should have 5 branches, has %d" % branches.size())

	var expectations := {
		GameState.State.INICIO: "intro",
		GameState.State.MAQUINA_EXAMINADA: "intro",
		GameState.State.REQUISITO_DESCUBIERTO: "reminder_formulario",
		GameState.State.DECLARACION_OBTENIDA: "reminder_use_machine",
		# DECLARACION_USADA used to fall through every branch range, so pick_branch
		# returned {} and talking to her there opened nothing at all.
		GameState.State.DECLARACION_USADA: "reminder_use_machine",
		GameState.State.TURNO_0_RECIBIDO: "turno_cero",
		GameState.State.ACCESO_AUTORIZADO: "post_autorizado",
		GameState.State.ESCENA_TERMINADA: "post_autorizado",
	}
	for state in expectations:
		var branch: Dictionary = DialogueManager.pick_branch(branches, state)
		_expect(not branch.is_empty(), "a branch should exist for %s" % GameState.State.keys()[state])
		_expect(branch.get("id", "") == expectations[state], "state %s should pick branch '%s', got '%s'" % [GameState.State.keys()[state], expectations[state], branch.get("id", "<none>")])

	# The intro deliberately carries no choice any more. The pair that used to
	# sit here ("Hijo." / "Soy el hijo. Nicanor Sosa. Poeta.") was the same
	# answer twice at different lengths, which is not a real option — Nicanor
	# just says it. The scene's one choice moved to formulario.json, where the
	# two options are actually different attitudes; _check_formulario_sequence
	# is what exercises the branching capability now.
	var intro: Dictionary = DialogueManager.pick_branch(branches, GameState.State.INICIO)
	for line in intro.get("lines", []):
		_expect(not (line is Dictionary and line.has("choice")),
			"the intro branch should carry no choice — the scene's choice lives in formulario.json")

	# turno_cero must flip the state forward via effects.set_state
	var turno_branch: Dictionary = DialogueManager.pick_branch(branches, GameState.State.TURNO_0_RECIBIDO)
	_expect(turno_branch.get("effects", {}).get("set_state", "") == "ACCESO_AUTORIZADO", "turno_cero branch should set ACCESO_AUTORIZADO")

func _check_state_text(path: String, key: String) -> void:
	var data := DialogueManager.load_json(path)
	_expect(not data.is_empty(), "%s should parse" % path)
	var by_state: Dictionary = data.get(key, {})
	_expect(not by_state.is_empty(), "%s.%s should not be empty" % [path, key])
	for state in GameState.State.values():
		var text: String = DialogueManager.pick_state_text(by_state, state)
		_expect(text != "", "%s.%s should resolve non-empty text for state %s" % [path, key, GameState.State.keys()[state]])

## The parrot answers every puzzle beat, so each remate has to exist, be
## unique (a repeated punchline reads as the game glitching, not as a running
## gag), and stop short of ESCENA_TERMINADA - the ending already plays
## remate_final, and a second parrot line there would step on it.
func _check_parrot_remates() -> void:
	var data := DialogueManager.load_json("res://data/dialogues/loro.json")
	var remates: Dictionary = data.get("remate_by_state", {})
	_expect(not remates.is_empty(), "loro.json should have remate_by_state")
	var seen: Array[String] = []
	for key in remates:
		var name := str(key)
		_expect(GameState.State.keys().has(name), "remate_by_state key %s should be a real state" % name)
		var text := str(remates[key])
		_expect(text != "", "remate for %s should not be empty" % name)
		_expect(not seen.has(text), "remate for %s repeats an earlier one" % name)
		seen.append(text)
	_expect(not remates.has("ESCENA_TERMINADA"),
		"ESCENA_TERMINADA must have no remate - remate_final already plays there")
	_expect(not remates.has("INICIO"), "INICIO is the starting state, it is never entered")

## The remate is deferred until the line queue drains, because some beats move
## the state before showing their own text and some after. This drives the
## before case (the machine's first click) end to end: the machine speaks
## first, and only once the player dismisses *every* line of the beat does the
## parrot get the last word. Draining rather than counting clicks matters now
## that one verb makes that beat two lines instead of one — a test that assumed
## a fixed length would have to be rewritten every time a prop gains a line.
func _check_parrot_speaks_after_a_beat() -> void:
	GameState.reset()
	var office: Node2D = load("res://scenes/office/oficina_recepcion.tscn").instantiate()
	add_child(office)
	await get_tree().process_frame

	var box: DialogueBox = office.get_node("UI/DialogueBox")
	var loro_data := DialogueManager.load_json("res://data/dialogues/loro.json")
	var expected: String = str(loro_data.get("remate_by_state", {}).get("MAQUINA_EXAMINADA", ""))

	office._handle_machine_interact()
	await get_tree().process_frame
	_expect(GameState.current == GameState.State.MAQUINA_EXAMINADA,
		"clicking the machine should move the state")
	_expect(box.visible and box._full_text != expected,
		"the machine should speak first, not the parrot")

	# Drain the machine's own lines; the parrot is whatever is still talking
	# after they run out.
	var guard := 0
	while box.visible and box._full_text != expected and guard < 20:
		guard += 1
		office._advance_queue()
		await get_tree().process_frame
	_expect(guard < 20, "the machine's beat should end")
	_expect(box.visible and box._full_text == expected,
		"the parrot should get the last word once the beat is dismissed")

	office._advance_queue()
	await get_tree().process_frame
	_expect(not box.visible, "the parrot remate should close like any other line")

	office._advance_queue()
	await get_tree().process_frame
	_expect(not box.visible, "a remate must fire once, not on every drain")

	office.queue_free()

## GameState is an autoload and survives reload_current_scene(), so Reiniciar
## used to redraw the scene with the puzzle still solved.
func _check_restart_resets_state() -> void:
	GameState.reset()
	var office: Node2D = load("res://scenes/office/oficina_recepcion.tscn").instantiate()
	add_child(office)
	await get_tree().process_frame

	GameState.set_state(GameState.State.ACCESO_AUTORIZADO)
	await get_tree().process_frame
	office._reset_puzzle_state()
	_expect(GameState.current == GameState.State.INICIO,
		"Reiniciar should put the puzzle back to INICIO, not just redraw the scene")
	_expect(office._pending_parrot_state == "",
		"a remate owed at the moment of the restart should not fire into the new run")

	office.queue_free()

func _check_final_dialogue() -> void:
	var final_data := DialogueManager.load_json("res://data/dialogues/final.json")
	_expect(final_data.get("nicanor_final", "") != "", "final.json should have a non-empty nicanor_final line")
	var loro_data := DialogueManager.load_json("res://data/dialogues/loro.json")
	_expect(loro_data.get("remate_final", "") != "", "loro.json should have a non-empty remate_final line")
