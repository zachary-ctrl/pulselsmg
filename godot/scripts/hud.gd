extends Control
## Resonance orb, health shards, projection timer, boss name and bar, toasts,
## area title cards, vignette and screen flash.

var main: Node


func _process(_d: float) -> void:
	queue_redraw()


func _text(font: Font, pos: Vector2, s: String, size: int, col: Color, center := false) -> void:
	var w = font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, pos - Vector2(w / 2.0 if center else 0.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


var _plate: Texture2D


func _draw() -> void:
	if main == null or main.mode in ["title", "boot", "splash", "arcade"]:
		return
	var W = 960.0
	var H = 540.0
	# vignette
	for i in 12:
		var a = 0.06 * (i / 12.0)
		draw_rect(Rect2(i * 4.0, i * 4.0, W - i * 8.0, H - i * 8.0), Color(0, 0, 0, 0.05), false, 8.0)
	if main.flash > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(main.flash_col, main.flash * 0.5))
	if main.mode == "end":
		return
	var p: Node = main.partner if (Net.is_guest() and main.partner_ok()) else main.player
	var t: float = main.t
	# cyberpunk GUI plate behind the orb, health and party
	if _plate == null:
		_plate = load("res://assets/gui/plate2.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	draw_texture_rect(_plate, Rect2(4, 2, 349, 115), false, Color(1, 1, 1, 0.92))
	# resonance orb
	var c = Vector2(56, 56)
	var r = 34.0
	var full: bool = p.res >= Game.fp_need()
	draw_circle(c, r + 6, Color(0.02, 0.02, 0.04, 0.65))
	var lvl: float = clampf(p.res / Game.fp_need(), 0.0, 1.0)
	var ly = c.y + r - lvl * r * 2.0
	if lvl > 0.01:
		# Liquid = circle ∩ (area under a wavy surface line).
		var circle = PackedVector2Array()
		for i in 40:
			var a = TAU * i / 40.0
			circle.append(c + Vector2(cos(a), sin(a)) * r)
		var liquid = PackedVector2Array()
		var x = -r - 4.0
		while x <= r + 4.0:
			liquid.append(Vector2(c.x + x, ly + sin(t * 3 + x * 0.15) * 2.5))
			x += 4.0
		liquid.append(Vector2(c.x + r + 4.0, c.y + r + 4.0))
		liquid.append(Vector2(c.x - r - 4.0, c.y + r + 4.0))
		for part in Geometry2D.intersect_polygons(circle, liquid):
			if part.size() >= 3:
				draw_colored_polygon(part, Color("#8f6cf0") if full else Color("#e0863a"))
	draw_arc(c, r, 0, TAU, 48, Color(0.93, 0.9, 0.85, 0.85), 2.0)
	draw_arc(c, r + 5, 0, TAU, 48, Color(0.93, 0.9, 0.85, 0.3), 1.0)
	if full:
		draw_circle(c, r + 14, Color(0.65, 0.55, 1, 0.12 + 0.08 * sin(t * 5)))
	for i in mini(Game.overdraw, 5):
		var a = -1.2 + i * 0.6
		draw_line(c + Vector2(cos(a), sin(a)) * r, c + Vector2(cos(a), sin(a + 0.15)) * (r - 12), Color(0.78, 0.67, 1, 0.9), 1.2)
	if p.max_hp > 20:
		_text(Game.font_display, Vector2(112, 50), "%d / %d" % [p.hp, p.max_hp], 18, Color("#efe7da"))
	for i in (p.max_hp if p.max_hp <= 20 else 0):
		var sp = clampf(225.0 / p.max_hp, 14.0, 26.0)
		var kq = clampf(sp / 26.0, 0.6, 1.0)
		var sc = Vector2(110 + i * sp, 44)
		var dia = PackedVector2Array([sc + Vector2(0, -13) * kq, sc + Vector2(9, -2) * kq, sc + Vector2(0, 13) * kq, sc + Vector2(-9, -2) * kq])
		if i < p.hp:
			draw_colored_polygon(dia, Color("#efe7da"))
			draw_circle(sc + Vector2(0, -1), 2.4, Color("#1a1420"))
		else:
			draw_colored_polygon(dia, Color(0.08, 0.08, 0.12, 0.6))
			dia.append(dia[0])
			draw_polyline(dia, Color(0.93, 0.9, 0.85, 0.35), 1.2)
	if not p.shinobi:
		_text(Game.font_semi, Vector2(110, 78), ("FULL POTENTIAL READY [" + Game.label("fp") + "]") if full else ("RESONANCE · %s alter ego" % ("[" + Game.label("transform") + "]") if p.res >= 30.0 else "RESONANCE"), 12, Color(0.93, 0.9, 0.85, 0.7))
	# hero, level and party
	for i in 10:
		draw_rect(Rect2(0, 96 + i * 5.0, 300 - i * 12.0, 5), Color(0, 0, 0, 0.32 - i * 0.02))
	# second player (couch or online co-op)
	var q: Node = null
	if main.partner_ok():
		q = main.player if (Net.is_guest()) else main.partner
	if q != null:
		var qc = Color(Game.HEROES[q.hero]["col"])
		draw_rect(Rect2(12, H - 44, 230, 32), Color(0.02, 0.02, 0.06, 0.7))
		_text(Game.font_display, Vector2(20, H - 22), ("HOST · " if Net.is_guest() else "P2 · ") + Game.HEROES[q.hero]["name"], 12, qc)
		for i in q.max_hp:
			var dc = Vector2(120 + i * 11, H - 27)
			var dd = PackedVector2Array([dc + Vector2(0, -6), dc + Vector2(4, -1), dc + Vector2(0, 6), dc + Vector2(-4, -1)])
			draw_colored_polygon(dd, Color("#efe7da") if i < q.hp else Color(1, 1, 1, 0.15))
		if q.down_t > 0.0:
			_text(Game.font_semi, Vector2(120, H - 12), "DOWN · back in %d" % ceili(q.down_t), 10, Color("#ff8a8a"))
	if Net.is_guest() and main.mode in ["choice"]:
		_text(Game.font_display, Vector2(W / 2, H / 2), "The host is choosing...", 18, Color.WHITE, true)
	var hd: Dictionary = Game.HEROES[p.hero]
	if p.shinobi:
		var ego = "ALTER EGO · " + p.EGO_NAMES[p.hero]
		_text(Game.font_display, Vector2(110, 78), ego, 12, Color(hd["col"]).lerp(Color.WHITE, 0.3 + 0.2 * sin(t * 6.0)))
	var pg: Dictionary = Game.prog
	_text(Game.font_display, Vector2(22, 112), "%s · LV %d" % [hd["name"], pg["level"]], 13, Color(hd["col"]))
	draw_rect(Rect2(22, 118, 150, 3), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(22, 118, 150.0 * clampf(float(pg["xp"]) / Game.xp_next(pg["level"]), 0.0, 1.0), 3), Color("#fff2c8"))
	var party: Array = Game.party()
	if party.size() > 1:
		for i in party.size():
			var h: String = party[i]
			var cc = Vector2(186 + i * 24, 114)
			var hc = Color(Game.HEROES[h]["col"])
			draw_circle(cc, 9, Color(hc, 0.9 if h == p.hero else 0.25))
			draw_arc(cc, 10, 0, TAU, 20, Color(1, 1, 1, 0.6 if h == p.hero else 0.2), 1.2)
			_text(Game.font_display, cc + Vector2(0, 4), h.substr(0, 1).to_upper(), 10, Color("#14101a"), true)
		_text(Game.font_semi, Vector2(186 + party.size() * 24, 118), "[" + Game.label("switch") + "]", 10, Color(0.93, 0.9, 0.85, 0.5))
	var pts = 0
	for h in party:
		pts += int(pg["pts"].get(h, 0))
	if pts > 0:
		_text(Game.font_semi, Vector2(22, 138), "%d attribute point%s · [%s]" % [pts, "" if pts == 1 else "s", Game.label("menu")], 11, Color("#fff2c8"))
	# projection timer
	if main.astral_active():
		var tl: float = maxf(0.0, main.astral.timer)
		var cc = Vector2(W / 2, 46)
		draw_arc(cc, 26, 0, TAU, 48, Color(0.65, 0.55, 1, 0.25), 5.0)
		draw_arc(cc, 26, -PI / 2, -PI / 2 + TAU * tl / 60.0, 48, Color("#ff8ab0") if tl < 10.0 else Color("#c9b8ff"), 5.0)
		_text(Game.font_display, cc + Vector2(0, 6), str(ceili(tl)), 15, Color("#ece6ff"), true)
		_text(Game.font_semi, Vector2(W / 2, 90), "ASTRAL · [" + Game.label("project") + "] to return", 11, Color("#ece6ff"), true)
	# boss
	if main.fight != null and main.mode != "choice" and is_instance_valid(main.fight["e"]):
		var e = main.fight["e"]
		_text(Game.font_display, Vector2(W / 2, H - 34), main.fight["name"], 15, Color(0.93, 0.9, 0.85, 0.9), true)
		_text(Game.font_italic, Vector2(W / 2, H - 16), main.fight["sub"], 12, Color(0.78, 0.75, 0.86, 0.8), true)
		draw_rect(Rect2(W / 2 - 160, H - 56, 320, 3), Color(0.93, 0.9, 0.85, 0.15))
		draw_rect(Rect2(W / 2 - 160, H - 56, 320.0 * maxf(0.0, float(e.hp) / e.max_hp), 3), Color(0.93, 0.9, 0.85, 0.8))
	if main.predict_text != "" and main.fight != null:
		_text(Game.font_display, Vector2(W / 2, 120), main.predict_text, 14, Color(1, 0.6, 0.85, 0.6 + 0.4 * sin(t * 20)), true)
	var ty = 150.0
	for tst in main.toasts:
		var a: float = minf(1.0, minf(tst["life"], (tst["max"] - tst["life"]) * 4.0))
		var s: String = tst["s"]
		var w = Game.font_italic.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 44
		draw_rect(Rect2(W / 2 - w / 2, ty - 20, w, 28), Color(0.02, 0.02, 0.04, 0.75 * a))
		_text(Game.font_italic, Vector2(W / 2, ty), s, 17, Color(0.93, 0.9, 0.85, a), true)
		ty += 32
	if main.card != null:
		var ct: float = main.card["t"]
		var a = ct if ct < 1.0 else (maxf(0.0, 4.0 - ct) if ct > 3.0 else 1.0)
		var y = H * 0.32
		draw_rect(Rect2(0, y - 60, W, 130), Color(0.01, 0.02, 0.03, 0.55 * a))
		_text(Game.font_display, Vector2(W / 2, y), main.card["name"].to_upper(), 40, Color(0.93, 0.9, 0.85, a), true)
		draw_line(Vector2(W / 2 - 190, y + 16), Vector2(W / 2 - 12, y + 16), Color(0.93, 0.9, 0.85, a * 0.7), 1.0)
		draw_line(Vector2(W / 2 + 12, y + 16), Vector2(W / 2 + 190, y + 16), Color(0.93, 0.9, 0.85, a * 0.7), 1.0)
		_text(Game.font_italic, Vector2(W / 2, y + 46), main.card["sub"], 17, Color(0.93, 0.9, 0.85, a), true)
	if main.mode == "dead":
		var a: float = minf(1.0, main.dead_t / 1.2)
		draw_rect(Rect2(0, 0, W, H), Color(0.01, 0.01, 0.02, a * 0.9))
		_text(Game.font_display, Vector2(W / 2, H / 2), "Your mind came loose.", 30, Color(0.93, 0.9, 0.85, a), true)
		_text(Game.font_italic, Vector2(W / 2, H / 2 + 34), "Your body remembers where you last rested.", 16, Color(0.78, 0.75, 0.86, a), true)
	if main.trans != null:
		var tt: float = main.trans["t"]
		var k = tt / 0.28 if tt < 0.28 else 1.0 - (tt - 0.28) / 0.32
		draw_rect(Rect2(0, 0, W, H), Color(0.01, 0.01, 0.02, clampf(k, 0, 1)))
