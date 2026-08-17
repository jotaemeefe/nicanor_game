extends Node

## Autoload. Central puzzle state machine for the active scene — see
## design/puzzles.md#puzle-activo--constancia-de-presencia for the design this mirrors.
## Holds no dialogue/observation text; scenes and data files own that.

enum State {
	INICIO,
	MAQUINA_EXAMINADA,
	REQUISITO_DESCUBIERTO,
	DECLARACION_OBTENIDA,
	DECLARACION_USADA,
	TURNO_0_RECIBIDO,
	ACCESO_AUTORIZADO,
	ESCENA_TERMINADA,
}

signal state_changed(previous: State, current: State)

var current: State = State.INICIO

func set_state(new_state: State) -> void:
	if new_state == current:
		return
	var previous := current
	current = new_state
	state_changed.emit(previous, current)

func is_at_least(state: State) -> bool:
	return current >= state

func is_exactly(state: State) -> bool:
	return current == state

func reset() -> void:
	set_state(State.INICIO)

func state_name(state: State = current) -> String:
	return State.keys()[state]

func state_from_name(name: String) -> State:
	var idx := State.keys().find(name)
	if idx == -1:
		push_warning("GameState: unknown state name '%s'" % name)
		return State.INICIO
	return idx as State
