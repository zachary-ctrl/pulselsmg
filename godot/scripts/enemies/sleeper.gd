extends CharacterBody2D
## An infected student: patrols, notices Max, lunges. Strikes "stabilize" them.

const Anim = preload("res://scripts/anim_sprite.gd")
const PHRASES := ["seven circles...", "are you listening", "not hungry", "it is so loud", "we see it", "the sun is black", "almost synchronized", "do you hear it"]

var main: Node
var id = ""
var kind = "sleeper"
var astral_only = false
var home = 0.0
var patrol_range = 150.0
var hp = 4
var state = "wander"
var tm = 0.0
var dir = 1
var face = 1
var flash = 0.0
var seed = 0.0
var whisper_t = 3.0
var ph = 0.0
var dead = false
var rig: Node2D
var w = 26.0
var h = 56.0


func setup(sid: String, pos: Vector2, rng: float, down: bool) -> void:
	id = sid
	position = pos
	home = pos.x
	patrol_range = rng
	state = "down" if down else "wander"
	tm = randf() * 2.0
	dir = -1 if randf() < 0.5 else 1
	seed = randf() * 10.0
	whisper_t = 2.0 + randf() * 4.0
	var cs = CollisionShape2D.new()
	var sh = RectangleShape2D.new()
	sh.size = Vector2(w, h)
	cs.shape = sh
	cs.position = Vector2(0, -h / 2.0)
	add_child(cs)
	collision_layer = 0
	collision_mask = 1 | 2 | 8 | 16
	rig = Anim.new()
	rig.key = "teacher" if (sid == "s2" or sid == "sx" or sid.begins_with("t")) else "returned"
	add_child(rig)


func hurt_rect() -> Rect2:
	return Rect2(position.x - w / 2.0, position.y - h, w, h)


func step(dt: float) -> void:
	if state == "down":
		if randf() < dt * 0.6:
			main.fx.text_float(position + Vector2(10, -18), "z", Color(0.86, 0.82, 1), 2.0)
		return
	flash = maxf(0.0, flash - dt)
	tm -= dt
	whisper_t -= dt
	var p: Node = main.player
	var dx: float = p.position.x - position.x
	var near = absf(dx) < 300.0 and absf(p.position.y - position.y) < 140.0
	if whisper_t <= 0.0:
		whisper_t = 4.0 + randf() * 5.0
		if absf(dx) < 520.0:
			main.fx.text_float(position + Vector2(0, -78), PHRASES[randi() % PHRASES.size()], Color(0.82, 0.78, 1), 2.4)
	match state:
		"wander":
			velocity.x = move_toward(velocity.x, dir * 42.0, 300.0 * dt)
			if absf(position.x - home) > patrol_range:
				dir = int(signf(home - position.x))
			if tm <= 0.0:
				tm = 1.5 + randf() * 2.0
				if randf() < 0.35:
					dir *= -1
			face = dir
			if (near and not main.astral_active()) or (near and absf(dx) < 160.0):
				state = "notice"
				tm = 0.5
				velocity.x = 0
				face = int(signf(dx)) if dx != 0 else 1
				Sound.play("whisper")
		"notice":
			velocity.x = 0
			if dx != 0:
				face = int(signf(dx))
			if tm <= 0.0:
				state = "lunge"
				velocity.x = face * 370.0
				velocity.y = -330.0
				tm = 0.7
				Sound.play("lunge")
		"lunge":
			if is_on_floor() and tm < 0.5:
				state = "recover"
				tm = 0.85
		"recover":
			velocity.x = move_toward(velocity.x, 0, 900.0 * dt)
			if tm <= 0.0:
				state = "notice" if near else "wander"
				tm = 0.6 if near else 1.0
		"hurt":
			velocity.x = move_toward(velocity.x, 0, 700.0 * dt)
			if tm <= 0.0:
				state = "recover"
				tm = 0.4
	if state == "wander" and is_on_floor() and not main.room.ground_at(Vector2(position.x + dir * 20, position.y + 4)):
		dir *= -1
		velocity.x = 0
	velocity.y = minf(velocity.y + 2200.0 * dt, 900.0)
	move_and_slide()
	if absf(velocity.x) > 5.0:
		ph += dt * 8.0
	if main.room.hazard_at(hurt_rect()):
		position = Vector2(home, position.y - 40)
		velocity = Vector2.ZERO
	if hurt_rect().intersects(main.player.hitbox()):
		main.hurt_player(1, position.x)


func hit(dmg: int, hdir: int) -> bool:
	if state == "down":
		return false
	hp -= dmg
	flash = 0.12
	state = "hurt"
	tm = 0.28
	velocity = Vector2(hdir * 260.0, -140.0)
	Sound.play("ehit", 0.1)
	if hp <= 0:
		state = "down"
		velocity = Vector2.ZERO
		if id != "sx":
			Game.set_flag("down_" + id, true)
			Game.flags["stabilized"] = int(Game.flags.get("stabilized", 0)) + 1
		Sound.play("stabilize")
		main.enemy_defeated(self, 14)
		for i in 26:
			main.fx.part(position + Vector2(0, -40), Vector2(randf_range(-80, 80), -randf() * 160), "wisp", Color("#c9b8ff"))
		main.fx.text_float(position + Vector2(0, -80), "stabilized", Color("#ffd2a8"), 2.0)
	return true


func _process(_d: float) -> void:
	rig.face = face
	match state:
		"down":
			rig.play("collapse")
		"notice":
			rig.play("notice")
		"lunge":
			rig.play("lunge")
		"hurt":
			rig.play("hurt")
		_:
			if absf(velocity.x) > 8.0 and is_on_floor():
				rig.play("walk")
				rig.speed = clampf(absf(velocity.x) / 45.0, 0.6, 1.4)
			else:
				rig.seek("walk", 0.0)
	rig.flash = clampf(flash * 6.0, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO)
	var shadow = PackedVector2Array()
	for i in 17:
		var a = TAU * i / 16.0
		shadow.append(Vector2(cos(a) * (34.0 if state == "down" else 16.0), sin(a) * 3.5))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.35))
	if state == "notice":
		draw_string(Game.font_display, Vector2(-5, -82), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dcff"))
