extends Node


var _waypoints: Array[Waypoint] = []

func _ready():
#	add_to_group("planet_mode")
	pass

func add_waypoint(p_waypoint: Waypoint) -> void:
	_waypoints.append(p_waypoint)

func remove_waypoint(p_waypoint: Waypoint):
	_waypoints.erase(p_waypoint)

func get_waypoints() -> Array[Waypoint]:
	return _waypoints

func pm_enabled(p_value: bool):
	if not p_value:
		_waypoints = []
