extends Game

@export var _pickable_object_scene: PackedScene

func _ready():
	super._ready()
	


func _spawn_player() -> void:
	await super._spawn_player()
	var instance: PickableObject = _pickable_object_scene.instantiate()
	var sb: StellarBody = _solar_system.get_reference_stellar_body()
	sb.node.add_child(instance)
	instance.position = _avatar.position
	
