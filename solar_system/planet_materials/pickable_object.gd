class_name PickableObject
extends Node3D

@export var _collect_sfx_scene: PackedScene = null
@export var uuid: String = ""
var id: int = -1

func _ready() -> void:
	add_to_group(&"pickable_object")


func get_id() -> int:
	return id


func _process(_delta: float) -> void:
	if Engine.get_process_frames() % 2 == 0:
		var game: Game = get_tree().get_first_node_in_group(&"game") as Game
		if game != null:
			visible = game.distance_from_player(global_position) < 32


func _on_area_3d_body_entered(body) -> void:
	
	if body is Character:
		print(body.get_controller())
	
	if body is Character and body.get_controller() != null:
		_get_hud()._can_mineral_interact_count += 1
		body.get_controller().set_pickable_object(self)


func _on_area_3d_body_exited(body) -> void:
	if body is Character and _get_hud():
		_get_hud()._can_mineral_interact_count -= 1
		body.get_controller().set_pickable_object(null)



func spawn_vfx() -> void:
	if _collect_sfx_scene:
		var instance: GPUParticles3D = _collect_sfx_scene.instantiate()
		get_tree().root.add_child(instance)
		instance.global_position = global_position
		instance.emitting = true


func _get_hud() -> Control:
	return get_tree().get_first_node_in_group(&"hud")


