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

func update(_delta: float) -> void:
	assert(false)

func pause() -> void:
	assert(false)

func stop() -> void:
	assert(false)

func resume_task(_p_data: Dictionary) -> void:
	assert(false)

func set_started_time_delta(_p_started_time: float) -> void:
	assert(false)


func get_finished() -> int:
	assert(false, "")
	return Finished.FAILED

func set_id(_p_id: int) -> void:
	assert(false)

func get_id() -> int:
	assert(false, "")
	return -1
