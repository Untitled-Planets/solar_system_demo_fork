
# Processes character physics.
# This is a simple implementation, enough for testing and simple games.
# If you need more specialized behavior, feel free to fork it.
class_name Character
extends CharacterBody3D

const VERTICAL_CORRECTION_SPEED = PI
const MOVE_ACCELERATION = 75.0
const MOVE_DAMP_FACTOR = 0.2
const JUMP_COOLDOWN_TIME = 0.3
const JUMP_SPEED = 10.0
const GRAVITY = 25.0

signal jumped

# In this system, the mouse does not control the camera directly,
# but a Node3D under the character, named "Head", representing the head.
# The camera may then use the transform of the Head to orient itself.
@onready var _head : Node3D = $Head
@onready var _mannequiny: Mannequiny = $Visual/mannequiny
@onready var _remote_movement = $remote_movement
@onready var _visual_root : Node3D = $Visual
@onready var _visual_head : Node3D = $Visual/Head
@onready var _visual_animated : Mannequiny = $Visual/mannequiny
@onready var _flashlight = $Visual/FlashLight
@onready var _audio = $Audio

var _velocity := Vector3()
var _jump_cooldown := 0.0
var _jump_cmd := 0
var _motor := Vector3()
var _planet_up := Vector3(0, 1, 0)
var _landed := false
var _visual_state = Mannequiny.States.IDLE
var _controller
var _direction: Vector3 = Vector3.ZERO




func jump():
	_jump_cmd = 5


# Local X and Z axes are used to strafe or move forward.
# This input is from user input
func set_motor(motor: Vector3):
	_motor = motor
	var plane := Plane(_planet_up, 0)
	var head_trans := _head.global_transform
	var right := plane.project(head_trans.basis.x)
	var forward := plane.project(-head_trans.basis.z)
	var dir := (_motor.z * forward + _motor.x * right).normalized()
#	_align_head_with_camera(get_viewport().get_camera_3d())
	set_direction(dir)


func _align_head_with_camera(p_camera: Camera3D):
	var back := p_camera.global_transform.basis.z
	var up := _head.global_transform.basis.y
	var b := Basis(_planet_up.cross(back) ,up, back)
	_head.look_at(_head.global_position + -back, _planet_up)

# You can decide gravity has a different direction.
func set_planet_up(up: Vector3):
	_planet_up = up


func get_head() -> Node3D:
	return _head

func _process(delta: float):
	var character_body := self
	var gtrans := character_body.global_transform

	# We want to rotate only along local Y
	var plane := Plane(_visual_root.global_transform.basis.y, 0)
	var head_basis := _head.global_transform.basis
	var forward := plane.project(-head_basis.z)
	if forward == Vector3():
		forward = Vector3(0, 1, 0)
	var up := gtrans.basis.y
	
	# Visual can be offset.
	# We need global transfotm tho cuz look_at wants a global position
	gtrans.origin = _visual_root.global_transform.origin
	
	var old_root_basis = _visual_root.transform.basis.orthonormalized()
	_visual_root.look_at(gtrans.origin + forward, up)
	_visual_root.transform.basis = old_root_basis.slerp(_visual_root.transform.basis, delta * 8.0)
	
	# TODO Temporarily removed Mannequinny, it did not port well to Godot4
	_process_visual_animated(forward, character_body)
	
	_visual_head.global_transform.basis = head_basis
	
#	if Input.is_action_just_pressed("spawn_miner_test"):
#		_spawn_miner()


func _process_visual_animated(forward: Vector3, character_body: CharacterBody3D):
	_visual_animated.set_move_direction(forward)

	var _last_motor: Vector3 = _direction
	var state = Mannequiny.States.RUN
	if _last_motor.length_squared() > 0.0:
		_visual_animated.set_is_moving(true)
		state = Mannequiny.States.RUN
	else:
		_visual_animated.set_is_moving(false)
		state = Mannequiny.States.IDLE
	if not character_body.is_landed():
		state = Mannequiny.States.AIR
	_set_visual_state(state)


func _set_visual_state(state: Mannequiny.States):
	# TODO Temporarily removed Mannequinny, it did not port well to Godot4
#	pass
	if _visual_state != state:
		_visual_state = state
		_visual_animated.transition_to(_visual_state)

func _physics_process(delta : float):
	var gtrans := global_transform
	var current_up := gtrans.basis.y
	var planet_up := _planet_up
	
#	if not _detect_planet():
#		return
	
	if planet_up.dot(current_up) < 0.999:
		# Align with planet.
		# This assumes the origin of the character is at the bottom.
		# TODO make it so it doesnt have to be
		var correction_axis := planet_up.cross(current_up).normalized()
		var correction_rot = Basis(
			correction_axis, -current_up.angle_to(planet_up) * VERTICAL_CORRECTION_SPEED * delta)
		gtrans.basis = correction_rot * gtrans.basis
		gtrans.origin += planet_up * 0.01
		global_transform = gtrans

	var plane := Plane(planet_up, 0)
	
	
	# Motor
	
	_velocity += _direction * MOVE_ACCELERATION * delta
	

	# Damping
	var planar_velocity := plane.project(_velocity)
	_velocity -= planar_velocity * MOVE_DAMP_FACTOR
	
	
	# To stop sliding on slopes while the player doesn't want to move, 
	# we can stop applying gravity if on the floor.
	if is_on_floor():
		# But this is not enough. `is_on_floor()` is highly unreliable when standing on the floor.
		# `is_on_floor()` can flip back to `false` just because we call `move_and_slide()`,
		# even with a null vector. So if our velocity comes to a stop while on the floor,
		# we make sure it gets nullified, and then we won't call `move_and_slide()` at all.
		if _velocity.length() < 0.001:
			_velocity = Vector3()
	else:
		# Apply gravity
		_velocity -= planet_up * GRAVITY * delta

	var space_state = get_world_3d().direct_space_state
	var ray_query := PhysicsRayQueryParameters3D.new()
	ray_query.from = gtrans.origin + 0.1 * planet_up
	ray_query.to = gtrans.origin - 0.1 * planet_up
	ray_query.exclude = [get_rid()]
	var ground_hit = space_state.intersect_ray(ray_query)
	_landed = not ground_hit.is_empty()
	
	if _velocity == Vector3() and is_on_floor():
		# BUT! If we remove the floor, by digging or other, our character will remain in the air,
		# because the only way to stop being on floor is to call that bad boy `move_and_slide`.
		# So we'll check ourselves if there is something under our feet, and add gravity back.
		if ground_hit.is_empty():
			_velocity -= planet_up * 0.01
	
	if _velocity != Vector3():
		up_direction = current_up
		if abs(_velocity.normalized().dot(up_direction)) < 0.9:
#			var camera: Camera3D = get_viewport().get_camera_3d()
			var projected := plane.project(_direction)
			var char_projected := plane.project(-_head.global_transform.basis.z)
			var angle: float = char_projected.signed_angle_to(projected, planet_up)
			_mannequiny.rotation.y = angle
#		print(_velocity)
		velocity = _velocity
		move_and_slide()
		_velocity = velocity
	
	# Jumping
	if _jump_cooldown > 0.0:
		_jump_cooldown -= delta
	elif _jump_cmd > 0:
		# Is there ground to jump from?
		if is_on_floor(): # not hit.is_empty():
			_velocity += planet_up * JUMP_SPEED
			_jump_cooldown = JUMP_COOLDOWN_TIME
			_jump_cmd = 0
			emit_signal("jumped")

	# is_on_floor() is SO UNBELIEVABLY UNRELIABLE it harms jump responsivity
	# so we spread it over several frames
	_jump_cmd -= 1
	
	# orientation
	_update_orientation()


func _detect_planet() -> bool:
	var space_state = get_world_3d().direct_space_state
	var ray_query := PhysicsRayQueryParameters3D.new()
	ray_query.from = global_transform.origin + 0.1 * _planet_up
	ray_query.to = Vector3.ZERO
	ray_query.exclude = [get_rid()]
	var ground_hit = space_state.intersect_ray(ray_query)
	return not ground_hit.is_empty()

func _update_orientation() -> void:
	var planet_center := Vector3()
	var gtrans := global_transform
	var planet_up := (gtrans.origin - planet_center).normalized()
	set_planet_up(planet_up)

func get_controller():
	return _controller

func get_flashlight():
	return _flashlight

func get_audio():
	return _audio

func set_controller(p_controller) -> void:
	_controller = p_controller


func is_landed() -> bool:
	return _landed

func set_direction(p_direction: Vector3) -> void:
	_direction = p_direction

#func update_position_from_remote(p_position):
#	_remote_movement.add_last_know_position(p_position)

#func set_position_from_remote(p_position: Vector3) -> void:
#	_remote_position = p_position
