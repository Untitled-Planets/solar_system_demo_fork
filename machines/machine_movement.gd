class_name MachineMovement
extends Node

@onready var machine: MachineCharacter = get_parent() as MachineCharacter

var _state: int = MachineCharacter.State.IDLE

func _ready():
	pass

func _process(delta):
	if _state == MachineCharacter.State.MOVING:
		_process_movement(delta)
	pass

func _process_movement(delta: float):
	pass


func get_state() -> int:
	return _state

# Target is the coordinate in latitude and longitude.
func go_to(target: Vector3):
	_state = MachineCharacter.State.MOVING
	pass

func get_self_coordinates() -> Vector2:
	return Vector2();
