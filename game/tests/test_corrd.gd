extends Node

func _ready():
	_test_case(Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)))
	_test_case(Vector3(-Vector3.RIGHT))
	pass

func _test_case(v: Vector3):
	print("---------------------------------")
	print(v)
	var u := Util.position_to_unit_coordinates(v)
	print(u)
	var vn := Util.unit_coordinates_to_unit_vector(u)
	print(vn)
	print("Dor: ", v.normalized().dot(vn.normalized()))
	print("---------------------------------")
	pass
