extends StaticBody2D
## A door (open once a flag is set; astral form passes through) or an arena gate.

@export_enum("door", "gate") var kind: String = "door"
@export var flag = ""
@export_enum("echo_fight", "echo_unresolved", "ciencia_fight") var condition: String = "echo_fight"
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
			"ciencia_fight":
				on = main.fight_id() == "ciencia"
	if on != active:
		active = on
		$Shape.set_deferred("disabled", not on)
