class_name IWorker
extends Node3D

signal task_finished(success: bool)

func get_tasks() -> Array[ITask]:
	assert(false, "")
	return []

func do_task(_task_id: String, _p_data) -> int:
	assert(false, "")
	return -1

func get_task(_task_id: String) -> ITask:
	assert(false)
	return null

func set_task_batch(_p_batch: Array[Dictionary]) -> void:
	assert(false)
	pass

func cancel_task(_task_id: int) -> void:
	assert(false, "Not implemented")

func get_current_task() -> ITask:
	assert(false)
	return null

