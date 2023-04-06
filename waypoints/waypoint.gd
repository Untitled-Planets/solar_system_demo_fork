class_name Waypoint
extends Node3D

signal mouse_entered
signal mouse_exit

@onready var _area = $Area
@onready var _mesh = $Area/MeshInstance3D

var waypoint_name : String = "HI"

var _info: String
var info: String:
	set(value):
		_info = value
	get:
		return _info

func _on_area_mouse_entered():
	mouse_entered.emit()

func _on_area_mouse_exited():
	mouse_exit.emit()

func scale_area(value: float) -> void:
	_area.scale = Vector3(value, value, value);

func set_enable_debug_mesh(value: bool) -> void:
	_mesh.visible = value
