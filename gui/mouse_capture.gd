extends Control

export var capture_mouse_in_ready = true

signal escaped

var in_ui = false

func _ready():
	add_to_group("planet_mode")
	if capture_mouse_in_ready:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func pm_enabled(p_enabled):
	in_ui = p_enabled
	if p_enabled:
		escape()
	else:
		capture()

func escape():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	emit_signal("escaped")


func capture():
	if in_ui:
		return
	# Remove focus from the HUD
	var focus_owner = get_focus_owner()
	if focus_owner != null:
		focus_owner.release_focus()
	
	# Capture the mouse for the game
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			capture()
	
	elif event is InputEventKey:
		if event.is_action_pressed("capture_escape"):
			if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
				escape()

