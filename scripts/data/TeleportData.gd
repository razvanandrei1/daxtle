class_name TeleportData

var id:       String
var portal_a: Vector2i
var portal_b: Vector2i
var one_way:  bool     # if true, only portal_a → portal_b; not the reverse


static func from_dict(d: Dictionary) -> TeleportData:
	var t := TeleportData.new()
	t.id       = d.get("id", "")
	t.portal_a = Vector2i(d["ax"], d["ay"])
	t.portal_b = Vector2i(d["bx"], d["by"])
	t.one_way  = d.get("one_way", false)
	return t


func partner(cell: Vector2i) -> Vector2i:
	if cell == portal_a:
		return portal_b
	return portal_a
