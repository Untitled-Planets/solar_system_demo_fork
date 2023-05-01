extends Control

@export var capture_mouse_in_ready = true

signal escaped

var in_ui := false

func _ready():
	if capture_mouse_in_ready:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func pm_enabled(p_enabled):
	in_ui = p_enabled
	if p_enabled:
		escape()
	else:
		capture()

func capture():
	if in_ui:
		return
	# Remove focus from the HUD
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner != null:
		focus_owner.release_focus()
	
	# Capture the mouse for the game
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func escape():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	emit_signal("escaped")

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			capture()
	
	elif event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
				# Get the mouse back
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				emit_signal("escaped")

