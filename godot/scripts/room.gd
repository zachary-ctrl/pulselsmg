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
@export var draw_platforms = false

var solids: Array = []
var markers = {}
var blockers: Array = []
var main: Node
var t = 0.0


func _ready() -> void:
	for k in ["exit", "trigger", "bench", "npc", "anchor", "sigil", "spawn", "hazard", "worker", "loot", "portal"]:
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


## Top of the first solid surface at or below `p` (or the room bottom).
func floor_below(p: Vector2) -> Vector2:
	var best = room_size.y
	for r in solid_rects(true):
		if p.x >= r.position.x and p.x <= r.end.x and r.position.y >= p.y - 2.0 and r.position.y < best:
			best = r.position.y
	return Vector2(p.x, best)


func hazard_at(r: Rect2):
	for h in markers["hazard"]:
		if h.id == "tide" and Game.flag("tideClear"):
			continue
		if h.rect().intersects(r):
			return h
	return null


func _process(delta: float) -> void:
	t += delta
	if main:
		for b in blockers:
			b.refresh(main)
	queue_redraw()


func _draw_fair() -> void:
	# Science-fair dressing drawn over the reused school art.
	var cols = [Color("#ff6aa8"), Color("#ffd06a"), Color("#6ad8ff"), Color("#9aff8a")]
	if room_id == "fairhall" or room_id == "gym":
		var floor_y = 470.0 if room_id == "fairhall" else 1010.0
		var x = 200.0
		var i = 0
		while x < room_size.x - 200.0:
			var c: Color = cols[i % cols.size()]
			var bx = x
			draw_rect(Rect2(bx - 34, floor_y - 30, 68, 30), Color("#2a2228"))
			draw_rect(Rect2(bx - 30, floor_y - 74, 18, 44), Color("#e9e1d0"))
			draw_rect(Rect2(bx - 12, floor_y - 80, 24, 50), Color("#f4eee2"))
			draw_rect(Rect2(bx + 12, floor_y - 74, 18, 44), Color("#e9e1d0"))
			draw_rect(Rect2(bx - 10, floor_y - 76, 20, 6), c)
			for k in 3:
				draw_rect(Rect2(bx - 26 + k * 20, floor_y - 62, 12, 9), Color(c, 0.5))
			x += 420.0 + (i % 3) * 60.0
			i += 1
		var y0 = 150.0 if room_id == "fairhall" else 450.0
		var bx2 = 120.0
		while bx2 < room_size.x - 120.0:
			var pts = PackedVector2Array()
			for k in 9:
				pts.append(Vector2(bx2 + k * 30.0, y0 + sin(k * 0.39) * 26.0))
			draw_polyline(pts, Color(0.9, 0.85, 0.8, 0.5), 1.5)
			for k in 8:
				var p0: Vector2 = pts[k]
				draw_colored_polygon(PackedVector2Array([p0, p0 + Vector2(22, 0), p0 + Vector2(11, 20)]), Color(cols[k % 4], 0.75))
			bx2 += 640.0
		draw_string(Game.font_display, Vector2(room_size.x / 2.0 - 260.0, y0 + 74.0), "WESTBROOK HIGH SCIENCE FAIR", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 0.9, 0.8, 0.5))
	elif room_id == "stage":
		for side in [0, 1]:
			var cx = 0.0 if side == 0 else room_size.x - 150.0
			for k in 6:
				var sx = cx + k * 25.0
				draw_rect(Rect2(sx, 0, 25, 470), Color(0.42 + 0.06 * sin(t + k), 0.06, 0.12, 0.85))
				draw_line(Vector2(sx, 0), Vector2(sx, 470), Color(0, 0, 0, 0.35), 2.0)
		draw_rect(Rect2(0, 0, room_size.x, 40), Color("#3a0812"))
		for k in 3:
			var lx = 260.0 + k * 300.0
			var sway = sin(t * 0.7 + k) * 60.0
			draw_colored_polygon(PackedVector2Array([Vector2(lx - 10, 40), Vector2(lx + 10, 40), Vector2(lx + 120 + sway, 470), Vector2(lx - 120 + sway, 470)]), Color(1, 0.9, 0.7, 0.05))
		draw_string(Game.font_display, Vector2(380, 120), "COLLECTIVE COGNITION", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 0.6, 0.85, 0.3 + 0.1 * sin(t * 3.0)))


func _draw() -> void:
	var amix: float = main.astral_mix if main else 0.0
	if room_id in ["fairhall", "gym", "stage"]:
		_draw_fair()
	if draw_platforms:
		_draw_platforms()
	for h in markers["hazard"]:
		_draw_sludge(h.rect(), h.id == "tide" and Game.flag("tideClear"))
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
	for pt in markers["portal"]:
		# A glowing doorway into a side area; press Up to enter.
		var c = pt.position
		_glow(c + Vector2(0, -50), 70, Color(0.65, 0.55, 1, 0.35 + 0.1 * sin(t * 3)))
		draw_rect(Rect2(c + Vector2(-26, -100), Vector2(52, 100)), Color(0.05, 0.03, 0.12, 0.85))
		draw_rect(Rect2(c + Vector2(-26, -100), Vector2(52, 100)), Color(0.8, 0.7, 1, 0.9), false, 3.0)
		_rings(c + Vector2(0, -50), 30, t, Color(0.85, 0.79, 1, 0.8), 1.5)
		if main and absf(main.player.position.x - c.x) < 40.0 and absf(main.player.position.y - c.y) < 40.0:
			var lbl = "[%s] %s" % [Game.label("up"), Game.ROOM_TITLES.get(pt.target_room, "Enter")]
			var fw = Game.font_semi.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			draw_rect(Rect2(c + Vector2(-fw / 2 - 6, -130), Vector2(fw + 12, 22)), Color(0, 0, 0, 0.7))
			draw_string(Game.font_semi, c + Vector2(-fw / 2, -114), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	if room_id == "lab":
		var x = 560.0
		var y = 470.0
		var dead = Game.flags.get("ending", "") == "STRIKE"
		for i in 7:
			var c = Color(0.2, 0.2, 0.2) if dead else Color(0.5, 0.94, 1, 0.4 + 0.3 * sin(t * 3 + i))
			_ellipse_line(Vector2(x, y - 60 - i * 24), 40 - i * 3, 8, c, 3.0)
		_glow(Vector2(x, y - 240), 80 + sin(t * 4) * 10, Color(0.5, 0.94, 1, 0.4 if main and main.fight_id() != "" else 0.2))
		draw_circle(Vector2(x, y - 240), 14, Color("#0a0e10"))


const STYLE := {
	"street": {"body": Color("#15161c"), "top": Color("#5a5650"), "plate": Color("#3a3f4a"), "edge": Color("#8a8478")},
	"hospital": {"body": Color("#1c2226"), "top": Color("#9aa8ae"), "plate": Color("#c9d2d6"), "edge": Color("#eef3f5")},
	"waterworks": {"body": Color("#101618"), "top": Color("#46545a"), "plate": Color("#2e3a40"), "edge": Color("#7f9aa3")},
	"pumphouse": {"body": Color("#0d1214"), "top": Color("#3c4a50"), "plate": Color("#2e3a40"), "edge": Color("#7f9aa3")},
	"fairhall": {"body": Color("#14121a"), "top": Color("#6a6070"), "plate": Color("#8a5a3a"), "edge": Color("#e0b080")},
	"gym": {"body": Color("#1a1210"), "top": Color("#b07a40"), "plate": Color("#3a3f4a"), "edge": Color("#c8ccd4")},
	"stage": {"body": Color("#120c10"), "top": Color("#5a2a30"), "plate": Color("#3a2a20"), "edge": Color("#d0a070")},
	"rooftop": {"body": Color("#10141e"), "top": Color("#4a5468"), "plate": Color("#2e3648"), "edge": Color("#9fb6e0")},
	"downtown": {"body": Color("#1a1218"), "top": Color("#6a4a52"), "plate": Color("#3a2a30"), "edge": Color("#ffb0a0")},
	"underpass": {"body": Color("#0c1418"), "top": Color("#3c5058"), "plate": Color("#283a42"), "edge": Color("#9fe2ff")},
	"neon": {"body": Color("#140c1c"), "top": Color("#5a2a6a"), "plate": Color("#3a1a4a"), "edge": Color("#ff9ad8")},
	"nightcity": {"body": Color("#0e1412"), "top": Color("#3a4a44"), "plate": Color("#26322e"), "edge": Color("#a8ffcf")},
	"skyline": {"body": Color("#1a1014"), "top": Color("#6a3a4a"), "plate": Color("#3a2430"), "edge": Color("#ffb0d8")},
	"archive": {"body": Color("#141008"), "top": Color("#6a5a30"), "plate": Color("#3a3020"), "edge": Color("#ffe08a")},
}


func _draw_platforms() -> void:
	var st: Dictionary = STYLE.get(room_id, STYLE["waterworks"])
	for s in solids:
		if s["astral"]:
			continue
		var r: Rect2 = s["rect"]
		if s["oneway"]:
			draw_rect(Rect2(r.position + Vector2(0, 2), Vector2(r.size.x, r.size.y)), Color(0, 0, 0, 0.35))
			draw_rect(r, st["plate"])
			draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), st["edge"])
			var x = r.position.x + 10
			while x < r.end.x - 4:
				draw_line(Vector2(x, r.end.y), Vector2(x, r.end.y + 26), Color(st["plate"], 0.8), 3.0)
				x += maxf(40.0, r.size.x / 3.0)
			if room_id in ["waterworks", "pumphouse"]:
				draw_line(r.position + Vector2(0, -22), Vector2(r.end.x, r.position.y - 22), Color(st["edge"], 0.5), 2.0)
				var px = r.position.x
				while px <= r.end.x:
					draw_line(Vector2(px, r.position.y), Vector2(px, r.position.y - 22), Color(st["edge"], 0.5), 2.0)
					px += 40.0
		else:
			draw_rect(r, st["body"])
			draw_rect(Rect2(r.position, Vector2(r.size.x, 6)), st["top"])
			draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color(st["edge"], 0.6))
			if room_id == "hospital":
				var tx = r.position.x
				while tx < r.end.x:
					draw_line(Vector2(tx, r.position.y), Vector2(tx, r.position.y + 6), Color(0, 0, 0, 0.25), 1.0)
					tx += 48.0
			elif room_id in ["waterworks", "pumphouse"]:
				var gx = r.position.x
				while gx < r.end.x:
					draw_line(Vector2(gx, r.position.y + 1), Vector2(gx - 8, r.position.y + 6), Color(0, 0, 0, 0.4), 1.0)
					gx += 14.0


func _draw_sludge(r: Rect2, clear := false) -> void:
	var pts = PackedVector2Array()
	pts.append(Vector2(r.position.x, r.end.y))
	var x = 0.0
	while x <= r.size.x:
		pts.append(Vector2(r.position.x + x, r.position.y + sin(t * 2 + x * 0.08) * 3))
		x += 10
	pts.append(r.end)
	draw_colored_polygon(pts, Color("#1f6a8a") if clear else Color("#7a1218"))
	draw_rect(Rect2(r.position.x, r.position.y + 8, r.size.x, r.size.y - 8), Color("#0c2a3a") if clear else Color("#3a0a0e"))
	_glow(Vector2(r.get_center().x, r.position.y), r.size.x * 0.7, Color(0.4, 0.8, 1, 0.14) if clear else Color(1, 0.25, 0.25, 0.14))
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
