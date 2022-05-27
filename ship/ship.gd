extends RigidBody

const StellarBody = preload("../solar_system/stellar_body.gd")
const Util = preload("../util/util.gd")

const STATE_LANDED = 0
const STATE_FLYING = 1

export var linear_acceleration := 10.0
export var angular_acceleration := 1000.0
export var speed_cap_on_planet := 40.0
export var speed_cap_in_space := 400.0

onready var _visual_root = $Visual/VisualRoot
onready var _controller = $Controller
onready var _landed_nodes = [
	$Visual/VisualRoot/ship/Interior2,
	$Visual/VisualRoot/ship/HatchDown/KinematicBody,
	$CommandPanel
]
onready var _landed_node_parents = []
onready var _flight_collision_shapes = [
	$FlightCollisionShape,
	#$FlightCollisionShape2,
	#$FlightCollisionShape3
]
onready var _animation_player = $AnimationPlayer
onready var _main_jets = [
	$Visual/VisualRoot/JetVFXMainLeft,
	$Visual/VisualRoot/JetVFXMainRight,
]
onready var _left_roll_jets = [
	$Visual/VisualRoot/JetVFXLeftWing1,
	$Visual/VisualRoot/JetVFXLeftWing2
]
onready var _right_roll_jets = [
	$Visual/VisualRoot/JetVFXRightWing1,
	$Visual/VisualRoot/JetVFXRightWing2
]
onready var _audio = $ShipAudio

var _move_cmd := Vector3()
var _turn_cmd := Vector3()
var _superspeed_cmd := false
var _exit_ship_cmd := false
var _state := STATE_FLYING
var _planet_damping_amount := 0.0 # TODO Doesnt need to be a member var
var _ref_change_info = null
var _was_superspeed := false
var _last_contacts_count := 0

var current_character

func _ready():
	
	add_to_group("planet_mode")
	
	for n in _landed_nodes:
		_landed_node_parents.append(n.get_parent())
	
	_visual_root.global_transform = global_transform
	enable_controller()
	
	get_solar_system().connect(
		"reference_body_changed", self, "_on_solar_system_reference_body_changed")

func pm_enabled(p_enabled):

	if current_character:
		return

	_controller.set_enabled(!p_enabled)

	if p_enabled:
		disable_controller()
	else:
		var camera = get_viewport().get_camera()
		camera.set_target(self)
		enable_controller()


func set_character(p_char):
	
	current_character = p_char
	if current_character:
		disable_controller()
	else:
		enable_controller()

func enable_controller():
	_controller.set_enabled(true)
	for n in _landed_nodes:
		n.get_parent().remove_child(n)
	for cs in _flight_collision_shapes:
		cs.disabled = false
	mode = RigidBody.MODE_RIGID
	_close_hatch()
	_state = STATE_FLYING
	_audio.play_enabled()


func disable_controller():
	_controller.set_enabled(false)
	for i in len(_landed_nodes):
		_landed_node_parents[i].add_child(_landed_nodes[i])
	for cs in _flight_collision_shapes:
		cs.disabled = true
	mode = RigidBody.MODE_STATIC
	_open_hatch()
	_state = STATE_LANDED
	_audio.play_disabled()


func _notification(what: int):
	if what == NOTIFICATION_PREDELETE:
		if _state != STATE_LANDED:
			for n in _landed_nodes:
				n.free()


func _open_hatch():
	_animation_player.play("hatch_open")


func _close_hatch():
	_animation_player.play_backwards("hatch_open")


func _on_solar_system_reference_body_changed(info):
	# We'll do that in `_integrate_forces`,
	# because Godot can't be bothered to do such override for us.
	# The camera following the ship will also needs to account for that delay...
	_ref_change_info = info
	#transform = info.inverse_transform * transform
	#_linear_velocity = info.inverse_transform.basis * _linear_velocity


func get_solar_system():
	return get_parent()


func set_move_cmd(vec: Vector3):
	_move_cmd = vec


func set_turn_cmd(vec: Vector3):
	_turn_cmd = vec


func set_superspeed_cmd(cmd: bool):
	_superspeed_cmd = cmd


func _integrate_forces(state: PhysicsDirectBodyState):
	if _ref_change_info != null:
		# Teleport
		state.transform = _ref_change_info.inverse_transform * state.transform
		state.linear_velocity = _ref_change_info.inverse_transform.basis * state.linear_velocity
		_ref_change_info = null
	
	var gtrans := state.transform
	var forward := -gtrans.basis.z
	var right := gtrans.basis.x
	var up := gtrans.basis.y

	var stellar_body : StellarBody = get_solar_system().get_reference_stellar_body()
	var linear_acceleration_mod := linear_acceleration
	var speed_cap_in_space_mod := speed_cap_in_space
	
	var superspeed = false
	if _superspeed_cmd and stellar_body.type == StellarBody.TYPE_SUN:
		speed_cap_in_space_mod *= 10.0
		linear_acceleration_mod *= 15.0
		superspeed = true
	
	if superspeed != _was_superspeed:
		if superspeed:
			_audio.play_start_superspeed()
		else:
			_audio.play_stop_superspeed()
		_was_superspeed = superspeed

	var speed_cap := speed_cap_in_space_mod
	
	var motor = _move_cmd.z * forward * linear_acceleration_mod
	state.add_force(motor, Vector3())

	_turn_cmd.x = clamp(_turn_cmd.x, -1, 1)
	_turn_cmd.y = clamp(_turn_cmd.y, -1, 1)
	_turn_cmd.z = clamp(_turn_cmd.z, -1, 1)
	
	state.apply_torque_impulse(up * _turn_cmd.x * angular_acceleration)
	state.apply_torque_impulse(right * _turn_cmd.y * angular_acceleration)
	state.apply_torque_impulse(forward * _turn_cmd.z * angular_acceleration)

	# Angular damping?
	#state.apply_torque_impulse(-state.angular_velocity * 0.01)

	# Planet influence
	if stellar_body.type != StellarBody.TYPE_SUN:
		var pull_center := stellar_body.node.global_transform.origin
		var distance_to_core := pull_center.distance_to(gtrans.origin)

		# Gravity
		# TODO Need a No-Man-Sky-esque mechanic to land without gravity
		# In case you dive into a stellar body, gravity actually reduces as you get closer to
		# the core, because some mass is now behind you
		var gd := abs(distance_to_core - stellar_body.radius) + stellar_body.radius
		var gravity_dir := (pull_center - gtrans.origin).normalized()
		var stellar_mass := Util.get_sphere_volume(stellar_body.radius)
		var f := 0.005 * stellar_mass / (gd * gd)
		state.add_force(gravity_dir * f, Vector3())
		
		# Near-planet damping
		var distance_to_surface := distance_to_core - stellar_body.radius
		_planet_damping_amount = \
			1.0 - clamp((distance_to_surface - 50.0) / stellar_body.radius, 0.0, 1.0)
		DDD.set_text("Atmosphere damping amount", _planet_damping_amount)
		speed_cap = lerp(speed_cap_in_space_mod, speed_cap_on_planet, _planet_damping_amount)
	
	var speed := state.linear_velocity.length()
	if speed > speed_cap:
		state.linear_velocity = state.linear_velocity.normalized() * speed_cap
	
	# Jets
	var main_jet_power = _move_cmd.z
	for jet in _main_jets:
		jet.set_power(main_jet_power)
	var left_roll_jet_power = max(_turn_cmd.z, 0.0)
	var right_roll_jet_power = max(-_turn_cmd.z, 0.0)
	for jet in _left_roll_jets:
		jet.set_power(left_roll_jet_power)
	for jet in _right_roll_jets:
		jet.set_power(right_roll_jet_power)
	_audio.set_main_jet_power(abs(_move_cmd.z))
	_audio.set_secondary_jet_power(clamp(left_roll_jet_power + right_roll_jet_power, 0.0, 1.0))

	DDD.set_text("Speed", state.linear_velocity.length())
	DDD.set_text("X", gtrans.origin.x)
	DDD.set_text("Y", gtrans.origin.y)
	DDD.set_text("Z", gtrans.origin.z)
	
	_visual_root.global_transform = gtrans
	
	_last_contacts_count = state.get_contact_count()


func get_last_contacts_count() -> int:
	return _last_contacts_count

