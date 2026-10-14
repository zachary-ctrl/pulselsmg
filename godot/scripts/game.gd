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
	"street": "res://scenes/rooms/street.tscn",
	"hospital": "res://scenes/rooms/hospital.tscn",
	"waterworks": "res://scenes/rooms/waterworks.tscn",
	"pumphouse": "res://scenes/rooms/pumphouse.tscn",
	"fairhall": "res://scenes/rooms/fairhall.tscn",
	"gym": "res://scenes/rooms/gym.tscn",
	"stage": "res://scenes/rooms/stage.tscn",
}

const CHAPTERS := {
	1: {"title": "Class Famine", "room": "classroom", "spawn": Vector2(140, 470)},
	2: {"title": "The Carrier", "room": "street", "spawn": Vector2(120, 470)},
	3: {"title": "Red Water", "room": "waterworks", "spawn": Vector2(120, 1010)},
	4: {"title": "#ScienceMatters", "room": "fairhall", "spawn": Vector2(120, 470)},
}
const CHAPTER_WORD := {1: "ONE", 2: "TWO", 3: "THREE", 4: "FOUR"}
const PROGRESS_PATH := "user://sakawa_progress.json"
var chapter = 1

## Difficulty: hp = Max's health, ehp = enemy health scale, espd = enemy speed,
## res = Resonance gain scale.
const DIFF := [
	{"name": "STORY", "hp": 10, "ehp": 0.6, "espd": 0.85, "res": 1.5},
	{"name": "NORMAL", "hp": 7, "ehp": 1.0, "espd": 1.0, "res": 1.0},
	{"name": "HARD", "hp": 5, "ehp": 1.4, "espd": 1.15, "res": 0.85},
]
var difficulty = 1

## Playable heroes. Max leads; Lana joins in Chapter 2, Jason in Chapter 3.
## Stats: run speed, jump, strike damage, strike cooldown, bonus health,
## aura color, and the special moves each can equip (the first is default).
const HEROES := {
	"max": {"name": "MAX", "run": 300.0, "jump": 760.0, "dmg": 1, "cd": 0.26, "hp": 0, "aura": "violet", "col": "#c9b8ff",
		"blurb": "Psychokinesis, levitation, astral projection.", "specials": ["laser", "orb"]},
	"lana": {"name": "LANA", "run": 335.0, "jump": 740.0, "dmg": 1, "cd": 0.19, "hp": 2, "aura": "crimson", "col": "#ff8a7a",
		"blurb": "Superhuman reflexes, durability, hand-to-hand.", "specials": ["shout", "flurry"]},
	"jason": {"name": "JASON", "run": 285.0, "jump": 720.0, "dmg": 2, "cd": 0.38, "hp": 1, "aura": "sky", "col": "#8fd8ff",
		"blurb": "Superhuman strength. Water answers him.", "specials": ["wave", "geyser"]},
}
const SPECIALS := {
	"laser": {"name": "Psychic Laser", "cost": 22, "lv": 1, "d": "A beam to the nearest wall. Hits everything in line for 3. Hold up to aim upward."},
	"orb": {"name": "Mind Orb", "cost": 16, "lv": 3, "d": "A slow homing orb of thought. 2 damage, then it bursts."},
	"shout": {"name": "Get Real", "cost": 20, "lv": 1, "d": "Lana says something unforgivable. Shockwave: 2 damage and stuns everyone close."},
	"flurry": {"name": "Flurry", "cost": 24, "lv": 3, "d": "Dash forward throwing six fast punches."},
	"wave": {"name": "Tidal Push", "cost": 22, "lv": 1, "d": "A wave rolls along the floor for 3 damage."},
	"geyser": {"name": "Geyser", "cost": 28, "lv": 4, "d": "Water erupts under the nearest enemy for 4 damage."},
}
## Equipment (three slots). Mods are summed across equipped items.
const ITEMS := {
	"lunchbox": {"name": "Unopened Lunchbox", "d": "+2 max health. Somebody's mom packed it with love.", "mods": {"hp": 2}},
	"charger": {"name": "Dad's Charger", "d": "+30% Resonance from hits. He wants it back.", "mods": {"res": 0.3}},
	"wristband": {"name": "Taped Wristband", "d": "Combo finishers and kicks deal +1 damage.", "mods": {"heavy": 1}},
	"phone": {"name": "Cracked Phone", "d": "Specials cost 6 less Resonance.", "mods": {"cost": -6}},
	"goggles": {"name": "Lab Goggles", "d": "Specials deal +1 damage.", "mods": {"sdmg": 1}},
	"hallpass": {"name": "Hall Pass", "d": "Dash recovers twice as fast.", "mods": {"dashcd": -0.24}},
	"jersey": {"name": "Westbrook Jersey", "d": "Move 12% faster.", "mods": {"speed": 0.12}},
	"bell": {"name": "Silenced Bell", "d": "Focus heals 40% faster.", "mods": {"focus": 0.4}},
	"stone": {"name": "Reservoir Stone", "d": "Strikes deal +1 damage. Cold to the touch.", "mods": {"dmg": 1}},
	"tot": {"name": "Lucky Tater Tot", "d": "Enemies drop health far more often.", "mods": {"luck": 0.3}},
	"badge": {"name": "Science Fair Ribbon", "d": "+30% experience.", "mods": {"xp": 0.3}},
	"seal": {"name": "Seal Fragment", "d": "Full Potential needs only 75 Resonance.", "mods": {"fp": -24}},
}
const DROP_POOL := ["charger", "jersey", "bell", "tot", "hallpass", "phone"]
var prog = {}


func fresh_prog(ch := 1) -> Dictionary:
	var lv = 1 + (ch - 1) * 2
	var pts = {}
	var attr = {}
	for k in HEROES:
		pts[k] = lv - 1
		attr[k] = {"vit": 0, "pow": 0, "foc": 0}
	var items = []
	if ch >= 2:
		items = ["lunchbox", "charger"]
	if ch >= 3:
		items += ["wristband"]
	if ch >= 4:
		items += ["goggles", "stone"]
	return {"xp": 0, "level": lv, "pts": pts, "attr": attr, "items": items, "equip": ["", "", ""], "hp_bonus": (ch - 1),
		"special": {"max": "laser", "lana": "shout", "jason": "wave"}, "hero": "max", "picked": {}}


func xp_next(lv: int) -> int:
	return 40 + lv * 35


func mod(name: String) -> float:
	var v = 0.0
	for id in prog.get("equip", []):
		if id != "" and ITEMS.has(id):
			v += float(ITEMS[id]["mods"].get(name, 0.0))
	return v


func attr(hero: String, a: String) -> int:
	return int(prog["attr"].get(hero, {}).get(a, 0))


func hero_unlocked(h: String) -> bool:
	if h == "max":
		return true
	if h == "lana":
		return chapter >= 2 or flag("lana_joined")
	return chapter >= 3 or flag("jason_joined")


func party() -> Array:
	var out = []
	for h in ["max", "lana", "jason"]:
		if hero_unlocked(h):
			out.append(h)
	return out


func hero_max_hp(h: String) -> int:
	return diff()["hp"] + int(HEROES[h]["hp"]) + attr(h, "vit") + int(prog.get("hp_bonus", 0)) + int(mod("hp"))


func special_cost(h: String) -> float:
	var sp: String = prog["special"].get(h, HEROES[h]["specials"][0])
	return maxf(6.0, float(SPECIALS[sp]["cost"]) + mod("cost") - attr(h, "foc") * 2.0)


func fp_need() -> float:
	return 99.0 + mod("fp")


## Adds experience; returns the number of levels gained.
func gain_xp(n: int) -> int:
	prog["xp"] += int(round(n * (1.0 + mod("xp"))))
	var ups = 0
	while prog["xp"] >= xp_next(prog["level"]) and prog["level"] < 30:
		prog["xp"] -= xp_next(prog["level"])
		prog["level"] += 1
		ups += 1
		for k in HEROES:
			prog["pts"][k] = int(prog["pts"].get(k, 0)) + 1
	return ups


func give_item(id: String) -> bool:
	if id in prog["items"]:
		return false
	prog["items"].append(id)
	for i in 3:
		if prog["equip"][i] == "":
			prog["equip"][i] = id
			break
	return true


func diff() -> Dictionary:
	return DIFF[clampi(difficulty, 0, DIFF.size() - 1)]


func cycle_difficulty() -> void:
	difficulty = (difficulty + 1) % DIFF.size()
	_write_progress(unlocked())

const ANCH := {
	"momText": {"title": "Text · Mom · 3:12 PM", "body": "School called. They said lunch was \"weird\"? Eat something. Love you. Dad says bring back his charger."},
	"unknownText": {"title": "Text · Unknown · arrived 3:58 PM, sent 4:01 PM", "body": "Look at the sun, Max."},
	"receipt": {"title": "Receipt · Cafeteria · Yesterday", "body": "412 lunches served. 0 eaten. Staff note scribbled on the back: \"kids just stared at the trays like they were listening to them.\""},
	"dharmaNote": {"title": "Letter · The Dharma Order", "body": "Dr. Ciencia: your access is revoked. The Order funds adaptation, not receivers. Whatever you are listening to is listening back."},
	"dadText": {"title": "Text · Dad · 6:40 PM", "body": "Your mom says you are \"out with friends.\" Which friends. Name them. Also bring milk."},
	"chart": {"title": "Patient Chart · Kai Brooks", "body": "Found at the reservoir edge in dry clothes. Core temperature 91°F. Patient speaks in three distinct voices. One voice requested \"more water.\""},
	"workOrder": {"title": "Work Order · Westbrook Waterworks", "body": "Intake 3 flagged: red discoloration, faint singing in the pipes. Supervisor note: \"Pipes don't sing. Close ticket.\""},
	"flyer": {"title": "Flyer · Science Fair Night", "body": "WESTBROOK SCIENCE FAIR! Guest judge: Dr. R. Ciencia, Dharma Order. Theme this year: COLLECTIVE COGNITION. Think together!"},
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
		[N, "", "Strike with {attack}. Hold UP or DOWN while striking to aim. Three quick strikes chain into a heavy finisher. Each hit builds RESONANCE."],
		[N, "", "Kick with {kick}. In midair it becomes a diving kick that bounces off whatever it hits. Fire a psychic laser with {laser}. It burns Resonance."],
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
		[N, "", "The next morning, Kai Brooks comes home after nine days missing."], [N, "", "He answers his mother in three different voices."]],
	"c2Intro": [[N, "", "Two days after the lab. Westbrook Avenue at dusk."],
		["lana", "smirk", "So we are just not talking about how you threw a science teacher through reality."], ["max", "worried", "I am talking about it. Inside. A lot."],
		["lana", "neutral", "Kai Brooks walked out of Mercy General an hour ago. Nine days missing, then he shows up at the reservoir in dry clothes."],
		["max", "worried", "And the three voices?"], ["lana", "angry", "One of them told his mom she looked tired. In HER mom's voice. Her mom has been dead six years."],
		["lana", "neutral", "Everybody he passes stops talking. Then they start listening. Follow the quiet."], [N, "", "Reach Mercy General at the end of the avenue."], [N, "", "LANA joins the party. Swap heroes with {switch}. Open gear, skills and stats with {menu}."],
		[N, "", "Strike {attack} · Kick {kick} · Special {laser}. Enemies drop experience, health and sometimes gear."]],
	"c2_lana2": [["lana", "smirk", "Hospital is that way. The quiet way."]],
	"c2_jason": [["jason", "smirk", "Inoki. Lana. I already called it in. Channel 6 is on the way."], ["max", "shocked", "You called the NEWS?"],
		["jason", "neutral", "Somebody has to be the face of this. You two can be the hands."], ["lana", "angry", "I am about to be a hand."],
		["jason", "worried", "...He is up on the ward. He said my name, man. In my dad's voice."]],
	"c2_jason2": [["jason", "neutral", "Channel 6 says five minutes. Hurry up and look heroic."]],
	"carrierIntro": [[N, "", "Kai stands in the ward. Three shadows move behind him, out of step."], ["choir", "", "WE CARRIED HIM HOME."],
		["max", "worried", "Kai? Kai, can you hear me?"], ["lana", "smirk", "They flinch when you get personal. Let me get personal."],
		[N, "", "Lana will shout something real every few seconds. When Kai staggers, strike hard."]],
	"c2End": [["jason", "smirk", "Channel 6 is here. Everybody look normal. Max, stop glowing."],
		["lana", "neutral", "He is asleep. Just one voice now. His."], [N, "", "Almost. Something in Kai keeps humming one word, over and over: reservoir."],
		[N, "", "That night the tap water in four neighborhoods runs red for one second, then clear."]],
	"c3Intro": [[N, "", "Westbrook Municipal Waterworks. 2:14 AM."], ["jason", "worried", "You two dragged me out of bed to trespass at a WATER plant."],
		["lana", "smirk", "You came. You wore the blazer."], ["max", "neutral", "Ciencia's lab drained into the city lines. Whatever the Choir left in it is in the pipes now."],
		["jason", "angry", "There are night workers in there. My cousin works the night shift."],
		[N, "", "Find the three trapped workers before the red water reaches them. Touch a worker to guide them out."],
		[N, "", "JASON joins the party. He hits harder than anyone. Swap heroes with {switch}."]],
	"c3_jason2": [["jason", "worried", "I can hear the water. That is normal, right? Everybody can hear water."]],
	"c3Rescued": [["jason", "neutral", "That is all of them. My cousin says the pumphouse has been singing since midnight."], ["max", "worried", "Pumphouse it is. Great. Love that for us."]],
	"tideIntro": [[N, "", "The pumphouse floor is a lake. The lake is breathing."], ["choir", "", "WE REMEMBER EVERYONE WHO DRANK."],
		["jason", "shocked", "There is somebody under there! A worker—"], ["max", "angry", "Jason, stay back!"], [N, "", "When the tide rises, get high."]],
	"tideAwaken": [["jason", "angry", "No. NO. You do not get him."], [N, "", "Jason dives. The red water closes over him. Then it stops. Then it moves for him."],
		["jason", "shocked", "...It is listening to me. Max, it is LISTENING to me."], [N, "", "JASON'S WATER awakens. The tide runs clear and turns on its source."],
		["max", "smile", "Okay, that is extremely cool. Do it again."]],
	"c3End": [["lana", "shocked", "Everybody breathing? Jason, you are dry. You were UNDER the water."], ["jason", "worried", "I can still hear it. All of it. Every pipe in the city."],
		["max", "worried", "Every infected mind was looking at the same black sun. Now the water is looking back."],
		[N, "", "Three weeks later, rain falls on a clear day."], [N, "", "Jason hears hundreds of voices inside a puddle. One of them says his name from beneath the water."]],
	"c4Intro": [[N, "", "Three weeks after the pumphouse. Westbrook High Science Fair, 7:00 PM."],
		["lana", "smirk", "Free pizza, sad volcanoes, and a kid who built a robot that only says no. I am thriving."],
		["max", "worried", "Lana. Look at the judges' table."], [N, "", "The third placard reads: DR. R. CIENCIA · GUEST JUDGE · DHARMA ORDER."],
		["jason", "angry", "He's on the program, Max. Principal Hale signed off on it herself."],
		["lana", "neutral", "Every exhibit in the gym is humming the same note. Brayden's baking-soda volcano is humming."],
		[N, "", "The trio is together now. Swap heroes any time with {switch}. Open gear, skills and stats with {menu}."],
		[N, "", "Lana is fast and says unforgivable things. Jason hits hardest, and the water listens to him. Each has their own special on {laser}."]],
	"c4_lana": [["lana", "angry", "Hallway's crawling with those skull-mask things. They climbed out of the projector screens."], ["max", "neutral", "Choir imps. It's what the signal looks like when it gets bored."],
		["lana", "smirk", "Cute. I'm calling them Kevins."]],
	"c4_lana2": [["lana", "smirk", "Kevins to the left. More Kevins to the right. Go."]],
	"eliteIntro": [[N, "", "Something rides out of the trophy case."], ["lana", "shocked", "Is that a PIG?"], ["jason", "neutral", "It's a boar. With a guy on it. Made of static."],
		["max", "angry", "Pig, boar, whatever. We hit it until it's a rumor."]],
	"c4_jason": [["jason", "worried", "Three exhibits in here are broadcasting. I can hear them in the sprinkler pipes."], ["max", "neutral", "Then we break the exhibits."],
		["jason", "smirk", "Finally, a plan I can vote for."], [N, "", "Break all three broadcasting exhibits to open the stage."]],
	"c4_jason2": [["jason", "neutral", "Three exhibits. Break them. Then the stage."]],
	"gymIntro": [[N, "", "Two hundred parents sit in the bleachers, perfectly still, all facing the stage. None of them blink."]],
	"collectiveIntro": [["ciencia", "smile", "Welcome, finalists. Tonight Westbrook demonstrates collective cognition. Four hundred minds. One thought."],
		["max", "angry", "You hijacked a SCIENCE FAIR."], ["ciencia", "neutral", "The Dharma Order wanted proof that humanity could be upgraded. I am submitting it. With a trifold."],
		["lana", "angry", "You're a fired chemistry teacher with a laser pointer."],
		["ciencia", "smirk", "And you, Mr. Inoki, are a Dharma project. Did no one tell you? The Order has watched you since the day you were born."],
		["max", "shocked", "...What?"], ["jason", "angry", "Don't listen to him. Max. MAX. We do this together."],
		[N, "", "Lana and Jason fight beside you. Swap who you control with {switch}."]],
	"c4End": [["lana", "worried", "Okay. Nobody's saying it, so I will. He said you're a Dharma project."], ["max", "worried", "My mom has a LOT of explaining to do."],
		["jason", "neutral", "Whatever they are, they don't get you. Not on my watch. Not near my water."],
		[N, "", "That night, Max finds a letter in his locker. The seal is a black sun ringed by seven broken circles."],
		[N, "", "It reads: SUBJECT 7. THE TEACHER WHO WAS FIRED HAS FAILED. COME HOME."]],
}

const PORTRAIT := {
	"max": {"neutral": "max_neutral", "smile": "max_smile", "smirk": "max_smirk", "worried": "max_worried", "shocked": "max_shocked", "angry": "max_angry", "sad": "max_worried"},
	"lana": {"neutral": "lana_neutral", "smile": "lana_smile", "smirk": "lana_smirk", "worried": "lana_worried", "shocked": "lana_shocked", "angry": "lana_angry", "sad": "lana_worried"},
	"jason": {"neutral": "jason_neutral", "smile": "jason_smile", "smirk": "jason_smirk", "worried": "jason_worried", "shocked": "jason_shocked", "angry": "jason_angry", "sad": "jason_worried"},
	"ciencia": {"*": "ciencia_0"},
	"choir": {"*": "choir_0"},
}
const SPEAKER := {"max": "MAX INOKI", "lana": "LANA", "jason": "JASON", "ciencia": "DR. CIENCIA", "choir": "THE CHOIR"}

var _portraits = {}


func _ready() -> void:
	_setup_input()
	prog = fresh_prog(1)
	difficulty = int(_progress().get("difficulty", 1))
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
		return {"jump": "JUMP", "attack": "STRIKE", "kick": "KICK", "laser": "SPECIAL", "switch": "SWAP", "menu": "MENU", "dash": "DASH", "heal": "FOCUS", "project": "PROJECT", "fp": "FULL", "up": "▲", "move": "◀ ▶"}.get(action, action)
	if Input.get_connected_joypads().size() > 0:
		return {"jump": "A", "attack": "X", "kick": "B", "laser": "RT", "switch": "R3", "menu": "Back", "dash": "RB", "heal": "LB", "project": "Y", "fp": "LT", "up": "Up", "move": "the left stick"}.get(action, action)
	return {"jump": "Space", "attack": "X", "kick": "V", "laser": "B", "switch": "Tab", "menu": "I", "dash": "C", "heal": "Q", "project": "E", "fp": "R", "up": "W", "move": "A / D"}.get(action, action)


func fill(text: String) -> String:
	for a in ["move", "jump", "dash", "attack", "kick", "laser", "switch", "menu", "heal", "project", "fp", "up"]:
		text = text.replace("{%s}" % a, "[" + label(a) + "]")
	return text


func _setup_input() -> void:
	var keys = {
		"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE, KEY_Z], "attack": [KEY_X, KEY_J], "kick": [KEY_V, KEY_L], "laser": [KEY_B, KEY_I], "dash": [KEY_C, KEY_K, KEY_SHIFT], "heal": [KEY_Q, KEY_F],
		"project": [KEY_E, KEY_P], "fp": [KEY_R], "confirm": [KEY_ENTER, KEY_KP_ENTER], "pause": [KEY_ESCAPE],
		"switch": [KEY_TAB], "hero1": [KEY_1], "hero2": [KEY_2], "hero3": [KEY_3], "menu": [KEY_I, KEY_M],
	}
	var pads = {
		"left": [JOY_BUTTON_DPAD_LEFT], "right": [JOY_BUTTON_DPAD_RIGHT], "up": [JOY_BUTTON_DPAD_UP], "down": [JOY_BUTTON_DPAD_DOWN],
		"jump": [JOY_BUTTON_A], "attack": [JOY_BUTTON_X], "dash": [JOY_BUTTON_RIGHT_SHOULDER], "heal": [JOY_BUTTON_LEFT_SHOULDER],
		"kick": [JOY_BUTTON_B], "project": [JOY_BUTTON_Y], "confirm": [JOY_BUTTON_A], "pause": [JOY_BUTTON_START],
		"switch": [JOY_BUTTON_RIGHT_STICK], "menu": [JOY_BUTTON_BACK],
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
	for pair in [["laser", JOY_AXIS_TRIGGER_RIGHT, 1.0], ["fp", JOY_AXIS_TRIGGER_LEFT, 1.0], ["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0], ["up", JOY_AXIS_LEFT_Y, -1.0], ["down", JOY_AXIS_LEFT_Y, 1.0]]:
		var m = InputEventJoypadMotion.new()
		m.axis = pair[1]
		m.axis_value = pair[2]
		InputMap.action_add_event(pair[0], m)


# ---------- saves ----------

func _progress() -> Dictionary:
	if not FileAccess.file_exists(PROGRESS_PATH):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(PROGRESS_PATH))
	return d if d is Dictionary else {}


func unlocked() -> int:
	return int(_progress().get("unlocked", 1))


func _write_progress(n: int) -> void:
	var f = FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"unlocked": n, "difficulty": difficulty}))


func unlock(n: int) -> void:
	if n <= unlocked():
		return
	_write_progress(n)


func new_game(ch := 1) -> void:
	chapter = ch
	flags = {}
	ability = {"project": false, "double": false}
	tend = {"connection": 0, "control": 0, "rupture": 0}
	witness = 0
	overdraw = 0
	anchors = {}
	visited = {}
	if ch >= 2:
		ability = {"project": true, "double": ch >= 2}
		flags = {"intro": true, "projected": true, "echoDone": true, "cienciaDone": true, "lana_joined": true}
	if ch >= 3:
		flags["carrierDone"] = true
		flags["jason_joined"] = true
	if ch >= 4:
		flags["tideDone"] = true
		flags["tideClear"] = true
	prog = fresh_prog(ch)
	var c: Dictionary = CHAPTERS[ch]
	save_data = {"room": c["room"], "x": c["spawn"].x, "y": c["spawn"].y}


func write_save(room_id: String, pos: Vector2) -> void:
	save_data = {"room": room_id, "x": pos.x, "y": pos.y, "chapter": chapter, "flags": flags, "ability": ability, "tend": tend,
		"witness": witness, "overdraw": overdraw, "anchors": anchors, "visited": visited, "prog": prog}
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
	chapter = int(d.get("chapter", 1))
	prog = fresh_prog(1)
	var pg = d.get("prog", {})
	if pg is Dictionary:
		for k in pg:
			prog[k] = pg[k]
	prog["level"] = int(prog["level"])
	prog["xp"] = int(prog["xp"])
	save_data = d


func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
