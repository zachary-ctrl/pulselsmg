extends "res://scripts/enemies/ciencia.gd"
## Chapter Four boss: Dr. Ciencia wired into the science-fair exhibit he
## calls Collective Cognition. Fights like the Viral Saint, but keeps calling
## Choir imps out of the audience, and in phase two sends Static Riders
## charging across the stage.

var summon_t = 9.0
var rider_t = 6.0


func setup(pos: Vector2) -> void:
	super.setup(pos)
	kind = "collective"
	hp = 64
	max_hp = 64


func step(dt: float) -> void:
	super.step(dt)
	if state == "dormant" or state == "defeated":
		return
	summon_t -= dt
	if summon_t <= 0.0:
		summon_t = 11.0 if phase2 else 13.0
		var n = 0
		for e in main.ents:
			if is_instance_valid(e) and e.kind == "imp" and not e.dead:
				n += 1
		if n < 2:
			main.summon("imp", Vector2([160.0, 960.0][randi() % 2], 300.0))
			main.toast("The audience is listening")
	if phase2:
		rider_t -= dt
		if rider_t <= 0.0:
			rider_t = 12.0
			var left = main.player.position.x > 560.0
			main.summon("rider", Vector2(60.0 if left else 1060.0, 470.0))


func _phase2_extra() -> void:
	main.toast("COLLECTIVE COGNITION: 100% SYNCHRONIZED")
	Sound.play("u_laugh", 0.0, -2.0)


func _on_defeat() -> void:
	main.resolve_collective(self)


func _form() -> String:
	return "saint"


func _draw() -> void:
	super._draw()
	if state != "defeated" and state != "dormant":
		for i in 3:
			var r = 150.0 + i * 40.0 + sin(main.t * 2.0 + i) * 8.0
			draw_arc(Vector2(0, -60), r, 0, TAU, 60, Color(1, 0.4, 0.6, 0.06), 2.0)
