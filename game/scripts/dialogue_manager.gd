class_name DialogueManager
extends RefCounted

## Loads data-driven dialogue/hotspot-text JSON (see game/data/) and resolves
## which branch or variant applies for the current GameState.State. Holds no
## content of its own — every string comes from the JSON files it reads.

static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("DialogueManager: file not found at %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	push_warning("DialogueManager: %s did not parse as a Dictionary" % path)
	return {}

## branches: Array of { id, min_state?, max_state?, lines: [...], effects?: {} }
## Returns the first branch whose [min_state, max_state] range contains `state`
## (bounds are inclusive; omitted bounds are unbounded on that side).
static func pick_branch(branches: Array, state: GameState.State) -> Dictionary:
	for branch in branches:
		var b: Dictionary = branch
		var min_state: GameState.State = GameState.State.INICIO
		var max_state: GameState.State = GameState.State.ESCENA_TERMINADA
		if b.has("min_state"):
			min_state = GameState.state_from_name(b["min_state"])
		if b.has("max_state"):
			max_state = GameState.state_from_name(b["max_state"])
		if state >= min_state and state <= max_state:
			return b
	return {}

## by_state: Dictionary of state-name -> value (String, or Array for variant pools).
## Walks backward from `state` to INICIO so a branch without its own entry
## falls back to the closest earlier state's text instead of an empty string.
static func pick_state_value(by_state: Dictionary, state: GameState.State) -> Variant:
	var s := int(state)
	while s >= 0:
		var key: String = GameState.State.keys()[s]
		if by_state.has(key):
			return by_state[key]
		s -= 1
	return null

static func pick_state_text(by_state: Dictionary, state: GameState.State, fallback: String = "") -> String:
	var value: Variant = pick_state_value(by_state, state)
	if value == null:
		return fallback
	if value is Array:
		if value.is_empty():
			return fallback
		return value[randi() % value.size()]
	return str(value)
