@tool
class_name MinerLaser
extends Node3D

@onready var _pivot = $laser_pivot
@onready var _mesh = $laser_pivot/MeshInstance3D
#@onready var _material = _mesh.get_surface_override_material(0)

var _distance: float = 1.0
@export_range(0, 999) var distance: float:
	get:
		return _distance
	set(value):
		_distance = value
		if _pivot:
			_pivot.scale.y = _distance
