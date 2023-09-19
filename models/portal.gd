extends Node3D


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"character"):
		var portal_menu: Control = get_portal_menu()
		assert(portal_menu != null)
		portal_menu.show()


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group(&"character"):
		var portal_menu: Control = get_portal_menu()
		assert(portal_menu != null)
		portal_menu.hide()


func get_portal_menu() -> Control:
	return get_tree().get_first_node_in_group(&"portal_menu")


