class_name TeleportData

var portal_a: Vector2i
var portal_b: Vector2i


static func from_dict(d: Dictionary) -> TeleportData:
	var t := TeleportData.new()
	t.portal_a = Vector2i(d["ax"], d["ay"])
	t.portal_b = Vector2i(d["bx"], d["by"])
	return t


func partner(cell: Vector2i) -> Vector2i:
	if cell == portal_a:
		return portal_b
	return portal_a
