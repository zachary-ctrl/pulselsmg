extends Control
## LSMG ARCADE · STEAMER DUCK. An endless 8-bit run built from the CC0 art,
## sounds and music of "Steamer Duck" (a pygame platformer). Its mechanics are
## kept: Jump hops off the ground, holding it flaps the wings to glide, and
## Strike QUACKS, which freezes every robot for 2.5 s (5 s cooldown).
## Trampolines launch you, spikes and robots end the run, and so do the pits.
## The world scrolls ever faster through meadow, desert and winter.

const PF = preload("res://scripts/pixelfont.gd")
const PX := 4.0
const DIR := "res://assets/arcade/duck/"
const T := 16.0
const G := 300.0
const G_FLAP := 172.0            # original: gravity minus the flying force
const FLAP_FALL := 50.0
const JUMP_V := 130.0
const TRAMP_V := 235.0
const SCROLL0 := 62.0
const SCROLL_MAX := 132.0
const HOME_X := 60.0
const HALF_W := 5.0
const BODY_H := 14.0
const QUACK_COOL := 5.0
const QUACK_FREEZE := 2.5
const BIOME_COLS := 140
const BIOMES := ["MEADOW", "DESERT", "WINTER"]
const BG_NAMES := ["green", "egypt", "winter"]
const TILE_NAMES := ["ground", "sand", "snow"]
const SKY := [Color("#c3b5f7"), Color("#9cc8ee"), Color("#e8f6fb")]
const RED := Color("#e8243a")
const WHITE := Color("#f4f4f4")
const GOLD := Color("#ffd23a")

var main: Node
var state = "title"
var t = 0.0
var best = 0
var logo: Texture2D
var tx = {}
var sfx = {}
var _players: Array = []
var _next_player = 0
var music: AudioStreamPlayer

var rng = RandomNumberGenerator.new()
# world: one Dictionary per 16-px column, cols[0] is column index col0
var cols: Array = []
var col0 = 0
var gen_col = 0
var gen_h = 2
var coins: Array = []
var eggs: Array = []
var robots: Array = []
var floats: Array = []
var rings: Array = []

var elapsed = 0.0
var scroll = SCROLL0
var cam = 0.0
var dx = 60.0
var dy = 103.0
var vy = 0.0
var grounded = true
var flapping = false
var walk = 0.0
var quack_t = 99.0
var quack_cd = 0.0
var start_x = 60.0
var coin_n = 0
var egg_n = 0
var score = 0
var dying = false
var die_t = 0.0
var die_vx = 0.0
var biome = 0
var bg_prev = 0
var bg_fade = 1.0
var new_best = false
var msg = ""
var msg_t = 0.0


func _ready() -> void:
	size = Vector2(960, 540)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo = load("res://assets/lsmg/logo8.png")
	for n in ["duck", "duck_big", "robot_fly", "robot_ground", "coin", "egg", "spikes", "trampoline", "tile_ground", "tile_sand", "tile_snow", "tile_bricks", "top_ground", "top_sand", "top_snow", "top_bricks", "bg_green", "bg_egypt", "bg_winter"]:
		tx[n] = load(DIR + n + ".png")
	for n in ["quack", "flapping", "coin", "click", "trampoline", "win"]:
		sfx[n] = load(DIR + "sfx/" + n + ".wav")
	for i in 5:
		var p = AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_players.append(p)
	music = AudioStreamPlayer.new()
	var stream = load(DIR + "music_you_know_why.ogg")
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	music.stream = stream
	music.volume_db = -9.0
	add_child(music)
	Sound.music("")
	if Sound.music_on:
		music.play()
	best = int(Game.settings.get("high_duck", 0))
	rng.randomize()
	_reset()


func _exit_tree() -> void:
	if music:
		music.stop()


func _sfx(n: String, vol := 0.0, pitch_var := 0.0) -> void:
	var p: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = sfx[n]
	p.volume_db = -6.0 + vol
	p.pitch_scale = 1.0 + rng.randf_range(-pitch_var, pitch_var)
	p.play()


func _reset() -> void:
	cols.clear()
	coins.clear()
	eggs.clear()
	robots.clear()
	floats.clear()
	rings.clear()
	col0 = 0
	gen_col = 0
	gen_h = 2
	elapsed = 0.0
	scroll = SCROLL0
	cam = 0.0
	dx = HOME_X
	start_x = dx
	dy = 135.0 - 2 * T
	vy = 0.0
	grounded = true
	flapping = false
	quack_t = 99.0
	quack_cd = 0.0
	coin_n = 0
	egg_n = 0
	score = 0
	dying = false
	die_t = 0.0
	biome = 0
	bg_prev = 0
	bg_fade = 1.0
	new_best = false
	msg_t = 0.0
	# a safe runway to start on
	for i in 16:
		_push_col(2, false, false)
	_generate(cam + 300.0)


func _start() -> void:
	_reset()
	state = "play"
	_say("GO DUCK GO!")
	_sfx("quack", -2.0)


func _say(s: String) -> void:
	msg = s
	msg_t = 1.6


# ---------- world generation ----------

func _push_col(h: int, tramp: bool, spike: bool) -> void:
	var b = int(gen_col / BIOME_COLS) % 3
	cols.append({"h": h, "b": b, "v": rng.randi() % 3, "tr": tramp, "sp": spike})
	gen_col += 1


func _col(c: int) -> Variant:
	var i = c - col0
	if i < 0 or i >= cols.size():
		return null
	return cols[i]


func _top(h: int) -> float:
	return 135.0 - h * T


func _generate(to_x: float) -> void:
	while gen_col * T < to_x:
		_gen_segment()


func _gen_segment() -> void:
	var diff = clampf((gen_col - 16) / 500.0, 0.0, 1.0)
	var length = rng.randi_range(4, 9 - int(diff * 3.0))
	var first = gen_col
	var top = _top(gen_h)
	# pick the hazards of this flat stretch
	var spike_col = -1
	if length >= 5 and rng.randf() < 0.2 + 0.35 * diff:
		spike_col = first + rng.randi_range(2, length - 2)
	for i in length:
		_push_col(gen_h, false, first + i == spike_col)
	var cx0 = first * T
	var cx1 = (first + length) * T
	var r = rng.randf()
	if r < 0.35:
		# a line of coins along the ground
		var n = mini(length - 1, rng.randi_range(3, 5))
		var s = first + (length - n) / 2
		for i in n:
			if s + i != spike_col:
				coins.append({"x": (s + i) * T + 8.0, "y": top - 9.0, "got": -1.0})
	elif r < 0.5:
		eggs.append({"x": cx0 + (cx1 - cx0) * 0.5, "y": top - 44.0, "got": -1.0})
	if length >= 6 and spike_col < 0 and rng.randf() < 0.2 + 0.35 * diff:
		robots.append({"k": "g", "x": cx0 + 40.0, "y": top, "x0": cx0 + 10.0, "x1": cx1 - 10.0, "vx": -22.0, "vy": 0.0, "next": 0.0, "a": 0.0})
	if rng.randf() < 0.12 + 0.3 * diff and gen_col > 30:
		var fy = top - rng.randf_range(30.0, 52.0)
		robots.append({"k": "f", "x": cx1 - 8.0, "y": fy, "ax": cx1 - 8.0, "ay": fy, "vx": 0.0, "vy": 0.0, "next": 0.0, "a": rng.randf()})
	# then the transition to the next stretch
	var tr = rng.randf()
	if tr < 0.5:
		var gap = rng.randi_range(1, 2 + int(diff * 2.5))
		var gx = gen_col * T
		for i in gap:
			_push_col(0, false, false)
		_arc_coins(gx - 8.0, gx + gap * T + 8.0, top, gap >= 2)
		gen_h = clampi(gen_h + rng.randi_range(-1, 1), 1, 3)
	elif tr < 0.72:
		gen_h = clampi(gen_h + (1 if rng.randf() < 0.5 else -1), 1, 4)
	elif tr < 0.85:
		# trampoline over a wide pit
		cols[cols.size() - 1]["tr"] = true
		cols[cols.size() - 1]["sp"] = false
		var gap = rng.randi_range(4, 6)
		var gx = gen_col * T
		for i in gap:
			_push_col(0, false, false)
		_arc_coins(gx, gx + gap * T, top - 30.0, true)
		gen_h = clampi(gen_h + rng.randi_range(-1, 1), 1, 3)


func _arc_coins(x0: float, x1: float, base: float, add: bool) -> void:
	if not add or rng.randf() < 0.4:
		return
	var n = int((x1 - x0) / 12.0)
	for i in n:
		var k = (i + 0.5) / n
		coins.append({"x": x0 + (x1 - x0) * k, "y": base - 12.0 - sin(k * PI) * 18.0, "got": -1.0})


# ---------- collision helpers ----------

func _ground_top(x0: float, x1: float) -> float:
	# highest ground surface under the x-range (INF over a pit)
	var top = INF
	for c in range(int(floorf(x0 / T)), int(floorf((x1 - 0.01) / T)) + 1):
		var col = _col(c)
		if col != null and col["h"] > 0:
			top = minf(top, _top(col["h"]))
	return top


func _overlap(ax: float, ay: float, ahw: float, ahh: float, bx: float, by: float, bhw: float, bhh: float) -> bool:
	return absf(ax - bx) < ahw + bhw and absf(ay - by) < ahh + bhh


# ---------- loop ----------

func _physics_process(dt: float) -> void:
	t += dt
	msg_t -= dt
	bg_fade = minf(1.0, bg_fade + dt * 0.8)
	if Input.is_action_just_pressed("pause"):
		_exit()
		return
	var jump_press = Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("up") or Input.is_action_just_pressed("confirm")
	var jump_held = Input.is_action_pressed("jump") or Input.is_action_pressed("up") or Input.is_action_pressed("confirm")
	var quack_press = Input.is_action_just_pressed("attack")
	for f in floats:
		f["y"] -= 20.0 * dt
		f["t"] += dt
	floats = floats.filter(func(f): return f["t"] < 0.8)
	for rg in rings:
		rg["t"] += dt
	rings = rings.filter(func(rg): return rg["t"] < 0.5)
	match state:
		"title":
			walk += dt
			if (jump_press or quack_press) and t > 0.5:
				_start()
		"over":
			if (jump_press or quack_press) and t > 0.8:
				_start()
		"play":
			_step(dt, jump_press, jump_held, quack_press)
	queue_redraw()


func _step(dt: float, jump_press: bool, jump_held: bool, quack_press: bool) -> void:
	elapsed += dt
	quack_t += dt
	quack_cd = maxf(0.0, quack_cd - dt)
	if dying:
		die_t += dt
		vy += G * dt
		dy += vy * dt
		dx += die_vx * dt
		if die_t > 1.6:
			_game_over()
		return
	scroll = minf(SCROLL_MAX, SCROLL0 + elapsed * 0.6)
	cam += scroll * dt
	_generate(cam + 300.0)
	# drop columns far behind
	while cols.size() > 0 and (col0 + 1) * T < cam - 40.0:
		cols.pop_front()
		col0 += 1
	# quack
	if quack_press and quack_cd <= 0.0:
		quack_cd = QUACK_COOL
		quack_t = 0.0
		rings.append({"x": dx, "y": dy - 8.0, "t": 0.0})
		_sfx("quack")
		_say("QUACK!")
	# jump / flap
	if jump_press:
		if grounded:
			vy = -JUMP_V
			grounded = false
		_sfx("flapping", -4.0, 0.08)
	flapping = jump_held and not grounded
	# horizontal: keep pace with the scroll, steer with left/right
	var dir = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	var sx = dx - cam
	var vx = scroll + dir * 60.0
	if dir == 0:
		vx += (HOME_X - sx) * 1.2
	var nx = clampf(dx + vx * dt, cam - 20.0, cam + 170.0)
	var wall_top = _ground_top(nx - HALF_W, nx + HALF_W)
	if wall_top < dy - 0.5:
		# blocked by a ledge: the scroll keeps going, the duck does not
		var c = int(floorf((nx + HALF_W) / T))
		if nx > dx:
			nx = minf(dx, c * T - HALF_W - 0.01)
		else:
			nx = dx
	dx = nx
	# vertical
	var g = G_FLAP if flapping else G
	var under = _ground_top(dx - HALF_W, dx + HALF_W)
	if grounded and under < INF and absf(under - dy) < 0.6:
		dy = under
		vy = 0.0
	else:
		grounded = false
		vy += g * dt
		if flapping and vy > FLAP_FALL:
			vy = FLAP_FALL
		var ny = dy + vy * dt
		if vy > 0.0 and under < INF and dy <= under + 0.5 and ny >= under:
			ny = under
			vy = 0.0
			grounded = true
		dy = ny
	if grounded:
		walk += dt * scroll / 40.0
		var col = _col(int(floorf(dx / T)))
		if col != null and col["tr"]:
			vy = -TRAMP_V
			grounded = false
			_sfx("trampoline")
	# biome changes
	var b = int(floorf(dx / T) / BIOME_COLS) % 3
	if b != biome:
		bg_prev = biome
		biome = b
		bg_fade = 0.0
		_say(BIOMES[b])
		_sfx("win", -3.0)
	score = int((dx - start_x) / T) + coin_n * 10 + egg_n * 50
	_step_things(dt)
	# deaths: pits, being shoved off screen, spikes, robots
	if dy > 150.0 or dx < cam - 6.0:
		_die()
		return
	var cy = dy - BODY_H * 0.5
	for c in range(int(floorf((dx - HALF_W) / T)), int(floorf((dx + HALF_W) / T)) + 1):
		var col = _col(c)
		if col != null and col["sp"]:
			var top = _top(col["h"])
			if _overlap(dx, cy, HALF_W - 1.0, BODY_H * 0.5, c * T + 8.0, top - 4.5, 6.0, 4.5):
				_die()
				return
	for r in robots:
		var hh = 8.0 if r["k"] == "g" else 6.0
		var ry = r["y"] - 9.0 if r["k"] == "g" else r["y"]
		if _overlap(dx, cy, HALF_W - 1.0, BODY_H * 0.5 - 1.0, r["x"], ry, 7.0, hh):
			_die()
			return


func _step_things(dt: float) -> void:
	var cy = dy - BODY_H * 0.5
	for c in coins:
		if c["got"] >= 0.0:
			c["got"] += dt
		elif _overlap(dx, cy, HALF_W + 1.0, BODY_H * 0.5, c["x"], c["y"], 4.0, 4.0):
			c["got"] = 0.0
			coin_n += 1
			floats.append({"x": c["x"], "y": c["y"] - 6.0, "s": "+10", "t": 0.0, "c": GOLD})
			_sfx("coin", -6.0, 0.05)
	coins = coins.filter(func(c): return c["x"] > cam - 20.0 and c["got"] < 0.3)
	for e in eggs:
		if e["got"] >= 0.0:
			e["got"] += dt
		elif _overlap(dx, cy, HALF_W + 1.0, BODY_H * 0.5, e["x"], e["y"], 4.0, 5.0):
			e["got"] = 0.0
			egg_n += 1
			floats.append({"x": e["x"], "y": e["y"] - 8.0, "s": "EGG +50", "t": 0.0, "c": WHITE})
			_sfx("click")
	eggs = eggs.filter(func(e): return e["x"] > cam - 20.0 and e["got"] < 0.3)
	var frozen = quack_t < QUACK_FREEZE
	for r in robots:
		if frozen:
			continue
		r["a"] += dt
		r["next"] -= dt
		if r["k"] == "g":
			if r["next"] <= 0.0:
				r["next"] = rng.randf_range(0.5, 2.0)
				r["vx"] = rng.randf_range(-30.0, 30.0)
			r["x"] += r["vx"] * dt
			if r["x"] < r["x0"] or r["x"] > r["x1"]:
				r["x"] = clampf(r["x"], r["x0"], r["x1"])
				r["vx"] = -r["vx"]
		else:
			if r["next"] <= 0.0:
				# the original AI: a new random direction every 0.5-2 s
				r["next"] = rng.randf_range(0.5, 2.0)
				r["vx"] = rng.randf_range(-1.0, 1.0) * 24.0
				r["vy"] = rng.randf_range(-1.0, 1.0) * 24.0
			r["x"] = clampf(r["x"] + r["vx"] * dt, r["ax"] - 26.0, r["ax"] + 26.0)
			r["y"] = clampf(r["y"] + r["vy"] * dt, maxf(20.0, r["ay"] - 18.0), r["ay"] + 14.0)
	robots = robots.filter(func(r): return r["x"] > cam - 30.0)


func _die() -> void:
	if dying:
		return
	dying = true
	die_t = 0.0
	vy = -150.0
	die_vx = -16.0
	quack_t = 0.0
	_sfx("quack", 2.0)


func _game_over() -> void:
	state = "over"
	t = 0.0
	if score > best:
		best = score
		new_best = true
		Game.settings["high_duck"] = best
		Game.save_settings()
		_sfx("win")
	else:
		Sound.play("ar_buzzer", 0.0, -6.0)


func _exit() -> void:
	if music:
		music.stop()
	main.close_arcade()
	queue_free()


## Test hook: jump the generator forward so later, harder terrain shows up.
func debug_skip(n_cols: int) -> void:
	var c = n_cols
	cam += c * T
	dx += c * T
	start_x += c * T
	_generate(cam + 300.0)
	var under = _ground_top(dx - HALF_W, dx + HALF_W)
	dy = under if under < INF else 40.0
	vy = 0.0
	elapsed += 60.0


# ---------- drawing (everything snaps to the 240x135 grid) ----------

func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(floorf(x) * PX, floorf(y) * PX, w * PX, h * PX), c)


func _txt(s: String, x: float, y: float, c: Color, scale := 1.0, center := false) -> void:
	PF.draw_text(self, s, Vector2(x * PX, y * PX), PX * scale, c, center)


func _spr(name: String, frame: int, fw: float, x: float, y: float, mod := Color.WHITE) -> void:
	var tex: Texture2D = tx[name]
	var fh = float(tex.get_height())
	draw_texture_rect_region(tex, Rect2(floorf(x) * PX, floorf(y) * PX, fw * PX, fh * PX), Rect2(frame * fw, 0, fw, fh), mod)


func _img(name: String, x: float, y: float, mod := Color.WHITE) -> void:
	var tex: Texture2D = tx[name]
	draw_texture_rect(tex, Rect2(floorf(x) * PX, floorf(y) * PX, tex.get_width() * PX, tex.get_height() * PX), false, mod)


func _draw_bg(b: int, a: float) -> void:
	_r(0, 0, 240, 135, Color(SKY[b], a))
	var n = "bg_" + BG_NAMES[b]
	var w = float(tx[n].get_width())
	var x = -fmod(cam * 0.25, w)
	while x < 240.0:
		_img(n, x, 0, Color(1, 1, 1, a))
		x += w


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("#0b0b14"))
	if bg_fade < 1.0:
		_draw_bg(bg_prev, 1.0)
	_draw_bg(biome, bg_fade)
	# terrain
	var c0 = int(floorf(cam / T)) - 1
	for c in range(c0, c0 + 17):
		var col = _col(c)
		if col == null or col["h"] <= 0:
			continue
		var x = c * T - cam
		var top = _top(col["h"])
		var tn = TILE_NAMES[col["b"]]
		if col["b"] == 1 and col["h"] >= 3:
			tn = "bricks"
		var nvar = tx["tile_" + tn].get_width() / 16
		var y = top
		var k = 0
		while y < 135.0:
			if k == 0 and col["tr"]:
				_img("trampoline", x, y)
			else:
				_spr("tile_" + tn, (col["v"] + k) % nvar, 16.0, x, y)
			y += T
			k += 1
		if not col["tr"]:
			var tp = "top_" + tn
			var lc = _col(c - 1)
			var rc = _col(c + 1)
			draw_texture_rect_region(tx[tp], Rect2(floorf(x) * PX, floorf(top - 1.0) * PX, 16 * PX, 5 * PX), Rect2(2, 0, 16, 5))
			if lc == null or lc["h"] < col["h"]:
				draw_texture_rect_region(tx[tp], Rect2(floorf(x - 2.0) * PX, floorf(top - 1.0) * PX, 2 * PX, 5 * PX), Rect2(0, 0, 2, 5))
			if rc == null or rc["h"] < col["h"]:
				draw_texture_rect_region(tx[tp], Rect2(floorf(x + 16.0) * PX, floorf(top - 1.0) * PX, 2 * PX, 5 * PX), Rect2(18, 0, 2, 5))
		if col["sp"]:
			_img("spikes", x, top - 16.0)
	# pickups
	for cn in coins:
		var a = 1.0 - clampf(cn["got"] / 0.3, 0.0, 1.0) if cn["got"] >= 0.0 else 1.0
		_spr("coin", int(t * 10.0 + cn["x"] * 0.1) % 6, 10.0, cn["x"] - cam - 5.0, cn["y"] - 5.0 - (cn["got"] * 30.0 if cn["got"] > 0.0 else 0.0), Color(1, 1, 1, a))
	for e in eggs:
		var a = 1.0 - clampf(e["got"] / 0.3, 0.0, 1.0) if e["got"] >= 0.0 else 1.0
		_img("egg", e["x"] - cam - 5.0, e["y"] - 6.0 + sin(t * 3.0) * 1.5, Color(1, 1, 1, a))
	# robots
	var frozen = quack_t < QUACK_FREEZE and not dying
	var fmod_c = Color(0.6, 0.85, 1.0) if frozen and int(t * 8.0) % 2 == 0 else Color.WHITE
	for r in robots:
		var rx = r["x"] - cam
		if r["k"] == "g":
			var f = 1
			if not frozen and absf(r["vx"]) > 2.0:
				f = 0 if r["vx"] < 0.0 else 2
				if int(r["a"] * 6.0) % 2 == 0:
					f = 1
			_spr("robot_ground", f, 22.0, rx - 11.0, r["y"] - 19.0, fmod_c)
		else:
			var f2 = 0 if frozen else int(r["a"] * 12.0) % 3
			_spr("robot_fly", f2, 22.0, rx - 11.0, r["y"] - 10.0, fmod_c)
	# duck
	var fr = 0
	if state == "title":
		fr = 1 + int(walk * 10.0) % 7
	elif quack_t < 0.35 or dying:
		fr = 12
	elif not grounded:
		var flap = int(t * 15.6) % 2 if flapping else 0
		fr = 8 + flap if vy < 0.0 else 11 - flap
	else:
		fr = 1 + int(walk * 7.0) % 7
	_spr("duck", fr, 22.0, dx - cam - 11.0, dy - 19.0)
	for rg in rings:
		var k = rg["t"] / 0.5
		var rad = 6.0 + k * 40.0
		for i in 16:
			var ang = TAU * i / 16.0
			_r(rg["x"] - cam + cos(ang) * rad, rg["y"] + sin(ang) * rad * 0.8, 2, 2, Color(1, 1, 1, 1.0 - k))
	for f in floats:
		_txt(f["s"], f["x"] - cam, f["y"], Color(f["c"], 1.0 - f["t"] / 0.8), 1.0, true)
	_draw_hud()
	if msg_t > 0.0 and state == "play":
		_txt(msg, 120, 34, GOLD if int(t * 10.0) % 2 == 0 else WHITE, 2.0, true)
	match state:
		"title":
			_r(24, 22, 192, 100, Color(0, 0, 0, 0.8))
			draw_texture_rect(logo, Rect2(84 * PX, 26 * PX, 73 * PX, 20 * PX), false)
			_txt("STEAMER DUCK", 120, 50, RED, 2.6, true)
			_img("duck_big", 30, 70)
			_txt(Game.label("jump") + " HOP", 76, 70, WHITE)
			_txt("HOLD TO FLAP AND GLIDE", 76, 78, WHITE)
			_txt(Game.label("attack") + " QUACK FREEZES ROBOTS", 76, 86, WHITE)
			_txt("MIND THE PITS AND SPIKES", 76, 94, Color(1, 1, 1, 0.6))
			if int(t * 2.0) % 2 == 0:
				_txt("PRESS " + Game.label("jump"), 120, 106, GOLD, 1.0, true)
			_txt(Game.label("pause") + " EXITS", 120, 114, Color(1, 1, 1, 0.5), 1.0, true)
		"over":
			_r(30, 30, 180, 74, Color(0, 0, 0, 0.82))
			_txt("SPLAT!", 120, 36, RED, 2.4, true)
			_txt("SCORE %d" % score, 120, 52, WHITE, 2.0, true)
			_txt("%dM  %d COINS  %d EGGS" % [int((dx - start_x) / T), coin_n, egg_n], 120, 66, Color(1, 1, 1, 0.7), 1.0, true)
			_txt(("NEW HIGH SCORE %d" if new_best else "HIGH SCORE %d") % best, 120, 76, GOLD if new_best else RED, 1.2, true)
			if int(t * 2.0) % 2 == 0 and t > 0.8:
				_txt("PRESS " + Game.label("jump") + " TO WADDLE AGAIN", 120, 88, GOLD, 1.0, true)
			_txt(Game.label("pause") + " EXITS", 120, 96, Color(1, 1, 1, 0.5), 1.0, true)
	for y in range(0, 540, 4):
		draw_rect(Rect2(0, y, 960, 1), Color(0, 0, 0, 0.18))


func _draw_hud() -> void:
	_r(0, 0, 240, 13, Color(0, 0, 0, 0.6))
	_r(0, 13, 240, 1, RED)
	if state == "title":
		_txt("HI %d" % best, 120, 4, Color(1, 1, 1, 0.75), 1.0, true)
		return
	_txt("SCORE %d" % score, 4, 4, WHITE)
	_txt("HI %d" % best, 120, 4, Color(1, 1, 1, 0.55), 1.0, true)
	_spr("coin", 0, 10.0, 166, 2)
	_txt("%d" % coin_n, 178, 4, WHITE)
	# quack meter
	_txt("Q", 200, 4, RED if quack_cd > 0.0 else GOLD)
	_r(205, 5, 31, 3, Color(1, 1, 1, 0.2))
	_r(205, 5, 31.0 * (1.0 - quack_cd / QUACK_COOL), 3, RED if quack_cd > 0.0 else GOLD)
