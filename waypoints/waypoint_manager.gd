extends Node


var _waypoints: Array[Waypoint] = []

func _ready():
	pass

#func add_waypoints_to_group(group_id: String, p_waypoints: Array):
#	_waypoints[group_id] = p_waypoints

func add_waypoint(p_waypoint: Waypoint) -> void:
	_waypoints.append(p_waypoint)

#func get_waypoints_from_group(group_id: String):
#	if _waypoints.has(group_id):
#		return _waypoints[group_id]
#	return []
#
#func remove_waypoints_from_group(group_id: String):
#	_waypoints.erase(group_id)

func get_waypoints() -> Array[Waypoint]:
	return _waypoints

func pm_enabled(p_value: bool):
	if not p_value:
		_waypoints = []
