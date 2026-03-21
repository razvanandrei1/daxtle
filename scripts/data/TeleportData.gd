class_name TeleportData

var id:       int
var portal_a: Vector2i
var portal_b: Vector2i
var one_way:  bool     # if true, only portal_a → portal_b; not the reverse


static func from_dict(d: Dictionary) -> TeleportData:
	var t := TeleportData.new()
	t.id       = d.get("id", 0)
	var pos: Array = d["pos"]
	t.portal_a = Vector2i(pos[0], pos[1])
	t.portal_b = Vector2i(pos[2], pos[3])
	t.one_way  = d.get("one_way", false)
	return t


func partner(cell: Vector2i) -> Vector2i:
	if cell == portal_a:
		return portal_b
	return portal_a
