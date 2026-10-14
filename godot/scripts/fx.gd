extends Node2D
## World-space effects drawn above the astral color grade: projectiles,
## particles, laser beams, prediction marks, slash arcs, floating text and the
## astral-only platforms.

var main: Node
var projectiles: Array = []
var parts: Array = []
var texts: Array = []
var beams: Array = []
var lasers: Array = []
var predict = null
var _cid = 0


func part(pos: Vector2, vel: Vector2, k: String, col: Color, follow: Node = null) -> void:
	if parts.size() > 500:
		return
	var life = {"res": 0.6, "wisp": 1.4, "heal": 0.7, "trail": 0.3}.get(k, 0.5)
	parts.append({"p": pos, "v": vel, "k": k, "c": col, "life": life, "max": life, "f": follow, "s": pos})


func burst(pos: Vector2, n: int, speed: float, col: Color) -> void:
	for i in n:
		part(pos, Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)) * speed, "spark", col)


func text_float(pos: Vector2, s: String, col: Color, life: float) -> void:
	texts.append({"p": pos, "s": s, "c": col, "life": life, "max": life})


func shoot(pos: Vector2, vel: Vector2, r: float, k: String, col: Color, grav := 0.0) -> void:
	projectiles.append({"p": pos, "v": vel, "r": r, "k": k, "c": col, "life": 4.0, "grav": grav, "rot": 0.0})


func chain(x: float, vx: float) -> void:
	_cid += 1
	for i in 6:
		projectiles.append({"p": Vector2(x, 400), "v": Vector2(vx, 0), "r": 9.0, "k": "chain", "c": Color("#7ff0ff"), "life": 6.0, "delay": i * 0.13, "by": 395.0, "i": i, "cid": _cid, "age": 0.0, "grav": 0.0, "rot": 0.0})


func clear_all() -> void:
	projectiles.clear()
	parts.clear()
	texts.clear()
	beams.clear()
	lasers.clear()
	predict = null


func step(dt: float) -> void:
	for l in lasers:
		l["life"] -= dt
	lasers = lasers.filter(func(l): return l["life"] > 0.0)
	var solids: Array = main.room.solid_rects(false)
	var floors: Array = main.room.solid_rects(true)
	for p in projectiles:
		if p["k"] == "chain":
			if p["delay"] > 0.0:
				p["delay"] -= dt
				continue
			p["age"] += dt
			p["p"].x += p["v"].x * dt
			p["p"].y = p["by"] + sin(p["age"] * 4.0 + p["i"] * 0.7) * 80.0
		else:
			p["p"] += p["v"] * dt
			if p["grav"] > 0.0:
				p["v"].y += p["grav"] * dt
				p["rot"] += dt * 10.0
		p["life"] -= dt
		if p["p"].x < -40 or p["p"].x > main.room.room_size.x + 40:
			p["life"] = 0.0
		if p["k"] == "beaker" or p["k"] == "sludge":
			for r in floors:
				if r.has_point(p["p"]):
					p["life"] = 0.0
					Sound.play("glass" if p["k"] == "beaker" else "land", 0.1)
					for i in 14:
						part(Vector2(p["p"].x, r.position.y - 4), Vector2(randf_range(-130, 130), -randf() * 240), "dust", p["c"])
					break
		elif p["k"] != "chain":
			for r in solids:
				if r.has_point(p["p"]):
					p["life"] = 0.0
					break
		if p["life"] > 0.0:
			var pr = Rect2(p["p"] - Vector2(p["r"], p["r"]), Vector2(p["r"], p["r"]) * 2)
			if pr.intersects(main.player.hitbox()):
				main.hurt_player(1, p["p"].x)
				p["life"] = 0.0
			elif main.astral_active() and pr.intersects(main.astral.hitbox()):
				main.hurt_astral()
				p["life"] = 0.0
	projectiles = projectiles.filter(func(p): return p["life"] > 0.0)
	update_cosmetic(dt)


func update_cosmetic(dt: float) -> void:
	for p in parts:
		p["life"] -= dt
		var k: String = p["k"]
		if k == "res" and is_instance_valid(p["f"]):
			var u: float = 1.0 - p["life"] / p["max"]
			p["p"] = p["s"].lerp(p["f"].position + Vector2(0, -30), u * u) + Vector2(0, -40 * sin(u * 3.0) * (1 - u * u))
			continue
		if k == "heal" and is_instance_valid(p["f"]):
			p["p"] = p["p"].lerp(p["f"].position + Vector2(0, -30), dt * 6.0)
			continue
		p["p"] += p["v"] * dt
		if k == "dust" or k == "spark":
			p["v"] *= 0.92
			if k == "dust":
				p["v"].y += 200.0 * dt
		if k == "wisp":
			p["v"].y -= 40.0 * dt
			p["v"].x *= 0.97
	parts = parts.filter(func(p): return p["life"] > 0.0)
	for t in texts:
		t["life"] -= dt
		t["p"].y -= dt * 10.0
	texts = texts.filter(func(t): return t["life"] > 0.0)


func _process(_d: float) -> void:
	queue_redraw()


func _glow(c: Vector2, r: float, col: Color) -> void:
	for i in 4:
		draw_circle(c, r * (1.0 - i * 0.22), Color(col, col.a * 0.25))


func _draw() -> void:
	if main == null or main.room == null:
		return
	var amix: float = main.astral_mix
	var t: float = main.t
	if amix > 0.02:
		for s in main.room.solids:
			if not s["astral"]:
				continue
			var r: Rect2 = s["rect"]
			draw_rect(r, Color(0.82, 0.75, 1, 0.85 * amix))
			draw_rect(Rect2(r.position + Vector2(0, r.size.y * 0.5), Vector2(r.size.x, r.size.y * 0.5)), Color(0.47, 0.31, 1, 0.5 * amix))
			_glow(r.get_center(), r.size.x * 0.7, Color(0.65, 0.55, 1, 0.2 * amix))
			for i in 7:
				var rad = 14.0 * (0.28 + i * 0.12)
				var a0 = (t if i % 2 else -t) + i * 1.7
				draw_arc(Vector2(r.get_center().x, r.end.y + 16), rad, a0, a0 + TAU - 0.6, 20, Color(0.86, 0.78, 1, 0.5 * amix), 1.0)
		for an in main.room.markers["anchor"]:
			if not an.astral or Game.anchors.has(an.id):
				continue
			var pos: Vector2 = an.position + Vector2(0, -26 + sin(t * 2.4) * 4)
			_glow(pos, 38, Color(0.65, 0.55, 1, 0.45 * amix))
			for i in 7:
				var rad = 20.0 * (0.28 + i * 0.12)
				var a0 = (t if i % 2 else -t) + i * 1.7
				draw_arc(pos, rad, a0, a0 + TAU - 0.6, 24, Color(0.93, 0.9, 1, amix), 1.5)
	# chains
	var chains = {}
	for p in projectiles:
		if p["k"] == "chain" and p["delay"] <= 0.0:
			if not chains.has(p["cid"]):
				chains[p["cid"]] = []
			chains[p["cid"]].append(p)
	for c in chains.values():
		c.sort_custom(func(a, b): return a["i"] < b["i"])
		var pts = PackedVector2Array()
		for p in c:
			pts.append(p["p"])
		if pts.size() > 1:
			draw_polyline(pts, Color(0.5, 0.94, 1, 0.5), 2.0)
	for p in projectiles:
		if p.get("delay", 0.0) > 0.0:
			continue
		_glow(p["p"], p["r"] * 3.0, Color(p["c"], 0.5))
		draw_circle(p["p"], p["r"] * 0.55, Color.WHITE)
		if p["k"] == "beaker":
			draw_set_transform(p["p"], p["rot"])
			draw_colored_polygon(PackedVector2Array([Vector2(-5, -9), Vector2(5, -9), Vector2(9, 8), Vector2(-9, 8)]), Color(0.78, 0.94, 1, 0.7))
			draw_rect(Rect2(-8, 2, 16, 6), Color("#4aff9a"))
			draw_set_transform(Vector2.ZERO)
		if p["k"] == "chain":
			draw_arc(p["p"], p["r"], 0, TAU, 20, Color(0.5, 0.94, 1, 0.8), 1.5)
	var rs: Vector2 = main.room.room_size
	for b in beams:
		var blink = 0.4 + 0.4 * sin(t * 30.0)
		if b["k"] == "v":
			if b["on"]:
				draw_rect(Rect2(b["x"] - 26, 0, 52, rs.y), Color(0.5, 0.94, 1, 0.35))
				draw_rect(Rect2(b["x"] - 9, 0, 18, rs.y), Color(0.86, 1, 1, 0.95))
			else:
				draw_dashed_line(Vector2(b["x"], 0), Vector2(b["x"], rs.y), Color(1, 0.35, 0.47, blink), 1.5, 8.0)
				draw_rect(Rect2(b["x"] - 20, 0, 40, rs.y), Color(1, 0.35, 0.47, 0.35), false, 1.0)
		else:
			if b["on"]:
				draw_rect(Rect2(0, b["y"] - 26, rs.x, 52), Color(0.5, 0.94, 1, 0.35))
				draw_rect(Rect2(0, b["y"] - 9, rs.x, 18), Color(0.86, 1, 1, 0.95))
			else:
				draw_dashed_line(Vector2(0, b["y"]), Vector2(rs.x, b["y"]), Color(1, 0.35, 0.47, blink), 1.5, 8.0)
	if predict != null:
		var c = Color(1, 0.48, 0.82, 0.5 + 0.5 * sin(t * 25.0))
		draw_arc(predict, 68, 0, TAU, 48, c, 2.0)
		draw_line(predict - Vector2(80, 0), predict + Vector2(80, 0), c, 2.0)
		draw_line(predict - Vector2(0, 80), predict + Vector2(0, 80), c, 2.0)
		draw_string(Game.font_semi, predict + Vector2(10, -72), "▸ " + main.predict_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ff9ad8"))
	for who in [main.player, main.astral]:
		if who == null or not is_instance_valid(who):
			continue
		var wc = Color("#c9b8ff") if who.is_astral else Color("#ffb06a")
		if who.atk_t > 0.0:
			_slash(who, wc)
		if who.kick_t > 0.0:
			_kick(who, wc)
		if not who.is_astral and who.laser_t > 0.0 and not who.laser_fired:
			var hand: Vector2 = who.position + (Vector2(0, -96) if who.laser_dir.y < 0.0 else Vector2(who.face * 26, -40))
			var k = 1.0 - (who.laser_t - 0.26) / 0.14
			draw_circle(hand, 4.0 + 14.0 * k, Color(1, 0.84, 0.6, 0.25 * k))
			draw_circle(hand, 2.0 + 6.0 * k, Color(1, 0.97, 0.9, 0.9))
	for l in lasers:
		var a: float = l["life"] / l["max"]
		var wv = 1.0 + 0.15 * sin(t * 60.0)
		draw_line(l["a"], l["b"], Color(1, 0.55, 0.25, 0.25 * a), 46.0 * a * wv)
		draw_line(l["a"], l["b"], Color(1, 0.8, 0.45, 0.6 * a), 22.0 * a * wv)
		draw_line(l["a"], l["b"], Color(1, 0.98, 0.92, a), 8.0 * a)
		draw_circle(l["a"], 18.0 * a, Color(1, 0.95, 0.85, 0.8 * a))
		draw_circle(l["b"], 26.0 * a, Color(1, 0.75, 0.4, 0.5 * a))
	for p in parts:
		var a: float = clampf(p["life"] / p["max"], 0.0, 1.0)
		var k: String = p["k"]
		var sz = 2.4
		if k == "wisp":
			sz = 3.0 + 2.0 * (1.0 - a)
		elif k == "dust":
			sz = 2.0
		elif k == "trail":
			sz = 4.0 * a + 1.0
		if k == "res" or k == "wisp":
			draw_circle(p["p"], 10, Color(p["c"], 0.12 * a))
		draw_circle(p["p"], sz, Color(p["c"], a))
	for tx in texts:
		var a = minf(0.9, tx["life"])
		var font: Font = Game.font_italic
		var size = 14
		var wdt = font.get_string_size(tx["s"], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string(font, tx["p"] - Vector2(wdt / 2.0, 0), tx["s"], HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(tx["c"], a))


func _slash(e: Node, col: Color) -> void:
	var k: float = 1.0 - e.atk_t / 0.24
	var origin: Vector2 = e.position + Vector2(0, -34)
	var a0 = 0.0
	var a1 = 0.0
	var c = Vector2.ZERO
	if e.atk_dir == "side":
		c = Vector2(e.face * 24, 0)
		if e.face > 0:
			a0 = -1.25
			a1 = 1.25
		else:
			a0 = PI + 1.25
			a1 = PI - 1.25
	elif e.atk_dir == "up":
		c = Vector2(0, -34)
		a0 = PI + 0.4
		a1 = TAU - 0.4
	else:
		c = Vector2(0, 40)
		a0 = 0.4
		a1 = PI - 0.4
	var big = 1.4 if e.atk_kind == "finisher" else 1.0
	var sweep = lerpf(a0, a1, minf(1.0, k * 1.8))
	var alpha = 1.0 - k
	for i in 4:
		var ccol = Color("#fff7e8") if i == 0 else col
		draw_arc(origin + c * big, (54.0 - i * 7) * big, minf(a0, sweep), maxf(a0, sweep), 24, Color(ccol, alpha * (1.0 - i * 0.2)), (9.0 - i * 2) * (1.0 - k * 0.5) * big)
	_glow(origin + c, 60, Color(col, 0.3 * alpha))


func _kick(e: Node, col: Color) -> void:
	if e.dive:
		var c: Vector2 = e.position + Vector2(e.face * 12, -6)
		draw_circle(c, 22, Color(col, 0.25))
		draw_arc(c, 26, 0, TAU, 24, Color("#fff7e8", 0.8), 3.0)
		for i in 3:
			var off = Vector2(-e.face * (14 + i * 12), -(18 + i * 16))
			draw_line(c + off, c + off * 1.8, Color(col, 0.6 - i * 0.15), 4.0 - i)
		return
	var k: float = clampf(1.0 - (e.kick_t - 0.06) / 0.26, 0.0, 1.0)
	if k <= 0.0 or k >= 1.0:
		return
	var c2: Vector2 = e.position + Vector2(e.face * (30 + 34 * k), -26)
	var alpha = 1.0 - k
	var a0 = -0.9 if e.face > 0 else PI + 0.9
	var a1 = 0.9 if e.face > 0 else PI - 0.9
	for i in 3:
		draw_arc(c2 - Vector2(e.face * i * 8, 0), 30.0 - i * 6, minf(a0, a1), maxf(a0, a1), 18, Color(Color("#fff7e8") if i == 0 else col, alpha * (1.0 - i * 0.25)), 7.0 - i * 2)
	_glow(c2, 40, Color(col, 0.3 * alpha))
