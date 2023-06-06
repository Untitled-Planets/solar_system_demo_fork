#This class holds just a ref to the body within solar_system.
class_name StellarBodyWrapper
extends Node3D


var stellar_body: StellarBody = null


func set_focus(p_value: bool) -> void:
#	_is_focussed = p_value
	pass

func is_focussed() -> bool:
	return false

func get_color() -> Color:
	return Color.WHITE
