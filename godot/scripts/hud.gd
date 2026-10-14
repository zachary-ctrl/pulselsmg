extends Control
## Resonance orb, health shards, projection timer, boss name and bar, toasts,
## area title cards, vignette and screen flash.

var main: Node


func _process(_d: float) -> void:
	queue_redraw()


func _text(font: Font, pos: Vector2, s: String, size: int, col: Color, center := false) -> void:
	var w = font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, pos - Vector2(w / 2.0 if center else 0.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _draw() -> void:
	if main == null or main.mode == "title" or main.mode == "boot":
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
	var p: Node = main.player
	var t: float = main.t
	# resonance orb
	var c = Vector2(56, 56)
	var r = 34.0
	var full: bool = p.res >= 99.0
	draw_circle(c, r + 6, Color(0.02, 0.02, 0.04, 0.65))
	var lvl: float = p.res / 99.0
	var ly = c.y + r - lvl * r * 2.0
	var poly = PackedVector2Array()
	var x = -r
	while x <= r:
		var yy = maxf(ly + sin(t * 3 + x * 0.15) * 2.5, c.y - sqrt(maxf(0.0, r * r - x * x)))
		poly.append(Vector2(c.x + x, minf(yy, c.y + sqrt(maxf(0.0, r * r - x * x)))))
		x += 4
	x = r
	while x >= -r:
		poly.append(Vector2(c.x + x, c.y + sqrt(maxf(0.0, r * r - x * x))))
		x -= 4
	if lvl > 0.01 and poly.size() > 3:
		draw_colored_polygon(poly, Color("#8f6cf0") if full else Color("#e0863a"))
	draw_arc(c, r, 0, TAU, 48, Color(0.93, 0.9, 0.85, 0.85), 2.0)
	draw_arc(c, r + 5, 0, TAU, 48, Color(0.93, 0.9, 0.85, 0.3), 1.0)
	if full:
		draw_circle(c, r + 14, Color(0.65, 0.55, 1, 0.12 + 0.08 * sin(t * 5)))
	for i in mini(Game.overdraw, 5):
		var a = -1.2 + i * 0.6
		draw_line(c + Vector2(cos(a), sin(a)) * r, c + Vector2(cos(a), sin(a + 0.15)) * (r - 12), Color(0.78, 0.67, 1, 0.9), 1.2)
	for i in p.max_hp:
		var sc = Vector2(110 + i * 30, 44)
		var dia = PackedVector2Array([sc + Vector2(0, -13), sc + Vector2(9, -2), sc + Vector2(0, 13), sc + Vector2(-9, -2)])
		if i < p.hp:
			draw_colored_polygon(dia, Color("#efe7da"))
			draw_circle(sc + Vector2(0, -1), 2.4, Color("#1a1420"))
		else:
			draw_colored_polygon(dia, Color(0.08, 0.08, 0.12, 0.6))
			dia.append(dia[0])
			draw_polyline(dia, Color(0.93, 0.9, 0.85, 0.35), 1.2)
	_text(Game.font_semi, Vector2(96, 78), ("FULL POTENTIAL READY [" + Game.label("fp") + "]") if full else "RESONANCE", 12, Color(0.93, 0.9, 0.85, 0.7))
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
