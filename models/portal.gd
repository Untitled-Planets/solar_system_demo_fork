extends Node3D


@onready var spawn_ship_position: Marker3D = $portal/SpawnPosition as Marker3D

var portal_info: PortalInfo = null

func _ready() -> void:
	portal_info = PortalInfo.new(spawn_ship_position.global_position)


func _on_area_3d_body_entered(body: Node3D) -> void:
	return
	if body.is_in_group(&"character"):
		var portal_menu: Control = get_portal_menu()
		assert(portal_menu != null)
		portal_menu.show_ui(portal_info)


func _on_area_3d_body_exited(body: Node3D) -> void:
	return
	if body.is_in_group(&"character"):
		var portal_menu: Control = get_portal_menu()
		assert(portal_menu != null)
		portal_menu.hide_ui()


func get_portal_menu() -> Control:
	return get_tree().get_first_node_in_group(&"portal_menu")


