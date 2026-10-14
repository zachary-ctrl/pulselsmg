extends Node2D
## Dr. Ciencia. Phase 1: teleports, laser grids, molecule chains, thrown
## beakers. Phase 2 (half health): faster, adds horizontal beams and attacks
## aimed at where Max is about to be.

const Anim = preload("res://scripts/anim_sprite.gd")
const TELEPORT_POINTS := [Vector2(150, 470), Vector2(970, 470), Vector2(560, 340), Vector2(300, 320), Vector2(820, 320)]

var main: Node
var id = "boss"
var kind = "ciencia"
var astral_only = false
var hp = 36
var max_hp = 36
var state = "dormant"
var sub = ""
var tm = 0.0
var alpha = 1.0
var face = -1
var flash = 0.0
var stag = 0
var last = ""
var seq = 0
var phase2 = false
var base_y = 470.0
var dead = false
var rig: Node2D


func setup(pos: Vector2) -> void:
	position = pos
	base_y = pos.y
	rig = Anim.new()
	rig.key = "ciencia"
	add_child(rig)


func hurt_rect() -> Rect2:
	return Rect2(position.x - 17, position.y - 84, 34, 84)


func step(dt: float) -> void:
	flash = maxf(0.0, flash - dt)
	if state == "dormant" or state == "defeated":
		return
	tm -= dt
	var p2 = hp <= max_hp / 2
	if p2 and not phase2:
		phase2 = true
		Sound.play("phase2")
		main.toast("THE CHOIR IS LEARNING YOUR INPUTS")
		main.flash_screen(0.5, Color("#a58bff"))
		if not Game.flag("allSaved"):
			main.spawn_add()
	var pp: Vector2 = main.player.position
	face = int(signf(pp.x - position.x)) if pp.x != position.x else face
	match state:
		"idle":
			if tm <= 0.0:
				_next_attack(p2)
		"tpOut":
			alpha = maxf(0.0, alpha - dt * 3.5)
			if alpha <= 0.0:
				var pick: Vector2 = TELEPORT_POINTS[randi() % TELEPORT_POINTS.size()]
				var tries = 0
				while absf(pick.x - pp.x) < 180.0 and tries < 10:
					pick = TELEPORT_POINTS[randi() % TELEPORT_POINTS.size()]
					tries += 1
				position = pick
				base_y = pick.y
				state = "tpIn"
				main.fx.burst(position + Vector2(0, -40), 20, 200, Color("#7ff0ff"))
		"tpIn":
			alpha = minf(1.0, alpha + dt * 3.5)
			if alpha >= 1.0:
				state = "idle"
				tm = 0.35 if p2 else 0.6
		"grid":
			if sub == "warn" and tm <= 0.0:
				sub = "fire"
				tm = 0.38
				for b in main.fx.beams:
					b["on"] = true
				Sound.play("beam")
				main.shake = maxf(main.shake, 0.15)
			elif sub == "fire" and tm <= 0.0:
				main.fx.beams.clear()
				state = "idle"
				tm = 0.5 if p2 else 0.8
		"chain":
			if tm <= 0.0:
				state = "idle"
				tm = 0.4 if p2 else 0.7
		"mimic":
			if tm <= 0.0:
				if seq > 0:
					seq -= 1
					tm = 0.32
					var vx = clampf((pp.x - position.x) / 0.95, -620, 620)
					main.fx.shoot(position + Vector2(0, -60), Vector2(vx, -460), 8.0, "beaker", Color("#9ff0d0"), 960.0)
					Sound.play("throw")
				else:
					state = "idle"
					tm = 0.7
		"predict":
			if sub == "aim" and tm <= 0.0:
				sub = "boom"
				tm = 0.2
				var pr = main.fx.predict
				if pr != null:
					Sound.play("boom")
					main.shake = 0.25
					main.fx.burst(pr, 24, 400, Color("#ff7ad0"))
					if main.player.position.distance_to(pr + Vector2(0, 30)) < 68.0:
						main.hurt_player(1, pr.x)
					if main.astral_active() and main.astral.position.distance_to(pr + Vector2(0, 30)) < 68.0:
						main.hurt_astral()
				main.fx.predict = null
			elif sub == "boom" and tm <= 0.0:
				if seq > 0:
					seq -= 1
					_aim_predict()
				else:
					state = "idle"
					tm = 0.6
					main.predict_text = ""
		"stagger":
			position.y = move_toward(position.y, 470.0, 500.0 * dt)
			if tm <= 0.0:
				state = "tpOut"
				stag = 0
	if state != "stagger" and state != "tpOut" and state != "tpIn":
		position.y = base_y + (sin(main.t * 2.0) * 8.0 if base_y < 460.0 else 0.0)
	if alpha > 0.6 and state != "stagger" and hurt_rect().intersects(main.player.hitbox()):
		main.hurt_player(1, position.x)
	for b in main.fx.beams:
		if not b["on"]:
			continue
		for tgt in ([main.player, main.astral] if main.astral_active() else [main.player]):
			var hb: Rect2 = tgt.hitbox()
			var hit: bool = (absf(hb.get_center().x - b["x"]) < 20.0) if b["k"] == "v" else (absf(hb.get_center().y - b["y"]) < 22.0)
			if hit:
				if tgt == main.player:
					main.hurt_player(1, b.get("x", hb.get_center().x - 1))
				else:
					main.hurt_astral()


func _next_attack(p2: bool) -> void:
	var pool = ["grid", "chain", "predict", "mimic", "tp", "grid", "predict"] if p2 else ["grid", "chain", "mimic", "tp", "grid"]
	var a: String = pool[randi() % pool.size()]
	while a == last:
		a = pool[randi() % pool.size()]
	last = a
	var pp: Vector2 = main.player.position
	match a:
		"tp":
			state = "tpOut"
			Sound.play("glitch")
		"grid":
			state = "grid"
			sub = "warn"
			tm = 0.62 if p2 else 0.8
			main.fx.beams.clear()
			var xs = [pp.x]
			var n = 4 if p2 else 3
			var guard = 0
			while xs.size() < n and guard < 40:
				guard += 1
				var x = clampf(pp.x + randf_range(-400, 400), 50, 1070)
				var ok = true
				for v in xs:
					if absf(v - x) < 110.0:
						ok = false
				if ok:
					xs.append(x)
			for x in xs:
				main.fx.beams.append({"k": "v", "x": x, "on": false})
			if p2:
				main.fx.beams.append({"k": "h", "y": pp.y - 29.0, "on": false})
			Sound.play("charge")
		"chain":
			state = "chain"
			tm = 1.3
			var d = signf(pp.x - position.x) if pp.x != position.x else 1.0
			main.fx.chain(position.x, d * (360.0 if p2 else 300.0))
			Sound.play("chain")
		"mimic":
			state = "mimic"
			seq = 3
			tm = 0.2
		"predict":
			state = "predict"
			seq = 2
			_aim_predict()


func _aim_predict() -> void:
	var p: Node = main.player
	main.fx.predict = Vector2(clampf(p.position.x + p.velocity.x * 0.55, 40, 1080), clampf(p.position.y - 30 + p.velocity.y * 0.18, 120, 450))
	sub = "aim"
	tm = 0.62
	Sound.play("lock")
	main.predict_text = "PREDICTED: " + ["JUMP", "DASH", "STRIKE", "RETREAT", "HESITATE"][randi() % 5]


func hit(dmg: int, _hdir: int) -> bool:
	if state == "dormant" or state == "defeated" or alpha < 0.5:
		return false
	hp -= dmg
	flash = 0.12
	stag += 1
	if stag >= 9 and state != "stagger" and hp > 0:
		state = "stagger"
		tm = 1.7
		main.fx.beams.clear()
		main.fx.predict = null
		main.predict_text = ""
		main.toast("Dr. Ciencia staggers")
		Sound.play("stagger")
	if hp <= 0:
		hp = 0
		state = "defeated"
		position.y = 470.0
		alpha = 1.0
		main.fx.beams.clear()
		main.fx.predict = null
		main.fx.projectiles.clear()
		main.predict_text = ""
		Sound.play("defeat")
		main.get_tree().create_timer(0.9).timeout.connect(func(): main.resolve_ciencia(self))
	return true


func _process(_d: float) -> void:
	rig.key = "saint" if phase2 else "ciencia"
	rig.face = face
	match state:
		"defeated":
			rig.play("kneel")
		"stagger":
			rig.play("stagger")
		"tpOut":
			rig.seek("teleport", (1.0 - alpha) * 0.6)
		"tpIn":
			rig.seek("teleport", 0.6 + alpha * 0.4)
		"grid", "predict":
			rig.play("cast")
		"mimic", "chain":
			rig.play("throw")
		_:
			rig.play("idle")
	rig.alpha = maxf(alpha, 0.35) if state in ["tpOut", "tpIn"] else 1.0
	rig.flash = clampf(flash * 6.0, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	for i in 4:
		draw_circle(Vector2(0, -50), 110.0 - i * 22, Color(0.25, 1, 0.82, 0.03 * alpha))
	if base_y < 460.0 and state != "defeated":
		var sh = PackedVector2Array()
		for i in 17:
			var a = TAU * i / 16.0
			sh.append(Vector2(cos(a) * 26, 470.0 - position.y + sin(a) * 4))
		draw_colored_polygon(sh, Color(0, 0, 0, 0.25 * alpha))
	if state != "defeated" and state != "dormant" and alpha > 0.5:
		for i in 7:
			var rad = 26.0 * (0.28 + i * 0.12)
			var a0: float = (main.t if i % 2 else -main.t) * (1 + i * 0.15) + i * 1.7
			draw_arc(Vector2(0, -110), rad, a0, a0 + TAU - (0.45 + (i % 3) * 0.35), 30, Color(0.5, 0.94, 1, 0.45), 1.2)
