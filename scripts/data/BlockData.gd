class_name BlockData

var id: String
var dir: String              # "left" | "right" | "up" | "down" | "none"
var origin: Vector2i         # starting grid position
var target_origin: Vector2i  # target grid position


static func from_dict(d: Dictionary) -> BlockData:
	var b := BlockData.new()
	b.id            = d["id"]
	b.dir           = d["dir"]
	b.origin        = Vector2i(d["origin_x"],        d["origin_y"])
	b.target_origin = Vector2i(d["target_origin_x"], d["target_origin_y"])
	return b


# Returns the grid cell this block occupies at a given origin
func cells(at_origin: Vector2i) -> Array[Vector2i]:
	return [at_origin]


func dir_vector() -> Vector2i:
	match dir:
		"left":  return Vector2i(-1,  0)
		"right": return Vector2i( 1,  0)
		"up":    return Vector2i( 0, -1)
		"down":  return Vector2i( 0,  1)
	return Vector2i.ZERO
