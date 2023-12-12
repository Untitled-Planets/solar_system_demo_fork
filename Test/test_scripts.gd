@tool
extends Node3D

@export var size: int = 10: 
	set(val):
		size = val
		if size > 0:
			build()
@export var mesh: Mesh

func _ready() -> void:
	var bitfield = BitField.new(100)
	print(bitfield)
	bitfield.set_bit_state(10, true)
	bitfield.set_bit_state(16, true)
	bitfield.set_bit_state(1, true)
	print(bitfield.get_bit_state(10))
	print(bitfield)



func build() -> void:
	randomize()
	
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	query.from = Vector3.ZERO
	query.collide_with_bodies = true
	
	for c in get_tree().get_nodes_in_group(&"clean_test"):
		c.queue_free()
	
	for i in range(size):
		var x: float = randf_range(-1, 1)
		var y: float = randf_range(0, 1)
		
		query.to = Util.unit_coordinates_to_unit_vector(Vector2(x, y)) * 50
		var result: Dictionary = space_state.intersect_ray(query)
		
		
		var node: MeshInstance3D = MeshInstance3D.new()
		node.add_to_group(&"clean_test")
		node.mesh = mesh
		add_child(node)
		node.position = query.to
