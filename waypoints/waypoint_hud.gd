extends Control

const SolarSystem = preload("res://solar_system/solar_system.gd")
const WaypointTexture = preload("res://gui/waypoint.png")

onready var info_label = get_node("waypoint_info")

var _solar_system : SolarSystem

var _labels = []


func set_solar_system(ss : SolarSystem):
	_solar_system = ss


func _process(delta):
	update()


func _draw():
	var camera := get_viewport().get_camera()
	if camera == null:
		return

	var body = _solar_system.get_reference_stellar_body()
	var font = get_font("font")
	var mouse_pos = get_viewport().get_mouse_position()

	for waypoint in body.waypoints:
		var pos : Vector3 = waypoint.transform.origin
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

		if waypoint.has_meta("mine"):
			var dist = mouse_pos.distance_to(pos_2d + Vector2(radius, radius))
			if dist <= radius:
				var mine = waypoint.get_meta("mine")
				info_label.show()
				info_label.set_text("Mine Pos :" + str(mine.pos)+"\nAmount: "+str(mine.amount))
				info_label.rect_position = mouse_pos
			else:
				info_label.hide()
		else:
			info_label.hide()
			
			
