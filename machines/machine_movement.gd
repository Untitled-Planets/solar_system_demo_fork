class_name MachineMovement
extends Node

@onready var machine: MachineCharacter = get_parent() as MachineCharacter

@export var _speed: float = 10
@export var _acceptable_radius: float = 1.0
@export var _height_from_planet: float = 10.0

var _state: int = MachineCharacter.State.IDLE
var _path_index: int = 0
var _move_path: Array[Vector3] = []

func _ready():
	Server.move_machine_requested.connect(_on_move_requested)

func _process(delta):
	if _state == MachineCharacter.State.MOVING:
		_process_movement(delta)

func _process_movement(delta: float):
	var target_position := _move_path[_path_index]
	var sr := _acceptable_radius * _acceptable_radius
	# Depending on speed this won't work.
	if (machine.position - target_position).length_squared() < sr:
		_path_index += 1
		if _path_index >= _move_path.size():
			_state = MachineCharacter.State.IDLE
			return
		_move(target_position, delta)
		_fix_orientation()
#		_fix_height()
	else:
		_move(target_position, delta)
		_fix_orientation()
#	_fix_height()

func _move(goal_position: Vector3, delta: float) -> void:
	var dir := (goal_position - machine.position).normalized()
	machine.global_translate(delta * _speed * dir)

func _fix_orientation() -> void:
	var n := machine.position.normalized()
	var up := machine.basis.y
	if n.is_equal_approx(up):
		return
	var t := machine.transform
	var forward := up.cross(n)
	var right := forward.cross(up)
	t.basis = Basis(right.normalized(), n, forward.normalized())
	machine.transform = t

func _fix_height() -> void:
	var planet := machine.get_planet()
	var state := machine.get_world_3d().direct_space_state
	var dir := -machine.position.normalized()
	var query := PhysicsRayQueryParameters3D.new()
	query.from = machine.global_position + (-dir * 100.0)
	query.to = planet.node.global_position
	var result := state.intersect_ray(query)
	if not result.is_empty():
		var point: Vector3 = result.position
		var min_height = planet.radius * _height_from_planet
		if (point - (dir * _height_from_planet)).length_squared() < min_height * min_height:
			point = (-dir) * (planet.radius + _height_from_planet)
		machine.position.y = point.y
	else:
		push_warning("NOt collision... Something is wrong!")

func get_state() -> int:
	return _state

func _on_move_requested(machine_node_path, path: Array[Vector3]):
	if machine.get_path() == machine_node_path:
		_state = MachineCharacter.State.MOVING
		_move_path = path
		_path_index = 0

## Target is the coordinate in latitude and longitude.
#func go_to(target: Vector3):
#	_state = MachineCharacter.State.MOVING

func get_self_coordinates() -> Vector2:
	return Vector2();


func _enter_tree():
	Server.move_machine_requested.disconnect(_on_move_requested)
