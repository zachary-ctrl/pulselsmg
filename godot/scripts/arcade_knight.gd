extends Control
## LSMG ARCADE · MIGHTY KNIGHT. A port of the endless runner "Mighty Knight"
## (MIT, (c) 2016 KOBUGE Project Incubator) to the 240x135 arcade grid.
## The knight runs on his own: Jump hops (hold for a floatier, higher jump),
## Strike swings the sword. Coins score, zombies (+5) and falling swords (+8)
## can be cut down. Every 100 coins earns a life; lose them all and it's over.
## Hazards arrive over time like the original: zombies at 15s, spikes at 30s,
## sword rain at 45s.

const PF = preload("res://scripts/pixelfont.gd")
const PX := 4.0
const DIR := "res://assets/arcade/knight/"
# Original world (1280x720) scaled by 0.1875 onto the 240x135 grid.
const PLACES := [111.0, 87.0, 63.0, 39.0]
const TILE_W := 24.0
const RUN_SPEED := 101.25        # 9 px/frame
const GRAV := 1350.0             # 2 px/frame^2
const GRAV_HELD := 506.25        # 0.75 px/frame^2 while jump is held
const JUMP_V := 281.25           # 25 px/frame
const HALF_W := 5.6
const BODY_H := 20.6
const SCREEN_X := 26.0           # the camera keeps the knight here
const SPAWN_AHEAD := 206.0
const SPAWN_STEP := 172.0        # 1.7 s of running between platform runs
const FALL_LIMIT := 183.0
const ZOMBIE_SPEED := 56.25
const FALL_SPEED := 90.0
const SWORD_SPEED := 112.5
const RED := Color("#e8243a")
const WHITE := Color("#f4f4f4")
const GOLD := Color("#ffd23a")

var main: Node
var state = "title"
var t = 0.0
var best = 0
var logo: Texture2D
var tx = {}

# run state
var elapsed = 0.0
var coins = 0
var coins_life = 0
var lives = 3
var kx = 24.0
var ky = 56.0
var vy = 0.0
var grounded = false
var held = false
var stuck = 0.0
var shield = 0.0
var attack_t = -1.0
var cool = 0.0
var dead = false
var dead_t = 0.0
var run_anim = 0.0
var next_spawn = 196.0
var sword_timer = 5.0
var bg_x = 0.0
var new_best = false

var tiles: Array = []
var coin_list: Array = []
var zombies: Array = []
var spikes: Array = []
var swords: Array = []
var floats: Array = []
var puffs: Array = []
var rng = RandomNumberGenerator.new()


func _ready() -> void:
	size = Vector2(960, 540)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo = load("res://assets/lsmg/logo8.png")
	for n in ["bg", "coin", "spikes", "sword", "life", "tile_left", "tile_mid", "tile_right", "knight_run", "knight_attack", "zombie_walk", "zombie_dead", "icon_attack", "icon_jump"]:
		tx[n] = load(DIR + n + ".png")
	best = int(Game.settings.get("high_knight", 0))
	rng.randomize()
	Sound.music("")
	_reset()
	ky = PLACES[0]
	grounded = true


func _reset() -> void:
	elapsed = 0.0
	coins = 0
	coins_life = 0
	lives = 3
	kx = 24.0
	ky = 56.0
	vy = 0.0
	grounded = false
	held = false
	stuck = 0.0
	shield = 0.0
	attack_t = -1.0
	cool = 0.0
	dead = false
	dead_t = 0.0
	next_spawn = 196.0
	sword_timer = 5.0
	new_best = false
	tiles.clear()
	coin_list.clear()
	zombies.clear()
	spikes.clear()
	swords.clear()
	floats.clear()
	puffs.clear()
	# the starting ground: 14 tiles, the last one with a right edge
	for i in 14:
		tiles.append({"x": i * TILE_W, "y": PLACES[0], "f": 2 if i == 13 else 1})


func _start() -> void:
	_reset()
	state = "play"
	Sound.play("ar_three")


# ---------- world generation (create_random from the original) ----------

func _spawn_run() -> void:
	var amount = rng.randi_range(5, 7)
	var place = PLACES[rng.randi() % PLACES.size()]
	var x0 = kx + SPAWN_AHEAD
	for i in amount:
		var cx = x0 + i * TILE_W + TILE_W * 0.5
		if rng.randi() % 2 == 0:
			coin_list.append({"x": cx, "y": place - 12.0, "ph": rng.randf() * TAU, "got": -1.0})
		var f = 1
		if i == 0:
			f = 0
		elif i == amount - 1:
			f = 2
			if elapsed >= 15.0 and rng.randi() % 2 == 0:
				zombies.append({"x": cx, "y": place, "dead": -1.0, "a": rng.randf() * 10.0})
		elif elapsed >= 30.0 and rng.randi() % 10 == 0:
			spikes.append({"x": cx, "y": place})
		tiles.append({"x": x0 + i * TILE_W, "y": place, "f": f})


func _spawn_swords() -> void:
	var amount = rng.randi() % 4
	for i in amount:
		swords.append({"x": kx + 75.0 + i * TILE_W, "y": -12.0, "s": "fall", "t": 0.0, "spin": 1.0 if rng.randi() % 2 == 0 else -1.0})


# ---------- collision helpers ----------

func _wall_at(x0: float, x1: float, foot: float) -> Variant:
	# a tile whose solid body overlaps the x-range above the given foot line
	for tl in tiles:
		if tl["x"] < x1 and tl["x"] + TILE_W > x0 and tl["y"] < foot - 0.5:
			return tl
	return null


func _ground_below(x0: float, x1: float, from_y: float, to_y: float) -> float:
	# highest tile top in [from_y, to_y] overlapping the x-range, or INF
	var best_top = INF
	for tl in tiles:
		if tl["x"] < x1 and tl["x"] + TILE_W > x0 and tl["y"] >= from_y - 0.5 and tl["y"] <= to_y and tl["y"] < best_top:
			best_top = tl["y"]
	return best_top


func _overlap(ax: float, ay: float, ahw: float, ahh: float, bx: float, by: float, bhw: float, bhh: float) -> bool:
	return absf(ax - bx) < ahw + bhw and absf(ay - by) < ahh + bhh


# ---------- loop ----------

func _physics_process(dt: float) -> void:
	t += dt
	if Input.is_action_just_pressed("pause"):
		_exit()
		return
	var jump_press = Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("up") or Input.is_action_just_pressed("confirm")
	var jump_held = Input.is_action_pressed("jump") or Input.is_action_pressed("up") or Input.is_action_pressed("confirm")
	var atk_press = Input.is_action_just_pressed("attack")
	run_anim += dt
	bg_x -= 5.625 * dt
	if bg_x <= -272.0:
		bg_x += 272.0
	_step_fx(dt)
	match state:
		"title", "over":
			if (jump_press or atk_press) and t > 0.6:
				_start()
		"play":
			elapsed += dt
			_step_knight(dt, jump_press, jump_held, atk_press)
			_step_world(dt)
	queue_redraw()


func _step_knight(dt: float, jump_press: bool, jump_held: bool, atk_press: bool) -> void:
	shield = maxf(0.0, shield - dt)
	cool = maxf(0.0, cool - dt)
	if attack_t >= 0.0:
		attack_t += dt
		if attack_t >= 0.5:
			attack_t = -1.0
	if dead:
		dead_t += dt
		if dead_t > 1.4:
			_game_over()
		return
	if atk_press and attack_t < 0.0 and cool <= 0.0:
		attack_t = 0.0
		cool = 1.5
		Sound.play("ar_swish")
	# jump: only from the ground, holding it lightens gravity
	if jump_press and grounded:
		held = true
		vy = -JUMP_V
		grounded = false
		Sound.play("ar_shoot", 0.05)
	if not jump_held:
		held = false
	# horizontal run, blocked by platform walls
	var nx = kx + RUN_SPEED * dt
	var wall = _wall_at(nx - HALF_W, nx + HALF_W, ky)
	if wall != null:
		kx = minf(kx, wall["x"] - HALF_W - 0.01)
		stuck += dt
	else:
		kx = nx
		stuck = 0.0
	# vertical
	var on = _ground_below(kx - HALF_W, kx + HALF_W, ky, ky + 0.5)
	if on < INF and vy >= 0.0:
		grounded = true
		vy = 0.0
		ky = on
	else:
		grounded = false
		vy += (GRAV_HELD if held else GRAV) * dt
		var ny = ky + vy * dt
		if vy > 0.0:
			var land = _ground_below(kx - HALF_W, kx + HALF_W, ky, ny)
			if land < INF:
				ny = land
				vy = 0.0
				grounded = true
				Sound.play("ar_bounce", 0.1, -8.0)
		ky = ny
	if stuck >= 0.83 or ky > FALL_LIMIT:
		_respawn()


func _respawn() -> void:
	stuck = 0.0
	vy = 0.0
	held = false
	# drop back in above the next platform so a respawn is never a free fall
	var target = kx
	if _ground_below(kx - HALF_W, kx + HALF_W, -100.0, 200.0) == INF:
		var nearest = INF
		for tl in tiles:
			if tl["x"] + TILE_W > kx and tl["x"] < nearest:
				nearest = tl["x"]
		if nearest < INF:
			target = nearest + 8.0
	kx = target
	ky = -24.0
	_damaged()


func _damaged() -> void:
	if shield > 0.0 or dead:
		return
	shield = 2.0
	lives -= 1
	Sound.play("ar_buzzer", 0.0, -4.0)
	if lives < 0:
		dead = true
		dead_t = 0.0
		_puff(kx, ky - 10.0, RED, true)
	else:
		_puff(4.0 + lives * 9.0 + 3.0, 6.0, RED, false)


func _attacking() -> bool:
	return attack_t >= 0.0


func _add_points(n: int, x: float, y: float) -> void:
	coins += n
	coins_life += n
	floats.append({"x": x, "y": y, "s": "+%d" % n, "n": n})
	if coins_life >= 100:
		coins_life -= 100
		lives += 1
		floats.append({"x": kx, "y": ky - 30.0, "s": "1UP", "n": 10})
		Sound.play("ar_three")


func _step_world(dt: float) -> void:
	if kx >= next_spawn:
		next_spawn += SPAWN_STEP
		_spawn_run()
	if elapsed >= 45.0:
		sword_timer -= dt
		if sword_timer <= 0.0:
			sword_timer += 5.0
			_spawn_swords()
	var cam = kx - SCREEN_X
	var kcy = ky - BODY_H * 0.5
	var alive = not dead
	# coins
	for c in coin_list:
		if c["got"] >= 0.0:
			c["got"] += dt
			c["y"] -= 30.0 * dt
		elif alive and _overlap(kx, kcy, HALF_W, BODY_H * 0.5, c["x"], c["y"], 5.0, 5.0):
			c["got"] = 0.0
			_add_points(1, c["x"], c["y"])
			Sound.play("ar_blip", 0.08, -4.0)
	coin_list = coin_list.filter(func(c): return c["x"] > cam - 30.0 and c["got"] < 0.4)
	# zombies walk left, fall off ledges, vanish into walls
	for z in zombies:
		if z["dead"] >= 0.0:
			z["dead"] += dt
			continue
		z["a"] += dt
		var zx = z["x"] - ZOMBIE_SPEED * dt
		if _wall_at(zx - HALF_W, zx + HALF_W, z["y"]) != null:
			z["dead"] = 99.0
			continue
		z["x"] = zx
		var g = _ground_below(zx - 2.0, zx + 2.0, z["y"], z["y"] + 0.5)
		if g == INF:
			var ny = z["y"] + FALL_SPEED * dt
			var land = _ground_below(zx - 2.0, zx + 2.0, z["y"], ny)
			z["y"] = land if land < INF else ny
		if alive and _overlap(kx, kcy, HALF_W, BODY_H * 0.5, z["x"], z["y"] - 9.7, 5.6, 9.7):
			if _attacking():
				z["dead"] = 0.0
				_add_points(5, z["x"], z["y"] - 20.0)
				Sound.play("ar_rim")
			else:
				_damaged()
	zombies = zombies.filter(func(z): return z["dead"] < 1.0 and z["x"] > cam - 40.0 and z["y"] < 200.0)
	# spikes
	if alive:
		for s in spikes:
			if _overlap(kx, kcy, HALF_W, BODY_H * 0.5, s["x"], s["y"] - 3.2, 4.1, 2.6):
				_damaged()
	spikes = spikes.filter(func(s): return s["x"] > cam - 30.0)
	# swords rain down and plant themselves in the ground
	for sw in swords:
		if sw["s"] == "broken":
			sw["t"] += dt
			continue
		if sw["s"] == "fall":
			var ny = sw["y"] + SWORD_SPEED * dt
			var land = _ground_below(sw["x"] - 1.0, sw["x"] + 1.0, sw["y"], ny)
			if land < INF:
				sw["y"] = land + 3.0
				sw["s"] = "planted"
				sw["t"] = 0.0
				Sound.play("ar_rim", 0.2, -10.0)
			else:
				sw["y"] = ny
		else:
			sw["t"] += dt
		var scy = sw["y"] - 5.6
		for z in zombies:
			if z["dead"] < 0.0 and _overlap(sw["x"], scy, 1.9, 5.6, z["x"], z["y"] - 9.7, 5.6, 9.7):
				z["dead"] = 0.0
				sw["s"] = "broken"
				sw["t"] = 0.0
		if sw["s"] != "broken" and alive and _overlap(kx, kcy, HALF_W, BODY_H * 0.5, sw["x"], scy, 1.9, 5.6):
			if _attacking():
				_add_points(8, sw["x"], sw["y"] - 14.0)
				cool = 0.0
				Sound.play("ar_swish", 0.2)
			else:
				_damaged()
			sw["s"] = "broken"
			sw["t"] = 0.0
	swords = swords.filter(func(sw): return sw["x"] > cam - 30.0 and sw["y"] < 200.0 and not (sw["s"] == "broken" and sw["t"] > 0.7))
	tiles = tiles.filter(func(tl): return tl["x"] + TILE_W > cam - 30.0)


func _step_fx(dt: float) -> void:
	for f in floats:
		f["y"] -= 90.0 * dt
	floats = floats.filter(func(f): return f["y"] > -10.0)
	for p in puffs:
		p["t"] += dt
	puffs = puffs.filter(func(p): return p["t"] < 0.6)


func _puff(x: float, y: float, c: Color, world: bool) -> void:
	puffs.append({"x": x, "y": y, "t": 0.0, "c": c, "w": world})


func _game_over() -> void:
	state = "over"
	t = 0.0
	if coins > best:
		best = coins
		new_best = true
		Game.settings["high_knight"] = best
		Game.save_settings()
	Sound.play("ar_three")


func _exit() -> void:
	main.close_arcade()
	queue_free()


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


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("#0b0b14"))
	_img("bg", bg_x, 0)
	_img("bg", bg_x + 272.0, 0)
	var cam = kx - SCREEN_X
	# platforms
	for tl in tiles:
		var n = ["tile_left", "tile_mid", "tile_right"][tl["f"]]
		_img(n, tl["x"] - cam, tl["y"])
	# spikes
	for s in spikes:
		_img("spikes", s["x"] - cam - 6.0, s["y"] - 12.0)
	# coins: bob on a little loop like the original idle animation
	for c in coin_list:
		var bob = sin(t * 4.0 + c["ph"]) * 1.0
		var a = 1.0 - clampf(c["got"] / 0.4, 0.0, 1.0) if c["got"] >= 0.0 else 1.0
		_img("coin", c["x"] - cam - 6.0, c["y"] - 6.0 + bob, Color(1, 1, 1, a))
	# zombies
	for z in zombies:
		if z["dead"] >= 0.0:
			var df = clampi(int(z["dead"] / 0.1), 0, 9)
			_spr("zombie_dead", df, 32.0, z["x"] - cam - 16.0, z["y"] - 25.0, Color(1, 1, 1, 1.0 - clampf(z["dead"] - 0.6, 0.0, 1.0) * 2.5))
		else:
			_spr("zombie_walk", int(z["a"] * 12.0) % 10, 22.0, z["x"] - cam - 11.0, z["y"] - 25.0)
	# swords
	for sw in swords:
		var sx = sw["x"] - cam - 2.0
		var sy = sw["y"] - 14.0
		var a = 1.0
		if sw["s"] == "broken":
			sy -= sin(clampf(sw["t"] / 0.6, 0.0, 1.0) * PI) * 9.0
			sx += sw["spin"] * sw["t"] * 14.0
			a = 1.0 - clampf((sw["t"] - 0.5) / 0.2, 0.0, 1.0)
		elif sw["s"] == "planted" and sw["t"] < 0.5:
			sx += sin(sw["t"] * 60.0) * (1.0 - sw["t"] * 2.0) * 1.5
		_img("sword", sx, sy, Color(1, 1, 1, a))
	# knight
	var blink = shield > 0.0 and int(shield * 10.0) % 2 == 0
	if not dead and not blink:
		var kxs = kx - cam - 11.0
		var kys = ky - 25.0
		if _attacking():
			_spr("knight_attack", clampi(int(attack_t / 0.05), 0, 9), 22.0, kxs, kys)
		else:
			var fr = int(run_anim * 25.0) % 10 if (grounded or state != "play") else 3
			_spr("knight_run", fr, 22.0, kxs, kys)
	for p in puffs:
		var k = p["t"] / 0.6
		for i in 8:
			var ang = TAU * i / 8.0
			_r(p["x"] - (cam if p["w"] else 0.0) + cos(ang) * k * 14.0, p["y"] + sin(ang) * k * 14.0, 2, 2, Color(p["c"], 1.0 - k))
	for f in floats:
		var col = Color(1.0, 1.1 - f["n"] * 0.1, 1.0 - f["n"] * 0.1)
		_txt(f["s"], f["x"] - cam, f["y"], col, 1.0, true)
	_draw_hud()
	match state:
		"title":
			_r(28, 30, 184, 86, Color(0, 0, 0, 0.78))
			draw_texture_rect(logo, Rect2(84 * PX, 34 * PX, 73 * PX, 20 * PX), false)
			_txt("MIGHTY KNIGHT", 120, 58, RED, 2.4, true)
			_txt(Game.label("jump") + " JUMP  HOLD TO SOAR", 120, 76, WHITE, 1.0, true)
			_txt(Game.label("attack") + " STRIKE ZOMBIES AND SWORDS", 120, 84, WHITE, 1.0, true)
			_txt("EVERY 100 COINS EARNS A LIFE", 120, 92, Color(1, 1, 1, 0.6), 1.0, true)
			if int(t * 2.0) % 2 == 0:
				_txt("PRESS " + Game.label("jump"), 120, 101, GOLD, 1.0, true)
			_txt(Game.label("pause") + " EXITS", 120, 109, Color(1, 1, 1, 0.5), 1.0, true)
		"over":
			_r(30, 34, 180, 70, Color(0, 0, 0, 0.8))
			_txt("GAME OVER", 120, 40, RED, 2.4, true)
			_txt("COINS %d" % coins, 120, 58, WHITE, 2.0, true)
			_txt(("NEW HIGH SCORE %d" if new_best else "HIGH SCORE %d") % best, 120, 74, GOLD if new_best else RED, 1.2, true)
			if int(t * 2.0) % 2 == 0 and t > 0.6:
				_txt("PRESS " + Game.label("jump") + " TO RIDE AGAIN", 120, 86, GOLD, 1.0, true)
			_txt(Game.label("pause") + " EXITS", 120, 95, Color(1, 1, 1, 0.5), 1.0, true)
	for y in range(0, 540, 4):
		draw_rect(Rect2(0, y, 960, 1), Color(0, 0, 0, 0.22))


func _draw_hud() -> void:
	if state == "title":
		_r(0, 0, 240, 13, Color(0, 0, 0, 0.55))
		_txt("HI %d" % best, 120, 4, Color(1, 1, 1, 0.7), 1.0, true)
		return
	_r(0, 0, 240, 13, Color(0, 0, 0, 0.55))
	_r(0, 13, 240, 1, RED)
	for i in maxi(lives, 0):
		_img("life", 4 + i * 9, 3)
	_img("coin", 196, 0)
	_txt("%d" % coins, 210, 4, WHITE)
	_txt("HI %d" % best, 120, 4, Color(1, 1, 1, 0.55), 1.0, true)
	# strike cooldown, like the original's on-screen attack button
	var ready = cool <= 0.0
	_img("icon_attack", 222, 116, Color(1, 1, 1, 0.9) if ready else Color(1, 1, 1, 0.3))
	if not ready:
		_r(222, 132, 15.0 * (1.0 - cool / 1.5), 1, RED)
	_img("icon_jump", 204, 116, Color(1, 1, 1, 0.9) if held else Color(1, 1, 1, 0.3))
