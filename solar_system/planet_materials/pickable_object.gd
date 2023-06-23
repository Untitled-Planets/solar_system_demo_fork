class_name PickableObject
extends Node3D



func _ready():
	pass
	
func _physics_process(delta):
	pass

func _on_area_3d_body_entered(body):
	if body is Character:
		body.get_controller().set_pickable_object(self)


func _on_area_3d_body_exited(body):
	if body is Character:
		body.get_controller().set_pickable_object(null)
