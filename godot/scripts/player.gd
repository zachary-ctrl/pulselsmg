extends CharacterBody2D
## Max's body, or his astral form when `is_astral` is true.
## Collision layers: 1 solid, 2 one-way, 3 astral-only, 4 doors, 5 gates.

const Anim = preload("res://scripts/anim_sprite.gd")
const Aura = preload("res://scripts/aura.gd")
const PRM_BODY := {"run": 300.0, "grav": 2400.0, "max_fall": 880.0, "jump": 760.0, "dash": 760.0}
const LASER_COST := 22.0
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
var atk_kind = "strike"  # strike, finisher, kick, dive
var atk_dmg = 1
var combo = 0
var combo_t = 0.0
var kick_t = 0.0
var kick_cd = 0.0
var dive = false
var laser_t = 0.0
var laser_cd = 0.0
var laser_dir = Vector2.RIGHT
var laser_fired = false
var special = "laser"
var flurry_t = 0.0
var flurry_tick = 0.0
var hero = "max"
var aura: Node2D
var swap_t = 0.0
var shinobi = false
var air_jumps = 0
var wall_dir = 0
var wall_grace = 0.0
var wall_lock = 0.0
var down_hold = 0.0
const EGO_NAMES := {"max": "SHADOW", "lana": "RONIN", "jason": "BRAWLER"}
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
var hp = 7
var max_hp = 7
var res = 0.0
var safe = Vector2.ZERO
var timer = 60.0
var ret = 0.0
var ret_from = Vector2.ZERO
var land_t = 0.0


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
	aura = Aura.new()
	add_child(aura)
	rig = Anim.new()
	rig.key = "max"
	if astral:
		rig.tint = Color(0.56, 0.45, 1.0, 0.82)
	add_child(rig)


func set_hero(h: String) -> void:
	hero = h
	rig.key = h + "_sh" if shinobi else h
	aura.color = Game.HEROES[h]["aura"]
	swap_t = 0.6


func dmg_bonus() -> int:
	return int(Game.mod("dmg")) + int(Game.attr(hero, "pow") / 2) + (1 if shinobi else 0)


## Alter ego: the hero becomes their shinobi self. Faster, an extra air jump,
## harder hits, but it burns Resonance while it lasts.
func set_shinobi(on: bool) -> void:
	if on == shinobi or is_astral:
		return
	shinobi = on
	rig.key = hero + "_sh" if on else hero
	swap_t = 0.6
	if on:
		Sound.play("u_transform", 0.0, -3.0)
		main.flash_screen(0.35, Color(Game.HEROES[hero]["col"]))
		main.fx.sprite("ring", position + Vector2(0, -4), 200.0, 0.4, 0.0, Color(Game.HEROES[hero]["col"]), 4, 2)
		main.fx.sprite("vfx/burst_pink" if hero == "max" else ("vfx/burst_ice" if hero == "jason" else "vfx/comet_orange"), position + Vector2(0, -40), 140.0, 0.45, -PI / 2.0 if hero == "lana" else 0.0)
		main.toast("ALTER EGO: " + EGO_NAMES[hero])
		Game.rumble(0.4, 0.6, 0.35)
	else:
		Sound.play("u_portal", 0.0, -8.0)
	for i in 30:
		var a = randf() * TAU
		main.fx.part(position + Vector2(0, -36), Vector2(cos(a), sin(a)) * 260.0, "spark", Color(Game.HEROES[hero]["col"]))


func hitbox() -> Rect2:
	return Rect2(position.x - w / 2.0, position.y - h, w, h)


func _set_drop(on: bool) -> void:
	set_collision_mask_value(2, not on)
	if is_astral:
		set_collision_mask_value(3, not on)


func control(dt: float) -> void:
	var prm: Dictionary = PRM_ASTRAL if is_astral else PRM_BODY
	if not is_astral:
		var hd: Dictionary = Game.HEROES[hero]
		prm = PRM_BODY.duplicate()
		prm["run"] = hd["run"] * (1.0 + Game.mod("speed")) * (1.25 if shinobi else 1.0)
		prm["jump"] = hd["jump"] * (1.06 if shinobi else 1.0)
		if Input.is_action_just_pressed("transform"):
			if shinobi:
				set_shinobi(false)
			elif res >= 30.0:
				set_shinobi(true)
			else:
				main.toast("Alter ego needs 30 Resonance")
				Sound.play("glitch", 0.05, -6.0)
		if shinobi:
			res = maxf(0.0, res - 4.5 * dt)
			if res <= 0.0:
				set_shinobi(false)
				main.toast("Your alter ego fades")
	swap_t = maxf(0.0, swap_t - dt)
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
		if heal_t >= 0.9 / (1.0 + Game.mod("focus")):
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
		elif dive:
			velocity.x = face * 520.0
		elif flurry_t > 0.0:
			velocity.x = face * 380.0
		elif laser_t > 0.0:
			velocity.x = move_toward(velocity.x, 0.0, 3000.0 * dt)
		elif kick_t > 0.0 and is_on_floor():
			velocity.x = face * 520.0 * maxf(0.0, (kick_t - 0.12) / 0.2)
		elif wall_lock > 0.0:
			wall_lock -= dt
		else:
			velocity.x = move_toward(velocity.x, dir * prm["run"], (4600.0 if is_on_floor() else 3800.0) * dt)
		if dir != 0 and atk_t <= 0.0 and kick_t <= 0.0 and laser_t <= 0.0 and not dive:
			face = dir
		if dive:
			velocity.y = 820.0
		elif (laser_t > 0.0 or flurry_t > 0.0) and not is_on_floor():
			velocity.y = minf(velocity.y + prm["grav"] * 0.25 * dt, 90.0)
		else:
			velocity.y = minf(velocity.y + prm["grav"] * dt, prm["max_fall"])
	# Wall slide: hold toward a wall while falling.
	wall_grace -= dt
	if not is_astral and not is_on_floor() and is_on_wall() and dash_t <= 0.0:
		var n = get_wall_normal().x
		if n != 0.0 and dir == -int(signf(n)):
			wall_dir = -int(signf(n))
			wall_grace = 0.12
			if velocity.y > 120.0:
				velocity.y = 120.0
				if randf() < 0.3:
					main.fx.part(position + Vector2(wall_dir * w / 2.0, -50), Vector2(0, -20), "dust", Color("#c8c0b0"))
	if Input.is_action_just_pressed("jump"):
		jump_buf = 0.16
	else:
		jump_buf -= dt
	coyote = 0.14 if is_on_floor() else coyote - dt
	# Hold down on a desk or ledge to drop through.
	if is_on_floor() and ground_oneway and Input.is_action_pressed("down") and dir == 0 and not healing:
		down_hold += dt
		if down_hold > 0.22:
			down_hold = 0.0
			drop_t = 0.25
			_set_drop(true)
			position.y += 2
	else:
		down_hold = 0.0
	var max_air = (1 if Game.ability.get("double", false) else 0) + (1 if shinobi else 0)
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
		elif not is_astral and wall_grace > 0.0:
			velocity.y = -prm["jump"] * 0.92
			velocity.x = -wall_dir * prm["run"] * 1.15
			face = -wall_dir
			wall_lock = 0.14
			wall_grace = 0.0
			jump_buf = 0.0
			jump_cut = false
			air_dash = true
			Sound.play("jump", 0.06)
			for i in 8:
				main.fx.part(position + Vector2(wall_dir * w / 2.0, -30), Vector2(-wall_dir * randf() * 120, randf_range(-60, 60)), "dust", Color("#c8c0b0"))
		elif not is_astral and air_jumps < max_air and dash_t <= 0.0:
			velocity.y = -prm["jump"] * 0.88
			air_jumps += 1
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
	if Input.is_action_just_pressed("dash") and dash_cd <= 0.0 and (is_on_floor() or air_dash) and not healing and not dive and laser_t <= 0.0:
		dash_t = 0.17
		dash_cd = maxf(0.12, 0.48 + Game.mod("dashcd"))
		if not is_on_floor():
			air_dash = false
		Sound.play("dash", 0.05)
	atk_cd -= dt
	combo_t -= dt
	if atk_t > 0.0:
		atk_t -= dt
		if atk_t > 0.12:
			main.attack_hits(self)
		if atk_t <= 0.13:
			pogo_done = false
	var busy = kick_t > 0.0 or dive or laser_t > 0.0 or flurry_t > 0.0
	if Input.is_action_just_pressed("attack") and atk_cd <= 0.0 and not healing and not busy:
		if Input.is_action_pressed("up"):
			atk_dir = "up"
		elif Input.is_action_pressed("down") and not is_on_floor():
			atk_dir = "down"
		else:
			atk_dir = "side"
		combo = (combo + 1) % 3 if (combo_t > 0.0 and atk_dir == "side") else 0
		combo_t = 0.5
		atk_kind = "finisher" if combo == 2 else "strike"
		var base_dmg: int = 1 if is_astral else int(Game.HEROES[hero]["dmg"])
		atk_dmg = (base_dmg + 1 + int(Game.mod("heavy")) if combo == 2 else base_dmg) + dmg_bonus()
		atk_t = 0.24
		var cdb: float = 0.26 if is_astral else float(Game.HEROES[hero]["cd"]) * (0.8 if shinobi else 1.0)
		atk_cd = cdb + 0.16 if combo == 2 else cdb
		hit_set = {}
		Sound.play("slash", 0.08)
		if combo == 2:
			Sound.play("kick", 0.05, -4.0)
	_kick(dt, healing)
	if not is_astral:
		_laser(dt, healing)
	if drop_t > 0.0:
		drop_t -= dt
		if drop_t <= 0.0:
			_set_drop(false)
	var vy_pre = velocity.y
	move_and_slide()
	_assists(dir, vy_pre)
	position.x = clampf(position.x, w / 2.0, main.room.room_size.x - w / 2.0)
	ground_oneway = false
	if is_on_floor():
		for i in get_slide_collision_count():
			var col = get_slide_collision(i).get_collider()
			if col is StaticBody2D and (col.collision_layer & (2 | 4)) != 0:
				ground_oneway = true
		used_double = false
		air_jumps = 0
		air_dash = true
		if dive:
			_end_dive(true)
		if not was_floor and vy_before > 320.0:
			land_t = 0.12
			Sound.play("land", 0.05, linear_to_db(clampf(vy_before / 900.0, 0.3, 1.0)))
		if absf(velocity.x) > 60.0 and dash_t <= 0.0:
			step_acc += absf(velocity.x) * dt
			if step_acc > 48.0:
				step_acc = 0.0
				Sound.play("step_astral" if is_astral else ("step_wood" if ground_oneway else "step_" + main.room.floor_sound), 0.08, -3.0)
	if absf(velocity.x) > 20.0 and is_on_floor():
		run_ph += dt * 11.5


func _kick(dt: float, healing: bool) -> void:
	kick_cd -= dt
	if kick_t > 0.0:
		kick_t -= dt
		if kick_t < 0.24 and kick_t > 0.06:
			main.attack_hits(self)
	if dive:
		kick_t = 0.2
		main.attack_hits(self)
		if randf() < 0.8:
			main.fx.part(position + Vector2(-face * 8, -20), Vector2(-face * 80, -120), "trail", Color("#a58bff") if is_astral else Color("#ffd6a0"))
	if not Input.is_action_just_pressed("kick") or kick_cd > 0.0 or healing or atk_t > 0.0 or laser_t > 0.0 or dive or dash_t > 0.0:
		return
	hit_set = {}
	atk_dmg = 2 + int(Game.mod("heavy")) + dmg_bonus() + (1 if hero == "jason" else 0)
	if is_on_floor():
		atk_kind = "kick"
		atk_dir = "side"
		kick_t = 0.32
		kick_cd = 0.5
	else:
		atk_kind = "dive"
		atk_dir = "down"
		dive = true
		kick_t = 0.2
		kick_cd = 0.45
	Sound.play("kick", 0.08)


func _end_dive(landed: bool) -> void:
	dive = false
	kick_t = 0.0
	if landed:
		Sound.play("land", 0.05)
		main.shake = maxf(main.shake, 0.12)
		main.fx.sprite("ring", position + Vector2(0, -2), 170.0, 0.36, 0.0, Color.WHITE, 4, 2)
		main.fx.sprite("dust", position + Vector2(0, -14), 90.0, 0.4, 0.0, Color.WHITE, 6)
		for i in 12:
			main.fx.part(position, Vector2(randf_range(-260, 260), -randf() * 90), "dust", Color("#e8d8c0"))


## Movement assists: climb onto a ledge you just barely missed, and slip
## around ceiling corners instead of bonking.
func _assists(dir: int, vy_pre: float) -> void:
	if is_astral:
		return
	if dir != 0 and not is_on_floor() and is_on_wall() and vy_pre > -260.0:
		for k in range(6, 34, 2):
			var tr = global_transform.translated(Vector2(0, -k))
			if not test_move(tr, Vector2(dir * 8, 0)) and test_move(tr.translated(Vector2(dir * 8, 0)), Vector2(0, k + 4)):
				position += Vector2(dir * 8, -k)
				velocity.y = minf(velocity.y, 0.0)
				break
	if is_on_ceiling() and vy_pre < -100.0:
		for off in [4, -4, 8, -8, 12, -12]:
			if not test_move(global_transform.translated(Vector2(off, 0)), Vector2(0, -8)):
				position.x += off
				velocity.y = vy_pre
				break


func dive_bounce() -> void:
	_end_dive(false)
	velocity.y = -620.0
	jump_cut = true
	used_double = false
	air_dash = true


func _laser(dt: float, healing: bool) -> void:
	laser_cd -= dt
	if flurry_t > 0.0:
		flurry_t -= dt
		flurry_tick -= dt
		if flurry_tick <= 0.0:
			flurry_tick = 0.08
			hit_set = {}
			Sound.play("slash", 0.15, -6.0)
		main.attack_hits(self)
		if flurry_t <= 0.0:
			atk_kind = "strike"
	if laser_t > 0.0:
		laser_t -= dt
		if not laser_fired and laser_t <= 0.26:
			laser_fired = true
			main.fire_special(self, special)
		return
	if not Input.is_action_just_pressed("laser") or laser_cd > 0.0 or healing or atk_t > 0.0 or kick_t > 0.0 or dash_t > 0.0 or flurry_t > 0.0:
		return
	special = Game.prog["special"].get(hero, Game.HEROES[hero]["specials"][0])
	var cost = Game.special_cost(hero)
	if res < cost:
		Sound.play("glitch", 0.05, -6.0)
		main.toast("%s needs %d Resonance. Land hits to build it." % [Game.SPECIALS[special]["name"], int(cost)])
		laser_cd = 0.6
		return
	res -= cost
	laser_dir = Vector2.UP if Input.is_action_pressed("up") and special == "laser" else Vector2(face, 0)
	laser_t = 0.4
	laser_cd = 0.55
	laser_fired = false
	Sound.play("charge", 0.05, -4.0)


func start_flurry() -> void:
	flurry_t = 0.5
	flurry_tick = 0.0
	atk_kind = "flurry"
	atk_dir = "side"
	atk_dmg = 1 + dmg_bonus() + int(Game.mod("sdmg"))


func attack_box() -> Rect2:
	if atk_kind == "flurry":
		return Rect2(position.x - 30 + face * 40, position.y - 64, 60, 60)
	if atk_kind == "kick":
		if face > 0:
			return Rect2(position.x + w / 2.0 - 6, position.y - 44, 74, 40)
		return Rect2(position.x - w / 2.0 - 68, position.y - 44, 74, 40)
	if atk_kind == "dive":
		return Rect2(position.x - 26 + face * 10, position.y - 30, 52, 44)
	if atk_kind == "finisher" and atk_dir == "side":
		if face > 0:
			return Rect2(position.x + w / 2.0 - 4, position.y - 78, 104, 80)
		return Rect2(position.x - w / 2.0 - 100, position.y - 78, 104, 80)
	if atk_dir == "up":
		return Rect2(position.x - 38, position.y - 138, 76, 86)
	if atk_dir == "down":
		return Rect2(position.x - 34, position.y - 14, 68, 80)
	if face > 0:
		return Rect2(position.x + w / 2.0 - 4, position.y - 62, 82, 60)
	return Rect2(position.x - w / 2.0 - 78, position.y - 62, 82, 60)


func update_pose(t: float, slumped: bool) -> void:
	land_t = maxf(0.0, land_t - get_physics_process_delta_time())
	rig.face = face
	rig.tilt = 0.0
	if dive:
		rig.seek("strike_down", 0.6)
		rig.tilt = 0.35 * face
	elif kick_t > 0.0:
		rig.seek("dash", clampf(1.0 - (kick_t - 0.08) / 0.24, 0.0, 1.0))
		rig.tilt = -0.12 * face
	elif flurry_t > 0.0:
		rig.seek("strike", fmod(flurry_t * 10.0, 1.0))
	elif laser_t > 0.0:
		var up = laser_dir.y < 0.0
		rig.seek("strike_up" if up else "strike", 0.3 if not laser_fired else 0.75)
	elif atk_t > 0.0:
		var name: String = {"side": "strike", "up": "strike_up", "down": "strike_down"}[atk_dir]
		rig.seek(name, 1.0 - atk_t / 0.24)
	elif dash_t > 0.0:
		rig.seek("dash", 1.0 - dash_t / 0.17)
	elif heal_t > 0.0:
		rig.seek("land", 0.0)
	elif slumped:
		rig.seek("idle", 0.0)
		rig.tilt = -0.08
	elif not is_on_floor():
		rig.seek("jump", 0.4 if velocity.y < -120.0 else (0.95 if velocity.y > 120.0 else 0.5))
	elif land_t > 0.0:
		rig.seek("land", 1.0 - land_t / 0.12)
	elif absf(velocity.x) > 20.0:
		rig.play("run")
		rig.speed = clampf(absf(velocity.x) / 300.0, 0.6, 1.2)
	else:
		rig.play("idle")
		rig.speed = 1.0
	if slumped:
		rig.tint = Color(0.75, 0.7, 1.0, 0.25)
	elif not is_astral:
		rig.tint = Color(0.65, 0.55, 1.0, 0.18) if Game.overdraw > 0 else Color(0, 0, 0, 0)
	rig.flash = 0.5 if (not is_astral and inv > 1.0) else 0.0
	if not is_astral and not is_on_floor() and wall_grace > 0.08 and velocity.y > 0.0 and atk_t <= 0.0:
		rig.seek("jump", 0.95)
		rig.face = -wall_dir
	var blink = inv > 0.0 and not is_astral and not slumped and int(inv * 14.0) % 2 == 1
	rig.visible = not blink
	if is_astral:
		aura.color = "violet"
		aura.target = 0.35
	else:
		var hot = laser_t > 0.0 or flurry_t > 0.0 or swap_t > 0.0 or heal_t > 0.0
		aura.target = 1.0 if hot else (0.6 if res >= Game.fp_need() or shinobi else 0.0)
	aura.face = face
