class_name MachineMovement
extends Node

signal move_request_finished(request_id: int)

@onready var machine: MachineCharacter = get_parent() as MachineCharacter

@export var _speed: float = 10
@export var _height_from_planet: float = 10.0


var _state: int = MachineCharacter.State.IDLE
var _travel_time: float = 0
var _move_data: MoveMachineData = null
var _total_time: float = 0.0
var _last_know_secure_height: float

func _ready():
	pass

func _process(delta):
	if _state == MachineCharacter.State.MOVING:
		_total_time += delta
		if machine.get_planet().static_bodies_are_in_tree:
			_process_movement()
		else:
			machine.visible = false
		_fix_transform()
		if machine.visible:
			_fix_orientation()
		if _total_time >= _travel_time:
			_state = MachineCharacter.State.IDLE
			move_request_finished.emit(0)

func _process_movement() -> void:
	var current_direction := _move_data.from.slerp(_move_data.to, _total_time / _travel_time).normalized()
	machine.position = current_direction * _move_data.planet_radius
	


func _fix_transform() -> void:
	var planet := machine.get_planet()
	var state := machine.get_world_3d().direct_space_state
	var dir := -machine.position.normalized()
	var query := PhysicsRayQueryParameters3D.new()
	query.from = machine.global_position + (-dir * 100.0)
	query.to = planet.node.global_position
	var result := state.intersect_ray(query)
	if not result.is_empty():
		machine.visible = true
		var recommend_height_point = ((-dir) * _height_from_planet) + result.position
		var diff = recommend_height_point - machine.position
		machine.position += diff
		_last_know_secure_height = machine.position.length()
	else:
		machine.position = (-dir) * _last_know_secure_height
#	_fix_orientation()

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

func is_moving() -> bool:
	return _state == MachineCharacter.State.MOVING

func get_state() -> int:
	return _state

func move_request(move_data: MoveMachineData):
	_state = MachineCharacter.State.MOVING
	_travel_time = move_data.get_travel_time()
	_total_time = 0.0
	_move_data = move_data
	_last_know_secure_height = _move_data.planet_radius

func get_self_coordinates() -> Vector2:
	return Util.position_to_coordinates(machine.position)
