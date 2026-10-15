extends CharacterBody2D
## Underbosses: mid-sized guardians of the side levels (and the Chapter 5
## boss). One script, configured per id in CONFIG: which sprite to wear, how
## big, how tough, and which attack patterns to mix:
##   charge  — telegraphed rush across the floor
##   slam    — leap at the hero, shockwaves both ways on landing
##   volley  — fan of orbs
##   summon  — calls Choir imps
##   blink   — vanishes and reappears beside the hero
##   pillars — vertical beams that lock on where the hero stands

const Anim = preload("res://scripts/anim_sprite.gd")
const CONFIG := {
	"monitor": {"name": "THE HALL MONITOR", "sub": "Detention never ends", "key": "teacher", "size": 1.7, "hp": 34, "col": "#ffb06a",
		"tint": Color(1, 0.4, 0.2, 0.2), "attacks": ["charge", "slam", "volley"], "item": "hallpass", "lore": "monitor"},
	"brood": {"name": "THE BROOD MOTHER", "sub": "Every imp has to come from somewhere", "key": "imp", "size": 2.2, "hp": 40, "col": "#ff5a4a",
		"tint": Color(0.6, 0.1, 0.3, 0.25), "attacks": ["volley", "summon", "slam"], "item": "tot", "lore": "brood"},
	"warden": {"name": "THE PIPE WARDEN", "sub": "He was the night shift", "key": "returned", "size": 1.8, "hp": 48, "col": "#7fd0ff",
		"tint": Color(0.2, 0.5, 1.0, 0.25), "attacks": ["slam", "charge", "volley"], "item": "bell", "lore": "warden"},
	"judge": {"name": "THE THIRD JUDGE", "sub": "Scores minds out of ten", "key": "saint", "size": 1.25, "hp": 54, "col": "#ff9ad8",
		"tint": Color(1, 0.3, 0.7, 0.2), "attacks": ["pillars", "blink", "volley"], "float": true, "item": "badge", "lore": "judge"},
	"auditor": {"name": "THE AUDITOR", "sub": "Dharma Order · Office of Continuity", "key": "saint", "size": 1.5, "hp": 96, "col": "#ffe08a",
		"tint": Color(1, 0.85, 0.3, 0.3), "attacks": ["pillars", "blink", "volley", "summon", "slam"], "float": true, "item": "seal", "lore": "auditor", "boss": true},
}

var main: Node
var id = ""
var cfg = {}
var kind = "underboss"
var astral_only = false
var hp = 30
var max_hp = 30
var state = "dormant"
var tm = 0.0
var face = -1
var flash = 0.0
var alpha = 1.0
var dead = false
var phase2 = false
var cur = ""
var last = ""
var seq = 0
var rig: Node2D
var w = 40.0
var h = 90.0
var home = Vector2.ZERO
var beams_on = false


func setup(sid: String, pos: Vector2) -> void:
	id = sid
	cfg = CONFIG.get(sid, CONFIG["monitor"])
	position = pos
	home = pos
	hp = cfg["hp"]
	max_hp = hp
	var s: float = cfg["size"]
	w = 26.0 * s
	h = 54.0 * s
	var cs = CollisionShape2D.new()
	var sh = RectangleShape2D.new()
	sh.size = Vector2(w * 0.8, h)
	cs.shape = sh
	cs.position = Vector2(0, -h / 2.0)
	add_child(cs)
	collision_layer = 0
	collision_mask = 1 | 2 | 8 | 16
	rig = Anim.new()
	rig.key = cfg["key"]
	rig.size_mul = s
	rig.tint = cfg["tint"]
	add_child(rig)


func hurt_rect() -> Rect2:
	return Rect2(position.x - w / 2.0, position.y - h, w, h)


func _anim(names: Array) -> String:
	for n in names:
		if Anim.has_anim(rig.key, n):
			return n
	return "idle"


func step(dt: float) -> void:
	flash = maxf(0.0, flash - dt)
	if state == "dormant" or state == "dying":
		if state == "dying":
			tm -= dt
			alpha = maxf(0.0, alpha - dt * 0.5)
			if tm <= 0.0:
				dead = true
		return
	var p: Node = main.player
	var dx: float = p.position.x - position.x
	if state == "wait":
		if absf(dx) < 420.0 and absf(p.position.y - position.y) < 220.0:
			main.start_underboss(self)
		_gravity(dt)
		return
	tm -= dt
	if not phase2 and hp <= max_hp / 2:
		phase2 = true
		main.toast(cfg["name"].capitalize() + " is furious")
		Sound.play("phase2")
		main.flash_screen(0.4, Color(cfg["col"]))
	match state:
		"idle":
			face = int(signf(dx)) if dx != 0 else face
			velocity.x = move_toward(velocity.x, signf(dx) * 70.0 if absf(dx) > 160.0 else 0.0, 600.0 * dt)
			if tm <= 0.0:
				_pick()
		"tell":
			velocity.x = 0.0
			if tm <= 0.0:
				_execute()
		"charge":
			velocity.x = face * (480.0 if phase2 else 400.0)
			if randf() < 0.5:
				main.fx.part(position + Vector2(-face * w * 0.4, -6), Vector2(-face * 80, -randf() * 60), "dust", Color("#c8b8a0"))
			if tm <= 0.0 or is_on_wall():
				_recover(0.8)
		"slam":
			if is_on_floor() and tm < 0.6:
				_shockwave()
				_recover(0.9)
		"volley":
			if tm <= 0.0:
				if seq > 0:
					seq -= 1
					tm = 0.35
					_fan(5 if phase2 else 3)
				else:
					_recover(0.7)
		"blink":
			alpha = maxf(0.0, alpha - dt * 4.0)
			if alpha <= 0.0:
				position = Vector2(clampf(p.position.x + (-1 if randf() < 0.5 else 1) * 160.0, 60.0, main.room.room_size.x - 60.0), p.position.y)
				state = "blinkin"
				main.fx.burst(position + Vector2(0, -h * 0.5), 20, 260, Color(cfg["col"]))
		"blinkin":
			alpha = minf(1.0, alpha + dt * 4.0)
			if alpha >= 1.0:
				_recover(0.5)
		"pillars":
			if tm <= 0.0 and not beams_on:
				beams_on = true
				tm = 0.4
				for b in main.fx.beams:
					b["on"] = true
				Sound.play("beam")
				main.shake = maxf(main.shake, 0.15)
			elif tm <= 0.0 and beams_on:
				beams_on = false
				main.fx.beams.clear()
				_recover(0.6)
			if beams_on:
				for b in main.fx.beams:
					if absf(p.hitbox().get_center().x - b["x"]) < 20.0:
						main.hurt_player(1, b["x"])
		"recover":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * dt)
			if tm <= 0.0:
				state = "idle"
				tm = 0.4 if phase2 else 0.7
	_gravity(dt)
	if alpha > 0.6 and hurt_rect().grow(-6).intersects(p.hitbox()):
		main.hurt_player(2 if state == "charge" and phase2 else 1, position.x)


func _gravity(dt: float) -> void:
	if cfg.get("float", false):
		position.y = lerpf(position.y, home.y, dt * 3.0) if state not in ["blinkin", "blink"] else position.y
		position.x += velocity.x * dt
		position.x = clampf(position.x, 40.0, main.room.room_size.x - 40.0)
		return
	velocity.y = minf(velocity.y + 2000.0 * dt, 900.0)
	move_and_slide()


func _pick() -> void:
	var pool: Array = cfg["attacks"].duplicate()
	pool.erase(last)
	cur = pool[randi() % pool.size()]
	if cur == "summon" and main.ents.filter(func(e): return is_instance_valid(e) and e.kind == "imp" and not e.dead).size() >= 2:
		cur = "volley"
	last = cur
	state = "tell"
	tm = 0.45 if phase2 else 0.6
	flash = 0.3
	Sound.play("lock", 0.1, -6.0)
	if cur == "pillars":
		main.fx.beams.clear()
		var px: float = main.player.position.x
		for k in (3 if phase2 else 2):
			main.fx.beams.append({"k": "v", "x": clampf(px + (k - 1) * 150.0 + randf_range(-30, 30), 40.0, main.room.room_size.x - 40.0), "on": false})
		main.fx.beams.append({"k": "v", "x": px, "on": false})


func _execute() -> void:
	match cur:
		"charge":
			state = "charge"
			tm = 1.3
			Sound.play("u_boar" if rig.key in ["imp", "rider"] else "lunge", 0.1, -3.0)
		"slam":
			state = "slam"
			tm = 1.4
			var dx: float = main.player.position.x - position.x
			velocity = Vector2(clampf(dx * 1.1, -520, 520), -760.0)
			Sound.play("djump", 0.1)
		"volley":
			state = "volley"
			seq = 3 if phase2 else 2
			tm = 0.05
		"summon":
			state = "recover"
			tm = 1.0
			for k in 2:
				main.summon("imp", position + Vector2((k * 2 - 1) * 90.0, -40.0))
		"blink":
			state = "blink"
			Sound.play("glitch")
		"pillars":
			state = "pillars"
			tm = 0.55 if phase2 else 0.75
			Sound.play("charge")


func _recover(t: float) -> void:
	state = "recover"
	tm = t * (0.75 if phase2 else 1.0)


func _fan(n: int) -> void:
	var from: Vector2 = position + Vector2(face * w * 0.3, -h * 0.65)
	var aim: Vector2 = (main.player.position + Vector2(0, -30) - from).normalized()
	for i in n:
		var a = (i - (n - 1) / 2.0) * 0.22
		main.fx.shoot(from, aim.rotated(a) * 240.0, 7.0, "orb", Color(cfg["col"]))
	Sound.play("u_spit" if rig.key == "imp" else "throw", 0.1, -4.0)


func _shockwave() -> void:
	main.shake = maxf(main.shake, 0.3)
	Sound.play("boom")
	main.fx.sprite("ring", position + Vector2(0, -4), 260.0, 0.4, 0.0, Color(cfg["col"]), 4, 2)
	for d in [-1, 1]:
		main.fx.shoot(position + Vector2(d * w * 0.5, -12), Vector2(d * (300.0 if phase2 else 240.0), 0), 12.0, "wave", Color(cfg["col"]))
	if main.player.is_on_floor() and absf(main.player.position.x - position.x) < 70.0:
		main.hurt_player(1, position.x)


func hit(dmg: int, _hdir: int) -> bool:
	if state in ["dormant", "dying", "wait"] or alpha < 0.5:
		return false
	hp -= dmg
	flash = 0.12
	Sound.play("ehit", 0.1)
	if hp <= 0:
		hp = 0
		state = "dying"
		tm = 2.0
		main.fx.beams.clear()
		velocity = Vector2.ZERO
		Sound.play("defeat")
		Sound.play("tp_explosion_big", 0.0, -10.0)
		main.underboss_defeated(self)
	return true


func _process(_d: float) -> void:
	rig.face = face
	match state:
		"dying":
			rig.play(_anim(["collapse", "death", "kneel", "stagger"]))
		"tell":
			rig.play(_anim(["notice", "cast", "attack"]))
		"charge":
			rig.play(_anim(["lunge", "attack2", "walk", "attack"]))
		"slam":
			rig.play(_anim(["lunge", "attack", "teleport"]))
		"volley", "pillars":
			rig.play(_anim(["shoot", "throw", "cast", "notice"]))
		"blink", "blinkin":
			rig.play(_anim(["teleport", "idle"]))
		"recover":
			rig.play(_anim(["hurt", "stagger", "idle", "walk"]))
		_:
			rig.play(_anim(["idle", "walk"]))
	rig.alpha = alpha
	rig.flash = clampf(flash * 5.0, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	if state == "dying" and alpha < 0.05:
		return
	var sh = PackedVector2Array()
	for i in 17:
		var a = TAU * i / 16.0
		sh.append(Vector2(cos(a) * w * 0.55, sin(a) * 5))
	if not cfg.get("float", false):
		draw_colored_polygon(sh, Color(0, 0, 0, 0.3 * alpha))
	var c = Color(cfg["col"])
	for i in 3:
		draw_circle(Vector2(0, -h * 0.5), h * (0.7 - i * 0.15), Color(c, 0.04 * alpha))
	if state == "tell":
		draw_string(Game.font_display, Vector2(-6, -h - 16), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, c)
