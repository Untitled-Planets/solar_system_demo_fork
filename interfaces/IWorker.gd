class_name IWorker
extends Node3D

signal task_finished(success: bool)

func get_tasks() -> Array[ITask]:
	assert(false, "")
	return []

func do_task(task_id: String) -> int:
	assert(false, "")
	return -1

func get_current_task() -> ITask:
	assert(false)
	return null

