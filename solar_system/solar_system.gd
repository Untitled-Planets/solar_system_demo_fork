extends Node


const StellarBody = preload("./stellar_body.gd")

const SunMaterial = preload("./materials/sun_yellow.tres")
const PlanetRockMaterial = preload("materials/planet_surface_rocks.tres")
const VolumetricAtmosphereScene = preload("../atmosphere/volumetric_atmosphere.tscn")

const BODY_REFERENCE_ENTRY_RADIUS_FACTOR = 3.0
const BODY_REFERENCE_EXIT_RADIUS_FACTOR = 3.25 # Must be higher for hysteresis


class ReferenceChangeInfo:
	var inverse_transform : Transform


signal reference_body_changed(info)


onready var _environment = $WorldEnvironment.environment
onready var _ship = $Ship

var _bodies := []
var _reference_body_id := 0
var _directional_light : DirectionalLight
var _physics_process_count := 0


func _ready():
	var sun = StellarBody.new()
	sun.type = StellarBody.TYPE_SUN
	sun.radius = 1500.0
	sun.self_revolution_time = 60.0
	sun.orbit_revolution_time = 60.0
	sun.name = "Sun"
	_bodies.append(sun)
	
	var planet = StellarBody.new()
	planet.name = "Mercury"
	planet.type = StellarBody.TYPE_ROCKY
	planet.radius = 256.0
	planet.parent_id = 0
	planet.distance_to_parent = 14400.0
	planet.self_revolution_time = 10.0 * 60.0
	planet.orbit_revolution_time = 50.0 * 60.0
	_bodies.append(planet)

	planet = StellarBody.new()
	planet.name = "Earth"
	planet.type = StellarBody.TYPE_ROCKY
	planet.radius = 480.0
	planet.parent_id = 0
	planet.distance_to_parent = 25600.0
	planet.self_revolution_time = 10.0 * 60.0
	planet.orbit_revolution_time = 150.0 * 60.0
	var earth_id = len(_bodies)
	_bodies.append(planet)

	planet = StellarBody.new()
	planet.name = "Moon"
	planet.type = StellarBody.TYPE_ROCKY
	planet.radius = 160.0
	planet.parent_id = earth_id
	planet.distance_to_parent = 3200.0
	planet.self_revolution_time = 10.0 * 60.0
	planet.orbit_revolution_time = 1.0 * 60.0
	_bodies.append(planet)

	planet = StellarBody.new()
	planet.name = "Mars"
	planet.type = StellarBody.TYPE_ROCKY
	planet.radius = 320.0
	planet.parent_id = 0
	planet.distance_to_parent = 48000.0
	planet.self_revolution_time = 10.0 * 60.0
	planet.orbit_revolution_time = 100.0 * 60.0
	_bodies.append(planet)

	planet = StellarBody.new()
	planet.name = "Jupiter"
	planet.type = StellarBody.TYPE_GAS
	planet.radius = 960.0
	planet.parent_id = 0
	planet.distance_to_parent = 70400.0
	planet.self_revolution_time = 8.0 * 60.0
	planet.orbit_revolution_time = 300.0 * 60.0
	_bodies.append(planet)
	
	_directional_light = DirectionalLight.new()
	_directional_light.shadow_enabled = true
	_directional_light.directional_shadow_normal_bias = 0.2
	_directional_light.directional_shadow_split_1 = 0.1
	_directional_light.directional_shadow_split_2 = 0.2
	_directional_light.directional_shadow_split_3 = 0.5
	_directional_light.directional_shadow_blend_splits = true
	_directional_light.directional_shadow_max_distance = 200.0
	
	for i in len(_bodies):
		var body : StellarBody = _bodies[i]

		var mesh := SphereMesh.new()
		mesh.radial_segments = 128
		mesh.rings = 64
		mesh.radius = body.radius
		mesh.height = mesh.radius * 2.0

		var mi := MeshInstance.new()
		mi.mesh = mesh
		mi.name = body.name
		
		var mat : SpatialMaterial
		if body.type == StellarBody.TYPE_SUN:
			mat = SunMaterial
			mi.cast_shadow = false
		else:
			mat = PlanetRockMaterial
		mi.material_override = mat
		
		var atmo = VolumetricAtmosphereScene.instance()
		#atmo.scale = Vector3(1, 1, 1) * (0.99 * body.radius)
		atmo.planet_radius = body.radius
		atmo.atmosphere_height = 0.12 * body.radius
		atmo.directional_light = _directional_light
		mi.add_child(atmo)
		
		body.node = mi
		add_child(mi)

	sun.node.add_child(_directional_light)


# DEBUG
func _input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.scancode:
				KEY_R:
					if _reference_body_id == 0:
						set_reference_body(2)
					else:
						set_reference_body(0)


func _physics_process(delta: float):
	# Check when to change referential
	if _physics_process_count > 0:
		if _reference_body_id == 0:
			for i in len(_bodies):
				var body : StellarBody = _bodies[i]
				if body.type == StellarBody.TYPE_SUN:
					# Ignore sun, no point landing there
					continue
				var body_pos = body.node.global_transform.origin
				var d = body_pos.distance_to(_ship.global_transform.origin)
				if d < BODY_REFERENCE_ENTRY_RADIUS_FACTOR * body.radius:
					print("Close to ", body.name, " which is at ", body_pos)
					set_reference_body(i)
					break
		else:
			var ref_body = _bodies[_reference_body_id]
			var body_pos = ref_body.node.global_transform.origin
			var d = body_pos.distance_to(_ship.global_transform.origin)
			if d > BODY_REFERENCE_EXIT_RADIUS_FACTOR * ref_body.radius:
				set_reference_body(0)
	
	# Calculate current referential transform
	var ref_trans_inverse = Transform()
	if _reference_body_id != 0:
		var ref_body = _bodies[_reference_body_id]
		var ref_trans = _compute_absolute_body_transform(ref_body)
		ref_trans_inverse = ref_trans.affine_inverse()

	# Simulate orbits
	for i in len(_bodies):
		var body : StellarBody = _bodies[i]
		
		body.self_revolution_progress += delta / body.self_revolution_time
		if body.self_revolution_progress >= 1.0:
			body.self_revolution_progress -= 1.0
			body.day_count += 1
		
		body.orbit_revolution_progress += delta / body.orbit_revolution_time
		if body.orbit_revolution_progress >= 1.0:
			body.orbit_revolution_progress -= 1.0
			body.year_count += 1
		
		if _reference_body_id == i:
			# Don't touch the reference body
			continue
		
		var trans = _compute_absolute_body_transform(body)
		
		if _reference_body_id != 0:
			trans = ref_trans_inverse * trans
		
		body.node.transform = trans
	
	# Update directional light. Smoke and mirrors here
	var camera : Camera = get_viewport().get_camera()
	if camera != null:
		var pos = camera.global_transform.origin
		pos.y = 0.0
		if pos != _directional_light.global_transform.origin:
			_directional_light.look_at(pos, Vector3(0, 1, 0))
	
	# Update sky rotation
	if _reference_body_id != 0:
		_environment.background_sky_orientation = ref_trans_inverse.basis
	else:
		_environment.background_sky_orientation = Basis()
	
	DDD.set_text("Reference body", _bodies[_reference_body_id].name)
	_physics_process_count += 1


func set_reference_body(ref_id: int):
	if _reference_body_id == ref_id:
		return
	_reference_body_id = ref_id
	var body = _bodies[_reference_body_id]
	print("Setting reference to ", ref_id, " (", body.name, ")")
	var trans = body.node.transform
	body.node.transform = Transform()
	var info = ReferenceChangeInfo.new()
	# TODO Also have relative velocity of the body,
	# so the ship can integrate it so it looks seamless
	info.inverse_transform = trans.affine_inverse() * body.node.transform
	emit_signal("reference_body_changed", info)


func _compute_absolute_body_transform(body: StellarBody) -> Transform:
	if body.parent_id == -1:
		# Sun
		return Transform()
	var parent_transform := Transform()
	if body.parent_id != -1:
		var parent_body = _bodies[body.parent_id]
		parent_transform = _compute_absolute_body_transform(parent_body)
	var orbit_angle := body.orbit_revolution_progress * TAU
	# TODO Elliptic orbits
	var pos := Vector3(cos(orbit_angle), 0, sin(orbit_angle)) * body.distance_to_parent
	pos = pos.rotated(Vector3(0, 0, 1), body.orbit_tilt)
	var self_angle := body.self_revolution_progress * TAU
	var basis := Basis(Vector3(0, self_angle, body.self_tilt))
	var local_transform := Transform(basis, pos)
	return parent_transform * local_transform


func get_stellar_body_count() -> int:
	return len(_bodies)


func get_stellar_body(idx: int) -> StellarBody:
	return _bodies[idx]
