class_name MachineCharacter
extends Node3D

enum State {
	WORKING,
	MOVING,
	IDLE,
	MINING,
}

@onready var _movement: MachineMovement = $movement

@export var _waypoint_scene: PackedScene

var _planet : StellarBody
var _waypoint: Waypoint


func go_to(location: Vector3) -> void:
	_movement.go_to(location)

func set_planet(p : StellarBody) -> void:
	_planet = p

func get_planet() -> StellarBody:
	return _planet

func configure_waypoint(value: bool) -> void:
	if value:
		_waypoint = _waypoint_scene.instantiate()
		_waypoint.info = "Machine name: {}".format([name], "{}")
		add_child(_waypoint)
		if ProjectSettings.get_setting("solar_system/debug/show_machine_waypoint"):
			_waypoint.set_enable_debug_mesh(true)
			_waypoint.scale_area(30)
			get_tree().call_group("waypoint_hud", "add_waypoint", _waypoint)
	else:
		if _waypoint:
			_waypoint.queue_free()
			_waypoint = null

func get_max_speed() -> float:
	return _movement._speed

func pm_enabled(value: bool) -> void:
	configure_waypoint(value)
