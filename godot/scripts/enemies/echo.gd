extends Node2D
## The Hallway Echo: replays Max's own path a second behind him.

const Rig = preload("res://scripts/rig.gd")

var main: Node
var id = "echo"
var kind = "echo"
var astral_only = false
var hp = 14
var max_hp = 14
var state = "rise"
var tm = 1.2
var lag = 0.0
var face = -1
var flash = 0.0
var dead = false
var pose = {}
var rig: Node2D
var ghosts: Array = []
var trail: Array = []


func setup(pos: Vector2) -> void:
	position = pos
	rig = Rig.new()
	rig.key = "max"
	rig.tint = Color(0.04, 0.05, 0.09, 0.96)
	rig.eyes = "echo"
	for i in 4:
		var g = Rig.new()
		g.key = "max"
		g.tint = Color(0.56, 0.45, 1.0, 0.82)
		g.alpha = 0.04 + i * 0.035
		ghosts.append(g)
		add_child(g)
	add_child(rig)


func hurt_rect() -> Rect2:
	return Rect2(position.x - 12, position.y - 58, 24, 58)


func step(dt: float) -> void:
	flash = maxf(0.0, flash - dt)
	if state == "rise":
		tm -= dt
		if tm <= 0.0:
			state = "follow"
			tm = 4.2
		return
	lag = maxf(0.0, lag - dt * 0.4)
	tm -= dt
	if state == "stutter":
		if tm <= 0.0:
			state = "follow"
			tm = 4.2
			var origin = position + Vector2(0, -30)
			var aim: float = (main.player.position + Vector2(0, -30) - origin).angle()
			for i in [-1, 0, 1]:
				var a: float = aim + i * 0.28
				main.fx.shoot(origin, Vector2(cos(a), sin(a)) * 330.0, 6.0, "shard", Color("#9fb6ff"))
			Sound.play("shards")
		return
	if tm <= 0.0:
		state = "stutter"
		tm = 0.7
		Sound.play("rewind")
		return
	var delay = 1.15 - (1.0 - float(hp) / max_hp) * 0.4 + lag
	var tt: float = main.t - delay
	var smp = null
	for i in range(main.hist.size() - 1, -1, -1):
		if main.hist[i]["t"] <= tt:
			smp = main.hist[i]
			break
	if smp:
		position = position.lerp(smp["pos"], minf(1.0, dt * 14.0))
		face = smp["face"]
		pose = smp
	trail.append({"p": position, "face": face, "pose": pose})
	if trail.size() > 18:
		trail.pop_front()
	if hurt_rect().intersects(main.player.hitbox()):
		main.hurt_player(1, position.x)


func hit(dmg: int, _hdir: int) -> bool:
	if state == "rise":
		return false
	hp -= dmg
	flash = 0.12
	lag += 0.22
	if hp <= 0:
		hp = 0
		main.resolve_echo(self)
	return true


func _process(_d: float) -> void:
	var a = 1.0 - tm / 1.2 if state == "rise" else 1.0
	var p = {"face": face, "t": main.t, "ph": pose.get("ph", 0.0), "moving": pose.get("moving", false), "air": pose.get("air", false), "vy": pose.get("vy", 0.0), "eyes": "echo"}
	rig.pose = p
	rig.alpha = clampf(a, 0.0, 1.0) * ((0.4 if randf() < 0.5 else 1.0) if state == "stutter" else 1.0)
	rig.position.x = randf_range(-3, 3) if state == "stutter" else 0.0
	rig.flash = clampf(flash * 6.0, 0.0, 1.0)
	for i in ghosts.size():
		var idx = i * 4
		if idx < trail.size():
			var tr: Dictionary = trail[idx]
			ghosts[i].visible = true
			ghosts[i].position = tr["p"] - position
			ghosts[i].pose = {"face": tr["face"], "t": main.t, "ph": tr["pose"].get("ph", 0.0), "moving": tr["pose"].get("moving", false), "air": tr["pose"].get("air", false), "vy": tr["pose"].get("vy", 0.0)}
		else:
			ghosts[i].visible = false
	queue_redraw()


func _draw() -> void:
	for i in 4:
		draw_circle(Vector2(0, -30), 60.0 - i * 12, Color(0.44, 0.53, 1, 0.04))
