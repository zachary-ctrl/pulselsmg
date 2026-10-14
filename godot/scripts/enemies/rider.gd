extends CharacterBody2D
## A Static Rider: a Choir goblin on a boar made of borrowed nightmares.
## Patrols, sneers, then charges; pokes with its spear up close. Riders whose
## id starts with "elite" are bigger mini-bosses that always drop equipment.

const Anim = preload("res://scripts/anim_sprite.gd")

var main: Node
var id = ""
var kind = "rider"
var astral_only = false
var hp = 9
var max_hp = 9
var state = "walk"
var tm = 0.0
var face = -1
var flash = 0.0
var dead = false
var home = 0.0
var patrol_range = 220.0
var alpha = 1.0
var elite = false
var rig: Node2D
var w = 70.0
var h = 76.0
var xp = 26


func setup(sid: String, pos: Vector2, rng: float) -> void:
	id = sid
	position = pos
	home = pos.x
	patrol_range = maxf(rng, 120.0)
	elite = sid.begins_with("elite")
	if elite:
		hp = 26
		max_hp = 26
		w = 88.0
		h = 96.0
		xp = 90
	var cs = CollisionShape2D.new()
	var sh = RectangleShape2D.new()
	sh.size = Vector2(w * 0.8, h)
	cs.shape = sh
	cs.position = Vector2(0, -h / 2.0)
	add_child(cs)
	collision_layer = 0
	collision_mask = 1 | 2 | 8 | 16
	rig = Anim.new()
	rig.key = "rider"
	rig.size_mul = 1.28 if elite else 1.0
	if elite:
		rig.tint = Color(0.6, 0.3, 1.0, 0.25)
	add_child(rig)


func hurt_rect() -> Rect2:
	return Rect2(position.x - w / 2.0, position.y - h, w, h)


func step(dt: float) -> void:
	flash = maxf(0.0, flash - dt)
	tm -= dt
	if state == "dying":
		alpha = maxf(0.0, alpha - dt * 1.6)
		if alpha <= 0.0:
			dead = true
		return
	var p: Node = main.player
	var dx: float = p.position.x - position.x
	var aware = absf(dx) < 400.0 and absf(p.position.y - position.y) < 120.0
	match state:
		"walk":
			velocity.x = move_toward(velocity.x, face * 60.0, 400.0 * dt)
			if absf(position.x - home) > patrol_range:
				face = int(signf(home - position.x))
			if is_on_floor() and not main.room.ground_at(Vector2(position.x + face * (w * 0.5 + 6), position.y + 4)):
				face *= -1
			if aware and tm <= 0.0:
				face = int(signf(dx)) if dx != 0 else face
				if absf(dx) < 120.0:
					state = "poke"
					tm = 0.45
				else:
					state = "sneer"
					tm = 0.55
					Sound.play("whisper", 0.1)
					if elite:
						main.start_elite(self)
		"sneer":
			velocity.x = 0.0
			if tm <= 0.0:
				state = "charge"
				tm = 1.5
				Sound.play("lunge")
		"charge":
			velocity.x = face * (520.0 if elite else 430.0)
			if randf() < 0.5:
				main.fx.part(position + Vector2(-face * 30, -4), Vector2(-face * 80, -randf() * 60), "dust", Color("#c8b8a0"))
			var edge = is_on_floor() and not main.room.ground_at(Vector2(position.x + face * (w * 0.5 + 10), position.y + 4))
			if tm <= 0.0 or is_on_wall() or edge:
				state = "recover"
				tm = 0.9
				if is_on_wall():
					main.shake = maxf(main.shake, 0.2)
					Sound.play("land")
		"poke":
			velocity.x = 0.0
			if tm < 0.3 and tm > 0.12:
				var box = Rect2(position.x + (w * 0.3 if face > 0 else -w * 0.3 - 80.0), position.y - h * 0.7, 80, 24)
				if box.intersects(p.hitbox()):
					main.hurt_player(1, position.x)
			if tm <= 0.0:
				state = "recover"
				tm = 0.6
		"recover", "hurt":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * dt)
			if tm <= 0.0:
				state = "walk"
				tm = 0.4
	velocity.y = minf(velocity.y + 2100.0 * dt, 900.0)
	move_and_slide()
	if main.room.hazard_at(hurt_rect()) or position.y > main.room.room_size.y + 60:
		position = Vector2(home, position.y - 80)
		velocity = Vector2.ZERO
	if hurt_rect().grow(-8).intersects(p.hitbox()):
		main.hurt_player(2 if state == "charge" and elite else 1, position.x)


func hit(dmg: int, hdir: int) -> bool:
	if state == "dying" or dead:
		return false
	hp -= dmg
	flash = 0.12
	Sound.play("ehit", 0.1)
	if hp <= 0:
		state = "dying"
		velocity = Vector2.ZERO
		Game.set_flag("down_" + id, true)
		Sound.play("defeat" if elite else "pop")
		main.enemy_defeated(self, xp)
		if elite:
			var pool = []
			for it in Game.DROP_POOL:
				if not it in Game.prog["items"]:
					pool.append(it)
			if not pool.is_empty():
				main._drop("item", position + Vector2(0, -50), {"item": pool[randi() % pool.size()]})
		for i in 26:
			main.fx.part(position + Vector2(0, -40), Vector2(randf_range(-200, 200), -randf() * 240), "wisp", Color("#ffb06a"))
		return true
	if state != "charge":
		state = "hurt"
		tm = 0.22
		velocity.x = hdir * (120.0 if elite else 200.0)
	return true


func _process(_d: float) -> void:
	rig.face = face
	match state:
		"sneer":
			rig.play("sneer")
		"charge":
			rig.play("attack2")
			rig.speed = 1.4
		"poke":
			rig.seek("attack1", 1.0 - tm / 0.45)
		"walk":
			rig.play("walk")
			rig.speed = 1.0
		_:
			rig.play("idle")
	rig.alpha = alpha
	rig.flash = clampf(flash * 6.0, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var sh = PackedVector2Array()
	for i in 17:
		var a = TAU * i / 16.0
		sh.append(Vector2(cos(a) * w * 0.45, sin(a) * 4))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.3 * alpha))
	if state == "sneer":
		draw_string(Game.font_display, Vector2(-5, -h - 14), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#ffb06a"))
