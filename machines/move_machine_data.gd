class_name MoveMachineData

#var planet_id: int
var planet_radius: float
#var machine_id: int
#var machine_node_path: NodePath
var machine_speed: float
var from: Vector3
var to: Vector3


func get_coordinates(p: Vector3) -> Vector2:
	return Util.position_to_coordinates(p)
	
func get_travel_time() -> float:
	var distance := Util.distance_on_sphere(planet_radius, from.normalized() * planet_radius, to.normalized() * planet_radius)
	return distance / machine_speed
