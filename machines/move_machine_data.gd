class_name MoveMachineData

var planet_radius: float
var machine_speed: float
var from: Vector2
var to: Vector2


func get_coordinates(p: Vector3) -> Vector2:
	return Util.position_to_coordinates(p)
	
func get_travel_time() -> float:
	var f = Util.coordinate_to_unit_vector(from)
	var t = Util.coordinate_to_unit_vector(to)
	var distance := Util.distance_on_sphere(planet_radius, f * planet_radius, t * planet_radius)
	return distance / machine_speed
