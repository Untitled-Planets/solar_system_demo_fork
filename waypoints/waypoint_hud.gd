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

var _planet_mode: PlanetMode = null

func _ready():
	_planet_mode = get_tree().get_nodes_in_group("planet_mode_script")[0]
	pass

func set_solar_system(ss : SolarSystem):
	_solar_system = ss


func _process(_delta):
	queue_redraw()


func is_on_waypoint() -> bool:
	return _selected_waypoint != null

func _draw():
	var _w = WaypointManager.get_waypoints()
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var mouse_collide = false
	
	var w: Waypoint = null
	for waypoint in _w:
		var pos : Vector3 = waypoint.global_transform.origin
		var center_2d := camera.unproject_position(pos)
		var size_3d = 2.0
		var center_2d_side := camera.unproject_position(pos + camera.transform.basis.x * size_3d)
		if camera.is_position_behind(pos):
			continue
		var radius = center_2d.distance_to(center_2d_side)
		var min_scale = 0.5
		var nt : Texture = waypoint.get_focus_texture()
		var color: Color = waypoint.get_color()
		var _is_candidate: bool = true
		if _planet_mode.is_enabled:
			if waypoint.global_transform.origin.dot(camera.global_transform.origin) < 0.0:
				color.a *= 0.5
				_is_candidate = false
		if radius < nt.get_width() * min_scale:
			radius = nt.get_width() * min_scale
		var pos_2d = center_2d - Vector2(radius, radius) * 0.5
		draw_texture_rect(
			nt, Rect2(pos_2d, Vector2(radius, radius) * 2.0), false, color)
		
		var dist = mouse_pos.distance_to(center_2d)
		if dist <= radius and _is_candidate:
			w = waypoint
			info_label.show()
			var so = waypoint.get_selected_object()
			if so is MachineCharacter:
				info_label.set_text(waypoint.info)
			else:
				var planet_id: int = _solar_system.get_reference_stellar_body_id()
				var info: String = "Location: {0}\nAmount: {1}.\nUnit Coordinates: {2}\nLocation_id: {3}".format([waypoint.location, Server.get_resource_amount(planet_id, waypoint.location_id), Util.position_to_unit_coordinates(waypoint.global_position), waypoint.location_id])
				info_label.set_text(info)
			info_label.position = mouse_pos
			mouse_collide = true
		
		if not mouse_collide:
			info_label.hide()
	_selected_waypoint = w

# Target waypoint to circle
