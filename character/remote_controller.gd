class_name RemoteController
extends Node

#const StellarBody = preload("../solar_system/stellar_body.gd")
#const SolarSystem = preload("../solar_system/solar_system.gd")
const Ship = preload("../ship/ship.gd")
#const Util = preload("../util/util.gd")
const CollisionLayers = preload("../collision_layers.gd")
# TODO This is very close to Godot's CharacterBody3D. Introduce prefixes?
# It could be confusing to not realize this is actually from the project and not Godot
#const CharacterBody = preload("res://addons/zylann.3d_basics/character/character.gd")
const SplitChunkRigidBodyComponent = preload("../solar_system/split_chunk_rigidbody_component.gd")

#const WaypointScene = preload("../waypoints/waypoint.tscn")

const VERTICAL_CORRECTION_SPEED = PI
const MOVE_ACCELERATION = 40.0
const MOVE_DAMP_FACTOR = 0.1
const JUMP_COOLDOWN_TIME = 0.3
const JUMP_SPEED = 8.0


@export var _mouse_turn_sensitivity: float = 0.1
@export var _max_angle: float = 89.0
@export var _min_angle: float = -89.0

var _dig_cmd := false
var _interact_cmd := false
var _build_cmd := false
var _waypoint_cmd := false
var _visual_state = Mannequiny.States.IDLE
var _last_motor := Vector3()
var _player_id: int = -1
var _game: Game
var _pickable: PickableObject = null
var _is_picking: bool = false
var _uuid: String = ""

var _flashlight : SpotLight3D
var _audio
var _character: Character = null
var _solar_system: SolarSystem = null
var _last_known_position: Vector3 = Vector3.ZERO

var _pitch := 0.0
var _yaw := 0.0


func _ready():
	_game = get_tree().get_nodes_in_group("game")[0]
#	_flashlight = get_node(_flashlight_nodepath)
#	_audio = get_node(_audio_nodepath)
#	_remote_movement = get_node(_remote)
#	await get_tree().process_frame # wait for parent.
#	set_multiplayer_authority(get_parent().network_id)
	
#	MultiplayerServer.resource_collection_finished.connect(_on_resource_collection_finished)

#func set_enable_local_controller(p_value: bool):
#	var enabled := p_value
#	set_physics_process(enabled)
##	set_process(enabled)
#	set_process_input(enabled)
#	set_process_unhandled_input(enabled)
##	_remote_movement.set_process(not enabled)
#	pass

# If uuid is empty. It is local player.
func set_uuid(p_uuid: String):
	_uuid = p_uuid


#func _on_resource_collection_finished(p_resource_id):
#	if _pickable:
#		_pickable.queue_free()

func _physics_process(delta):
	_follow_original(delta)

func _follow_original(delta: float) -> void:
	if _last_known_position != Vector3.ZERO:
		var delta_movement := _last_known_position - _character.global_position
		if delta_movement.length_squared() > 0.1:
			_character.set_direction(delta_movement.normalized())
		else:
			_character.set_direction(Vector3.ZERO)

#	var motor := Vector3()
#
##	if Input.is_key_pressed(KEY_W):
#	if Input.is_action_pressed("forward"):
#		motor += Vector3(0, 0, -1)
##	if Input.is_key_pressed(KEY_S):
#	if Input.is_action_pressed("back"):
#		motor += Vector3(0, 0, 1)
##	if Input.is_key_pressed(KEY_A):
#	if Input.is_action_pressed("left"):
#		motor += Vector3(-1, 0, 0)
##	if Input.is_key_pressed(KEY_D):
#	if Input.is_action_pressed("right"):
#		motor += Vector3(1, 0, 0)
#
#	var character_body := _get_body()
#	character_body.set_motor(motor)
#
#	var planet_center := Vector3()
#	var gtrans := character_body.global_transform
#	var planet_up := (gtrans.origin - planet_center).normalized()
#	character_body.set_planet_up(planet_up)
#
#	_process_actions()
#	_process_undig()
#
#	_last_motor = motor
#
#	_pick(Input.is_action_pressed("pick_object"))

#func _pick(p_value: bool):
##	var picking := p_value
#	if _is_picking != p_value:
#		if _pickable and p_value:
#			MultiplayerServer.start_resource_collect(0, _game.get_solar_system().get_reference_stellar_body_id(), _pickable.get_id(), 1)
##			rpc("_server_pick", _pickable.get_id())
#		else:
#			pass
#		_is_picking = p_value


#@rpc
#func _server_pick(p_resource_id: String):
#	print("_server_pick")
#	if multiplayer.is_server():
#		print("Calling from server")

func finish_collect_resource():
	_is_picking = false


func _process_undig():
	var solar_system = _get_solar_system()
	if solar_system == null:
		# In testing scene?
		return
	var volume = solar_system.get_reference_stellar_body().volume
	var vt = volume.get_voxel_tool()
	var to_local = volume.global_transform.affine_inverse()
	var character_body = _get_body()
	var local_pos = to_local * character_body.global_transform.origin
	vt.channel = VoxelBuffer.CHANNEL_SDF
	var sdf = vt.get_voxel_f_interpolated(local_pos)
#	DDD.set_text("SDF at feet", sdf)
	if sdf < -0.001:
		# We got buried, teleport at nearest safe location
		print("Character is buried, teleporting back to air")
		var up = local_pos.normalized()
		var offset_local_pos = local_pos
		for i in 10:
			print("Undig attempt ", i)
			offset_local_pos += 0.2 * up
			sdf = vt.get_voxel_f_interpolated(offset_local_pos)
			if sdf > 0.0005:
				break
		var gtrans = character_body.global_transform
		gtrans.origin = volume.get_global_transform() * offset_local_pos
		character_body.global_transform = gtrans


func _process_actions():
	if _interact_cmd:
		_interact_cmd = false
#		_interact()

	var character_body := _get_body()
	
	var camera := get_viewport().get_camera_3d()
	var front := -camera.global_transform.basis.z
	var cam_pos = camera.global_transform.origin
	var space_state := character_body.get_world_3d().direct_space_state
	
	var ray_query := PhysicsRayQueryParameters3D.new()
	ray_query.from = cam_pos
	ray_query.to = cam_pos + front * 50.0
	ray_query.exclude = [character_body.get_rid()]
	var hit = space_state.intersect_ray(ray_query)

#	if not hit.is_empty():
#		if hit.collider is VoxelLodTerrain:
#			DDD.draw_box(hit.position, Vector3(0.5,0.5,0.5), Color(1,1,0))
#			DDD.draw_ray_3d(hit.position, hit.normal, 1.0, Color(1,1,0))
	
	if not hit.is_empty():
		if hit.collider is VoxelLodTerrain:
			var volume : VoxelLodTerrain = hit.collider

			if _dig_cmd:
				_dig_cmd = false
				var vt : VoxelTool = volume.get_voxel_tool()
				var pos = volume.get_global_transform().affine_inverse() * hit.position
				var sphere_size = 3.5
				#pos -= front * (sphere_size * 0.9)
				vt.channel = VoxelBuffer.CHANNEL_SDF
				vt.mode = VoxelTool.MODE_REMOVE
				vt.do_sphere(pos, sphere_size)
				_audio.play_dig(pos)

				var splitter_aabb = AABB(pos, Vector3()).grow(16.0)
				var bodies = vt.separate_floating_chunks(splitter_aabb, camera.get_parent())
				print("Created ", len(bodies), " bodies")
				for body in bodies:
					var cmp = SplitChunkRigidBodyComponent.new()
					body.add_child(cmp)
				DDD.draw_box_aabb(splitter_aabb, Color(0,1,0), 60)

			if _build_cmd:
				_build_cmd = false
				var vt : VoxelTool = volume.get_voxel_tool()
				var pos = volume.get_global_transform().affine_inverse() * hit.position
				vt.channel = VoxelBuffer.CHANNEL_SDF
				vt.mode = VoxelTool.MODE_ADD
				vt.do_sphere(pos, 3.5)
				_audio.play_dig(pos)
			
#			if _waypoint_cmd:
#				_waypoint_cmd = false
#				var planet = _get_solar_system().get_reference_stellar_body()
#				var waypoint = WaypointScene.instantiate()
#				waypoint.transform = Transform3D(character_body.transform.basis, hit.position)
#				planet.node.add_child(waypoint)
#				planet.waypoints.append(waypoint)
#				_audio.play_waypoint()


#func _input(event):
#	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
#		return
#
#	if event is InputEventMouseMotion:
#		# Get mouse delta
#		var motion = event.relative
#
#		# Add to rotations
#		_yaw -= motion.x * _mouse_turn_sensitivity
#		_pitch += motion.y * _mouse_turn_sensitivity
#
#		# Clamp pitch
#		var e = 0.001
#		if _pitch > _max_angle - e:
#			_pitch = _max_angle - e
#		elif _pitch < _min_angle + e:
#			_pitch = _min_angle + e
#
#	update_rotations()

#func _unhandled_input(event):
#	if event is InputEventKey:
#		if event.pressed and not event.is_echo():
#			match event.keycode:
#				KEY_SPACE:
#					var body := _get_body()
#					body.jump()
#				KEY_E:
#					_interact_cmd = true
#				KEY_F:
#					_flashlight.visible = not _flashlight.visible
#					if _flashlight.visible:
#						_audio.play_light_on()
#					else:
#						_audio.play_light_off()
#				KEY_T:
#					_waypoint_cmd = true
#
#	elif event is InputEventMouseButton:
#		if event.pressed:
#			match event.button_index:
#				MOUSE_BUTTON_LEFT:
#					_dig_cmd = true
#				MOUSE_BUTTON_RIGHT:
#					_build_cmd = true


#func _interact():
#	var character_body := _get_body()
#	var space_state := character_body.get_world_3d().direct_space_state
#	var camera := get_viewport().get_camera_3d()
#	var front := -camera.global_transform.basis.z
#	var pos = camera.global_transform.origin
#
#	var ray_query := PhysicsRayQueryParameters3D.new()
#	ray_query.from = pos
#	ray_query.to = pos + front * 10.0
#	ray_query.collision_mask = CollisionLayers.DEFAULT
#	ray_query.collide_with_bodies = false
#	ray_query.collide_with_areas = true
#	var hit = space_state.intersect_ray(ray_query)
#
#	if not hit.is_empty():
#		if hit.collider.name == "CommandPanel":
#			var ship = Util.find_parent_by_type(hit.collider, Ship)
#			if ship != null:
#				_enter_ship(ship)


#func update_rotations():
#	var head := _character.get_head()
#	head.rotation = Vector3(0, deg_to_rad(_yaw), 0)
#	head.rotate(head.transform.basis.x.normalized(), -deg_to_rad(_pitch))

#func _enter_ship(ship: Ship):
#	var camera = get_viewport().get_camera_3d()
#	camera.set_target(ship)
#	ship.enable_controller()
#	_get_body().queue_free()



func get_player_id() -> int:
	return _player_id

#func _spawn_miner() -> void:
#	var sl := SpawnLocation.new()
#	sl.location = Vector2()
#	sl.radius = 0.0
#	Server.miner_spawn(0, _game.get_solar_system().get_reference_stellar_body_id(), _game._username, )



func set_pickable_object(p_pickable: PickableObject) -> void:
	print(p_pickable)
	_pickable = p_pickable

func _get_solar_system() -> SolarSystem:
	# TODO That looks really bad. Probably need to use injection some day
	return _solar_system

func set_solar_system(p_solar_system: SolarSystem) -> void:
	_solar_system = p_solar_system

func _get_body() -> Character:
	return _character as Character


func get_character():
	return _character

func get_last_motor() -> Vector3:
	return _last_motor


func possess(p_char: Character) -> void:
	if _character:
		unpossess()
	
	if not p_char:
		return
	
	unpossess()
	
	_character = p_char
	_character.collision_layer = 0
	_flashlight = _character.get_flashlight()
	_audio = _character.get_audio()

func unpossess() -> void:
	if not _character:
		return
	
	_character.queue_free()
	_character = null

func set_remote_position(p_position: Vector3):
	_last_known_position = p_position
