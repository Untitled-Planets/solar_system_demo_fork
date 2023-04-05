class_name MachineCharacter
extends Node3D

@onready var _movement: MachineMovement = $movement

enum State {
	WORKING,
	MOVING,
	IDLE
}

var _planet

func _ready():
	pass


func go_to(location: Vector3) -> void:
	_movement.go_to(location)

func get_planet():
	return _planet
