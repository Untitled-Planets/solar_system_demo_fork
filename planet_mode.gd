class_name PlanetMode
extends Node

#const StellarBody = preload("res://solar_system/stellar_body.gd")
#const SolarSystem = preload("res://solar_system/solar_system.gd")
const MOUSE_TURN_SENSITIVITY = 0.1

@export var WaypointScene: PackedScene = null


var _pitch := 0.0
var _yaw := 0.0

var distance

var _is_enabled = false
var is_enabled: bool:
	get:
		return _is_enabled

#@export var planet_radius: float:
#	get:
#		return _planet_radius
#	set(value):
#		set_planet_radius(value)

var _planet
var camera
var planet: StellarBody:
	get:
		return _planet
	set(value):
		_planet = value

var pivot

func _get_solar_system() -> SolarSystem:
	# TODO That looks really bad. Probably need to use injection some day
	return get_parent() as SolarSystem

func load_waypoints():
	var deposits = Server.planet_get_deposits(_get_solar_system().get_reference_stellar_body_id())
#	var ss := _get_solar_system()
	for index in deposits.size():
		var mine = deposits[index]
		var waypoint: Waypoint = WaypointScene.instantiate()
		waypoint.transform = planet.get_surface_transform(mine.pos)
		waypoint.location = mine.pos
		waypoint.info = "Mine pos: {}\nAmount: {}".format([mine.pos, mine.amount], "{}")
		waypoint.location_id = index
		planet.node.add_child(waypoint)
		planet.waypoints.append(waypoint)


func clear_waypoints():
	var ws = planet.waypoints
	planet.waypoints = []
	for w in ws:
		w.queue_free()

func enable():
	print("Enabling planet_mode")
	camera = get_viewport().get_camera_3d()

	planet = _get_solar_system().get_reference_stellar_body()
	pivot = planet.node.get_node("head")
	
	camera.set_target(planet.node)
	distance = camera.distance_to_target

	set_process_input(true)

	get_tree().call_group("planet_mode", "pm_enabled", true)
	
	load_waypoints()
	
	_config_camera(false)
	
	_is_enabled = true

func disable():
	set_process_input(false)
	get_tree().call_group("planet_mode", "pm_enabled", false)
	
	clear_waypoints()
	
	_config_camera(true)
	
	_is_enabled = false


func _config_camera(p_collision_enabled: bool) -> void:
	var player_camera: PlayerCamera = get_viewport().get_camera_3d()
	if player_camera:
		player_camera.collision_detection_enabled = p_collision_enabled

func _input(event):
	
	if (event is InputEventMouseMotion) && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
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
	pivot.rotation = Vector3(0, deg_to_rad(_yaw), 0)
	pivot.rotate(pivot.transform.basis.x.normalized(), -deg_to_rad(_pitch))

func pm_try_enable():
	var ref = _get_solar_system().get_reference_stellar_body()
	if ref.type == StellarBody.TYPE_SUN:
		printt("no current planet")
		return
		
	enable()
	

func _ready():
	set_process_input(false)
#	add_to_group("planet_mode")
	camera = get_viewport().get_camera_3d()

