extends Node2D
## The Red Tide: contaminated lab waste that remembers everyone who drank it.
## Lobs sludge, sends floor waves and raises the water. At half health Jason's
## water awakens: the tide turns clear and his pillars strike the core.

var main: Node
var id = "tide"
var kind = "tide"
var astral_only = false
var hp = 40
var max_hp = 40
var state = "dormant"
var tm = 0.0
var seq = 0
var last = ""
var flash = 0.0
var dead = false
var phase2 = false
var pillar_t = 3.0
var radius = 62.0
var surge = 0.0
var pillar_fx = 0.0


func setup(pos: Vector2) -> void:
	position = pos


func core() -> Vector2:
	return position + Vector2(0, -radius - 6.0 + sin(main.t * 1.6) * 5.0)


func hurt_rect() -> Rect2:
	var c = core()
	return Rect2(c - Vector2(radius, radius), Vector2(radius, radius) * 2.0)


func step(dt: float) -> void:
	flash = maxf(0.0, flash - dt)
	pillar_fx = maxf(0.0, pillar_fx - dt)
	if state == "dormant" or state == "defeated":
		main.set_tide(478.0)
		return
	tm -= dt
	if hp <= max_hp / 2 and not phase2:
		phase2 = true
		state = "idle"
		tm = 1.0
		surge = 0.0
		main.tide_awaken(self)
		return
	match state:
		"idle":
			if tm <= 0.0:
				_next()
		"arcs":
			if tm <= 0.0:
				if seq > 0:
					seq -= 1
					tm = 0.35
					var vx = clampf((main.player.position.x - position.x) / 1.0, -520.0, 520.0) + randf_range(-70, 70)
					main.fx.shoot(core(), Vector2(vx, -520.0), 9.0, "sludge", Color("#ff4a4a"), 900.0)
					Sound.play("throw")
				else:
					state = "idle"
					tm = 0.8
		"wave":
			if tm <= 0.0:
				for d in [-1, 1]:
					main.fx.shoot(position + Vector2(d * (radius + 10), -14), Vector2(d * 300.0, 0), 14.0, "wave", Color("#ff5050"))
				Sound.play("boom")
				state = "idle"
				tm = 1.0
		"surge":
			if tm > 3.0:
				surge = 0.0
			elif tm > 0.6:
				surge = minf(1.0, surge + dt * 2.5)
			else:
				surge = maxf(0.0, surge - dt * 2.0)
			if tm <= 0.0:
				surge = 0.0
				state = "idle"
				tm = 0.6
	main.set_tide(lerpf(478.0, 418.0, surge))
	if phase2:
		pillar_t -= dt
		if pillar_t <= 0.0:
			pillar_t = 3.4
			pillar_fx = 0.5
			hp -= 2
			flash = 0.15
			main.fx.burst(core(), 26, 320, Color("#7fd8ff"))
			Sound.play("beam")
			main.shake = 0.2
			if hp <= 0:
				_die()
	if main.player.position.distance_to(core()) < radius + 10.0:
		main.hurt_player(1, position.x)


func _next() -> void:
	var pool = ["arcs", "wave", "surge", "arcs"] if not phase2 else ["arcs", "wave", "arcs"]
	var a: String = pool[randi() % pool.size()]
	while a == last:
		a = pool[randi() % pool.size()]
	last = a
	state = a
	match a:
		"arcs":
			seq = 5 if phase2 else 4
			tm = 0.3
		"wave":
			tm = 0.5
			Sound.play("charge")
		"surge":
			tm = 4.0
			Sound.play("phase2")
			main.toast("The water is rising")


func hit(dmg: int, _hdir: int) -> bool:
	if state == "dormant" or state == "defeated":
		return false
	hp -= dmg
	flash = 0.12
	Sound.play("ehit", 0.1)
	if hp <= 0:
		_die()
	return true


func _die() -> void:
	hp = 0
	state = "defeated"
	surge = 0.0
	main.fx.projectiles.clear()
	Sound.play("defeat")
	main.get_tree().create_timer(1.2).timeout.connect(func(): main.resolve_tide(self))


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t: float = main.t
	var c = core() - position
	var r = radius * (0.6 if state == "defeated" else 1.0)
	var base = Color("#2a6f96") if phase2 else Color("#8a1219")
	var hi = Color("#9fe2ff") if phase2 else Color("#ff6a5a")
	if flash > 0.0:
		base = Color.WHITE
	for i in 4:
		draw_circle(c, r * (1.9 - i * 0.2), Color(hi, 0.04))
	var pts = PackedVector2Array()
	for i in 32:
		var a = TAU * i / 32.0
		var rr = r * (1.0 + 0.09 * sin(t * 3.0 + i * 1.3) + 0.05 * sin(t * 5.1 + i * 2.7))
		pts.append(c + Vector2(cos(a) * rr, sin(a) * rr * 1.1))
	draw_colored_polygon(pts, base)
	draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.3, Color(hi, 0.25))
	for i in 7:
		var rad = r * (0.22 + i * 0.1)
		var a0 = (t if i % 2 else -t) * (1 + i * 0.15) + i * 1.7
		draw_arc(c, rad, a0, a0 + TAU - (0.45 + (i % 3) * 0.35), 30, Color(1, 0.85, 0.85, 0.5) if not phase2 else Color(0.85, 0.95, 1, 0.55), 1.5)
	var o = 0.6 + 0.4 * sin(t * 1.7)
	draw_circle(c, 9.0 * o, Color("#fff2ee"))
	draw_circle(c, 3.5 * o, Color("#1a0505"))
	for i in 5:
		var x = c.x + (i - 2) * 22.0
		var ph = fmod(t * 0.8 + i * 0.37, 1.0)
		draw_circle(Vector2(x, c.y + r + ph * 50.0), 3.0, Color(hi, 1.0 - ph))
	if pillar_fx > 0.0:
		var k = pillar_fx / 0.5
		draw_rect(Rect2(c.x - 28, -540, 56, 560), Color(0.5, 0.85, 1.0, 0.45 * k))
		draw_rect(Rect2(c.x - 10, -540, 20, 560), Color(0.9, 0.98, 1.0, 0.9 * k))
