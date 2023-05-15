class_name ITask
extends Node

class Data:
	var id: int = -1
	var name: String = ""
	var data: Dictionary = {}

enum Finished {
	NONE = 0,
	SUCCESS = 1,
	FAILED = 2,
	STOP = 3,
}

func get_task_name() -> String:
	return name

func start() -> void:
	assert(false)

func update(delta: float) -> void:
	assert(false)

func pause() -> void:
	assert(false)

func stop() -> void:
	assert(false)

func get_finished() -> int:
	assert(false, "")
	return Finished.FAILED

func get_id() -> int:
	assert(false, "")
	return -1
