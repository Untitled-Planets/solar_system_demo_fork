extends Node3D


@onready var spawn_ship_position: Marker3D = $SpawnPosition as Marker3D

var portal_info: PortalInfo = null

var ships_count: int = 0

func _ready() -> void:
	pass



func _on_area_3d_body_entered(body) -> void:
	if body.is_in_group(&"character"):
		
		var portal_menu: Control = get_portal_menu()
		if portal_menu:
			portal_info = PortalInfo.new(spawn_ship_position.global_position)
			get_tree().get_first_node_in_group(&"portal_hud_menu")._current_portal_info = portal_info
			portal_menu.show()
		var controller = get_tree().get_first_node_in_group(&"character_controler_p")
		if controller:
			controller._portal_count += 1


func _on_area_3d_body_exited(body) -> void:
	if body.is_in_group(&"character"):
		var portal_menu: Control = get_portal_menu()
		if portal_menu:
			portal_menu.hide()
		var controller = get_tree().get_first_node_in_group(&"character_controler_p")
		if controller:
			controller._portal_count -= 1


func get_portal_menu() -> Control:
	return get_tree().get_first_node_in_group(&"enter_portal_hud_label")




func _on_detect_ship_body_entered(body):
	if body.is_in_group(&"ship"):
		ships_count += 0


func _on_detect_ship_body_exited(body):
	if body.is_in_group(&"ship"):
		ships_count -= 0
