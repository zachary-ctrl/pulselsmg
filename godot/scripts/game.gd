extends Node
## Global state: story flags, abilities, choice tendencies, saves, input map,
## fonts, and the chapter's dialogue and lore text.

const SAVE_PATH := "user://sakawa_save.json"

var flags = {}
var ability = {"project": false, "double": false}
var tend = {"connection": 0, "control": 0, "rupture": 0}
var witness = 0
var overdraw = 0
var anchors = {}
var visited = {}
var save_data = null
var touch_mode = false

var font_display: Font
var font_body: Font
var font_italic: Font
var font_semi: Font

const ROOM_SCENES := {
	"classroom": "res://scenes/rooms/classroom.tscn",
	"hallway": "res://scenes/rooms/hallway.tscn",
	"cafeteria": "res://scenes/rooms/cafeteria.tscn",
	"lab": "res://scenes/rooms/lab.tscn",
}

const ANCH := {
	"momText": {"title": "Text · Mom · 3:12 PM", "body": "School called. They said lunch was \"weird\"? Eat something. Love you. Dad says bring back his charger."},
	"unknownText": {"title": "Text · Unknown · arrived 3:58 PM, sent 4:01 PM", "body": "Look at the sun, Max."},
	"receipt": {"title": "Receipt · Cafeteria · Yesterday", "body": "412 lunches served. 0 eaten. Staff note scribbled on the back: \"kids just stared at the trays like they were listening to them.\""},
	"dharmaNote": {"title": "Letter · The Dharma Order", "body": "Dr. Ciencia: your access is revoked. The Order funds adaptation, not receivers. Whatever you are listening to is listening back."},
	"levitation": {"title": "Memory Anchor · Levitation", "body": "Your body remembers what your mind just learned. Press JUMP again in midair to levitate once.", "ability": "double"},
}

const N := "narr"
const DLG := {
	"intro": [[N, "", "Room 101. Last period. Dr. Ciencia was fired three days ago."], [N, "", "Since then, nobody at Westbrook High has eaten. Not one tater tot."],
		["max", "worried", "Okay. Thirty kids. Thirty full lunch trays. Nobody is touching the tots. That is not a vibe. That is a crime scene."],
		["max", "neutral", "Devon? You good, man? ...Devon is drawing circles again. Seven of them. Every one broken."],
		["max", "worried", "Cool. Cool cool cool. I am gonna go find literally any adult."], [N, "", "Move with {move}. Jump with {jump}. Dash with {dash}."]],
	"firstProjection": [["max", "worried", "Why is my head ringing? Why is everything so loud and so quiet at the same time—"],
		["choir", "", "WE SEE YOU SEEING US."],
		["max", "shocked", "I am floating. I am OUTSIDE my body. My body is right there. It has a really dumb look on its face."],
		["max", "worried", "There is a second classroom on top of this one. Same desks. Wrong angles."],
		[N, "", "ASTRAL PROJECTION awakened. Press {project} to leave your body, and again to return. You have about sixty seconds before it gets dangerous."],
		[N, "", "Your astral self passes through doors and touches what is hidden. Your body stays behind, and anything can reach it there."]],
	"doorLocked": [["max", "neutral", "Chained from the hallway side. My hands cannot fix that. My brain, maybe."]],
	"lana1": [["lana", "smirk", "Inoki! You are alive. And chewing-capable? Prove it."], ["max", "neutral", "Lana. Everybody is acting weird. Like, weirder than me."],
		["lana", "smirk", "Bar is on the floor, man. Coach Reyes stood in the gym for two hours whispering \"seven.\" I asked if he meant laps."],
		["lana", "neutral", "The zombies — sorry, \"infected,\" my mom says be sensitive — they flip when you get in their face. Hit them with something real and they drop."],
		["max", "worried", "I can kind of... push things. With my brain. Since today."], ["lana", "shocked", "Since TODAY? And you are telling me in a HALLWAY?"],
		["lana", "smirk", "Fine. Push them gently. They are still Brayden and them. Even Brayden."],
		[N, "", "Strike with {attack}. Hold UP or DOWN while striking to aim. Each hit builds RESONANCE."],
		[N, "", "Hold {heal} while standing still to focus Resonance into healing. Rest at benches to save."],
		["lana", "neutral", "I will hold the hallway. You find whatever is making this school forget how to eat."]],
	"lana2": [["lana", "smirk", "Still here. Still the only person in this building with snacks. Go."]],
	"echoIntro": [[N, "", "A student-shaped silhouette walks exactly where you walked. A second late. Always late."], ["max", "worried", "Is that... me? Why does it look embarrassed?"]],
	"jason1": [["jason", "smirk", "Inoki. Figures you would be wandering around while somebody actually handles this."], ["max", "neutral", "Handles it how? You are standing in the cafeteria."],
		["jason", "neutral", "Strategic position. Food supply. Central exits. You would not get it."], ["jason", "worried", "...Every tray is full, man. My little brother did not eat breakfast. Or dinner."],
		["max", "neutral", "Ciencia's old lab is up there. Past the balcony."], ["jason", "smirk", "\"Up there\" is a fifteen-foot wall and you can barely do a pull-up."],
		["max", "smirk", "Yeah. I am working on something."], [N, "", "Some ledges are too high for your body. Your mind does not have that problem."]],
	"jason2": [["jason", "neutral", "When this is over, I am telling the whole student council I handled it. Just so you know."]],
	"cienciaIntro": [["ciencia", "neutral", "Mr. Inoki. You projected in my classroom. Did you think I would not feel it?"],
		["max", "worried", "Dr. Ciencia? You got fired. Why are you in the basement in the lab coat? That is the saddest thing I have ever seen."],
		["ciencia", "angry", "I was RELIEVED of a school. I have been given a town."],
		["ciencia", "smile", "Your classmates are not sick. They are listening. For the first time in history, everyone hears the same thing."],
		["max", "angry", "They stopped EATING."], ["ciencia", "smile", "Hunger is an individual opinion. We are moving past opinions."]],
	"cienciaAllSaved": [["ciencia", "worried", "...You stabilized them. Every one. How unhelpfully kind."]],
	"cienciaSomeSaved": [["ciencia", "smirk", "You left some of them listening. Good. They will keep me company."]],
	"cienciaGo": [["ciencia", "angry", "Let me show you what a mind is for."]],
	"ending": [["lana", "shocked", "Max! Your nose is bleeding. Also you are glowing? Also what did you DO to Dr. C?"], ["jason", "worried", "Is it over? Tell me it is over."],
		["max", "worried", "Every one of them was looking at the same thing. Down there, in the dark. A black sun."],
		[N, "", "Three weeks later, rain falls on a clear day."], [N, "", "Jason hears hundreds of voices inside a puddle. One of them says his name from beneath the water."]],
}

const PORTRAIT := {
	"max": {"neutral": "max_0", "worried": "max_1", "shocked": "max_1", "smile": "max_2", "smirk": "max_2", "angry": "max_0", "sad": "max_0"},
	"lana": {"smile": "lana_0", "smirk": "lana_1", "neutral": "lana_1", "angry": "lana_2", "shocked": "lana_2", "worried": "lana_2", "sad": "lana_2"},
	"jason": {"smirk": "jason_0", "smile": "jason_0", "neutral": "jason_2", "worried": "jason_1", "angry": "jason_1", "shocked": "jason_1", "sad": "jason_1"},
	"ciencia": {"*": "ciencia_0"},
	"choir": {"*": "choir_0"},
}
const SPEAKER := {"max": "MAX INOKI", "lana": "LANA", "jason": "JASON", "ciencia": "DR. CIENCIA", "choir": "THE CHOIR"}

var _portraits = {}


func _ready() -> void:
	_setup_input()
	touch_mode = DisplayServer.is_touchscreen_available()
	var cinzel: FontFile = load("res://assets/fonts/Cinzel.ttf")
	var display = FontVariation.new()
	display.base_font = cinzel
	display.variation_embolden = 0.55
	font_display = display
	font_body = load("res://assets/fonts/Spectral-Regular.ttf")
	font_italic = load("res://assets/fonts/Spectral-Italic.ttf")
	font_semi = load("res://assets/fonts/Spectral-SemiBold.ttf")


func portrait(who: String, expr: String) -> Texture2D:
	if not PORTRAIT.has(who):
		return null
	var m: Dictionary = PORTRAIT[who]
	var key: String = m.get(expr, m.get("neutral", m.get("*", "")))
	if key == "":
		return null
	if not _portraits.has(key):
		_portraits[key] = load("res://assets/portraits/%s.png" % key)
	return _portraits[key]


func flag(name: String) -> bool:
	return bool(flags.get(name, false))


func set_flag(name: String, value = true) -> void:
	flags[name] = value


func label(action: String) -> String:
	if touch_mode:
		return {"jump": "JUMP", "attack": "STRIKE", "dash": "DASH", "heal": "FOCUS", "project": "PROJECT", "fp": "FULL", "up": "▲", "move": "◀ ▶"}.get(action, action)
	if Input.get_connected_joypads().size() > 0:
		return {"jump": "A", "attack": "X", "dash": "RB", "heal": "LB", "project": "Y", "fp": "B", "up": "Up", "move": "the left stick"}.get(action, action)
	return {"jump": "Space", "attack": "X", "dash": "C", "heal": "Q", "project": "E", "fp": "R", "up": "W", "move": "A / D"}.get(action, action)


func fill(text: String) -> String:
	for a in ["move", "jump", "dash", "attack", "heal", "project", "fp", "up"]:
		text = text.replace("{%s}" % a, "[" + label(a) + "]")
	return text


func _setup_input() -> void:
	var keys = {
		"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE, KEY_Z], "attack": [KEY_X, KEY_J], "dash": [KEY_C, KEY_K, KEY_SHIFT], "heal": [KEY_Q, KEY_F],
		"project": [KEY_E, KEY_P], "fp": [KEY_R], "confirm": [KEY_ENTER, KEY_KP_ENTER], "pause": [KEY_ESCAPE],
	}
	var pads = {
		"left": [JOY_BUTTON_DPAD_LEFT], "right": [JOY_BUTTON_DPAD_RIGHT], "up": [JOY_BUTTON_DPAD_UP], "down": [JOY_BUTTON_DPAD_DOWN],
		"jump": [JOY_BUTTON_A], "attack": [JOY_BUTTON_X], "dash": [JOY_BUTTON_RIGHT_SHOULDER], "heal": [JOY_BUTTON_LEFT_SHOULDER],
		"project": [JOY_BUTTON_Y], "fp": [JOY_BUTTON_B], "confirm": [JOY_BUTTON_A], "pause": [JOY_BUTTON_START],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.35)
		for k in keys[action]:
			var ev = InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
		for b in pads.get(action, []):
			var jb = InputEventJoypadButton.new()
			jb.button_index = b
			InputMap.action_add_event(action, jb)
	for pair in [["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0], ["up", JOY_AXIS_LEFT_Y, -1.0], ["down", JOY_AXIS_LEFT_Y, 1.0]]:
		var m = InputEventJoypadMotion.new()
		m.axis = pair[1]
		m.axis_value = pair[2]
		InputMap.action_add_event(pair[0], m)


# ---------- saves ----------

func new_game() -> void:
	flags = {}
	ability = {"project": false, "double": false}
	tend = {"connection": 0, "control": 0, "rupture": 0}
	witness = 0
	overdraw = 0
	anchors = {}
	visited = {}
	save_data = {"room": "classroom", "x": 140.0, "y": 470.0}


func write_save(room_id: String, pos: Vector2) -> void:
	save_data = {"room": room_id, "x": pos.x, "y": pos.y, "flags": flags, "ability": ability, "tend": tend,
		"witness": witness, "overdraw": overdraw, "anchors": anchors, "visited": visited}
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save_data))


func read_save():
	if not FileAccess.file_exists(SAVE_PATH):
		return null
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return null
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else null


func load_save(d: Dictionary) -> void:
	flags = d.get("flags", {})
	ability = d.get("ability", {"project": false, "double": false})
	tend = d.get("tend", {"connection": 0, "control": 0, "rupture": 0})
	witness = int(d.get("witness", 0))
	overdraw = int(d.get("overdraw", 0))
	anchors = d.get("anchors", {})
	visited = d.get("visited", {})
	save_data = d


func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
