extends Control
## LSMG ARCADE · LAST SHOT. An 8-bit buzzer-beater minigame drawn on a
## 240x135 pixel grid (4x scale). Hold Jump or Strike to charge a shot,
## release to shoot. 45 seconds; the final five count double.

const PF = preload("res://scripts/pixelfont.gd")
const PX := 4.0
const FLOOR_Y := 118.0
const RIM_L := 196.0
const RIM_R := 210.0
const BOARD_X := 213.0
const GRAV := 150.0

var main: Node
var state = "title"
var t = 0.0
var clock = 45.0
var score = 0
var streak = 0
var best = 0
var px_x = 60.0
var face = 1
var charge = -1.0
var ball = null
var hoop_y = 64.0
var hoop_base = 64.0
var msg = ""
var msg_t = 0.0
var logo: Texture2D
var crowd: Array = []
var buzzer_done = false


func _ready() -> void:
	size = Vector2(960, 540)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo = load("res://assets/lsmg/logo8.png")
	best = int(Game.settings.get("high", 0))
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	for i in 60:
		crowd.append([rng.randi_range(0, 239), rng.randi_range(0, 3), rng.randf() * 6.0, [Color("#e8243a"), Color("#f4f4f4"), Color("#5a5f7a"), Color("#2a2f4a")][rng.randi_range(0, 3)]])
	Sound.music("")


func _start() -> void:
	state = "play"
	clock = 45.0
	score = 0
	streak = 0
	px_x = 60.0
	ball = null
	charge = -1.0
	hoop_y = hoop_base
	buzzer_done = false
	_say("TIP OFF!")
	Sound.play("ar_three")


func _say(s: String) -> void:
	msg = s
	msg_t = 1.4


func _physics_process(dt: float) -> void:
	t += dt
	msg_t -= dt
	if Input.is_action_just_pressed("pause"):
		_exit()
		return
	var shoot_held = Input.is_action_pressed("jump") or Input.is_action_pressed("attack") or Input.is_action_pressed("confirm")
	var shoot_press = Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("confirm")
	match state:
		"title", "over":
			if shoot_press and t > 0.5:
				_start()
		"play":
			clock -= dt
			if clock <= 5.0 and clock + dt > 5.0:
				_say("LAST SHOT!")
				Sound.play("ar_three")
			if clock <= 0.0 and not buzzer_done:
				buzzer_done = true
				Sound.play("ar_buzzer")
			if clock <= -1.5 and ball == null:
				_game_over()
			var dir = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
			if charge < 0.0 and clock > 0.0:
				px_x = clampf(px_x + dir * 70.0 * dt, 14.0, 160.0)
				if dir != 0:
					face = dir
			if ball == null and clock > 0.0:
				if shoot_press:
					charge = 0.0
					Sound.play("ar_charge")
				elif charge >= 0.0:
					if shoot_held:
						charge += dt
					else:
						_shoot()
			if score >= 10:
				hoop_y = hoop_base + sin(t * (1.2 + score * 0.02)) * 16.0
			_step_ball(dt)
	queue_redraw()


func _power() -> float:
	# Ping-pong 0..1 so holding too long is a miss too.
	var p = fmod(charge / 0.9, 2.0)
	return p if p <= 1.0 else 2.0 - p


func _shoot() -> void:
	var p = _power()
	var speed = 70.0 + p * 120.0
	var ang = deg_to_rad(-58.0)
	ball = {"p": Vector2(px_x + 3, FLOOR_Y - 22), "v": Vector2(cos(ang), sin(ang)) * speed, "from": px_x, "life": 0.0, "scored": false, "rim": 0, "buzzer": clock <= 0.6}
	charge = -1.0
	Sound.play("ar_shoot")


func _step_ball(dt: float) -> void:
	if ball == null:
		return
	ball["life"] += dt
	var prev: Vector2 = ball["p"]
	ball["v"].y += GRAV * dt
	ball["p"] += ball["v"] * dt
	var p: Vector2 = ball["p"]
	for rx in [RIM_L, RIM_R]:
		var rp = Vector2(rx, hoop_y)
		if p.distance_to(rp) < 3.0:
			var n = (p - rp).normalized()
			ball["v"] = ball["v"].bounce(n) * 0.6
			ball["p"] = rp + n * 3.1
			ball["rim"] += 1
			Sound.play("ar_rim")
	if p.x > BOARD_X - 2.0 and p.y > hoop_y - 26.0 and p.y < hoop_y + 4.0 and ball["v"].x > 0.0:
		ball["v"].x *= -0.55
		ball["p"].x = BOARD_X - 2.0
		Sound.play("ar_bounce")
	if not ball["scored"] and prev.y < hoop_y and p.y >= hoop_y and p.x > RIM_L + 1.5 and p.x < RIM_R - 1.5 and ball["v"].y > 0.0:
		ball["scored"] = true
		var pts = 3 if ball["from"] < 96.0 else 2
		if clock <= 5.0 or ball["buzzer"]:
			pts *= 2
		streak += 1
		if streak >= 3:
			pts += 1
		score += pts
		Sound.play("ar_swish")
		var words = "SWISH!" if ball["rim"] == 0 else "AND IN!"
		if ball["buzzer"] and clock <= 0.0:
			words = "BUZZER BEATER!"
		elif streak >= 3:
			words = "ON FIRE!"
		_say("%s +%d" % [words, pts])
	if p.y > FLOOR_Y - 2.0:
		ball["p"].y = FLOOR_Y - 2.0
		ball["v"].y *= -0.55
		ball["v"].x *= 0.8
		if absf(ball["v"].y) > 20.0:
			Sound.play("ar_bounce")
	if ball["life"] > 2.4 or p.x < -10.0 or p.x > 250.0:
		if not ball["scored"]:
			streak = 0
		ball = null


func _game_over() -> void:
	state = "over"
	t = 0.0
	if score > best:
		best = score
		Game.settings["high"] = best
		Game.save_settings()
		_say("NEW HIGH SCORE!")
	Sound.play("ar_three")


func _exit() -> void:
	main.close_arcade()
	queue_free()


# ---------- drawing (everything snaps to the 240x135 grid) ----------

func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(floorf(x) * PX, floorf(y) * PX, w * PX, h * PX), c)


func _txt(s: String, x: float, y: float, c: Color, scale := 1.0, center := false) -> void:
	PF.draw_text(self, s, Vector2(x * PX, y * PX), PX * scale, c, center)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("#0b0b14"))
	# arena: crowd, banners, floor
	_r(0, 0, 240, 60, Color("#141428"))
	for c in crowd:
		var bob = 1.0 if (state == "play" and msg_t > 0.0 and int(t * 8.0 + c[2]) % 2 == 0) else 0.0
		_r(c[0], 34 + c[1] * 6 - bob, 3, 3, c[3])
		_r(c[0], 37 + c[1] * 6 - bob, 3, 4, Color(c[3], 0.6))
	_r(0, 58, 240, 2, Color("#e8243a"))
	draw_texture_rect(logo, Rect2(84 * PX, 4 * PX, 73 * PX, 20 * PX), false)
	_txt("ARCADE", 120, 26, Color("#f4f4f4"), 1.0, true)
	_r(0, FLOOR_Y, 240, 17, Color("#b5733a"))
	for x in range(0, 240, 12):
		_r(x, FLOOR_Y, 1, 17, Color("#9a5f2e"))
	_r(0, FLOOR_Y, 240, 1, Color("#f4d8a8"))
	_r(96, FLOOR_Y, 1, 17, Color("#f4f4f4"))
	_txt("3PT", 84, FLOOR_Y + 3, Color(1, 1, 1, 0.6))
	# hoop: pole, backboard with the LSMG mark, rim, net
	_r(222, hoop_y - 26, 3, FLOOR_Y - hoop_y + 26, Color("#5a5f7a"))
	_r(BOARD_X, hoop_y - 26, 3, 30, Color("#f4f4f4"))
	_r(BOARD_X + 1, hoop_y - 18, 1, 8, Color("#e8243a"))
	_r(RIM_L, hoop_y, RIM_R - RIM_L + 1, 1, Color("#ff6a2a"))
	for i in 6:
		var nx = RIM_L + 1 + i * 2
		_r(nx, hoop_y + 1, 1, 6 - absf(i - 2.5), Color(1, 1, 1, 0.8))
	# player (8-bit Max)
	var x = px_x
	var fy = FLOOR_Y
	var jump = 0.0
	if ball != null and ball["life"] < 0.25:
		jump = 4.0 * sin(ball["life"] / 0.25 * PI)
	_r(x, fy - 2 - jump, 3, 2, Color("#1a1a22"))
	_r(x + 4, fy - 2 - jump, 3, 2, Color("#1a1a22"))
	_r(x, fy - 8 - jump, 7, 6, Color("#2a2f4a"))
	_r(x, fy - 15 - jump, 7, 7, Color("#8a8f9a"))
	_r(x + 1, fy - 20 - jump, 5, 5, Color("#6b4630"))
	_r(x + 1, fy - 22 - jump, 5, 2, Color("#1a1210"))
	_r(x + (5 if face > 0 else 1), fy - 18 - jump, 1, 1, Color.WHITE)
	if ball == null and state == "play" and clock > 0.0:
		_r(x + 2, fy - 27 - jump, 4, 4, Color("#ff7a2a"))
		_r(x + 3, fy - 27 - jump, 1, 4, Color("#1a1210"))
	if ball != null:
		var bp: Vector2 = ball["p"]
		var bc = Color("#ff3a2a") if streak >= 3 else Color("#ff7a2a")
		_r(bp.x - 2, bp.y - 2, 4, 4, bc)
		_r(bp.x - 1, bp.y - 2, 1, 4, Color("#1a1210"))
	# power meter
	if charge >= 0.0:
		_r(x - 4, fy - 34, 16, 4, Color("#1a1a2a"))
		var pw = _power()
		_r(x - 3, fy - 33, 14 * pw, 2, Color("#e8243a") if pw > 0.85 else Color("#f4f4f4"))
	# scoreboard
	_r(4, 4, 70, 22, Color("#05050a"))
	_txt("SCORE", 8, 7, Color("#e8243a"))
	_txt("%03d" % score, 8, 15, Color("#f4f4f4"), 1.2)
	_r(166, 4, 70, 22, Color("#05050a"))
	_txt("TIME", 170, 7, Color("#e8243a"))
	var cl = maxf(0.0, clock)
	_txt("%02d.%d" % [int(cl), int(fmod(cl, 1.0) * 10.0)], 170, 15, Color("#ff3a3a") if cl <= 5.0 else Color("#f4f4f4"), 1.2)
	_txt("HI %03d" % best, 120, 50, Color(1, 1, 1, 0.5), 1.0, true)
	if msg_t > 0.0:
		_txt(msg, 120, 70, Color("#ffd23a") if int(t * 10.0) % 2 == 0 else Color("#f4f4f4"), 1.6, true)
	match state:
		"title":
			_r(30, 62, 180, 52, Color(0, 0, 0, 0.75))
			_txt("LAST SHOT", 120, 68, Color("#e8243a"), 3.0, true)
			_txt("HOLD AND RELEASE TO SHOOT", 120, 90, Color("#f4f4f4"), 1.0, true)
			if int(t * 2.0) % 2 == 0:
				_txt("PRESS " + Game.label("jump"), 120, 100, Color("#ffd23a"), 1.0, true)
			_txt(Game.label("pause") + " EXITS", 120, 108, Color(1, 1, 1, 0.5), 1.0, true)
		"over":
			_r(30, 62, 180, 50, Color(0, 0, 0, 0.8))
			_txt("FINAL %d" % score, 120, 68, Color("#f4f4f4"), 2.0, true)
			_txt("HIGH SCORE %d" % best, 120, 88, Color("#e8243a"), 1.2, true)
			if int(t * 2.0) % 2 == 0:
				_txt("PRESS " + Game.label("jump") + " TO RUN IT BACK", 120, 100, Color("#ffd23a"), 1.0, true)
	for y in range(0, 540, 4):
		draw_rect(Rect2(0, y, 960, 1), Color(0, 0, 0, 0.22))
