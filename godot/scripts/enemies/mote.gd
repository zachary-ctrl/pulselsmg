extends Node2D
## A Choir Mote: a floating eye ringed by broken circles. Drifts toward
## whoever Max is right now (body or astral form) and fires slow orbs.

var main: Node
var id = ""
var kind = "mote"
var astral_only = true
var home = Vector2.ZERO
var vel = Vector2.ZERO
var hp = 3
var shoot = 2.0
var flash = 0.0
var seed = 0.0
var dead = false


func setup(sid: String, pos: Vector2) -> void:
	id = sid
	position = pos
	home = pos
	shoot = 2.0 + randf() * 2.0
	seed = randf() * 10.0


func hurt_rect() -> Rect2:
	return Rect2(position - Vector2(15, 15), Vector2(30, 30))


func step(dt: float) -> void:
	flash = maxf(0.0, flash - dt)
	var c: Node = main.ctrl()
	var target: Vector2 = c.position + Vector2(0, -30)
	var d = position.distance_to(target)
	if d < 440.0:
		var a = (target - position).angle()
		vel = vel.move_toward(Vector2(cos(a), sin(a)) * 85.0, 200.0 * dt)
	else:
		vel = vel.move_toward((home - position) * 0.5, 100.0 * dt)
	position += vel * dt + Vector2(0, sin(main.t * 2.0 + seed) * 0.4)
	shoot -= dt
	if shoot <= 0.0 and d < 520.0:
		shoot = 2.8
		main.fx.shoot(position, (target - position).normalized() * 210.0, 7.0, "orb", Color("#c9b8ff"))
		Sound.play("zap")
	var box = Rect2(position.x - 12, position.y - 15, 24, 30)
	if box.intersects(main.player.hitbox()):
		main.hurt_player(1, position.x)
	if main.astral_active() and box.intersects(main.astral.hitbox()):
		main.hurt_astral()


func hit(dmg: int, hdir: int) -> bool:
	hp -= dmg
	flash = 0.12
	vel.x += hdir * 220.0
	if hp <= 0:
		dead = true
		Game.set_flag("down_" + id, true)
		Sound.play("pop")
		main.enemy_defeated(self, 10)
		main.fx.burst(position, 20, 260, Color("#c9b8ff"))
	return true


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t: float = main.t + seed
	for i in 4:
		draw_circle(Vector2.ZERO, 40.0 - i * 8, Color(0.65, 0.55, 1, (0.55 if shoot < 0.6 else 0.3) * 0.18))
	for i in 5:
		var a = i / 5.0 * TAU + t
		var pts = PackedVector2Array([Vector2(cos(a), sin(a)) * 10, Vector2(cos(a + 0.5), sin(a + 0.5)) * 22, Vector2(cos(a + 0.2) * 30 + sin(t * 3 + i) * 3, sin(a + 0.2) * 30)])
		draw_polyline(pts, Color(0.82, 0.75, 1, 0.7), 1.2)
	draw_circle(Vector2.ZERO, 13, Color.WHITE if flash > 0 else Color("#100c1c"))
	draw_arc(Vector2.ZERO, 13, 0, TAU, 32, Color("#d8c9ff"), 1.4)
	var o = 0.6 + 0.4 * sin(t * 1.7)
	var eye = PackedVector2Array()
	for i in 13:
		var a = PI * i / 12.0
		eye.append(Vector2(-cos(a) * 8, -sin(a) * 7 * o))
	for i in 13:
		var a = PI * i / 12.0
		eye.append(Vector2(cos(a) * 8, sin(a) * 7 * o))
	draw_colored_polygon(eye, Color("#f2ecff"))
	var c: Node = main.ctrl()
	var look = (c.position + Vector2(0, -30) - global_position).angle()
	draw_circle(Vector2(cos(look) * 2.5, sin(look) * 1.5), 2.6 * o, Color("#1a0a2a"))
