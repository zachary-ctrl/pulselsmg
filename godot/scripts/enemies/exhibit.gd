extends Node2D
## A science-fair exhibit Ciencia rewired into a Choir broadcaster. It pulses
## a damaging ring; break all three to open the way to the stage.

const TITLES := ["DO PLANTS DREAM?", "THE HIVE MIND (OF BEES)", "ONE BRAIN, MANY HEADS"]

var main: Node
var id = ""
var kind = "exhibit"
var astral_only = false
var hp = 8
var max_hp = 8
var dead = false
var broken = false
var flash = 0.0
var pulse = 2.0
var ring = -1.0
var title = ""


func setup(sid: String, pos: Vector2) -> void:
	id = sid
	position = pos
	broken = Game.flag("down_" + sid)
	title = TITLES[(int(sid.substr(1)) - 1) % TITLES.size()] if sid.length() > 1 else TITLES[0]
	pulse = 1.0 + randf() * 2.0


func hurt_rect() -> Rect2:
	return Rect2(position.x - 34, position.y - 58, 68, 58)


func step(dt: float) -> void:
	flash = maxf(0.0, flash - dt)
	if broken:
		return
	pulse -= dt
	if pulse <= 0.0:
		pulse = 3.2
		ring = 0.0
		Sound.play("zap", 0.1, -8.0)
	if ring >= 0.0:
		ring += dt * 220.0
		var pc: Vector2 = main.player.position + Vector2(0, -30)
		var d = pc.distance_to(position + Vector2(0, -30))
		if absf(d - ring) < 14.0:
			main.hurt_player(1, position.x)
		if ring > 150.0:
			ring = -1.0


func hit(dmg: int, _hdir: int) -> bool:
	if broken:
		return false
	hp -= dmg
	flash = 0.12
	Sound.play("glass", 0.1, -4.0)
	if hp <= 0:
		broken = true
		Game.set_flag("down_" + id)
		Game.flags["exhibits"] = int(Game.flags.get("exhibits", 0)) + 1
		Sound.play("stabilize")
		Sound.play("tp_impact_metal", 0.1, -8.0)
		main.shake = 0.25
		main.fx.burst(position + Vector2(0, -40), 30, 320, Color("#ff9ad8"))
		main.toast("Exhibit silenced (%d / 3)" % Game.flags["exhibits"])
		main.enemy_defeated(self, 20)
		if int(Game.flags["exhibits"]) >= 3:
			main.say([["jason", "smirk", "That's all three. The stage door just unlocked. I heard it. Through the water pipes. Don't ask."]])
	return true


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t: float = main.t if main else 0.0
	var on = not broken
	draw_rect(Rect2(-40, -6, 80, 6), Color("#2a1e18"))
	var panels = [Rect2(-38, -60, 22, 54), Rect2(-16, -64, 32, 58), Rect2(16, -60, 22, 54)]
	for p in panels:
		draw_rect(p, Color("#e9e1d0") if on else Color("#6a645a"))
		draw_rect(p, Color("#3a2e28"), false, 1.0)
	draw_rect(Rect2(-12, -58, 24, 8), Color("#ff6aa8") if on else Color("#4a3a40"))
	draw_string(Game.font_semi, Vector2(-40, -70), title, HORIZONTAL_ALIGNMENT_LEFT, 80, 8, Color(1, 0.85, 0.95, 0.9 if on else 0.4))
	if on:
		for i in 7:
			var rad = 22.0 * (0.28 + i * 0.12)
			var a0 = (t if i % 2 else -t) * (1 + i * 0.2) + i * 1.7
			draw_arc(Vector2(0, -34), rad, a0, a0 + TAU - 0.6, 24, Color(1, 0.45, 0.75, 0.7), 1.4)
		if ring >= 0.0:
			draw_arc(Vector2(0, -30), ring, 0, TAU, 64, Color(1, 0.4, 0.7, 0.8 * (1.0 - ring / 150.0)), 6.0)
		if flash > 0.0:
			draw_rect(Rect2(-40, -66, 80, 66), Color(1, 1, 1, flash * 4.0))
	else:
		draw_line(Vector2(-30, -50), Vector2(24, -14), Color("#2a2020"), 2.0)
