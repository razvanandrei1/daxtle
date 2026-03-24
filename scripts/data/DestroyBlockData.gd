class_name DestroyBlockData

var origin: Vector2i         # grid position


static func from_dict(d: Dictionary) -> DestroyBlockData:
	var db := DestroyBlockData.new()
	db.origin = Vector2i(d["origin"][0], d["origin"][1])
	return db


func cells() -> Array[Vector2i]:
	return [origin]
