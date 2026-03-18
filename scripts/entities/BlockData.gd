class_name BlockData

var id: String
var dir: String              # "left" | "right" | "up" | "down"
var squares: Array[Vector2i] # shape offsets relative to origin
var origin: Vector2i         # starting grid position
var target_origin: Vector2i  # target grid position


static func from_dict(d: Dictionary) -> BlockData:
	var b := BlockData.new()
	b.id            = d["id"]
	b.dir           = d["dir"]
	b.origin        = Vector2i(d["origin_x"],        d["origin_y"])
	b.target_origin = Vector2i(d["target_origin_x"], d["target_origin_y"])
	b.squares       = []
	for sq in d["squares"]:
		b.squares.append(Vector2i(sq["pos_x"], sq["pos_y"]))
	return b


# Returns all grid cells this block currently occupies given an origin position
func cells(at_origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for sq in squares:
		result.append(at_origin + sq)
	return result


func dir_vector() -> Vector2i:
	match dir:
		"left":  return Vector2i(-1,  0)
		"right": return Vector2i( 1,  0)
		"up":    return Vector2i( 0, -1)
		"down":  return Vector2i( 0,  1)
	return Vector2i.ZERO
