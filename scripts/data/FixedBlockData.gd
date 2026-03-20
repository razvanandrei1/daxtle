class_name FixedBlockData

var squares: Array[Vector2i] # shape offsets relative to origin
var origin: Vector2i         # grid position


static func from_dict(d: Dictionary) -> FixedBlockData:
	var c := FixedBlockData.new()
	c.origin  = Vector2i(d["origin"][0], d["origin"][1])
	c.squares = []
	for sq in d["squares"]:
		c.squares.append(Vector2i(sq["pos_x"], sq["pos_y"]))
	return c


# Returns all grid cells this block occupies
func cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for sq in squares:
		result.append(origin + sq)
	return result
