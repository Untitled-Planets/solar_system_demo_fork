class_name WaypointHUD
extends Control

signal waypoint_selected(waypoint)

@onready var info_label = get_node("waypoint_info")

@export var WaypointTexture: Texture

var _solar_system : SolarSystem

var _selected_waypoint: Waypoint
var selected_waypoint: Waypoint:
	get:
		return _selected_waypoint


var _waypoints := []


func set_solar_system(ss : SolarSystem):
	_solar_system = ss


func _process(_delta):
	queue_redraw()

func add_waypoint(w: Waypoint) -> void:
	_waypoints.append(w)

func is_on_waypoint() -> bool:
	return _selected_waypoint != null

# As we cannot guaranty the order in call_group
# we will wait one frame after the creation of the waypoints.
func pm_enabled(value: bool) -> void:
	if value:
		await get_tree().process_frame
		_waypoints = get_tree().get_nodes_in_group("waypoint")
	else:
		_waypoints = []

func _draw():
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var mouse_collide = false
	
	var w: Waypoint = null
	for waypoint in _waypoints:
		var pos : Vector3 = waypoint.global_transform.origin
		var center_2d := camera.unproject_position(pos)
		var size_3d = 2.0
		var center_2d_side := camera.unproject_position(pos + camera.transform.basis.x * size_3d)
		if camera.is_position_behind(pos):
			continue
		var radius = center_2d.distance_to(center_2d_side)
		var min_scale = 0.5
		if radius < WaypointTexture.get_width() * min_scale:
			radius = WaypointTexture.get_width() * min_scale
		#draw_string(font, pos_2d, waypoint.waypoint_name, Color(0.3, 1.0, 0.3))
		var pos_2d = center_2d - Vector2(radius, radius) * 0.5
		draw_texture_rect(
			WaypointTexture, Rect2(pos_2d, Vector2(radius, radius)), false, Color(0.3, 1.0, 0.3))
		
		var dist = mouse_pos.distance_to(center_2d)
		if dist <= radius:
			w = waypoint
			info_label.show()
			var so = waypoint.get_selected_object()
			if so is MachineCharacter:
				info_label.set_text(waypoint.info)
			else:
				var planet_id: int = _solar_system.get_reference_stellar_body_id()
				var info: String = "Location: {0}\nAmount: {1}".format([waypoint.location, Server.get_resource_amount(planet_id, waypoint.location_id)])
				info_label.set_text(info)
			info_label.position = mouse_pos
			mouse_collide = true
		
		if not mouse_collide:
			info_label.hide()
			
	_selected_waypoint = w
