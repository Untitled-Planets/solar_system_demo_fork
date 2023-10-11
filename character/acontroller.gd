class_name AController
extends Node

signal escaped()

var _player_id: int = -1
var _game: Game
var _character = null:
	set(val):
		_character = val
		if val == null:
			print_stack()

func _ready():
	add_to_group(&"network")
	_game = get_tree().get_first_node_in_group(&"game")
	#push_warning("No game class exists in the scene")

func get_player_id() -> int:
	return _player_id

#####################################
# Network interface
#####################################

func serialize() -> Dictionary:
	var char: Character = get_character()
	return {
		"id": 0,
		"position": {
			"x": char.global_position.x,
			"y": char.global_position.z,
			"z": char.global_position.y
		}
	}

func deserialize(_p_data: Dictionary) -> void:
	pass

#####################################
# End Network interface
#####################################

func possess(p_char) -> void:
	if _character:
		unpossess()
	
	if not p_char:
		return
	
	unpossess()
	_character = p_char


func get_character():
	return _character

func unpossess() -> void:
#	if not _character:
#		return
#	_character.queue_free()
	_character = null


func capture_mouse():
	capture()

func release_mouse():
	escape()


func capture() -> void:
#	if in_ui:
#		return
	# Remove focus from the HUD
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	if focus_owner != null:
		focus_owner.release_focus()
	
	# Capture the mouse for the game
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func escape() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	escaped.emit()
