class_name Waypoint
extends Node3D

signal mouse_entered
signal mouse_exit

@onready var _area = $Area
@onready var _mesh = $Area/MeshInstance3D
@onready var _attached_object = get_parent()

@export var _normal_texture: Texture = null
@export var _focus_texture: Texture = null

var waypoint_name : String = "HI"
var location_id: int = -1
var location: Vector2


var _info: String
var info: String:
	set(value):
		_info = value
	get:
		return _info

func _ready():
	WaypointManager.add_waypoint(self)

func _on_area_mouse_entered():
	print("Mouse entered")
	mouse_entered.emit()

func _on_area_mouse_exited():
	print("Mouse exited")
	mouse_exit.emit()

func scale_area(value: float) -> void:
	_area.scale = Vector3(value, value, value);

func set_enable_debug_mesh(value: bool) -> void:
	_mesh.visible = value


func get_normal_texture() -> Texture:
	return _normal_texture

func get_focus_texture() -> Texture:
	if get_selected_object():
		if get_selected_object().is_focussed():
			return _focus_texture
		else:
			return _normal_texture
	return _normal_texture

func _on_area_input_event(_camera, _event, _position, _normal, _shape_idx):
	print("gui_event")

func get_selected_object():
	return _attached_object


func get_color() -> Color:
	if get_selected_object():
		return get_selected_object().get_color()
	else:
		return Color.WHITE
#		if get_selected_object().is_focussed():
#			return Color.WHITE
#		else:
#			return Color(0.3, 1.0, 0.3)
#	return Color(0.3, 1.0, 0.3)
