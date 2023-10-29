extends Node


var _seed: int = 1
var _state: int = 0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func update(new_seed: int, new_state: int) -> void:
	_seed = new_seed
	_state = new_state
	
	rng.seed = _seed
	rng.state = _state
