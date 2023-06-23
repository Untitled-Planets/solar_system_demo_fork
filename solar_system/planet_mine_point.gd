class_name PlanetMine
extends Node3D

@export var _waypoint_scene: PackedScene = null

func _ready():
	var w = _waypoint_scene.instantiate()
	w.info = "RAndom"
	add_child(w)

func is_focussed() -> bool:
	return false

func get_color() -> Color:
	return Color.WHITE
