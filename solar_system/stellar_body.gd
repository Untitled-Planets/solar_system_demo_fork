class_name StellarBody
const PlanetAtmosphere = preload("res://addons/zylann.atmosphere/planet_atmosphere.gd")

const TYPE_SUN = 0
const TYPE_ROCKY = 1
const TYPE_GAS = 2

# Static values
var name := ""
var type := TYPE_SUN
var parent_id := -1
var radius := 0.0
var distance_to_parent := 0.0
var orbit_revolution_time := 0.0
var self_revolution_time := 0.0
var orbit_tilt := 0.0
var self_tilt := 0.0
var atmosphere_color := Color(0.5, 0.7, 1.0)
var sea := false
var day_ambient_sound : AudioStream
var night_ambient_sound : AudioStream

# State values
var orbit_revolution_progress := 0.0
var self_revolution_progress := 0.0
var day_count := 0
var year_count := 0
var static_bodies_are_in_tree := false

#var portal_spawn_point: Node3D = Node3D.new()

var waypoints = []

# Godot stuff
var node : Node3D
var volume : VoxelLodTerrain
var instancer : VoxelInstancer
var atmosphere : PlanetAtmosphere
var static_bodies := []

var _machine_pivot: Node3D
var _waypoint_pivot: Node3D

func _notification(what: int):
	if what == NOTIFICATION_PREDELETE:
		if not static_bodies_are_in_tree:
			for sb in static_bodies:
				sb.free()

func get_surface_transform(pos):
	var t = Transform3D().rotated(Vector3.UP, deg_to_rad(pos.y))
	var cross := Vector3.UP.cross(t.basis.z)
	t = t.rotated(cross, deg_to_rad(pos.x))
	t = t.translated_local(Vector3(0, 0, radius))
	return t

func add_machine(p_machine: MachineCharacter) -> void:
	_machine_pivot.add_child(p_machine)

func remove_machines() -> void:
	for c in _machine_pivot.get_children():
		c.queue_free()


func add_waypoint(p_index: int, p_waypoint: Waypoint):
	if p_index > _waypoint_pivot.get_child_count():
		pass
	pass

# Returns the position relative to the planet to spawn an machine.
func get_spawn_point() -> Vector3:
	return node.basis.y * radius
