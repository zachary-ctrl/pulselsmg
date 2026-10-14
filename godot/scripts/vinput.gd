extends RefCounted
## Where a player's buttons come from. "local" reads the normal input map
## (player 1); "pad" reads one specific controller through the same
## bindings (couch co-op player 2); "remote" uses the button state sent over
## the network by an online partner. Call tick() once per physics frame.

const ACTIONS := ["left", "right", "up", "down", "jump", "attack", "kick", "laser", "dash", "heal", "project", "fp", "transform"]

var source = "local"
var device = 1
var remote_bits = 0
var _now = {}
var _prev = {}


func tick() -> void:
	_prev = _now
	_now = {}
	for i in ACTIONS.size():
		var a: String = ACTIONS[i]
		var on = false
		match source:
			"local":
				on = Input.is_action_pressed(a)
			"pad":
				on = _pad_pressed(a)
			"remote":
				on = (remote_bits >> i) & 1 == 1
		_now[a] = on


func pressed(a: String) -> bool:
	return _now.get(a, false)


func just(a: String) -> bool:
	return _now.get(a, false) and not _prev.get(a, false)


## Bitmask of the current local buttons (what an online guest sends).
static func local_bits() -> int:
	var b = 0
	for i in ACTIONS.size():
		if Input.is_action_pressed(ACTIONS[i]):
			b |= 1 << i
	return b


func _pad_pressed(a: String) -> bool:
	var codes: Array = Game.settings["bind"].get(a, {}).get("p", [])
	for c in codes:
		if c.begins_with("b"):
			if Input.is_joy_button_pressed(device, int(c.substr(1))):
				return true
		else:
			var ax = int(c.substr(1, c.length() - 2))
			var v = Input.get_joy_axis(device, ax)
			if (c.ends_with("+") and v > 0.5) or (c.ends_with("-") and v < -0.5):
				return true
	var stick = {"left": [0, -1], "right": [0, 1], "up": [1, -1], "down": [1, 1]}
	if stick.has(a):
		return Input.get_joy_axis(device, stick[a][0]) * stick[a][1] > 0.5
	return false
