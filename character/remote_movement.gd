extends Node

@onready var _character: Character = get_parent()

var _last_known_position: Vector3 = Vector3.ZERO


func _ready():
	pass

func add_last_know_position(p_position: Vector3):
	_last_known_position = p_position

func _process(delta):
	if _last_known_position != Vector3.ZERO:
		if _character.global_position.distance_squared_to(_last_known_position) < 0.1:
			return
		_character.set_planet_up(_character.global_position.normalized())
		var x := _last_known_position.x - _character.global_position.x
		var z := _last_known_position.z - _character.global_position.z
		var motor := _last_known_position - _character.global_position
		_character.set_direction(motor.normalized())
