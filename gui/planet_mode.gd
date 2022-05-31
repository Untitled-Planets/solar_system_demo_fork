extends Control

const StellarBody = preload("res://solar_system/stellar_body.gd")
const SolarSystem = preload("res://solar_system/solar_system.gd")
const WaypointScene = preload("../waypoints/waypoint.tscn")

const MOUSE_TURN_SENSITIVITY = 0.1

var _pitch := 0.0
var _yaw := 0.0

var distance

var camera
var planet
var pivot

func _get_solar_system() -> SolarSystem:
	# TODO That looks really bad. Probably need to use injection some day
	return get_parent().get_parent() as SolarSystem

func load_waypoints():
	
	var deposits = Server.planet_get_deposits()
	for mine in deposits:
		var waypoint = WaypointScene.instance()
		waypoint.transform = planet.get_surface_transform(mine.pos)
		waypoint.set_meta("mine", mine)
		planet.node.add_child(waypoint)
		planet.waypoints.append(waypoint)

	
	
	
func clear_waypoints():
	for i in range(planet.waypoints.size(), 0):
		var w = planet.waypoints[i]
		if w.has_meta("mine"):
			planet.waypoints.remove(i)
			w.queue_free()

func enable():

	camera = get_viewport().get_camera()

	planet = _get_solar_system().get_reference_stellar_body()
	pivot = planet.node.get_node("head")
	
	camera.set_target(planet.node)
	distance = camera.distance_to_target

	set_process_input(true)

	get_tree().call_group("planet_mode", "pm_enabled", true)
	
	load_waypoints()

func disable():
	set_process_input(false)
	get_tree().call_group("planet_mode", "pm_enabled", false)
	
	clear_waypoints()
	

func _input(event):
	
	if (event is InputEventMouseMotion) && Input.is_mouse_button_pressed(BUTTON_LEFT):
		var motion = event.relative
		
		# Add to rotations
		_yaw -= motion.x * MOUSE_TURN_SENSITIVITY
		_pitch += motion.y * MOUSE_TURN_SENSITIVITY

		update_rotations()

	if event.is_action_pressed("zoom_in"):
		distance -= 10
		camera.distance_to_target = distance
	elif event.is_action_pressed("zoom_out"):
		distance += 10
		camera.distance_to_target = distance

	if event.is_action_pressed("planet_mode_toggle"):
		disable()

func update_rotations():
	pivot.rotation = Vector3(0, deg2rad(_yaw), 0)
	pivot.rotate(pivot.transform.basis.x.normalized(), -deg2rad(_pitch))

func pm_try_enable():
	var ref = _get_solar_system().get_reference_stellar_body()
	if ref.type == StellarBody.TYPE_SUN:
		printt("no current planet")
		return
		
	enable()
	

func _ready():
	set_process_input(false)
	add_to_group("planet_mode")
	camera = get_viewport().get_camera()
	pass

