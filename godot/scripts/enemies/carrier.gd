extends CharacterBody2D
## The Carrier: Kai Brooks, home after nine days, speaking in three voices.
## Walks, lunges, fires fans of voice orbs and floor-hugging shouts. Lana's
## provocations stun him; stunned, he takes double damage.

const Anim = preload("res://scripts/anim_sprite.gd")
const TAUNTS := ["KAI! You still owe me five dollars!", "Kai, your mom made the GOOD lasagna!", "Remember when you cried at the Lion King? On a FIELD TRIP?",
	"Kai Brooks, your science fair volcano is still in my garage!", "You said I was your best friend in second grade. Prove it!"]

var main: Node
var id = "carrier"
var kind = "carrier"
var astral_only = false
var hp = 28
var max_hp = 28
var state = "dormant"
var tm = 0.0
var face = -1
var flash = 0.0
var dead = false
var lana_t = 6.0
var taunt_i = 0
var seq = 0
var last = ""
var rig: Node2D
var w = 30.0
var h = 84.0


func setup(pos: Vector2) -> void:
	position = pos
	var cs = CollisionShape2D.new()
	var sh = RectangleShape2D.new()
	sh.size = Vector2(w, h)
	cs.shape = sh
	cs.position = Vector2(0, -h / 2.0)
	add_child(cs)
	collision_layer = 0
	collision_mask = 1 | 2 | 8 | 16
	rig = Anim.new()
	rig.key = "returned"
	rig.size_mul = 1.18
	add_child(rig)


func hurt_rect() -> Rect2:
	return Rect2(position.x - w / 2.0, position.y - h, w, h)


func step(dt: float) -> void:
	flash = maxf(0.0, flash - dt)
	velocity.y = minf(velocity.y + 2200.0 * dt, 900.0)
	if state == "dormant" or state == "defeated":
		velocity.x = 0.0
		move_and_slide()
		return
	tm -= dt
	lana_t -= dt
	var dx: float = main.player.position.x - position.x
	if lana_t <= 0.0 and state != "stunned":
		lana_t = 8.5
		main.toast("LANA: " + TAUNTS[taunt_i % TAUNTS.size()])
		taunt_i += 1
		Sound.voice("lana")
		Sound.play("stagger")
		state = "stunned"
		tm = 2.2
	match state:
		"idle":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * dt)
			if dx != 0.0:
				face = int(signf(dx))
			if tm <= 0.0:
				_next()
		"walk":
			velocity.x = face * 110.0
			if tm <= 0.0 or absf(dx) < 70.0:
				state = "idle"
				tm = 0.3
		"windup":
			velocity.x = 0.0
			if tm <= 0.0:
				state = "lunge"
				velocity = Vector2(face * 430.0, -280.0)
				tm = 0.7
				Sound.play("lunge")
		"lunge":
			if is_on_floor() and tm < 0.45:
				state = "idle"
				tm = 0.6
		"chorus":
			velocity.x = 0.0
			if tm <= 0.0:
				if seq > 0:
					seq -= 1
					tm = 0.45
					var origin = position + Vector2(0, -60)
					var aim: float = (main.player.position + Vector2(0, -30) - origin).angle()
					for i in [-1, 0, 1]:
						var a: float = aim + i * 0.32
						main.fx.shoot(origin, Vector2(cos(a), sin(a)) * 240.0, 7.0, "orb", Color("#b48cff"))
					Sound.voice("choir")
					Sound.play("zap")
				else:
					state = "idle"
					tm = 0.7
		"shout":
			velocity.x = 0.0
			if tm <= 0.0:
				for d in [-1, 1]:
					main.fx.shoot(position + Vector2(d * 20, -14), Vector2(d * 320.0, 0), 12.0, "wave", Color("#9a6bff"))
				Sound.play("boom")
				main.shake = 0.2
				state = "idle"
				tm = 0.9
		"stunned":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * dt)
			if tm <= 0.0:
				state = "idle"
				tm = 0.4
	move_and_slide()
	position.x = clampf(position.x, 1420.0, main.room.room_size.x - 20.0)
	if state != "stunned" and hurt_rect().intersects(main.player.hitbox()):
		main.hurt_player(1, position.x)


func _next() -> void:
	var pool = ["walk", "windup", "chorus", "shout", "walk"]
	var a: String = pool[randi() % pool.size()]
	while a == last:
		a = pool[randi() % pool.size()]
	last = a
	state = a
	match a:
		"walk":
			tm = 1.2
		"windup":
			tm = 0.45
			Sound.play("whisper")
		"chorus":
			seq = 2
			tm = 0.35
		"shout":
			tm = 0.55
			Sound.play("charge")


func hit(dmg: int, hdir: int) -> bool:
	if state == "dormant" or state == "defeated":
		return false
	var mult = 2 if state == "stunned" else 1
	hp -= dmg * mult
	flash = 0.12
	Sound.play("ehit", 0.1)
	if mult == 2:
		main.fx.text_float(position + Vector2(0, -96), "x2", Color("#ffd2a8"), 0.8)
	if hp <= 0:
		hp = 0
		state = "defeated"
		velocity = Vector2.ZERO
		main.fx.projectiles.clear()
		Sound.play("defeat")
		main.get_tree().create_timer(1.2).timeout.connect(func(): main.resolve_carrier(self))
	return true


func _process(_d: float) -> void:
	rig.face = face
	match state:
		"defeated":
			rig.play("collapse")
		"stunned":
			rig.play("hurt")
		"windup", "shout", "chorus":
			rig.play("notice")
		"lunge":
			rig.play("lunge")
		"walk":
			rig.play("walk")
		_:
			rig.play("idle")
	rig.flash = clampf(flash * 6.0, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	if state == "defeated" or state == "dormant":
		return
	for i in 3:
		var a: float = main.t * (1.2 + i * 0.4) + i * 2.1
		var p = Vector2(cos(a) * 34.0, -70.0 + sin(a) * 16.0)
		draw_circle(p, 10.0, Color(0.6, 0.4, 1.0, 0.12))
		draw_circle(p, 4.0, Color(0.85, 0.75, 1.0, 0.6))
