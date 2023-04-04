extends Node

# Fill it through the editor
@export var _machines := {
	
}

func spawn_machine(miner_id, location: SpawnLocation) -> void:
	print("Spawning miner with id: ", miner_id)
