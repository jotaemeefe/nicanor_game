extends Node

## Headless content/logic check for the "constancia de presencia" puzzle
## (design/puzzles.md). Does not simulate mouse clicks or Nicanor's physical
## walk — see game/docs/PLAYTEST.md for the manual click-through test that
## covers the full point-and-click flow. This checks:
##   1. GameState transitions and comparisons behave correctly.
##   2. Every dialogue/hotspot-text JSON resolves a non-empty string for
##      every reachable puzzle state (catches typos in state names and gaps
##      in branch coverage without needing the editor open).
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
		GameState.State.TURNO_0_RECIBIDO: "turno_cero",
		GameState.State.ACCESO_AUTORIZADO: "post_autorizado",
		GameState.State.ESCENA_TERMINADA: "post_autorizado",
	}
	for state in expectations:
		var branch: Dictionary = DialogueManager.pick_branch(branches, state)
		_expect(not branch.is_empty(), "a branch should exist for %s" % GameState.State.keys()[state])
		_expect(branch.get("id", "") == expectations[state], "state %s should pick branch '%s', got '%s'" % [GameState.State.keys()[state], expectations[state], branch.get("id", "<none>")])

	# The "intro" branch must contain a choice entry (exercises the
	# options/branching capability the dialogue system is required to support).
	var intro: Dictionary = DialogueManager.pick_branch(branches, GameState.State.INICIO)
	var has_choice := false
	for line in intro.get("lines", []):
		if line is Dictionary and line.has("choice"):
			has_choice = true
			_expect((line["choice"] as Array).size() == 2, "intro choice should offer 2 options")
	_expect(has_choice, "intro branch should contain a choice entry")

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

func _check_final_dialogue() -> void:
	var final_data := DialogueManager.load_json("res://data/dialogues/final.json")
	_expect(final_data.get("nicanor_final", "") != "", "final.json should have a non-empty nicanor_final line")
	var loro_data := DialogueManager.load_json("res://data/dialogues/loro.json")
	_expect(loro_data.get("remate_final", "") != "", "loro.json should have a non-empty remate_final line")
