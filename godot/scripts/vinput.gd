extends RefCounted
## The player's buttons, sampled once per physics frame so "just pressed"
## stays consistent inside one control() step.

const ACTIONS := ["left", "right", "up", "down", "jump", "attack", "kick", "laser", "dash", "heal", "project", "fp", "transform"]

var _now = {}
var _prev = {}


func tick() -> void:
	_prev = _now
	_now = {}
	for a in ACTIONS:
		_now[a] = Input.is_action_pressed(a)


func pressed(a: String) -> bool:
	return _now.get(a, false)


func just(a: String) -> bool:
	return _now.get(a, false) and not _prev.get(a, false)
