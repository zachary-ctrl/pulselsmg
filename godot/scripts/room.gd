extends Node2D
## Root of a room scene. Collects its platforms, blockers and markers and draws
## the animated pieces the baked art can't: sludge, doors, sigils, gates,
## anchors, bench glow and the lab transmitter.

@export var room_id = ""
@export var display_name = ""
@export var subtitle = ""
@export var room_size = Vector2(960, 540)
@export_enum("wood", "tile", "lino", "metal") var floor_sound: String = "wood"
@export var tint = Color.WHITE

var solids: Array = []
var markers = {}
var blockers: Array = []
var main: Node
var t = 0.0


func _ready() -> void:
	for k in ["exit", "trigger", "bench", "npc", "anchor", "sigil", "spawn", "hazard"]:
		markers[k] = []
	for c in $Platforms.get_children():
		var sh: CollisionShape2D = c.get_node("Shape")
		var size: Vector2 = sh.shape.size
		solids.append({"rect": Rect2(c.position - size / 2.0, size), "oneway": sh.one_way_collision, "astral": c.get_meta("astral", false)})
	for m in $Markers.get_children():
		markers[m.kind].append(m)
	blockers = $Blockers.get_children()


func solid_rects(include_oneway := false) -> Array:
	var out = []
	for s in solids:
		if s["astral"]:
			continue
		if s["oneway"] and not include_oneway:
			continue
		out.append(s["rect"])
	for b in blockers:
		if b.active:
			out.append(b.rect())
	return out


func ground_at(p: Vector2) -> bool:
	for r in solid_rects(true):
		if r.has_point(p):
			return true
	return false


func hazard_at(r: Rect2):
	for h in markers["hazard"]:
		if h.rect().intersects(r):
			return h
	return null


func _process(delta: float) -> void:
	t += delta
	if main:
		for b in blockers:
			b.refresh(main)
	queue_redraw()


func _draw() -> void:
	var amix: float = main.astral_mix if main else 0.0
	for h in markers["hazard"]:
		_draw_sludge(h.rect())
	for b in blockers:
		if b.kind == "door":
			_draw_door(b)
		elif b.active:
			_draw_gate(b.rect())
	for s in markers["sigil"]:
		var done = Game.flag(s.flag)
		var a = 0.15 if done else 0.18 + amix * 0.82
		_glow(s.position, 70, Color(0.65, 0.55, 1, 0.4 * a))
		_rings(s.position, 48, t * (0.2 if done else 1.0), Color(0.85, 0.79, 1, a), 2.0)
	for an in markers["anchor"]:
		if Game.anchors.has(an.id):
			continue
		var y: float = an.position.y - 26 + sin(t * 2.4) * 4
		var pos = Vector2(an.position.x, y)
		if an.astral:
			if amix < 0.05:
				_glow(pos, 30, Color(0.65, 0.55, 1, 0.12 + 0.06 * sin(t * 2)))
			continue
		_glow(pos, 38, Color(1, 0.82, 0.54, 0.45))
		draw_rect(Rect2(pos.x - 7, pos.y - 12, 14, 24), Color("#0d0f14"))
		draw_rect(Rect2(pos.x - 5.5, pos.y - 10, 11, 18), Color("#bfe0ff"))
		draw_rect(Rect2(pos.x - 4, pos.y - 7, 8, 2), Color("#3a6ac9"))
	for b in markers["bench"]:
		_glow(b.position + Vector2(0, -30), 60, Color(1, 0.82, 0.54, 0.12 + 0.04 * sin(t * 2)))
	if room_id == "lab":
		var x = 560.0
		var y = 470.0
		var dead = Game.flags.get("ending", "") == "STRIKE"
		for i in 7:
			var c = Color(0.2, 0.2, 0.2) if dead else Color(0.5, 0.94, 1, 0.4 + 0.3 * sin(t * 3 + i))
			_ellipse_line(Vector2(x, y - 60 - i * 24), 40 - i * 3, 8, c, 3.0)
		_glow(Vector2(x, y - 240), 80 + sin(t * 4) * 10, Color(0.5, 0.94, 1, 0.4 if main and main.fight_id() != "" else 0.2))
		draw_circle(Vector2(x, y - 240), 14, Color("#0a0e10"))


func _draw_sludge(r: Rect2) -> void:
	var pts = PackedVector2Array()
	pts.append(Vector2(r.position.x, r.end.y))
	var x = 0.0
	while x <= r.size.x:
		pts.append(Vector2(r.position.x + x, r.position.y + sin(t * 2 + x * 0.08) * 3))
		x += 10
	pts.append(r.end)
	draw_colored_polygon(pts, Color("#7a1218"))
	draw_rect(Rect2(r.position.x, r.position.y + 8, r.size.x, r.size.y - 8), Color("#3a0a0e"))
	_glow(Vector2(r.get_center().x, r.position.y), r.size.x * 0.7, Color(1, 0.25, 0.25, 0.14))
	for i in 4:
		var ph = fmod(t * 1.3 + i, 1.0)
		var bx = r.position.x + fmod(i * 67.0 + t * 30.0, r.size.x)
		draw_arc(Vector2(bx, r.position.y - ph * 14), 2 + ph * 3, 0, TAU, 12, Color(1, 0.55, 0.47, (1 - ph) * 0.6), 1.0)
	draw_rect(Rect2(r.position.x - 6, r.position.y - 2, 6, r.size.y + 40), Color("#090a0e"))
	draw_rect(Rect2(r.end.x, r.position.y - 2, 6, r.size.y + 40), Color("#090a0e"))


func _draw_door(b: Node) -> void:
	var r: Rect2 = b.rect()
	if Game.flag(b.flag):
		draw_rect(Rect2(r.position, Vector2(r.size.x + 50, r.size.y)), Color("#05070a"))
		draw_colored_polygon(PackedVector2Array([r.position, r.position + Vector2(14, 2), r.position + Vector2(14, r.size.y + 2), r.position + Vector2(0, r.size.y)]), Color("#4a3424"))
		return
	draw_rect(r, Color("#4a3322"))
	draw_rect(Rect2(r.position + Vector2(4, 20), Vector2(r.size.x - 8, 40)), Color(0.63, 0.78, 0.9, 0.25))
	draw_circle(r.position + Vector2(4, 90), 3, Color("#c9b48a"))
	for i in 5:
		_ellipse_line(r.position + Vector2(r.size.x / 2, 76 + i * 8), 5, 3.5, Color("#8a8f96"), 3.0)
	draw_rect(Rect2(r.position + Vector2(2, 112), Vector2(r.size.x - 4, 16)), Color("#7a7f86"))


func _draw_gate(r: Rect2) -> void:
	for i in 6:
		var x0 = r.position.x + 4 + i * 4 + sin(t * 8 + i) * 2
		var pts = PackedVector2Array()
		var y = r.position.y
		while y < r.end.y:
			pts.append(Vector2(x0 + sin(t * 12 + y * 0.2 + i) * 3, y))
			y += 12
		draw_polyline(pts, Color(0.67, 0.59, 1, 0.25 + 0.2 * sin(t * 5 + i)), 2.0)
	_glow(r.get_center(), 120, Color(0.65, 0.55, 1, 0.12))


func _glow(c: Vector2, radius: float, col: Color) -> void:
	for i in 5:
		var f = 1.0 - i / 5.0
		draw_circle(c, radius * f, Color(col, col.a * 0.22))


func _rings(c: Vector2, r: float, rot: float, col: Color, width: float) -> void:
	for i in 7:
		var rad = r * (0.28 + i * 0.12)
		var gap = 0.45 + (i % 3) * 0.35
		var a0 = (rot if i % 2 else -rot) * (1 + i * 0.15) + i * 1.7
		draw_arc(c, rad, a0, a0 + TAU - gap, 40, col, width)


func _ellipse_line(c: Vector2, rx: float, ry: float, col: Color, width: float) -> void:
	var pts = PackedVector2Array()
	for i in 25:
		var a = TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, col, width)
