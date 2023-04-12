class_name MachineMovement
extends Node

@onready var machine: MachineCharacter = get_parent() as MachineCharacter

@export var _speed: float = 10
@export var _acceptable_radius: float = 1.0
@export var _height_from_planet: float = 10.0

var _state: int = MachineCharacter.State.IDLE
var _path_index: int = 0
var _move_path: Array[Vector3] = []
var _travel_time: float = 0
var _move_data: MoveMachineData = null
var _total_time: float = 0.0
var _from: Vector3
var _to: Vector3
var _last_know_secure_height: float

func _ready():
	Server.move_machine_requested.connect(_on_move_requested)

func _process(delta):
	if _state == MachineCharacter.State.MOVING:
		_total_time += delta
		if machine.get_planet().static_bodies_are_in_tree:
			machine.visible = true
			_show_position()
			_fix_height()
			_fix_orientation()
		else:
			machine.visible = false
		if _total_time >= _travel_time:
			_state = MachineCharacter.State.IDLE

func _show_position() -> void:
	var current_direction := _move_data.from.slerp(_move_data.to, _total_time / _travel_time).normalized()
	_fix_height()
	machine.position = current_direction * _move_data.planet_radius

#func _process_movement(delta: float):
#	var target_position := _move_path[_path_index]
#	# Depending on speed this won't work.
#	if _has_reached_goal(target_position):
#		_path_index += 1
#		if _path_index >= _move_path.size():
#			_state = MachineCharacter.State.IDLE
#			return
#		_move(target_position, delta)
#		_fix_orientation()
##		_fix_height()
#	else:
#		_move(target_position, delta)
#		_fix_orientation()
#	_fix_height()

func _has_reached_goal(goal_position: Vector3) -> bool:
	var sr := _acceptable_radius * _acceptable_radius
	var plane := Plane(goal_position.normalized(), goal_position.length())
	var pro_point := plane.project(machine.position)
	return (pro_point - goal_position).length_squared() < sr
	

func _move(goal_position: Vector3, delta: float) -> void:
	var dir := (goal_position - machine.position).normalized()
	machine.position += delta * _speed * dir

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
		var recommend_height_point = ((-dir) * _height_from_planet) + result.position
		var diff = recommend_height_point - machine.position
		machine.position += diff
		_last_know_secure_height = machine.position.length()
	else:
		machine.position = (-dir) * _last_know_secure_height

func get_state() -> int:
	return _state

func _on_move_requested(machine_node_path, move_data: MoveMachineData):
	if machine.get_path() == machine_node_path:
		_state = MachineCharacter.State.MOVING
		_travel_time = move_data.get_travel_time()
		_total_time = 0.0
		_move_data = move_data
		_last_know_secure_height = _move_data.planet_radius
		

## Target is the coordinate in latitude and longitude.
#func go_to(target: Vector3):
#	_state = MachineCharacter.State.MOVING

func get_self_coordinates() -> Vector2:
	return Util.position_to_coordinates(machine.position)


func _enter_tree():
	Server.move_machine_requested.disconnect(_on_move_requested)
