extends CharacterBody2D
## A Choir Imp: a skull-masked astral creature that slipped through with the
## signal. Hops, spits red bolts from range and claws up close.

const Anim = preload("res://scripts/anim_sprite.gd")

var main: Node
var id = ""
var kind = "imp"
var astral_only = false
var hp = 5
var max_hp = 5
var state = "idle"
var tm = 0.0
var cd = 1.5
var face = -1
var flash = 0.0
var dead = false
var home = 0.0
var patrol_range = 140.0
var fired = false
var rig: Node2D
var w = 30.0
var h = 50.0
var xp = 18


func setup(sid: String, pos: Vector2, rng: float) -> void:
	id = sid
	position = pos
	home = pos.x
	patrol_range = rng
	cd = 1.0 + randf() * 1.5
	var cs = CollisionShape2D.new()
	var sh = RectangleShape2D.new()
	sh.size = Vector2(w, h)
	cs.shape = sh
	cs.position = Vector2(0, -h / 2.0)
	add_child(cs)
	collision_layer = 0
	collision_mask = 1 | 2 | 8 | 16
	rig = Anim.new()
	rig.key = "imp"
	add_child(rig)


func hurt_rect() -> Rect2:
	return Rect2(position.x - w / 2.0, position.y - h, w, h)


func step(dt: float) -> void:
	flash = maxf(0.0, flash - dt)
	tm -= dt
	cd -= dt
	if state == "dying":
		if tm <= 0.0:
			dead = true
		return
	var p: Node = main.player
	var dx: float = p.position.x - position.x
	var dy: float = p.position.y - position.y
	var aware = absf(dx) < 460.0 and absf(dy) < 200.0
	match state:
		"idle":
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * dt)
			if aware:
				face = int(signf(dx)) if dx != 0 else face
				if absf(dx) < 90.0 and cd <= 0.0:
					state = "attack"
					tm = 0.5
					Sound.play("u_bat", 0.1, -6.0)
				elif cd <= 0.0:
					state = "shoot"
					tm = 0.55
					fired = false
				elif is_on_floor() and randf() < dt * 0.8:
					velocity = Vector2(-signf(dx) * 160.0 if absf(dx) < 160.0 else signf(dx) * 140.0, -420.0)
			elif is_on_floor() and randf() < dt * 0.4:
				var d = signf(home - position.x) if absf(position.x - home) > patrol_range else (1.0 if randf() < 0.5 else -1.0)
				face = int(d)
				velocity = Vector2(d * 120.0, -360.0)
		"shoot":
			velocity.x = 0.0
			if not fired and tm <= 0.25:
				fired = true
				var from: Vector2 = position + Vector2(face * 18, -30)
				var to: Vector2 = p.position + Vector2(0, -30)
				main.fx.shoot(from, (to - from).normalized() * 250.0, 7.0, "orb", Color("#ff5a4a"))
				Sound.play("u_spit", 0.1, -4.0)
			if tm <= 0.0:
				state = "idle"
				cd = 2.2 + randf() * 0.8
		"attack":
			velocity.x = face * 120.0 if tm > 0.2 else 0.0
			if tm < 0.32 and tm > 0.12:
				var box = Rect2(position.x + (0.0 if face > 0 else -54.0), position.y - 46, 54, 40)
				if box.intersects(p.hitbox()):
					main.hurt_player(1, position.x)
			if tm <= 0.0:
				state = "idle"
				cd = 1.4
				velocity = Vector2(-face * 200.0, -380.0)
		"hurt":
			velocity.x = move_toward(velocity.x, 0, 700.0 * dt)
			if tm <= 0.0:
				state = "idle"
	velocity.y = minf(velocity.y + 1900.0 * dt, 800.0)
	move_and_slide()
	if main.room.hazard_at(hurt_rect()) or position.y > main.room.room_size.y + 60:
		position = Vector2(home, position.y - 60)
		velocity = Vector2.ZERO
	if state != "attack" and hurt_rect().grow(-6).intersects(p.hitbox()):
		main.hurt_player(1, position.x)


func hit(dmg: int, hdir: int) -> bool:
	if state == "dying" or dead:
		return false
	hp -= dmg
	flash = 0.12
	Sound.play("ehit", 0.1)
	if hp <= 0:
		state = "dying"
		tm = 0.6
		velocity = Vector2.ZERO
		Game.set_flag("down_" + id, true)
		Sound.play("pop")
		main.enemy_defeated(self, xp)
		for i in 18:
			main.fx.part(position + Vector2(0, -30), Vector2(randf_range(-160, 160), -randf() * 220), "wisp", Color("#ff8a7a"))
		return true
	state = "hurt"
	tm = 0.25
	velocity = Vector2(hdir * 240.0, -160.0)
	return true


func _process(_d: float) -> void:
	rig.face = face
	match state:
		"dying":
			rig.play("death")
		"shoot":
			rig.seek("shoot", 1.0 - tm / 0.55)
		"attack":
			rig.seek("attack", 1.0 - tm / 0.5)
		"hurt":
			rig.play("hurt")
		_:
			rig.play("idle")
	rig.flash = clampf(flash * 6.0, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var sh = PackedVector2Array()
	for i in 17:
		var a = TAU * i / 16.0
		sh.append(Vector2(cos(a) * 15, sin(a) * 3))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.3))
	for i in 3:
		draw_circle(Vector2(0, -28), 30.0 - i * 8.0, Color(1, 0.3, 0.3, 0.03))
