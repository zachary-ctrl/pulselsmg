extends CharacterBody2D
## Max's body, or his astral form when `is_astral` is true.
## Collision layers: 1 solid, 2 one-way, 3 astral-only, 4 doors, 5 gates.

const Rig = preload("res://scripts/rig.gd")
const PRM_BODY := {"run": 300.0, "grav": 2400.0, "max_fall": 880.0, "jump": 760.0, "dash": 760.0}
const PRM_ASTRAL := {"run": 280.0, "grav": 1300.0, "max_fall": 520.0, "jump": 620.0, "dash": 700.0}

var main: Node
var is_astral = false
var rig: Node2D
var w = 24.0
var h = 58.0
var face = 1
var coyote = 0.0
var jump_buf = 0.0
var jump_cut = true
var used_double = false
var air_dash = true
var dash_t = 0.0
var dash_cd = 0.0
var atk_t = 0.0
var atk_cd = 0.0
var atk_dir = "side"
var hit_set = {}
var pogo_done = false
var recoil_t = 0.0
var recoil_v = 0.0
var heal_t = 0.0
var drop_t = 0.0
var run_ph = 0.0
var step_acc = 0.0
var inv = 0.0
var ground_oneway = false
var hp = 5
var max_hp = 5
var res = 0.0
var safe = Vector2.ZERO
var timer = 60.0
var ret = 0.0
var ret_from = Vector2.ZERO


func setup(astral: bool) -> void:
	is_astral = astral
	if astral:
		w = 22.0
		h = 54.0
	var cs = CollisionShape2D.new()
	var sh = RectangleShape2D.new()
	sh.size = Vector2(w, h)
	cs.shape = sh
	cs.position = Vector2(0, -h / 2.0)
	add_child(cs)
	collision_layer = 0
	collision_mask = (1 | 2 | 4 | 16) if astral else (1 | 2 | 8 | 16)
	floor_snap_length = 6.0
	floor_max_angle = deg_to_rad(50)
	rig = Rig.new()
	rig.key = "max"
	if astral:
		rig.tint = Color(0.56, 0.45, 1.0, 0.82)
		rig.eyes = "echo"
	add_child(rig)


func hitbox() -> Rect2:
	return Rect2(position.x - w / 2.0, position.y - h, w, h)


func _set_drop(on: bool) -> void:
	set_collision_mask_value(2, not on)
	if is_astral:
		set_collision_mask_value(3, not on)


func control(dt: float) -> void:
	var prm: Dictionary = PRM_ASTRAL if is_astral else PRM_BODY
	var was_floor = is_on_floor()
	var vy_before = velocity.y
	var dir = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	var healing = (not is_astral) and Input.is_action_pressed("heal") and is_on_floor() and res >= 33.0 and hp < max_hp and atk_t <= 0.0
	if healing:
		dir = 0
		if heal_t == 0.0:
			Sound.play("focus")
		heal_t += dt
		if randf() < dt * 30.0:
			main.fx.part(position + Vector2(randf_range(-30, 30), -10 - randf() * 50), Vector2.ZERO, "heal", Color("#8affb0"), self)
		if heal_t >= 0.9:
			heal_t = 0.0
			hp += 1
			res -= 33.0
			Sound.play("heal")
			main.fx.burst(position + Vector2(0, -30), 16, 200, Color("#8affb0"))
	else:
		if heal_t > 0.0:
			Sound.stop_focus()
		heal_t = 0.0
	if dash_t > 0.0:
		dash_t -= dt
		velocity.x = face * prm["dash"]
		velocity.y = 0.0
		if randf() < 0.6:
			main.fx.part(position + Vector2(-face * 10, -30 + randf_range(-15, 15)), Vector2(-face * 60, 0), "trail", Color("#a58bff") if is_astral else Color("#ffb06a"))
		if dash_t <= 0.0:
			velocity.x = face * prm["run"] * 0.55
	else:
		if recoil_t > 0.0:
			recoil_t -= dt
			velocity.x = recoil_v
		else:
			velocity.x = move_toward(velocity.x, dir * prm["run"], (4200.0 if is_on_floor() else 2800.0) * dt)
		if dir != 0 and atk_t <= 0.0:
			face = dir
		velocity.y = minf(velocity.y + prm["grav"] * dt, prm["max_fall"])
	if Input.is_action_just_pressed("jump"):
		jump_buf = 0.13
	else:
		jump_buf -= dt
	coyote = 0.1 if is_on_floor() else coyote - dt
	if jump_buf > 0.0 and not healing:
		if Input.is_action_pressed("down") and is_on_floor() and ground_oneway:
			drop_t = 0.25
			jump_buf = 0.0
			_set_drop(true)
			position.y += 2
		elif coyote > 0.0:
			velocity.y = -prm["jump"]
			coyote = 0.0
			jump_buf = 0.0
			jump_cut = false
			Sound.play("jump", 0.06)
			for i in 6:
				main.fx.part(position, Vector2(randf_range(-60, 60), -randf() * 40), "dust", Color("#c8c0b0"))
		elif not is_astral and Game.ability.get("double", false) and not used_double and dash_t <= 0.0:
			velocity.y = -prm["jump"] * 0.88
			used_double = true
			jump_buf = 0.0
			jump_cut = false
			Sound.play("djump")
			for i in 14:
				var a = TAU * i / 14.0
				main.fx.part(position + Vector2(cos(a) * 16, sin(a) * 6), Vector2(cos(a) * 120, sin(a) * 40), "spark", Color("#c9b8ff"))
	if not Input.is_action_pressed("jump") and velocity.y < 0.0 and not jump_cut:
		velocity.y *= 0.45
		jump_cut = true
	dash_cd -= dt
	if Input.is_action_just_pressed("dash") and dash_cd <= 0.0 and (is_on_floor() or air_dash) and not healing:
		dash_t = 0.17
		dash_cd = 0.48
		if not is_on_floor():
			air_dash = false
		Sound.play("dash", 0.05)
	atk_cd -= dt
	if atk_t > 0.0:
		atk_t -= dt
		if atk_t > 0.12:
			main.attack_hits(self)
		if atk_t <= 0.13:
			pogo_done = false
	if Input.is_action_just_pressed("attack") and atk_cd <= 0.0 and not healing:
		if Input.is_action_pressed("up"):
			atk_dir = "up"
		elif Input.is_action_pressed("down") and not is_on_floor():
			atk_dir = "down"
		else:
			atk_dir = "side"
		atk_t = 0.24
		atk_cd = 0.34
		hit_set = {}
		Sound.play("slash", 0.08)
	if drop_t > 0.0:
		drop_t -= dt
		if drop_t <= 0.0:
			_set_drop(false)
	move_and_slide()
	position.x = clampf(position.x, w / 2.0, main.room.room_size.x - w / 2.0)
	ground_oneway = false
	if is_on_floor():
		for i in get_slide_collision_count():
			var col = get_slide_collision(i).get_collider()
			if col is StaticBody2D and (col.collision_layer & (2 | 4)) != 0:
				ground_oneway = true
		used_double = false
		air_dash = true
		if not was_floor and vy_before > 320.0:
			Sound.play("land", 0.05, linear_to_db(clampf(vy_before / 900.0, 0.3, 1.0)))
		if absf(velocity.x) > 60.0 and dash_t <= 0.0:
			step_acc += absf(velocity.x) * dt
			if step_acc > 48.0:
				step_acc = 0.0
				Sound.play("step_astral" if is_astral else ("step_wood" if ground_oneway else "step_" + main.room.floor_sound), 0.08, -3.0)
	if absf(velocity.x) > 20.0 and is_on_floor():
		run_ph += dt * 11.5


func attack_box() -> Rect2:
	if atk_dir == "up":
		return Rect2(position.x - 38, position.y - 138, 76, 86)
	if atk_dir == "down":
		return Rect2(position.x - 34, position.y - 14, 68, 80)
	if face > 0:
		return Rect2(position.x + w / 2.0 - 4, position.y - 62, 82, 60)
	return Rect2(position.x - w / 2.0 - 78, position.y - 62, 82, 60)


func update_pose(t: float, slumped: bool) -> void:
	rig.pose = {
		"face": face, "t": t, "ph": run_ph, "moving": absf(velocity.x) > 20.0 and is_on_floor(), "air": not is_on_floor(), "vy": velocity.y,
		"atk": atk_dir if atk_t > 0.0 else "", "dash": dash_t > 0.0, "heal": heal_t > 0.0, "slump": slumped,
		"eyes": ("echo" if is_astral else ("echo" if slumped else ("glow" if Game.overdraw > 0 else ""))),
	}
	rig.flash = 0.5 if (not is_astral and inv > 1.0) else 0.0
	var blink = inv > 0.0 and not is_astral and not slumped and int(inv * 14.0) % 2 == 1
	rig.visible = not blink
