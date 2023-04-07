class_name MachineMovement
extends Node

@onready var machine: MachineCharacter = get_parent() as MachineCharacter

var _state: int = MachineCharacter.State.IDLE

var _move_machine_update_time = 1.0
var _move_machine_update_time_acc = 1.0
var _move_path: Array[Vector3] = []
var _path_index: int = 0

func _ready():
	Server.move_machine_requested.connect(_on_move_requested)

func _process(delta):
	if _state == MachineCharacter.State.MOVING:
		_process_movement(delta)

func _process_movement(delta: float):
	if _move_machine_update_time_acc > _move_machine_update_time:
		_move_machine_update_time_acc = 0.0
		machine.position = _move_path[_path_index]
		_path_index += 1
		if _path_index >= _move_path.size():
			_state = MachineCharacter.State.IDLE
	else:
		_move_machine_update_time_acc += delta
		
	pass


func get_state() -> int:
	return _state

func _on_move_requested(machine_node_path, path: Array[Vector3]):
	if machine.get_path() == machine_node_path:
		print("Moving machine Miner: {}".format(machine_node_path, "{}"))
		_state = MachineCharacter.State.MOVING
		_move_path = path
		_path_index = 0

# Target is the coordinate in latitude and longitude.
func go_to(target: Vector3):
	_state = MachineCharacter.State.MOVING
	pass

func get_self_coordinates() -> Vector2:
	return Vector2();


func _enter_tree():
	Server.move_machine_requested.disconnect(_on_move_requested)
