extends StaticBody2D
## A door (open once a flag is set; astral form passes through) or an arena gate.

@export_enum("door", "gate") var kind: String = "door"
@export var flag = ""
@export_enum("echo_fight", "echo_unresolved", "ciencia_fight", "carrier_fight", "tide_fight", "rescue_incomplete", "collective_fight", "exhibits_incomplete", "elite_alive") var condition: String = "echo_fight"
@export var size = Vector2(22, 172)
var active = true


func rect() -> Rect2:
	return Rect2(position - size / 2.0, size)


func refresh(main: Node) -> void:
	var on = true
	if kind == "door":
		on = not Game.flag(flag)
	else:
		match condition:
			"echo_fight":
				on = main.fight_id() == "echo"
			"echo_unresolved":
				on = not Game.flag("echoDone")
			"ciencia_fight", "carrier_fight", "tide_fight", "collective_fight":
				on = main.fight_id() == condition.trim_suffix("_fight")
			"rescue_incomplete":
				on = int(Game.flags.get("rescued", 0)) < 3
			"exhibits_incomplete":
				on = int(Game.flags.get("exhibits", 0)) < 3
			"elite_alive":
				on = not Game.flag("down_" + flag)
	if on != active:
		active = on
		$Shape.set_deferred("disabled", not on)
