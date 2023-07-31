class_name PickableObject
extends Node3D

@export var _collect_sfx_scene: PackedScene = null
@export var uuid: String = ""

func _ready():
	pass


func get_id() -> String:
	return uuid

func _physics_process(delta):
	pass

func _on_area_3d_body_entered(body):
	if body is Character:
		body.get_controller().set_pickable_object(self)


func _on_area_3d_body_exited(body):
	if body is Character:
		body.get_controller().set_pickable_object(null)


func _exit_tree():
	if _collect_sfx_scene:
		var instance: GPUParticles3D = _collect_sfx_scene.instantiate()
		get_tree().root.add_child(instance)
		instance.global_position = global_position
		instance.emitting = true
