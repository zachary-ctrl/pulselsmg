@tool
extends Node2D
## A point or rectangle in a room that the game reacts to.
## Rect markers (exit, trigger, hazard) use `size` from the node position.

@export_enum("exit", "trigger", "bench", "npc", "anchor", "sigil", "spawn", "hazard", "worker") var kind: String = "trigger"
@export var size = Vector2(24, 24)
@export var target_room = ""
@export var spawn_point = Vector2.ZERO
@export var event = ""
@export var id = ""
@export var flag = ""
@export var dialog = ""
@export var dialog_repeat = ""
@export var face = 1
@export var astral = false
@export var enemy = ""
@export var patrol_range = 150.0

const EDITOR_COLORS := {"exit": Color(0.3, 1, 0.5, 0.35), "trigger": Color(1, 0.8, 0.2, 0.3), "hazard": Color(1, 0.2, 0.2, 0.35)}


func rect() -> Rect2:
	return Rect2(position, size)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	if kind in EDITOR_COLORS:
		draw_rect(Rect2(Vector2.ZERO, size), EDITOR_COLORS[kind])
	else:
		draw_circle(Vector2.ZERO, 10, Color(0.65, 0.55, 1, 0.8))
