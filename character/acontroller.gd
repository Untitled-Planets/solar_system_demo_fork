class_name AController
extends Node

signal escaped()

var _player_id: int = -1
var _game: Game
var _character = null

func _ready():
	_game = get_tree().get_nodes_in_group("game")[0]

func get_player_id() -> int:
	return _player_id


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


func capture():
#	if in_ui:
#		return
	# Remove focus from the HUD
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner != null:
		focus_owner.release_focus()
	
	# Capture the mouse for the game
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func escape():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	emit_signal("escaped")
