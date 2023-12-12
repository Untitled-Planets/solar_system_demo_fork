class_name Util

const TWO_PI = 2.0 * PI
const HALF_PI = 0.5 * PI

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
		return str(roundi(n / 1000.0), ",", str(n % 1000).pad_zeros(3))
	if n < 10000000000:
		return str(n / 1000000.0, ",", 
			str(roundi(n / 1000.0) % 10000000).pad_zeros(3), ",", 
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
	return sphere_radius * acos(p1.dot(p2) / (sphere_radius * sphere_radius))

static func coordinate_to_unit_vector(coord: Vector2) -> Vector3:
	if abs(coord.x) == 1.0:
		return Vector3.UP * sign(coord.x)
	var v := Vector3.FORWARD
	v = v.rotated(Vector3.UP, coord.y)
	var c: Vector3 = Vector3.UP.cross(v)
	v = v.rotated(c, -coord.x)
	return v

static func position_to_unit_coordinates(position: Vector3) -> Vector2:
	var n := position.normalized()
	var dot := n.dot(Vector3.UP)
	if  abs(dot) == 1.0: # Maybe a simpler if for x and z does a better job
		return Vector2(sign(dot), 0.0)
	
	var y := Vector3(n.x, 0.0, n.z).normalized()
	var y_angle := Vector3.FORWARD.signed_angle_to(y, Vector3.UP)
	if y_angle < 0.0:
		y_angle += TWO_PI
	# the worst name in the world
	var c := Vector3.UP.cross(n)
	var x_angle := Vector3.UP.signed_angle_to(n, c)
	if x_angle <= HALF_PI:
		x_angle = (HALF_PI - x_angle)
	else:
		x_angle = -(x_angle - HALF_PI)
	return Vector2(x_angle / HALF_PI, y_angle / TWO_PI)


static func generate_unit_coordinates() -> Vector2:
	var azimuthal := randf()
	var latitude := randf_range(-1.0, 1.0)
	return Vector2(latitude, azimuthal)


static func unit_coordinates_to_unit_vector(p_coord: Vector2) -> Vector3:
	var aangle := p_coord.y * TWO_PI
	#var forward := Vector3.FORWARD
	var v := Vector3.FORWARD.rotated(Vector3.UP, aangle)
	var c := v.cross(Vector3.UP)
	return v.rotated(c, p_coord.x * HALF_PI)

# p_coordinates must be in radians
static func coordinate_to_unit_coordinates(p_coordinate: Vector2) -> Vector2:
	return Vector2(p_coordinate.x / HALF_PI, p_coordinate.y / TWO_PI)


static func serialize_dic(data: Dictionary) -> Dictionary:
	var new_dic: Dictionary = {}
	
	for k in data.keys():
		if typeof(data[k]) == TYPE_VECTOR3:
			new_dic[k] = serialize_vec3(data[k])
		elif typeof(data[k]) == TYPE_TRANSFORM3D:
			new_dic[k] = serialize_transform(data[k])
		else:
			new_dic[k] = data[k]
	
	return new_dic


static func deserialize_dic(data: Dictionary) -> Dictionary:
	var new_dic: Dictionary = {}
	
	for k in data.keys():
		if typeof(data[k]) == TYPE_DICTIONARY:
			if data[k].has("x") and data[k].has("y") and data[k].has("z"):
				new_dic[k] = deserialize_vec3(data[k])
			elif data[k].has("origin") and data[k].has("basis"):
				pass
		else:
			new_dic[k] = data[k]
	
	return new_dic


static func serialize_vec3(vec: Vector3) -> Dictionary:
	return {
		"x": vec.x,
		"y": vec.y,
		"z": vec.z
	}


static func deserialize_vec3(vec_data: Dictionary) -> Vector3:
	return Vector3(vec_data.get("x", 0), vec_data.get("y", 0), vec_data.get("z", 0))


static func deserialize_vec2(vec_data: Dictionary) -> Vector2:
	return Vector2(vec_data.get("x", 0), vec_data.get("y", 0))


static func serialize_transform(transform: Transform3D) -> Dictionary:
	return {
		"basis": Util.serialize_basis(transform.basis),
		"origin": Util.serialize_vec3(transform.origin)
	}


static func deserialize_transform(data: Dictionary) -> Transform3D:
	return Transform3D(
		Util.deserialize_basis(data["basis"]),
		Util.deserialize_vec3(data["origin"])
	)



static func serialize_basis(basis: Basis) -> Dictionary:
	return {
		"x": Util.serialize_vec3(basis.x),
		"y": Util.serialize_vec3(basis.y),
		"z": Util.serialize_vec3(basis.z)
	}

static func deserialize_basis(basis: Dictionary) -> Basis:
	return Basis(
		Util.deserialize_vec3(basis["x"]),
		Util.deserialize_vec3(basis["y"]),
		Util.deserialize_vec3(basis["z"])
	)


static func hash_from_number(num: int) -> String:
	return String.num_int64(num, 16).sha256_text()


static func toggle_bit(position: int, bitset: int) -> int:
	assert(position >= 0 and bitset >= 0)
	bitset |= (1 << position)
	return bitset


static func is_bit_enable(position: int, bitset: int) -> bool:
	assert(position >= 0 and bitset >= 0)
	return ((bitset >> position) & 1) == 1


static func decode_u32(buffer: PackedByteArray) -> int:
	return buffer[0] << 24 | buffer[1] << 16 | buffer[2] << 8 | buffer[3]

static func decode_u16(buffer: PackedByteArray) -> int:
	return buffer[0] << 8 | buffer[1]
