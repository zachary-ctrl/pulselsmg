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


func _nodevil() -> void:
	for k in range(1, 6):
		Game.flags["down_devil%d" % k] = true


func advance(n: int) -> void:
	for k in n:
		if main.mode != "dialog":
			return
		await tap("confirm")
		await tap("confirm")


## QUICK=<chapter> runs a short check of that chapter's start instead.
func _quick(ch: int) -> void:
	main.start_chapter(ch, true)
	await wait(0.5)
	await advance(14)
	main.card = null
	await wait(0.3)
	await shot("q_start")
	for i in 6:
		main._drop(["xp", "hp", "res"][i % 3], main.player.position + Vector2(80, -40), {"xp": 10})
	print("drop-start")
	await wait(0.4)
	await shot("q_drops")
	print("drop-end")
	await wait(2.0)
	var d0 = Game.difficulty
	Game.difficulty = 0
	Game.apply_story()
	print("STORY party=", Game.party(), " items=", Game.prog["items"].size(), " cost=", Game.special_cost("max"))
	main.open_menu()
	main.ui._menu_go(4)
	await wait(0.3)
	await shot("q_lore")
	main.ui._menu_go(0)
	await wait(0.3)
	await shot("q_party")
	main.close_menu()
	Game.difficulty = d0
	get_tree().quit()


func _run() -> void:
	if OS.get_environment("DEVIL") != "":
		await wait(1.0)
		main.start_chapter(5, false)
		await wait(1.0)
		await advance(14)
		main.card = null
		main.mode = "play"
		await _devil_test()
		get_tree().quit()
		return
	if OS.get_environment("QUICK") == "ui":
		await wait(0.5)
		await shot("q_title")
		main.ui.show_sub("controls")
		await wait(0.3)
		await shot("q_controls")
		main.ui.sub_back()
		main.ui.sub_back()
		main.open_arcade()
		await wait(0.8)
		await tap("jump")
		await wait(0.4)
		Input.action_press("jump")
		await wait(0.45)
		await shot("q_arcade_charge")
		Input.action_release("jump")
		await wait(0.6)
		await shot("q_arcade_shot")
		print("arcade state=", main.arcade.state)
		main.arcade.score = 17
		main.arcade._game_over()
		await wait(0.3)
		await shot("q_arcade_over")
		get_tree().quit()
		return
	if OS.get_environment("QUICK") != "":
		await _quick(int(OS.get_environment("QUICK")))
		return
	await wait(1.0)
	await shot("01_title")
	# splash
	var sp = main.SplashScript.new()
	sp.main = main
	main.mode = "splash"
	main.ui_layer.add_child(sp)
	await wait(1.6)
	await shot("00_splash")
	await wait(2.4)
	# settings and controls
	main.ui.show_sub("settings")
	await wait(0.3)
	await shot("01b_settings")
	main.ui.show_sub("controls")
	await wait(0.3)
	await shot("01c_controls")
	var ev = InputEventKey.new()
	ev.physical_keycode = KEY_K
	Game.rebind("jump", ev)
	var pj = InputEventJoypadButton.new()
	pj.button_index = JOY_BUTTON_A
	print("REBIND jump=", Game.bind_label("jump", false), " dash_keys=", Game.settings["bind"]["dash"]["k"].size(), " ps=", Game.PAD_NAMES["ps"]["b0"])
	Game.reset_bindings()
	main.ui.sub_back()
	main.ui.sub_back()
	main.ui.show_sub("credits")
	await wait(0.3)
	await shot("01e_credits")
	main.ui.sub_back()
	# LSMG arcade
	main.open_arcade()
	await wait(0.8)
	await shot("02a_arcade_title")
	await tap("jump")
	await wait(0.4)
	Input.action_press("jump")
	await wait(0.45)
	await shot("02b_arcade_charge")
	Input.action_release("jump")
	await wait(0.7)
	await shot("02c_arcade_shot")
	main.arcade.clock = 4.0
	await wait(0.4)
	await shot("02d_arcade_lastshot")
	main.arcade.score = 17
	main.arcade._game_over()
	await wait(0.3)
	await shot("02e_arcade_over")
	main.arcade._exit()
	await wait(0.4)
	print("ARCADE mode=", main.mode, " high=", Game.settings.get("high", 0))
	main.ui.show_sub("arcade")
	await wait(0.3)
	await shot("02f_arcade_menu")
	main.ui.sub_back()
	for cab in ["knight", "duck"]:
		main.open_arcade(cab)
		await wait(0.6)
		await tap("jump")
		await wait(1.5)
		await tap("jump", 0.3)
		await wait(0.4)
		await shot("02g_" + cab)
		main.arcade._exit()
		await wait(0.4)
		print("CABINET ", cab, " back mode=", main.mode)
	main.new_game()
	await wait(1.2)
	await shot("02_intro_dialog")
	await advance(10)
	main.ui.show_pause()
	await wait(0.2)
	await shot("08f_pause")
	main.ui.hide_pause()
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
	await wait(0.22)
	await tap("attack")
	await wait(0.22)
	await tap("attack")
	await wait(0.04)
	await shot("08b_finisher")
	await wait(0.5)
	await tap("kick")
	await wait(0.1)
	await shot("08c_kick")
	await wait(0.5)
	await tap("jump", 0.25)
	await wait(0.15)
	await tap("kick")
	await wait(0.06)
	await shot("08d_divekick")
	await wait(0.8)
	main.player.res = 60.0
	await tap("laser")
	await wait(0.18)
	await shot("08e_laser")
	print("MOVES res=", main.player.res, " max_hp=", main.player.max_hp, " diff=", Game.diff()["name"])
	await wait(0.5)
	main.player.position = Vector2(1060, 470)
	await wait(1.2)
	await shot("09_enemy")
	main.player.hp = 5
	_nodevil()
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
	_nodevil()
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
	_nodevil()
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
	# ---- chapter 4 ----
	main.start_chapter(4, false)
	_nodevil()
	await wait(1.0)
	await shot("40_ch4_intro")
	await advance(12)
	await wait(0.6)
	await shot("41_fairhall")
	main.player.position = Vector2(900, 470)
	main.player.res = 99.0
	await tap("switch")
	await wait(0.3)
	await shot("42_swap_lana")
	await tap("attack")
	await wait(0.22)
	await tap("attack")
	await wait(0.22)
	await tap("attack")
	await wait(0.05)
	await shot("43_lana_combo")
	await wait(0.4)
	await tap("laser")
	await wait(0.2)
	await shot("44_lana_shout")
	await wait(0.6)
	await tap("switch")
	await wait(0.3)
	main.player.res = 99.0
	await tap("laser")
	await wait(0.3)
	await shot("45_jason_wave")
	main.player.res = 99.0
	await tap("transform")
	await wait(0.5)
	await shot("45b_jason_ego")
	await tap("attack")
	await wait(0.1)
	await shot("45c_ego_strike")
	await tap("switch")
	await wait(0.4)
	await shot("45d_max_ego")
	print("EGO shinobi=", main.player.shinobi, " key=", main.player.rig.key)
	await tap("transform")
	await wait(0.3)
	await wait(0.6)
	for i in 8:
		main._drop("xp", main.player.position + Vector2(60, -40), {"xp": 30})
	main._drop("hp", main.player.position + Vector2(-60, -40), {})
	main._drop("item", main.player.position + Vector2(40, -60), {"item": "jersey"})
	await wait(0.15)
	await shot("46_loot")
	await wait(2.0)
	print("LOOT level=", Game.prog["level"], " items=", Game.prog["items"], " pts=", Game.prog["pts"])
	main.card = null
	main.open_menu()
	await wait(0.3)
	await shot("47_menu_party")
	main.ui._spend(main.player.hero, "vit")
	main.ui._menu_go(1)
	await wait(0.2)
	await shot("48_menu_gear")
	main.ui._menu_go(2)
	await wait(0.2)
	await shot("49_menu_skills")
	main.ui._menu_go(3)
	await wait(0.3)
	await shot("49b_menu_map")
	main.ui._menu_go(1)
	await wait(0.2)
	await shot("49c_menu_gear_icons")
	main.close_menu()
	await tap("hero1")
	await wait(0.3)
	main.player.hp = main.player.max_hp
	main.player.position = Vector2(2300, 470)
	await wait(0.2)
	await advance(6)
	await wait(1.5)
	await shot("50_elite")
	print("elite fight=", main.fight_id())
	for e in main.ents:
		if e.kind == "rider" and e.elite:
			e.hit(999, 1)
	await wait(1.0)
	main.player.hp = main.player.max_hp
	main.load_room("gym", Vector2(300, 1010))
	await wait(0.4)
	await advance(4)
	await wait(0.6)
	await shot("51_gym")
	for e in main.ents:
		if e.kind == "exhibit":
			e.hit(99, 1)
	await wait(0.3)
	await advance(4)
	print("exhibits=", Game.flags.get("exhibits", 0))
	main.player.hp = main.player.max_hp
	main.load_room("stage", Vector2(160, 470))
	await wait(0.4)
	await hold("right", 0.5)
	await wait(0.4)
	await advance(12)
	await wait(2.0)
	await shot("52_collective_fight")
	main.player.hp = 99
	main.player.max_hp = 99
	for e in main.ents:
		if e.kind == "collective":
			e.hp = 30
			e.summon_t = 0.0
	await wait(2.0)
	await shot("53_collective_phase2")
	for e in main.ents:
		if e.kind == "collective":
			e.alpha = 1.0
			e.state = "idle"
			e.hit(999, 1)
	await wait(1.6)
	await shot("54_collective_choice")
	main._on_choice("REACH")
	await wait(0.3)
	await advance(14)
	await wait(1.0)
	await shot("55_ch4_end")
	# ---- chapter 5 + side areas + rage ----
	main.start_chapter(5, false)
	_nodevil()
	await wait(1.0)
	await shot("60_ch5_intro")
	await advance(12)
	await wait(0.6)
	await shot("61_nightcity")
	main.toggle_rage()
	await wait(0.5)
	await shot("62_rage")
	await tap("attack")
	await wait(0.1)
	await tap("laser")
	await wait(0.35)
	await tap("laser")
	await wait(0.2)
	await shot("63_rage_powers")
	var hp0 = main.player.hp
	main.hurt_player(3, main.player.position.x + 10)
	print("RAGE immortal hp_before=", hp0, " after=", main.player.hp, " rage=", main.player.rage)
	main.toggle_rage()
	main.load_room("rooftop", Vector2(1800, 470))
	await wait(0.4)
	await advance(4)
	await wait(1.2)
	await shot("64_underboss")
	print("UNDERBOSS fight=", main.fight_id(), " name=", main.fight["name"] if main.fight != null else "")
	for e in main.ents:
		if e.kind == "underboss":
			e.state = "idle"
			e.hit(999, 1)
	await wait(1.5)
	await advance(6)
	print("UNDERBOSS down=", Game.flag("down_monitor"))
	main.load_room("skyline", Vector2(300, 470))
	await wait(0.6)
	await advance(4)
	await shot("65_skyline")
	main.player.hp = 99
	main.player.max_hp = 99
	main.load_room("archive", Vector2(160, 470))
	await wait(0.4)
	await hold("right", 0.5)
	await wait(0.4)
	await advance(10)
	await wait(1.5)
	await shot("66_auditor")
	for e in main.ents:
		if e.kind == "underboss":
			e.hp = 40
	await wait(1.5)
	await shot("67_auditor_phase2")
	for e in main.ents:
		if e.kind == "underboss":
			e.alpha = 1.0
			e.state = "idle"
			e.hit(999, 1)
	await wait(2.6)
	await shot("68_auditor_choice")
	main._on_choice("BIND")
	await wait(0.3)
	await advance(14)
	await wait(1.0)
	await shot("69_ch5_end")
	main.open_menu()
	main.ui._menu_go(4)
	await wait(0.3)
	await shot("70_lore")
	main.close_menu()
	await _devil_test()
	print("CH5 auditor=", Game.flags.get("auditorDone_choice", ""))
	print("AUTOTEST DONE mode=", main.mode, " tide=", Game.flags.get("tideDone_choice", ""), " collective=", Game.flags.get("collectiveDone_choice", ""), " unlocked=", Game.unlocked(), " level=", Game.prog["level"])
	get_tree().quit()


func _devil_test() -> void:
	# ---- Azazel (the recurring devil), spells, boss-help key, Rage for all ----
	main.card = null
	main.ui._end.hide()
	main.mode = "play"
	Game.flags.erase("down_devil5")
	main.player.hp = 99
	main.player.max_hp = 99
	main.load_room("skyline", Vector2(2420, 470))
	await wait(0.4)
	await hold("right", 0.3)
	await wait(0.6)
	await shot("71_devil_intro")
	await advance(6)
	await wait(1.2)
	print("DEVIL fight=", main.fight_id(), " name=", main.fight["name"] if main.fight != null else "", " allies=", main.allies.size())
	await shot("72_devil_fight")
	await tap("allies")
	await wait(0.2)
	print("ALLIES key off=", not Game.settings.get("allies", true), " allies=", main.allies.size())
	await tap("allies")
	await wait(0.2)
	print("ALLIES key on=", Game.settings.get("allies", true), " allies=", main.allies.size())
	main.player.res = 99.0
	var spells = ["firebolt", "lance", "arcane", "sigil", "thorns", "spikes", "flame", "charm", "glyph", "smoke"]
	var dhp0 = 0
	for e in main.ents:
		if e.kind == "underboss":
			dhp0 = e.hp
	for spl in spells:
		main.player.laser_dir = Vector2(main.player.face, 0)
		main.fire_special(main.player, spl)
		await wait(0.12)
		if spl == "flame":
			await shot("73_spell_flame")
		if spl == "lance":
			await shot("73_spell_lance")
	await wait(0.5)
	var dhp1 = 0
	for e in main.ents:
		if e.kind == "underboss":
			dhp1 = e.hp
	print("SPELLS cast=", spells.size(), " devil_hp ", dhp0, " -> ", dhp1)
	Game.prog["special"]["max"] = "laser"
	await tap("spell")
	print("SPELL cycle max=", Game.prog["special"]["max"])
	main.switch_hero("lana")
	main.toggle_rage()
	await wait(0.4)
	var lhp = main.player.hp
	main.hurt_player(3, main.player.position.x + 10)
	print("RAGE lana rage=", main.player.rage, " hero=", main.player.hero, " hp ", lhp, " -> ", main.player.hp)
	await shot("74_rage_lana")
	main.toggle_rage()
	main.switch_hero("max")
	for e in main.ents:
		if e.kind == "underboss":
			e.alpha = 1.0
			e.state = "idle"
			e.hit(999, 1)
	await wait(2.0)
	await shot("75_devil_kneel")
	await advance(6)
	print("DEVIL down=", Game.flag("down_devil5"))
