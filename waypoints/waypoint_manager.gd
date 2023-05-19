extends Node


var _waypoints: Dictionary = {}

func add_waypoints_to_group(group_id: String, p_waypoints: Array):
	_waypoints[group_id] = p_waypoints

func get_waypoints_from_group(group_id: String):
	if _waypoints.has(group_id):
		return _waypoints[group_id]
	return []

func remove_waypoints_from_group(group_id: String):
	_waypoints.erase(group_id)
