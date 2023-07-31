class_name ResourceProducer
extends Node


@export var _collect_delta_time: float = 5.0

var _acc_time: float = 0.0
var _resources: float = 0.0


func _process(delta):
	_acc_time += delta
	if _collect_delta_time < _acc_time:
		print("Collecting...")
		_resources += 1.0
		_acc_time = 0.0


func grab(p_amount: float) -> float:
	var amount: float = p_amount
	if _resources > p_amount:
		_resources -= p_amount
	else:
		amount = _resources
		_resources = 0.0
	return amount
