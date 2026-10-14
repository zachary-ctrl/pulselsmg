extends Node
## Plays through the chapter and saves screenshots. Run with:
##   godot --path . -- --autotest <output_dir>

var main: Node
var out := "user://autotest"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--autotest")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main = get_parent()
	_run.call_deferred()


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/" + name + ".png")
	print("shot ", name, " mode=", main.mode, " room=", main.room_id)


func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func tap(action: String, hold := 0.06) -> void:
	Input.action_press(action)
	await wait(hold)
	Input.action_release(action)
	await wait(0.04)


func hold(action: String, s: float) -> void:
	Input.action_press(action)
	await wait(s)
	Input.action_release(action)


func advance(n: int) -> void:
	for k in n:
		if main.mode != "dialog":
			return
		await tap("confirm")
		await tap("confirm")


func _run() -> void:
	await wait(1.0)
	await shot("01_title")
	main.new_game()
	await wait(1.2)
	await shot("02_intro_dialog")
	await advance(10)
	await wait(0.5)
	await shot("03_classroom")
	await hold("right", 1.6)
	await wait(0.6)
	await shot("04_projection_dialog")
	await advance(10)
	await wait(1.0)
	await shot("05_astral")
	await tap("project")
	await wait(1.0)
	main.load_room("hallway", Vector2(700, 470))
	main.card = null
	Game.set_flag("met_lana")
	await wait(0.6)
	Input.action_press("right")
	await wait(0.25)
	await shot("06_hallway_run")
	await tap("jump", 0.2)
	await wait(0.1)
	await shot("07_jump")
	Input.action_release("right")
	await tap("attack")
	await shot("08_strike")
	main.player.position = Vector2(1060, 470)
	await wait(1.2)
	await shot("09_enemy")
	main.player.hp = 5
	main.load_room("hallway", Vector2(2470, 470))
	await wait(0.3)
	await hold("right", 0.5)
	await wait(0.4)
	await advance(4)
	await wait(1.8)
	await shot("10_echo_fight")
	for e in main.ents:
		if e.kind == "echo":
			e.state = "follow"
			e.hit(99, 1)
	await wait(1.2)
	await shot("11_echo_choice")
	main._on_choice("READ")
	await wait(0.3)
	await advance(4)
	await wait(0.9)
	main._on_choice("REACH")
	await wait(0.3)
	await advance(4)
	print("echoDone=", Game.flag("echoDone"), " tend=", Game.tend)
	main.player.hp = 5
	main.load_room("cafeteria", Vector2(300, 1010))
	await wait(0.8)
	await shot("12_cafeteria")
	Game.ability["project"] = true
	await tap("project")
	await wait(1.2)
	await shot("13_cafeteria_astral")
	await tap("project")
	await wait(0.8)
	Game.ability["double"] = true
	Game.flags["stabilized"] = 4
	main.player.hp = 5
	main.load_room("lab", Vector2(250, 470))
	main.card = null
	await wait(0.4)
	await hold("right", 0.5)
	await wait(0.5)
	await shot("14_boss_dialog")
	await advance(10)
	await wait(2.5)
	await shot("15_boss_fight")
	for e in main.ents:
		if e.kind == "ciencia":
			e.hp = 10
			e.state = "idle"
			e.tm = 0.0
	await wait(1.5)
	await shot("16_boss_phase2")
	for e in main.ents:
		if e.kind == "ciencia":
			e.alpha = 1.0
			e.state = "idle"
			e.hit(99, 1)
	await wait(1.6)
	await shot("17_boss_choice")
	main._on_choice("BIND")
	await wait(0.3)
	await advance(12)
	await wait(1.0)
	await shot("18_end")
	print("CH1 DONE mode=", main.mode, " ending=", Game.flags.get("ending", ""))
	# ---- chapter 2 ----
	main.start_chapter(2, false)
	await wait(1.0)
	await shot("20_ch2_intro")
	await advance(10)
	await wait(0.6)
	Input.action_press("right")
	await wait(0.5)
	await shot("21_street_run")
	Input.action_release("right")
	main.player.position = Vector2(1000, 470)
	await wait(0.8)
	await tap("attack")
	await shot("22_street_strike")
	await wait(0.6)
	await shot("23_street_enemy")
	main.player.hp = 5
	main.load_room("hospital", Vector2(160, 470))
	await wait(0.6)
	await hold("right", 0.4)
	await wait(0.5)
	await shot("24_hospital_jason")
	await advance(8)
	main.player.position = Vector2(1420, 470)
	await wait(0.3)
	await hold("right", 0.4)
	await wait(0.4)
	await advance(8)
	await wait(2.5)
	await shot("25_carrier_fight")
	for e in main.ents:
		if e.kind == "carrier":
			e.lana_t = 0.0
	await wait(0.3)
	await shot("26_carrier_stunned")
	for e in main.ents:
		if e.kind == "carrier":
			e.hit(99, 1)
	await wait(1.6)
	await shot("27_carrier_choice")
	main._on_choice("REACH")
	await wait(0.3)
	await advance(12)
	await wait(1.0)
	await shot("28_ch2_end")
	print("CH2 mode=", main.mode, " carrier=", Game.flags.get("carrierDone_choice", ""))
	# ---- chapter 3 ----
	main.start_chapter(3, false)
	await wait(1.0)
	await advance(10)
	await wait(0.5)
	await shot("30_waterworks")
	for wk in ["w1", "w2", "w3"]:
		for n in main.npcs:
			if n.get("worker", false) and n["m"].id == wk:
				main.player.position = n["m"].position
		await wait(0.4)
	await advance(4)
	await wait(0.4)
	print("rescued=", Game.flags.get("rescued", 0))
	main.player.position = Vector2(1300, 1010)
	await wait(0.6)
	await shot("31_waterworks_upper")
	main.player.hp = 5
	main.load_room("pumphouse", Vector2(160, 470))
	await wait(0.4)
	await hold("right", 0.4)
	await wait(0.4)
	await advance(8)
	await wait(1.5)
	await shot("32_tide_fight")
	main.player.hp = 99
	main.player.max_hp = 99
	for e in main.ents:
		if e.kind == "tide":
			e.state = "surge"
			e.tm = 2.0
	await wait(0.9)
	await shot("33_tide_surge")
	for e in main.ents:
		if e.kind == "tide":
			e.hp = 19
	await wait(0.4)
	await advance(10)
	await wait(1.5)
	await shot("34_tide_phase2")
	for e in main.ents:
		if e.kind == "tide":
			e.hit(99, 1)
	await wait(1.6)
	await shot("35_tide_choice")
	main._on_choice("BIND")
	await wait(0.3)
	await advance(12)
	await wait(1.0)
	await shot("36_ch3_end")
	main.player.max_hp = 5
	print("AUTOTEST DONE mode=", main.mode, " tide=", Game.flags.get("tideDone_choice", ""), " unlocked=", Game.unlocked())
	get_tree().quit()
