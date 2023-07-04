extends Game

@export var _pickable_object_scene: PackedScene

func _ready():
	super._ready()
	

#func _on_resource_collection_finished(p_resource_id):
#	super._on_resource_collection_finished(p_resource_id)

#func _spawn_player() -> Character:
#	var a = await super._spawn_player()
#	var instance: PickableObject = _pickable_object_scene.instantiate()
#	var sb: StellarBody = _solar_system.get_reference_stellar_body()
#	sb.node.add_child(instance)
#	instance.position = _avatar.position
#	return a

func _on_planet_status_requested(solar_system_id, planet_id, data):
	super._on_planet_status_requested(solar_system_id, planet_id, data)
	var floating_resources = data.floating_resources
	for fr in floating_resources:
		var instance = _pickable_object_scene.instantiate()
		var sb: StellarBody = _solar_system.get_reference_stellar_body()
		sb.node.add_child(instance)
		var coord = fr.unit_coordinates
		var dir = Util.unit_coordinates_to_unit_vector(Vector2(coord.x, coord.y))
		
		var found: bool = false
		
		while not found:
			await get_tree().process_frame
			var query := PhysicsRayQueryParameters3D.new()
			query.from = sb.radius * 10 * dir
			query.to = Vector3.ZERO
			var state := get_world_3d().direct_space_state
			var result := state.intersect_ray(query)
			
			if not result.is_empty():
				instance.position = result.position
				found = true
		
	print("Spawned all resources")
