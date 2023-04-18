class_name Util

const TWO_PI = 2.0 * PI

static func get_sphere_volume(r: float) -> float:
	return PI * r * r * r * 4.0 / 3.0


static func find_node_by_type(parent: Node, klass):
	for i in parent.get_child_count():
		var child = parent.get_child(i)
		if is_instance_of(child, klass):
			return child
		var res = find_node_by_type(child, klass)
		if res != null:
			return res
	return null

static func find_parent_by_type(node: Node, klass):
	while node.get_parent() != null:
		node = node.get_parent()
		if is_instance_of(node, klass):
			return node
	return null


static func format_integer_with_commas(n: int) -> String:
	if n < 0:
		return "-" + format_integer_with_commas(-n)
	if n < 1000:
		return str(n)
	if n < 1000000:
		return str(n / 1000, ",", str(n % 1000).pad_zeros(3))
	if n < 10000000000:
		return str(n / 1000000, ",", 
			str((n / 1000) % 10000000).pad_zeros(3), ",", 
			str(n % 1000).pad_zeros(3))
	push_error("Number too big for shitty function")
#	assert(false)
	return "<error>"


static func ray_intersects_sphere(
	ray_origin: Vector3, ray_dir: Vector3, center: Vector3, radius: float) -> bool:
	
	var t = (center - ray_origin).dot(ray_dir)
	if t < 0.0:
		return false
	var p = ray_origin + ray_dir * t
	var y = (center - p).length()
	return y <= radius


# BoxMesh doesn't have a wireframe option
static func create_wirecube_mesh(color = Color(1,1,1)) -> Mesh:
	var positions := PackedVector3Array([
		Vector3(0, 0, 0),
		Vector3(1, 0, 0),
		Vector3(1, 0, 1),
		Vector3(0, 0, 1),
		Vector3(0, 1, 0),
		Vector3(1, 1, 0),
		Vector3(1, 1, 1),
		Vector3(0, 1, 1),
	])
	var colors := PackedColorArray([
		color, color, color, color,
		color, color, color, color,
	])
	var indices := PackedInt32Array([
		0, 1,
		1, 2,
		2, 3,
		3, 0,

		4, 5,
		5, 6,
		6, 7,
		7, 4,

		0, 4,
		1, 5,
		2, 6,
		3, 7
	])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh

# Target position is relative to the planet.
# planet origin is always 0
# ref: https://math.stackexchange.com/questions/923279/find-a-vector-parallel-to-the-plane-z-2x3y
#static func get_quaternion_from_position(target_position: Vector3, planet_transform: Transform3D) -> Quaternion:
#	var cathetus: float = target_position.y
#	var angle: float = asin((cathetus * cathetus) / target_position.length_squared())
#	var fvector: Vector3 = target_position.normalized()
#	var plane := Plane(fvector, 0.0)
#	print("get_quaternion_from_position")
#	return Quaternion()

# https://stackoverflow.com/questions/35613741/convert-2-3d-points-to-directional-vectors-to-euler-angles
# Vector2.x -> Latitude
# Vector2.y -> Azimuthal
static func position_to_coordinates(v: Vector3) -> Vector2:
	if v.normalized().abs() == Vector3.UP:
		return Vector2(90 * sign(v.y), 0)
	var original := v
	v.y = 0.0
	var azimuthal := v.signed_angle_to(Vector3.FORWARD, Vector3.UP)
	var latitude := original.signed_angle_to(v, Vector3.RIGHT)
	return Vector2(rad_to_deg(latitude), rad_to_deg(azimuthal))
	

# https://math.stackexchange.com/questions/1304169/distance-between-two-points-on-a-sphere
static func distance_on_sphere(sphere_radius: float, p1: Vector3, p2: Vector3) -> float:
	return sphere_radius * acos(p1.normalized().dot(p2.normalized()) / (sphere_radius * sphere_radius))

static func coordinate_to_unit_vector(coord: Vector2) -> Vector3:
	var v := Vector3.FORWARD
	v = v.rotated(Vector3.UP, deg_to_rad(coord.y))
	v = v.rotated(Vector3.RIGHT, deg_to_rad(coord.x))
	return v

static func position_to_unit_coordinates(position: Vector3) -> Vector2:
	var n := position.normalized()
	var dot := n.dot(Vector3.UP)
	if  abs(dot) == 1.0: # Maybe a simpler if for x and z does a better job
		return Vector2(0.0, sign(dot))
	
	var y := Vector3(n.x, 0.0, n.z)
	var y_angle := y.signed_angle_to(Vector3.FORWARD, Vector3.UP)
	if y_angle < 0.0:
		y_angle += TWO_PI
	# the worst name in the world
	var x_angle := Vector3.UP.angle_to(n)
	return Vector2(x_angle / PI, y_angle / TWO_PI)
