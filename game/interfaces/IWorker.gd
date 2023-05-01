class_name IWorker
extends Node3D

signal task_finished(success: bool)

func get_tasks() -> Array[ITask]:
	assert(false, "")
	return []

func do_task(task_id: String, p_data) -> int:
	assert(false, "")
	return -1

func get_task(task_id) -> ITask:
	assert(false)
	return null

func cancel_task(task_id: String) -> void:
	assert(false, "Not implemented")

func get_current_task() -> ITask:
	assert(false)
	return null

