extends Node2D
## A party member fighting beside the player in boss battles. Keeps a spot
## on the player's side of the boss, darts in to strike, and uses their
## special every few seconds. Allies can't be hurt.

const Anim = preload("res://scripts/anim_sprite.gd")
const Aura = preload("res://scripts/aura.gd")

var main: Node
var hero = "lana"
var slot = 0
var rig: Node2D
var aura: Node2D
var face = 1
var state = "move"
var tm = 1.2
var special_t = 5.0
var vy = 0.0
var hit_done = false
var strike_t = 0.0


func _ready() -> void:
	aura = Aura.new()
	aura.color = Game.HEROES[hero]["aura"]
	add_child(aura)
	rig = Anim.new()
	rig.key = hero
	add_child(rig)
	special_t = 4.0 + slot * 2.5
	tm = 0.8 + slot * 0.6


func _boss() -> Node:
	var f = main.fight
	if f == null or not is_instance_valid(f["e"]):
		return null
	return f["e"]


func _dmg() -> int:
	return int(Game.HEROES[hero]["dmg"]) + int(Game.prog["level"] / 6)


func tick(dt: float) -> void:
	var b = _boss()
	if b == null:
		return
	var bc: Vector2 = b.hurt_rect().get_center()
	var side = signf(main.player.position.x - b.position.x)
	if side == 0:
		side = -1
	var run: float = Game.HEROES[hero]["run"] * 0.85
	tm -= dt
	special_t -= dt
	strike_t = maxf(0.0, strike_t - dt)
	var want_x: float = b.position.x + side * (150.0 + slot * 55.0)
	match state:
		"move":
			position.x = move_toward(position.x, want_x, run * dt)
			if tm <= 0.0:
				state = "dash"
				hit_done = false
		"dash":
			position.x = move_toward(position.x, b.position.x + side * 46.0, run * 2.2 * dt)
			if absf(position.x - (b.position.x + side * 46.0)) < 6.0:
				state = "strike"
				strike_t = 0.3
				if b.hit(_dmg(), int(-side)):
					main.fx.burst(bc, 12, 300, Color(Game.HEROES[hero]["col"]))
					Sound.play("hit", 0.1, -4.0)
				else:
					Sound.play("slash", 0.1, -6.0)
		"strike":
			if strike_t <= 0.0:
				state = "move"
				tm = randf_range(1.6, 2.6)
	position.x = clampf(position.x, 20.0, main.room.room_size.x - 20.0)
	var fl: Vector2 = main.room.floor_below(Vector2(position.x, position.y - 60.0))
	if fl.y < position.y - 4.0:
		vy = -420.0
	vy += 1800.0 * dt
	position.y = minf(position.y + vy * dt, fl.y)
	if position.y >= fl.y:
		vy = 0.0
	face = int(signf(b.position.x - position.x)) if b.position.x != position.x else face
	if special_t <= 0.0 and state == "move":
		special_t = randf_range(6.5, 8.5)
		_special(b, bc)


func _special(b: Node, bc: Vector2) -> void:
	var col = Color(Game.HEROES[hero]["col"])
	aura.target = 1.0
	get_tree().create_timer(0.8).timeout.connect(func(): if is_instance_valid(self): aura.target = 0.0)
	match hero:
		"max":
			var from: Vector2 = position + Vector2(face * 26, -40)
			main.fx.lasers.append({"a": from, "b": bc, "life": 0.3, "max": 0.3, "c": Color(0.75, 0.55, 1.0), "k": "laser"})
			Sound.play("beam", 0.05, -3.0)
			b.hit(3, face)
		"lana":
			main.fx.rings.append({"p": position + Vector2(0, -34), "r": 10.0, "life": 0.45, "max": 0.45, "c": col})
			main.fx.text_float(position + Vector2(0, -90), ["HEY. UGLY.", "LOOK AT ME", "NOT TODAY"][randi() % 3], Color("#ffd0c8"), 1.3)
			Sound.play("boom", 0.05, -4.0)
			if position.distance_to(b.position) < 260.0:
				b.hit(2, face)
			strike_t = 0.3
		"jason":
			main.fx.projectiles.append({"p": position + Vector2(face * 30, -14), "v": Vector2(face * 520, 0), "r": 22.0, "k": "pwave", "c": col,
				"life": 1.4, "grav": 0.0, "rot": 0.0, "friendly": true, "pierce": true, "dmg": 3, "hits": {}})
			Sound.play("splash", 0.05, -3.0)


func _process(_d: float) -> void:
	if rig == null:
		return
	rig.face = face
	match state:
		"strike":
			rig.seek("strike", 1.0 - strike_t / 0.3)
		"dash":
			rig.play("dash" if Anim.has_anim(hero, "dash") else "run")
		_:
			if vy != 0.0:
				rig.seek("jump", 0.5)
			elif Anim.has_anim(hero, "run") and main.fight != null and _boss() != null and absf(position.x - (_boss().position.x + signf(main.player.position.x - _boss().position.x) * (150.0 + slot * 55.0))) > 8.0:
				rig.play("run")
			else:
				rig.play("idle")
	queue_redraw()


func _draw() -> void:
	var c = Color(Game.HEROES[hero]["col"])
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -86), Vector2(5, -86), Vector2(0, -79)]), Color(c, 0.85))
	var sh = PackedVector2Array()
	for i in 17:
		var a = TAU * i / 16.0
		sh.append(Vector2(cos(a) * 16, sin(a) * 3.5))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.3))
