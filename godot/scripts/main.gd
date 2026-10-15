extends Node2D
## Runs the chapter: modes (title, play, dialog, choice, pause, dead, end),
## rooms and transitions, the camera with parallax, the astral color grade,
## story events, combat resolution, saving and the ending.

const W := 960.0
const H := 540.0
const PlayerScript = preload("res://scripts/player.gd")
const Sleeper = preload("res://scripts/enemies/sleeper.gd")
const Mote = preload("res://scripts/enemies/mote.gd")
const Echo = preload("res://scripts/enemies/echo.gd")
const Ciencia = preload("res://scripts/enemies/ciencia.gd")
const Rig = preload("res://scripts/rig.gd")
const Anim = preload("res://scripts/anim_sprite.gd")
const Carrier = preload("res://scripts/enemies/carrier.gd")
const Tide = preload("res://scripts/enemies/tide.gd")
const Imp = preload("res://scripts/enemies/imp.gd")
const Rider = preload("res://scripts/enemies/rider.gd")
const Collective = preload("res://scripts/enemies/collective.gd")
const AllyScript = preload("res://scripts/ally.gd")
const SplashScript = preload("res://scripts/splash.gd")
const ArcadeScript = preload("res://scripts/arcade.gd")
const ArcadeKnight = preload("res://scripts/arcade_knight.gd")
const ArcadeDuck = preload("res://scripts/arcade_duck.gd")
const Exhibit = preload("res://scripts/enemies/exhibit.gd")
const Underboss = preload("res://scripts/enemies/underboss.gd")
const FxScript = preload("res://scripts/fx.gd")
const HudScript = preload("res://scripts/hud.gd")
const UiScript = preload("res://scripts/ui.gd")
const GRADE_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount = 0.0;
void fragment() {
	vec4 c = texture(screen_tex, SCREEN_UV);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 v = vec3(0.45, 0.33, 0.9) * (0.35 + l * 1.5);
	COLOR = vec4(mix(c.rgb, v, amount * 0.62), 1.0);
}
"""

var mode = "boot"
var t = 0.0
var room: Node2D
var room_id = ""
var meta = {}
var cam = Vector2.ZERO
var zoom = 1.22
var shake = 0.0
var hitstop = 0.0
var flash = 0.0
var flash_col = Color.WHITE
var astral_mix = 0.0
var player: CharacterBody2D
var astral: CharacterBody2D = null
var ents: Array = []
var pickups: Array = []
var allies: Array = []
var npcs: Array = []
var fight = null
var hist: Array = []
var trans = null
var card = null
var toasts: Array = []
var dead_t = 0.0
var predict_text = ""
var title_art: Texture2D
var astral_art: Texture2D

var world: Node2D
var world_art: Sprite2D
var ents_root: Node2D
var bg_layer: CanvasLayer
var bg: Node2D
var grade_rect: ColorRect
var top_layer: CanvasLayer
var fx: Node2D
var camera: Camera2D
var fg_layer: CanvasLayer
var fg: Node2D
var ui_layer: CanvasLayer
var hud: Control
var ui: Control
var _bg_tex: Array = []
var _fg_tex: Texture2D


func _exit_tree() -> void:
	if player and player.get_parent() == null:
		player.free()


func _ready() -> void:
	meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/rooms/meta.json"))
	title_art = load("res://assets/art/outside.jpg")
	astral_art = load("res://assets/art/astral.jpg")
	bg_layer = CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	bg = Node2D.new()
	bg.draw.connect(_draw_bg)
	bg_layer.add_child(bg)
	world = Node2D.new()
	add_child(world)
	world_art = Sprite2D.new()
	world_art.centered = false
	world_art.scale = Vector2(1, 1) / 1.5
	world.add_child(world_art)
	ents_root = Node2D.new()
	world.add_child(ents_root)
	var grade_layer = CanvasLayer.new()
	grade_layer.layer = 1
	add_child(grade_layer)
	grade_rect = ColorRect.new()
	grade_rect.size = Vector2(W, H)
	var sm = ShaderMaterial.new()
	var sh = Shader.new()
	sh.code = GRADE_SHADER
	sm.shader = sh
	grade_rect.material = sm
	grade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade_rect.visible = false
	grade_layer.add_child(grade_rect)
	camera = Camera2D.new()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(camera)
	camera.make_current()
	top_layer = CanvasLayer.new()
	top_layer.layer = 2
	top_layer.follow_viewport_enabled = true
	add_child(top_layer)
	fx = FxScript.new()
	fx.main = self
	top_layer.add_child(fx)
	fg_layer = CanvasLayer.new()
	fg_layer.layer = 3
	add_child(fg_layer)
	fg = Node2D.new()
	fg.draw.connect(_draw_fg)
	fg_layer.add_child(fg)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	hud = HudScript.new()
	hud.main = self
	hud.size = Vector2(W, H)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(hud)
	ui = UiScript.new()
	ui.main = self
	ui_layer.add_child(ui)
	ui.choice_made.connect(_on_choice)
	player = PlayerScript.new()
	player.main = self
	player.setup(false)
	if "--autotest" in OS.get_cmdline_user_args():
		show_title()
		add_child(load("res://tools/autotest.gd").new())
	else:
		mode = "splash"
		var sp = SplashScript.new()
		sp.main = self
		ui_layer.add_child(sp)


func splash_done() -> void:
	show_title()


var arcade: Control = null


## LSMG ARCADE cabinets: "shot" (Last Shot), "knight" (Mighty Knight, MIT,
## KOBUGE Project Incubator) and "duck" (Steamer Duck assets, CC0).
func open_arcade(id := "shot") -> void:
	mode = "arcade"
	ui.hide_title()
	ui._touch.visible = Game.touch_mode
	arcade = {"knight": ArcadeKnight, "duck": ArcadeDuck}.get(id, ArcadeScript).new()
	arcade.main = self
	ui_layer.add_child(arcade)


func close_arcade() -> void:
	arcade = null
	Sound._music_name = "_"
	show_title()


# ---------- modes ----------

func show_title() -> void:
	mode = "title"
	fight = null
	ui.hide_end()
	ui.hide_pause()
	ui.show_title(Game.read_save() != null, Game.unlocked())
	Sound.music("title")
	world.visible = false


func new_game() -> void:
	start_chapter(1, true)


## Begins chapter `n`. `fresh` resets story state (title or chapter select);
## otherwise flags, choices and anchors carry over from the previous chapter.
func start_chapter(n: int, fresh: bool) -> void:
	ui.hide_end()
	if fresh:
		Game.clear_save()
		Game.new_game(n)
	else:
		Game.chapter = n
		Game.ability["project"] = true
		Game.ability["double"] = true
	Game.unlock(n)
	toasts.clear()
	card = null
	_reset_player()
	_enter_play()
	var c: Dictionary = Game.CHAPTERS[n]
	load_room(c["room"], c["spawn"])
	Game.write_save(c["room"], c["spawn"])
	if n > 1:
		card = {"name": "Chapter " + Game.CHAPTER_WORD[n].capitalize(), "sub": c["title"], "t": 0.0}


func continue_game() -> void:
	var s = Game.read_save()
	if s == null:
		new_game()
		return
	Game.load_save(s)
	_reset_player()
	_enter_play()
	load_room(s["room"], Vector2(s["x"], s["y"]))


func _reset_player() -> void:
	var h: String = Game.prog.get("hero", "max")
	if not Game.hero_unlocked(h):
		h = "max"
	player.set_hero(h)
	player.swap_t = 0.0
	player.shinobi = false
	player.rage = false
	player.set_hero(h)
	player.max_hp = Game.hero_max_hp(h)
	player.hp = player.max_hp
	player.res = 0.0
	player.dive = false
	player.kick_t = 0.0
	player.laser_t = 0.0
	player.inv = 0.0
	player.velocity = Vector2.ZERO


func _enter_play() -> void:
	ui.hide_title()
	ui.hide_end()
	world.visible = true
	mode = "play"
	fight = null
	hist.clear()


func open_menu() -> void:
	mode = "menu"
	Sound.play("pause")
	ui.show_menu()


func close_menu() -> void:
	ui.hide_menu()
	mode = "play"
	var m: int = Game.hero_max_hp(player.hero)
	player.hp = clampi(player.hp + (m - player.max_hp), 1, m)
	player.max_hp = m


func open_pause() -> void:
	mode = "pause"
	Sound.play("pause")
	ui.show_pause()


func close_pause() -> void:
	ui.hide_pause()
	mode = "play"


func fight_id() -> String:
	return fight["id"] if fight != null else ""


func ctrl() -> CharacterBody2D:
	return astral if astral_active() and astral.ret <= 0.0 else player


func astral_active() -> bool:
	return astral != null and is_instance_valid(astral)


func toast(s: String) -> void:
	toasts.append({"s": s, "life": 3.2, "max": 3.2})


func flash_screen(amount: float, col: Color) -> void:
	flash = amount
	flash_col = col


# ---------- rooms ----------

var _city_meta = {}


func load_room(id: String, spawn: Vector2) -> void:
	if room:
		room.queue_free()
		room = null
	for e in ents:
		if is_instance_valid(e):
			e.queue_free()
	ents.clear()
	for n in npcs:
		n["node"].queue_free()
	npcs.clear()
	_end_astral_now()
	fx.clear_all()
	pickups.clear()
	_clear_allies()
	predict_text = ""
	fight = null
	hist.clear()
	room_id = id
	room = load(Game.ROOM_SCENES[id]).instantiate()
	room.main = self
	world.add_child(room)
	world.move_child(room, 1)
	var m: Dictionary = meta[id]
	_bg_tex.clear()
	var layers: Array = m["layers"]
	if m.has("city"):
		# Craftpix city parallax sets; wide rooms use the seamless tiled layers.
		if _city_meta.is_empty():
			_city_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/rooms/city_meta.json"))
		layers = []
		for L in _city_meta[m["city"]]["layers"]:
			layers.append({"file": L["tiled_file"], "f": L["f"], "w": L["tiled_w"], "h": L["h"]})
	for L in layers:
		_bg_tex.append({"tex": load("res://assets/rooms/" + L["file"]), "f": L["f"], "w": L["w"], "h": L["h"]})
	var wp = "res://assets/rooms/%s_world.png" % id
	world_art.texture = load(wp) if ResourceLoader.exists(wp) else null
	var fp = "res://assets/rooms/%s_fg.png" % id
	_fg_tex = load(fp) if ResourceLoader.exists(fp) else null
	if player.get_parent() == null:
		ents_root.add_child(player)
	player.position = spawn
	player.velocity = Vector2.ZERO
	player.dash_t = 0.0
	player.atk_t = 0.0
	player.heal_t = 0.0
	player.safe = spawn
	for s in room.markers["spawn"]:
		_spawn(s)
	for lm in room.markers["loot"]:
		if not Game.prog["picked"].has(lm.id):
			var it: String = lm.item
			pickups.append({"p": lm.position + Vector2(0, -18), "v": Vector2.ZERO, "k": "heart" if it == "heart" else "item", "item": it, "id": lm.id, "age": 1.0, "seed": randf() * 6.0, "fixed": true})
	for n in room.markers["npc"]:
		var r = Anim.new()
		r.key = n.id
		r.position = n.position
		r.play("idle")
		ents_root.add_child(r)
		npcs.append({"m": n, "node": r, "near": false, "face": n.face})
	for wk in room.markers["worker"]:
		if Game.flag("rescued_" + wk.id):
			continue
		var r = Rig.new()
		r.key = "teacher"
		r.position = wk.position
		ents_root.add_child(r)
		npcs.append({"m": wk, "node": r, "near": false, "face": -1, "worker": true})
	zoom = 1.0 if fight != null else 1.22
	var vw = W / zoom
	var vh = H / zoom
	cam = Vector2(clampf(spawn.x - vw / 2, 0, room.room_size.x - vw), clampf(spawn.y - vh * 0.62, 0, room.room_size.y - vh))
	_cam_y = spawn.y - vh * 0.62
	Sound.ambience(id)
	if not Game.visited.has(id):
		Game.visited[id] = true
		card = {"name": room.display_name, "sub": room.subtitle, "t": 0.0}
		Sound.play("gong")
	if id == "classroom" and not Game.flag("intro"):
		Game.set_flag("intro")
		start_dialog("intro")
	for pair in [["street", "c2Intro"], ["waterworks", "c3Intro"], ["fairhall", "c4Intro"], ["nightcity", "c5Intro"]]:
		if id == pair[0] and not Game.flag(pair[1]):
			Game.set_flag(pair[1])
			start_dialog(pair[1])


func _spawn(s: Node) -> void:
	var e: Node
	match s.enemy:
		"sleeper":
			e = Sleeper.new()
			e.main = self
			e.setup(s.id, s.position, s.patrol_range, Game.flag("down_" + s.id))
		"mote":
			if Game.flag("down_" + s.id):
				return
			e = Mote.new()
			e.main = self
			e.setup(s.id, s.position)
		"ciencia":
			if Game.flag("cienciaDone"):
				return
			e = Ciencia.new()
			e.main = self
			e.setup(s.position)
		"carrier":
			if Game.flag("carrierDone"):
				return
			e = Carrier.new()
			e.main = self
			e.setup(s.position)
		"tide":
			if Game.flag("tideDone"):
				return
			e = Tide.new()
			e.main = self
			e.setup(s.position)
		"imp", "rider":
			if Game.flag("down_" + s.id):
				return
			e = Imp.new() if s.enemy == "imp" else Rider.new()
			e.main = self
			e.setup(s.id, s.position, s.patrol_range)
		"exhibit":
			e = Exhibit.new()
			e.main = self
			e.setup(s.id, s.position)
		"underboss":
			if Game.flag("down_" + s.id):
				return
			e = Underboss.new()
			e.main = self
			e.setup(s.id, s.position)
			e.state = "dormant" if e.cfg.get("boss", false) else "wait"
		"collective":
			if Game.flag("collectiveDone"):
				return
			e = Collective.new()
			e.main = self
			e.setup(s.position)
		_:
			return
	scale_enemy(e)
	ents_root.add_child(e)
	ents.append(e)


func scale_enemy(e: Node) -> void:
	e.hp = maxi(1, roundi(e.hp * Game.diff()["ehp"]))
	if "max_hp" in e:
		e.max_hp = e.hp


func spawn_add() -> void:
	var e = Sleeper.new()
	e.main = self
	e.setup("sx", Vector2(1000 if player.position.x < 560 else 120, 470), 150, false)
	e.state = "notice"
	e.tm = 0.8
	scale_enemy(e)
	ents_root.add_child(e)
	ents.append(e)
	toast("A listener stumbles in from the stairwell")


func go_room(ex: Node) -> void:
	if trans != null:
		return
	trans = {"t": 0.0, "to": ex.target_room, "spawn": ex.spawn_point, "done": false}
	Sound.play("whoosh")


# ---------- dialog ----------

func start_dialog(id: String, on_end := Callable(), extra: Array = []) -> void:
	var lines: Array = Game.DLG.get(id, []).duplicate()
	lines.append_array(extra)
	if lines.is_empty():
		if on_end.is_valid():
			on_end.call()
		return
	mode = "dialog"
	var done = func():
		mode = "play"
		if on_end.is_valid():
			on_end.call()
	ui.start_dialog(lines, done)


func say(lines: Array, on_end := Callable()) -> void:
	start_dialog("_", on_end, lines)


# ---------- main loop ----------

func _physics_process(dt: float) -> void:
	t += dt
	match mode:
		"splash", "arcade":
			return
		"title", "boot", "pause", "choice", "end", "menu":
			if mode == "menu" and (Input.is_action_just_pressed("menu") or Input.is_action_just_pressed("pause")):
				close_menu()
			fx.update_cosmetic(dt)
			_update_view(dt)
			return
		"dialog":
			ui.update_dialog(dt, Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("confirm"))
			fx.update_cosmetic(dt * 0.5)
			_update_view(dt)
			return
		"dead":
			dead_t += dt
			fx.update_cosmetic(dt)
			if dead_t > 2.2:
				_respawn()
			_update_view(dt)
			return
	if Input.is_action_just_pressed("pause"):
		open_pause()
		return
	if Input.is_action_just_pressed("menu"):
		open_menu()
		return
	_check_switch()
	if Input.is_action_just_pressed("rage"):
		toggle_rage()
	if Input.is_action_just_pressed("allies"):
		toggle_allies()
	if Input.is_action_just_pressed("spell"):
		cycle_special()
	if trans != null:
		trans["t"] += dt
		if not trans["done"] and trans["t"] >= 0.28:
			trans["done"] = true
			load_room(trans["to"], trans["spawn"])
		if trans["t"] >= 0.6:
			trans = null
		_update_view(dt)
		return
	if hitstop > 0.0:
		hitstop -= dt
		_update_view(dt)
		return
	shake = maxf(0.0, shake - dt)
	flash = maxf(0.0, flash - dt * 2.0)
	player.inv = maxf(0.0, player.inv - dt)
	if card != null:
		card["t"] += dt
		if card["t"] > 4.0:
			card = null
	for tst in toasts:
		tst["life"] -= dt
	toasts = toasts.filter(func(x): return x["life"] > 0.0)
	if Input.is_action_just_pressed("project"):
		if astral_active():
			end_projection(false)
		else:
			start_projection(false)
	if astral_active():
		astral.inv = maxf(0.0, astral.inv - dt)
		if astral.ret > 0.0:
			astral.ret -= dt
			var k: float = 1.0 - astral.ret / 0.4
			astral.position = astral.ret_from.lerp(player.position, k * k)
			if astral.ret <= 0.0:
				fx.burst(player.position + Vector2(0, -30), 14, 160, Color("#a58bff"))
				_end_astral_now()
		else:
			astral.control(dt)
			var before = ceili(astral.timer)
			astral.timer -= dt
			if astral.timer < 10.0 and ceili(astral.timer) != before:
				Sound.play("tick")
			if astral.timer <= 0.0:
				toast("Sixty seconds. Your body pulls you home.")
				end_projection(true)
			_check_sigils()
		player.velocity.x = 0.0
		player.velocity.y = minf(player.velocity.y + 2400.0 * dt, 880.0)
		player.move_and_slide()
	else:
		player.control(dt)
	if Input.is_action_just_pressed("fp") and player.res >= Game.fp_need() and not astral_active():
		_full_potential()
	if not astral_active():
		var hz = room.hazard_at(player.hitbox())
		if hz != null and mode == "play":
			player.inv = 0.0
			hurt_player(1, player.position.x)
			if player.hp > 0:
				player.position = player.safe
				player.velocity = Vector2.ZERO
				player.inv = maxf(player.inv, 1.0)
		if player.is_on_floor() and not player.ground_oneway:
			var l = Rect2(player.position.x - 72, player.position.y + 2, 24, 10)
			var r = Rect2(player.position.x + 48, player.position.y + 2, 24, 10)
			if room.hazard_at(l) == null and room.hazard_at(r) == null:
				player.safe = player.position
		if player.position.y > room.room_size.y + 120:
			player.position = player.safe
			player.velocity = Vector2.ZERO
			hurt_player(1, player.position.x)
	for e in ents:
		if is_instance_valid(e) and not e.dead:
			e.step(dt * Game.diff()["espd"])
	for e in ents:
		if is_instance_valid(e) and e.dead and e.kind != "sleeper":
			e.queue_free()
	ents = ents.filter(func(e): return is_instance_valid(e) and not (e.dead and e.kind != "sleeper"))
	if fight_id() == "echo":
		hist.append({"t": t, "pos": player.position, "face": player.face, "moving": absf(player.velocity.x) > 20.0 and player.is_on_floor(), "air": not player.is_on_floor(), "vy": player.velocity.y, "ph": player.run_ph})
		while hist.size() > 0 and hist[0]["t"] < t - 4.0:
			hist.pop_front()
	if fight_id() == "elite" and (not is_instance_valid(fight["e"]) or fight["e"].state == "dying" or fight["e"].dead):
		fight = null
		toast("The Static Rider comes apart into snow")
	fx.step(dt)
	_update_pickups(dt)
	_update_allies(dt)
	if mode == "play" and trans == null and not astral_active():
		_world_interactions()
	_check_anchors()
	astral_mix = move_toward(astral_mix, 1.0 if (astral_active() and astral.ret <= 0.0) else 0.0, dt * 3.0)
	if P_hp_low():
		_heartbeat(dt)
	_update_view(dt)


var _hb = 0.0
func P_hp_low() -> bool:
	return player.hp == 1


func _heartbeat(dt: float) -> void:
	_hb -= dt
	if _hb <= 0.0:
		_hb = 0.9
		Sound.play("heartbeat")


func _update_view(dt: float) -> void:
	if mode == "title" or room == null:
		bg.queue_redraw()
		fg.queue_redraw()
		Sound.music(("menu_dark_synth" if ui._sub != null and ui._sub.visible and ui._sub_kind == "credits" else "title") if mode == "title" else "")
		return
	var c = ctrl()
	zoom = move_toward(zoom, 1.0 if fight != null else 1.22, dt * 0.5)
	var vw = W / zoom
	var vh = H / zoom
	var focus: Vector2 = c.position
	# Look ahead in the direction of travel, and only follow vertically
	# once the hero leaves a small dead zone (steadier jumps).
	_look = _look.lerp(Vector2(c.face * 70.0 + clampf(c.velocity.x * 0.12, -50.0, 50.0), 0.0), minf(1.0, dt * 2.5))
	var ty = focus.y - vh * 0.62
	if absf(ty - _cam_y) > 40.0 or c.is_on_floor():
		_cam_y = lerpf(_cam_y, ty, minf(1.0, dt * 4.0))
	var target = Vector2(clampf(focus.x - vw / 2 + _look.x, 0, maxf(0.0, room.room_size.x - vw)), clampf(_cam_y, 0, maxf(0.0, room.room_size.y - vh)))
	cam = cam.lerp(target, minf(1.0, dt * 6.0))
	cam.x = clampf(cam.x, 0, maxf(0.0, room.room_size.x - vw))
	cam.y = clampf(cam.y, 0, maxf(0.0, room.room_size.y - vh))
	var so = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 12.0 if shake > 0.0 else Vector2.ZERO
	camera.position = cam
	camera.zoom = Vector2(zoom, zoom)
	camera.offset = so / zoom
	grade_rect.visible = astral_mix > 0.0
	(grade_rect.material as ShaderMaterial).set_shader_parameter("amount", astral_mix)
	player.update_pose(t, astral_active())
	if astral_active():
		astral.update_pose(t, false)
	var speaker = ""
	if ui.dlg != null:
		speaker = ui.dlg["lines"][ui.dlg["i"]][0]
	for n in npcs:
		var m: Node = n["m"]
		if n.get("worker", false):
			n["node"].pose = {"face": n["face"], "t": t, "seed": m.position.x, "kneel": true}
			n["node"].tint = Color(0.9, 0.5, 0.4, 0.15 + 0.1 * sin(t * 3.0))
		else:
			n["node"].face = n["face"]
			n["node"].play("talk" if speaker == m.id else "idle")
	bg.queue_redraw()
	fg.queue_redraw()
	var mus = "explore"
	if mode == "end":
		mus = "end"
	elif fight != null:
		match fight["id"]:
			"echo":
				mus = "echo"
			"carrier":
				mus = "carrier"
			"tide":
				mus = "tide"
			"elite", "underboss":
				mus = "boss_clash" if fight["id"] == "elite" or not (is_instance_valid(fight["e"]) and fight["e"].phase2) else "ciencia2"
			"collective":
				mus = "ciencia2" if (is_instance_valid(fight["e"]) and fight["e"].phase2) else "boss_clash"
			_:
				mus = "ciencia2" if (is_instance_valid(fight["e"]) and fight["e"].phase2) else "ciencia"
	elif astral_active():
		mus = "astral"
	elif Game.chapter == 4 and room_id in ["fairhall", "gym"]:
		mus = "fair_bustle"
	Sound.music(mus)


var _look = Vector2.ZERO
var _cam_y = 0.0


func _draw_bg() -> void:
	if room == null or mode == "title":
		return
	for L in _bg_tex:
		var f: float = L["f"]
		bg.draw_texture_rect(L["tex"], Rect2(-cam * f * zoom, Vector2(L["w"], L["h"]) * zoom), false)
	if astral_mix > 0.0:
		var s = H / astral_art.get_height()
		var tw = astral_art.get_width() * s
		var off = -fmod(cam.x * 0.15, tw * 2.0)
		var x = off
		var i = 0
		while x < W:
			var rect = Rect2(x, 0, tw, H)
			if i % 2 == 1:
				rect = Rect2(x + tw, 0, -tw, H)
			bg.draw_texture_rect(astral_art, rect, false, Color(1, 1, 1, astral_mix * 0.62))
			x += tw
			i += 1


func _draw_fg() -> void:
	if room == null or mode == "title" or _fg_tex == null:
		return
	fg.draw_texture_rect(_fg_tex, Rect2(-cam * 1.3 * zoom, Vector2(_fg_tex.get_width(), _fg_tex.get_height()) * zoom), false)


# ---------- interactions ----------

func _world_interactions() -> void:
	var pb = player.hitbox()
	for pt in room.markers["portal"]:
		if absf(player.position.x - pt.position.x) < 40.0 and absf(player.position.y - pt.position.y) < 40.0 and fight == null:
			if Input.is_action_just_pressed("up"):
				Sound.play("u_portal", 0.0, -4.0)
				fx.burst(pt.position + Vector2(0, -50), 24, 260, Color("#c9b8ff"))
				go_room(pt)
				return
	for ex in room.markers["exit"]:
		if ex.rect().intersects(pb) and fight == null:
			go_room(ex)
			return
	for tr in room.markers["trigger"]:
		if tr.rect().intersects(pb):
			_fire_event(tr.event)
	for b in room.blockers:
		if b.kind == "door" and b.active and absf(player.position.x - (b.rect().position.x - player.w / 2.0)) < 4.0 and Input.is_action_pressed("right") and not Game.flag("doorTold"):
			Game.set_flag("doorTold")
			start_dialog("doorLocked")
	for n in npcs:
		if not n.get("worker", false):
			continue
		var wm: Node = n["m"]
		if not Game.flag("rescued_" + wm.id) and absf(player.position.x - wm.position.x) < 40.0 and absf(player.position.y - wm.position.y) < 50.0:
			Game.set_flag("rescued_" + wm.id)
			Game.flags["rescued"] = int(Game.flags.get("rescued", 0)) + 1
			Sound.play("stabilize")
			fx.burst(wm.position + Vector2(0, -30), 24, 240, Color("#ffd6a0"))
			toast("Worker guided to safety (%d / 3)" % Game.flags["rescued"])
			n["node"].queue_free()
			npcs.erase(n)
			if Game.flags["rescued"] >= 3:
				start_dialog("c3Rescued")
			return
	for n in npcs:
		if n.get("worker", false):
			continue
		var m: Node = n["m"]
		n["near"] = absf(player.position.x - m.position.x) < 70.0 and absf(player.position.y - m.position.y) < 40.0
		if n["near"] and (not Game.flag("met_" + m.id) or Input.is_action_just_pressed("up")):
			var first = not Game.flag("met_" + m.id)
			Game.set_flag("met_" + m.id)
			n["face"] = int(signf(player.position.x - m.position.x))
			start_dialog(m.dialog if first else m.dialog_repeat)
			return
	for b in room.markers["bench"]:
		var near: bool = absf(player.position.x - b.position.x) < 50.0 and absf(player.position.y - b.position.y) < 30.0
		if near and Input.is_action_just_pressed("up") and fight == null:
			player.hp = player.max_hp
			player.position.x = b.position.x
			player.velocity.x = 0
			Game.write_save(room_id, player.position)
			Sound.play("rest")
			toast("Rested. Progress saved.")
			for i in 18:
				fx.part(b.position + Vector2(0, -30), Vector2(randf_range(-80, 80), -randf() * 160), "wisp", Color("#ffd6a0"))


func _check_sigils() -> void:
	for s in room.markers["sigil"]:
		if not Game.flag(s.flag) and absf(astral.position.x - s.position.x) < 40.0 and absf(astral.position.y - 30 - s.position.y) < 60.0:
			Game.set_flag(s.flag)
			Sound.play("unlock")
			shake = 0.3
			flash_screen(0.4, Color("#a58bff"))
			toast("Something on the other side of the door came undone")
			fx.burst(s.position, 30, 300, Color("#c9b8ff"))


func _check_anchors() -> void:
	for a in room.markers["anchor"]:
		if Game.anchors.has(a.id) or fight != null:
			continue
		var c: Node = null
		if a.astral:
			if astral_active() and astral.ret <= 0.0:
				c = astral
		elif not astral_active():
			c = player
		if c == null:
			continue
		if absf(c.position.x - a.position.x) < 34.0 and absf(c.position.y - a.position.y) < 70.0:
			Game.anchors[a.id] = true
			Sound.play("phone")
			var d: Dictionary = Game.ANCH[a.id]
			if d.has("ability"):
				Game.ability[d["ability"]] = true
			fx.burst(a.position + Vector2(0, -24), 24, 240, Color("#c9b8ff") if a.astral else Color("#ffe2a8"))
			var is_astral: bool = a.astral
			say([["phone", d["title"], d["body"]]], func(): if is_astral: toast("Levitation learned. Return to your body."))


# ---------- projection ----------

func start_projection(force: bool) -> void:
	if not Game.ability.get("project", false) or astral_active() or (not player.is_on_floor() and not force) or player.heal_t > 0.0:
		return
	astral = PlayerScript.new()
	astral.main = self
	astral.setup(true)
	astral.position = player.position + Vector2(0, -6)
	astral.velocity = Vector2(0, -180)
	astral.face = player.face
	astral.timer = 60.0
	astral.inv = 0.4
	top_layer.add_child(astral)
	Sound.play("project")
	for i in 24:
		fx.part(player.position + Vector2(0, -30), Vector2(randf_range(-100, 100), -randf() * 200), "wisp", Color("#a58bff"))
	player.velocity.x = 0


func end_projection(forced: bool) -> void:
	if not astral_active() or astral.ret > 0.0:
		return
	astral.ret = 0.4
	astral.ret_from = astral.position
	Sound.play("return")
	if forced:
		shake = maxf(shake, 0.2)


func _end_astral_now() -> void:
	if astral_active():
		astral.queue_free()
	astral = null


# ---------- combat ----------

func attack_hits(e: CharacterBody2D) -> void:
	var b: Rect2 = e.attack_box()
	var kind: String = e.atk_kind
	var striking = kind == "strike" or kind == "finisher"
	var hit = false
	var pogo = false
	for en in ents:
		if not is_instance_valid(en) or en.dead or e.hit_set.has(en):
			continue
		if e.is_astral and not en.astral_only and en.kind != "ciencia":
			continue
		var box: Rect2 = en.hurt_rect()
		if b.intersects(box):
			var dir: int = e.face if e.atk_dir == "side" or kind == "dive" else (int(signf(en.position.x - e.position.x)) if en.position.x != e.position.x else 1)
			var crit = randf() < 0.04 + Game.attr(e.hero, "lck") * 0.03 + (0.15 if e.rage else 0.0)
			if en.hit(e.atk_dmg * (2 if crit else 1), dir):
				if crit:
					fx.text_float(box.get_center() + Vector2(0, -30), "CRIT!", Color("#ffe066"), 0.8)
				e.hit_set[en] = true
				hit = true
				if striking and e.atk_dir == "down":
					pogo = true
				if (kind == "kick" or kind == "finisher") and en.kind == "sleeper":
					en.velocity.x = dir * 520.0
				_gain_res(11.0, e)
				fx.burst(box.get_center(), 18 if e.atk_dmg > 1 else 10, 420 if e.atk_dmg > 1 else 300, Color("#ffd6a0"))
				if e.rage:
					fx.sprite("magic/fire_bolt_impact", box.get_center(), 130.0, 0.28, 0.0, Color.WHITE, 4)
				if e.atk_dmg > 1 or kind == "flurry":
					var hv = {"max": "vfx/burst_pink", "lana": "vfx/comet_orange", "jason": "vfx/burst_ice"}.get(e.hero, "vfx/burst_pink")
					fx.sprite(hv, box.get_center(), 90.0 if e.atk_dmg > 1 else 60.0, 0.28, 0.0 if hv != "vfx/comet_orange" else (0.0 if e.face > 0 else PI))
				for i in 3:
					fx.part(en.position + Vector2(0, -20), Vector2.ZERO, "res", Color("#ffb06a"), player)
	if not e.is_astral and striking and e.atk_dir == "down" and not pogo:
		if room.hazard_at(Rect2(b.position, b.size + Vector2(0, 6))) != null:
			pogo = true
	if hit:
		hitstop = 0.09 if e.atk_dmg > 1 else 0.055
		Sound.play("hit", 0.08)
		if not e.is_astral and e.hero != "max":
			Sound.play("u_punch1" if randf() < 0.5 else "u_punch2", 0.1, -6.0)
		Game.rumble(0.25 if e.atk_dmg > 1 else 0.12, 0.3 if e.atk_dmg > 1 else 0.0, 0.12)
		shake = maxf(shake, 0.16 if e.atk_dmg > 1 else 0.08)
	if kind == "dive" and hit:
		e.dive_bounce()
	elif pogo and not e.pogo_done:
		e.velocity.y = -640.0
		e.jump_cut = true
		e.used_double = false
		e.air_dash = true
		e.pogo_done = true
	elif hit and e.atk_dir == "side":
		e.recoil_t = 0.07
		e.recoil_v = -e.face * (300.0 if kind == "kick" else 230.0)


func apply_difficulty() -> void:
	var m: int = Game.hero_max_hp(player.hero)
	player.hp = clampi(player.hp + (m - player.max_hp), 1, m)
	player.max_hp = m


func _gain_res(n: float, who = null) -> void:
	var p = player
	var m: float = Game.diff()["res"] * (1.0 + Game.mod("res") + Game.attr(p.hero, "foc") * 0.1)
	p.res = minf(99.0, p.res + n * m)


func special_dmg(p: CharacterBody2D, base: int) -> int:
	return base + int(Game.mod("sdmg")) + p.dmg_bonus() + int(Game.attr(p.hero, "spr") / 2)


func fire_special(p: CharacterBody2D, kind: String) -> void:
	match kind:
		"laser":
			fire_laser(p)
		"orb":
			Sound.play("u_spell", 0.05, -6.0)
			fx.projectiles.append({"p": p.position + Vector2(p.face * 26, -44), "v": Vector2(p.face * 260, -40), "r": 13.0, "k": "mind", "c": Color("#c9b8ff"),
				"life": 3.2, "grav": 0.0, "rot": 0.0, "friendly": true, "home": true, "dmg": special_dmg(p, 2), "hits": {}})
			Sound.play("zap")
		"shout":
			var c: Vector2 = p.position + Vector2(0, -34)
			fx.rings.append({"p": c, "r": 10.0, "life": 0.45, "max": 0.45, "c": Color("#ff8a7a")})
			fx.sprite("vfx/burst_pink", c, 220.0, 0.4)
			fx.sprite("magic/arcane_splash", c, 200.0, 0.45, 0.0, Color.WHITE, 6)
			fx.text_float(c + Vector2(0, -50), ["YOU SMELL LIKE GLUE", "SIT DOWN", "BRAYDEN, REALLY?", "GET REAL"][randi() % 4], Color("#ffd0c8"), 1.4)
			Sound.play("boom")
			shake = maxf(shake, 0.25)
			for en in ents:
				if is_instance_valid(en) and not en.dead and en.hurt_rect().get_center().distance_to(c) < 180.0:
					if en.hit(special_dmg(p, 2), int(signf(en.position.x - p.position.x)) if en.position.x != p.position.x else 1):
						stun(en, 1.6)
		"flurry":
			p.start_flurry()
		"wave":
			fx.projectiles.append({"p": p.position + Vector2(p.face * 30, -14), "v": Vector2(p.face * 540, 0), "r": 22.0, "k": "pwave", "c": Color("#8fd8ff"),
				"life": 1.5, "grav": 0.0, "rot": 0.0, "friendly": true, "pierce": true, "dmg": special_dmg(p, 3), "hits": {}})
			Sound.play("whoosh")
		"firebolt":
			var dv: Vector2 = p.laser_dir
			fx.projectiles.append({"p": p.position + Vector2(p.face * 26, -48), "v": dv * 620.0, "r": 12.0, "k": "fire", "c": Color("#ffb060"),
				"life": 1.4, "grav": 0.0, "rot": 0.0, "friendly": true, "dmg": special_dmg(p, 3), "hits": {}})
			fx.sprite("magic/flame_flicker", p.position + Vector2(p.face * 30, -40), 70.0, 0.25, 0.0, Color.WHITE, 4)
			Sound.play("u_shot", 0.08, -6.0)
		"lance":
			_spell_lance(p)
		"arcane":
			var ac: Vector2 = p.position + Vector2(p.face * 110, -40)
			fx.sprite("magic/arcane_splash", ac, 240.0, 0.45, 0.0, Color.WHITE, 6)
			Sound.play("u_spell", 0.05, -4.0)
			Sound.play("pop")
			_spell_area(p, ac, 120.0, 3, 0.0)
		"sigil":
			var sc: Vector2 = p.position + Vector2(0, -40)
			fx.sprite("magic/void_sigil_ring", sc, 340.0, 0.6, 0.0, Color.WHITE, 8)
			fx.rings.append({"p": sc, "r": 10.0, "life": 0.45, "max": 0.45, "c": Color("#c9b8ff")})
			Sound.play("glitch")
			Sound.play("boom", 0.05, -6.0)
			shake = maxf(shake, 0.2)
			_spell_area(p, sc, 170.0, 2, 1.6)
		"thorns":
			for k in 3:
				var tx: float = p.position.x + p.face * (70.0 + k * 80.0)
				fx.sprite("magic/thorn_bramble" if k % 2 == 0 else "magic/thorn_bramble_b", Vector2(tx, p.position.y - 60), 150.0, 0.6, 0.0, Color.WHITE, 8)
			Sound.play("u_bat", 0.1, -6.0)
			_spell_box(p, Rect2(minf(p.position.x, p.position.x + p.face * 280.0), p.position.y - 70, 280, 80), 2, 2.0)
		"spikes":
			var tgt: Node = _nearest(p, 640.0)
			var sx: float = tgt.position.x if tgt else p.position.x + p.face * 160.0
			var sy: float = tgt.position.y if tgt else p.position.y
			fx.sprite("magic/stone_spikes", Vector2(sx, sy - 70), 160.0, 0.55, 0.0, Color.WHITE, 8)
			Sound.play("boom", 0.05, -3.0)
			shake = maxf(shake, 0.2)
			_spell_box(p, Rect2(sx - 50, sy - 200, 100, 210), 4, 0.0)
		"flame":
			for k in 3:
				var fxp: float = p.position.x + p.face * (80.0 + k * 90.0)
				var delay = k * 0.12
				get_tree().create_timer(delay).timeout.connect(func():
					fx.sprite("magic/flame_splash_ground", Vector2(fxp, p.position.y - 50), 130.0, 0.5, 0.0, Color.WHITE, 4)
					fx.sprite("magic/flame_flicker", Vector2(fxp, p.position.y - 50), 110.0, 0.6, 0.0, Color.WHITE, 4)
					Sound.play("whoosh", 0.1, -6.0)
					_spell_box(p, Rect2(fxp - 45, p.position.y - 110, 90, 120), 2, 0.0))
		"charm":
			var ct: Node = _nearest(p, 520.0)
			var cp: Vector2 = ct.hurt_rect().get_center() if ct else p.position + Vector2(p.face * 120, -50)
			fx.sprite("magic/heart_charm", cp + Vector2(0, -30), 150.0, 0.8, 0.0, Color.WHITE, 8)
			Sound.play("u_item", 0.05, -4.0)
			if ct:
				ct.hit(1, p.face)
				stun(ct, 3.0)
			p.hp = mini(p.max_hp, p.hp + 1)
			fx.text_float(p.position + Vector2(0, -90), "+1", Color("#ff9ad8"), 0.8)
		"glyph":
			fx.sprite("magic/heal_glyph_ground", p.position + Vector2(0, -40), 200.0, 0.9, 0.0, Color.WHITE, 8)
			Sound.play("heal")
			p.hp = mini(p.max_hp, p.hp + 2)
			fx.text_float(p.position + Vector2(0, -90), "+2", Color("#9fffc8"), 0.9)
		"smoke":
			_spell_smoke(p)
		"geyser":
			var best: Node = null
			var bd = 640.0
			for en in ents:
				if alive(en):
					var d = en.position.distance_to(p.position)
					if d < bd:
						bd = d
						best = en
			var gx: float = best.position.x if best else p.position.x + p.face * 160.0
			var gy: float = best.position.y if best else p.position.y
			fx.lasers.append({"a": Vector2(gx, gy + 4), "b": Vector2(gx, gy - 260), "life": 0.5, "max": 0.5, "c": Color(0.4, 0.75, 1.0), "k": "geyser"})
			Sound.play("splash")
			shake = maxf(shake, 0.2)
			for i in 20:
				fx.part(Vector2(gx, gy), Vector2(randf_range(-160, 160), -randf() * 420), "dust", Color("#9fe2ff"))
			fx.sprite("magic/stone_spikes", Vector2(gx, gy - 70), 150.0, 0.5, 0.0, Color(0.6, 0.85, 1.0), 8)
			for en in ents:
				if is_instance_valid(en) and not en.dead and absf(en.hurt_rect().get_center().x - gx) < 46.0 and absf(en.position.y - gy) < 220.0:
					en.hit(special_dmg(p, 4), 1)


func _nearest(p: Node, within: float) -> Node:
	var best: Node = null
	var bd = within
	for en in ents:
		if alive(en):
			var d: float = en.position.distance_to(p.position)
			if d < bd:
				bd = d
				best = en
	return best


## Spell damage helpers: everything alive in a circle or a box.
func _spell_area(p: Node, c: Vector2, r: float, base: int, stun_t: float) -> void:
	for en in ents:
		if alive(en) and en.hurt_rect().get_center().distance_to(c) < r:
			if en.hit(special_dmg(p, base), int(signf(en.position.x - p.position.x)) if en.position.x != p.position.x else 1) and stun_t > 0.0:
				stun(en, stun_t)


func _spell_box(p: Node, box: Rect2, base: int, stun_t: float) -> void:
	for en in ents:
		if alive(en) and en.hurt_rect().intersects(box):
			if en.hit(special_dmg(p, base), p.face) and stun_t > 0.0:
				stun(en, stun_t)


## Light Lance: like the psychic laser, in white light (diagonal when aimed).
func _spell_lance(p: CharacterBody2D) -> void:
	var dir: Vector2 = p.laser_dir
	var from: Vector2 = p.position + Vector2(p.face * 26, -48)
	var to: Vector2 = from + dir * 900.0
	var r = p.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, 1 | 8))
	if not r.is_empty():
		to = r["position"]
	var diag: bool = dir.y != 0.0
	var n = maxi(1, int(from.distance_to(to) / 110.0))
	for i in n:
		var at: Vector2 = from.lerp(to, (i + 0.5) / float(n))
		if diag:
			fx.sprite("magic/light_beam_diag", at, 170.0, 0.4, -PI / 2.0 if dir.x > 0.0 else PI, Color(1, 0.95, 0.8), 8)
		else:
			fx.sprite("magic/light_beam_h", at, 150.0, 0.4, 0.0 if dir.x > 0.0 else PI, Color(1, 0.95, 0.8), 8)
	Sound.play("beam", 0.05)
	shake = maxf(shake, 0.15)
	fx.burst(to, 14, 320, Color("#fff2c8"))
	for en in ents:
		if not alive(en):
			continue
		var box: Rect2 = en.hurt_rect().grow(14)
		# Sample along the beam: cheap segment-vs-box.
		for k in 12:
			if box.has_point(from.lerp(to, k / 11.0)):
				en.hit(special_dmg(p, 3), int(signf(dir.x)) if dir.x != 0.0 else 1)
				break


## Smoke Step: vanish, reappear up to 200px ahead (stopping at walls),
## hitting everything passed through.
func _spell_smoke(p: CharacterBody2D) -> void:
	var from: Vector2 = p.position
	var want: Vector2 = from + Vector2(p.face * 200.0, 0)
	var r = p.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from + Vector2(0, -30), want + Vector2(0, -30), 1))
	if not r.is_empty():
		want.x = r["position"].x - p.face * 20.0
	fx.sprite("magic/smoke_poof", from + Vector2(0, -40), 150.0, 0.45, 0.0, Color.WHITE, 8)
	p.position.x = want.x
	p.inv = maxf(p.inv, 0.3)
	fx.sprite("magic/smoke_poof", p.position + Vector2(0, -40), 150.0, 0.45, 0.0, Color.WHITE, 8)
	Sound.play("whoosh")
	_spell_box(p, Rect2(minf(from.x, want.x), from.y - 90, absf(want.x - from.x) + 1.0, 90), 1, 0.4)


func alive(en) -> bool:
	return is_instance_valid(en) and not en.dead and not (en.kind == "sleeper" and en.state == "down") and not (en.kind == "exhibit" and en.broken)


var _sum = 0


## Bosses call in extra enemies mid-fight.
func summon(kind: String, at: Vector2) -> void:
	_sum += 1
	var e = Imp.new() if kind == "imp" else Rider.new()
	e.main = self
	e.setup("sum%d_%d" % [_sum, randi() % 9999], at, 200.0)
	scale_enemy(e)
	ents_root.add_child(e)
	ents.append(e)
	fx.burst(at + Vector2(0, -30), 24, 300, Color("#ff6a8a"))
	Sound.play("glitch")


## Underbosses wake when the hero comes close (bosses wait for their cue).
func start_underboss(e: Node) -> void:
	if fight != null or mode != "play":
		return
	if e.cfg.has("devil") and e.state == "wait" and not e.introduced:
		# Azazel always has something to say first (voiced with ElevenLabs).
		e.state = "dormant"
		e.introduced = true
		Sound.line("vo_devil%d" % e.cfg["devil"])
		fx.sprite("magic/void_sigil_ring", e.position + Vector2(0, -60), 300.0, 1.0, 0.0, Color(0.5, 1.0, 0.95), 8)
		flash_screen(0.4, Color("#5ff2e0"))
		start_dialog(e.id, func():
			if is_instance_valid(e):
				e.state = "wait"
				start_underboss(e))
		return
	e.state = "idle"
	e.tm = 1.0
	fight = {"id": "underboss", "name": e.cfg["name"], "sub": e.cfg["sub"], "e": e}
	Sound.play("gate")
	Sound.play("u_roar", 0.0, -3.0)
	shake = 0.3


func underboss_defeated(e: Node) -> void:
	Game.set_flag("down_" + e.id)
	fight = null
	fx.projectiles.clear()
	for x in ents:
		if is_instance_valid(x) and (x.kind == "imp" or x.kind == "rider") and x.id.begins_with("sum"):
			x.hit(999, 1)
	boss_reward(140 if e.cfg.get("boss", false) else 90 + 25 * int(e.cfg.get("devil", 0)), e.cfg.get("item", ""), e.position + Vector2(0, -60))
	if e.cfg.has("lore") or e.id in ["devil1", "devil3", "devil5"]:
		toast("New lore unlocked · " + Game.label("menu") + " → LORE")
	if e.id == "auditor":
		get_tree().create_timer(1.2).timeout.connect(resolve_auditor)
		return
	if e.cfg.has("devil"):
		Sound.line("vo_devil_rest")
		get_tree().create_timer(1.6).timeout.connect(func(): start_dialog(e.id + "Out", func(): Sound.line("vo_devil_laugh")))
		return
	var done = {"monitor": "rooftopDone", "brood": "downtownDone", "warden": "underpassDone", "judge": "neonDone"}.get(e.id, "")
	if done != "":
		get_tree().create_timer(1.0).timeout.connect(func(): start_dialog(done))


func resolve_auditor() -> void:
	_boss_choice("THE AUDITOR", "The Office of Continuity's records spill across the floor. Psychometry shows you everything.",
		[{"k": "READ"}, {"k": "REACH", "d": "EXPOSE: send the files to Channel 6. Let Westbrook know."}, {"k": "BIND", "d": "CONFRONT: take the files home to your mother. Privately."},
		{"k": "STRIKE", "d": "INFILTRATE: burn the office and wear its access badge."}],
		[["narr", "", "READ: A lab, nineteen years ago. A young Ciencia presses a probe to a sleeping child's temple. The child projects. The worlds touch for the first time."], ["narr", "", "The child is Max."]],
		{"REACH": [["jason", "smirk", "Channel 6 has it. All of it. Good luck auditing that."], ["narr", "", "By morning, the Dharma Foundation's website is gone. Its office is empty. Its ads are not."]],
		"BIND": [["max", "worried", "Mom. We need to talk. About the lab. About me."], ["narr", "", "She doesn't cry. She just nods, like she has been waiting sixteen years for this."]],
		"STRIKE": [["lana", "angry", "Burn it."], ["narr", "", "The records go up. Max pockets a grey access badge. It has his photo on it already."]]},
		"auditorDone", "c5End", 5)


## Elite riders become a mini-boss fight the first time they notice you.
func start_elite(e: Node) -> void:
	if fight != null or mode != "play":
		return
	fight = {"id": "elite", "name": "STATIC RIDER", "sub": "Something that rode out of a nightmare", "e": e}
	Sound.play("gate")
	Sound.play("tp_gate_open", 0.0, -8.0)
	Sound.play("u_roar", 0.0, -2.0)
	shake = 0.3


func stun(en: Node, t: float) -> void:
	if en.kind in ["sleeper", "imp", "rider"] and "state" in en and en.state != "down" and not en.dead:
		en.state = "hurt"
		en.tm = t


## Max's psychic laser: a beam from his hands to the first wall, hitting every
## enemy along it for 3.
func fire_laser(p: CharacterBody2D) -> void:
	var dir: Vector2 = p.laser_dir
	var from: Vector2 = p.position + (Vector2(0, -96) if dir.y < 0.0 else Vector2(p.face * 26, -40))
	var to: Vector2 = from + dir * 900.0
	var q = PhysicsRayQueryParameters2D.create(from, to, 1 | 8)
	var r = p.get_world_2d().direct_space_state.intersect_ray(q)
	if not r.is_empty():
		to = r["position"]
	var thick = 34.0
	var beam = Rect2(from, Vector2.ZERO).expand(to)
	beam = beam.grow_individual(0, thick / 2.0, 0, thick / 2.0) if dir.y == 0.0 else beam.grow_individual(thick / 2.0, 0, thick / 2.0, 0)
	fx.lasers.append({"a": from, "b": to, "life": 0.3, "max": 0.3, "c": Color(0.72, 0.5, 1.0), "k": "laser"})
	Sound.play("beam", 0.05)
	Sound.play("u_shot", 0.05, -8.0)
	Game.rumble(0.3, 0.5, 0.2)
	shake = maxf(shake, 0.18)
	fx.burst(to, 16, 360, Color("#ffd6a0"))
	var hit = false
	for en in ents:
		if not is_instance_valid(en) or en.dead:
			continue
		var box: Rect2 = en.hurt_rect()
		if beam.intersects(box):
			if en.hit(3 + int(Game.mod("sdmg")) + p.dmg_bonus(), int(signf(dir.x)) if dir.x != 0.0 else 1):
				hit = true
				fx.burst(box.get_center(), 22, 460, Color("#fff2c8"))
	if hit:
		hitstop = 0.08
		Sound.play("hit", 0.08)


## Rage: unlimited, immortal, a doubled aura and every power at no cost, for
## whoever is being played. Toggled on and off with its own button (1).
func toggle_rage() -> void:
	if player.rage:
		player.rage = false
		player.aura.scale = Vector2.ONE
		toast("Rage fades. %s breathes again." % Game.HEROES[player.hero]["name"].capitalize())
		Sound.play("u_portal", 0.0, -6.0)
		return
	if astral_active():
		end_projection(false)
	player.rage = true
	player.res = 99.0
	player.inv = 0.0
	player.hp = player.max_hp
	Sound.play("u_roar", 0.0, -1.0)
	Sound.play("fp", 0.0, -4.0)
	flash_screen(0.6, Color("#ff3a6a"))
	shake = 0.5
	Game.rumble(0.8, 1.0, 0.5)
	for i in 50:
		var a = randf() * TAU
		fx.part(player.position + Vector2(0, -36), Vector2(cos(a), sin(a)) * randf_range(200, 520), "spark", Color("#ff6a9a") if i % 2 else Color("#c9b8ff"))
	fx.sprite("ring", player.position, 260.0, 0.5, 0.0, Color("#ff6a9a"), 4, 2)
	fx.sprite("magic/void_sigil_ring", player.position + Vector2(0, -40), 320.0, 0.8, 0.0, Color.WHITE, 8)
	toast("RAGE · %s can't be hurt · every power is free · %s to calm down" % [Game.HEROES[player.hero]["name"].capitalize(), Game.label("rage")])


## Lana & Jason's help in boss fights, on and off (2 by default). Takes effect
## at once, mid-fight included.
func toggle_allies() -> void:
	var on = not Game.settings.get("allies", true)
	Game.settings["allies"] = on
	Game.save_settings()
	Sound.play("select")
	if on:
		toast("Boss help ON · the others fight beside you · %s to turn off" % Game.label("allies"))
		if fight != null:
			_spawn_allies()
	else:
		toast("Boss help OFF · you fight bosses alone · %s to turn on" % Game.label("allies"))
		for a in allies:
			if is_instance_valid(a):
				fx.sprite("magic/smoke_poof", a.position + Vector2(0, -40), 130.0, 0.4, 0.0, Color.WHITE, 8)
		_clear_allies()


## Step to the next special this hero has unlocked (Max: his whole spellbook).
func cycle_special() -> void:
	if astral_active():
		return
	var h: String = player.hero
	var list: Array = []
	for sp in Game.HEROES[h]["specials"]:
		if Game.prog["level"] >= int(Game.SPECIALS[sp]["lv"]) or Game.story_mode():
			list.append(sp)
	if list.size() < 2:
		toast("No other specials yet")
		return
	var cur: String = Game.prog["special"].get(h, list[0])
	var nxt: String = list[(list.find(cur) + 1) % list.size()]
	Game.prog["special"][h] = nxt
	Sound.play("tick")
	fx.text_float(player.position + Vector2(0, -100), Game.SPECIALS[nxt]["name"].to_upper(), Color(Game.HEROES[h]["col"]), 0.9)
	toast("%s · %s (%d Resonance)" % [Game.SPECIALS[nxt]["name"], Game.SPECIALS[nxt]["d"], int(Game.special_cost(h))])


func hurt_player(d: int, from_x: float) -> void:
	if player.rage and mode == "play":
		if player.inv <= 0.0:
			player.inv = 0.35
			fx.burst(player.position + Vector2(0, -30), 10, 240, Color("#ff9ab8"))
			Sound.play("tp_shield_parry", 0.1, -10.0)
		return
	if player.inv > 0.0 or mode != "play":
		return
	player.hp -= d
	player.inv = 1.3
	player.heal_t = 0.0
	player.dash_t = 0.0
	player.dive = false
	player.kick_t = 0.0
	player.laser_t = 0.0
	var dir = signf(player.position.x - from_x)
	if dir == 0:
		dir = -player.face
	player.velocity = Vector2(dir * 330.0, -380.0)
	player.recoil_t = 0.15
	player.recoil_v = dir * 330.0
	hitstop = 0.12
	shake = 0.3
	flash_screen(0.25, Color.WHITE)
	Sound.play("hurt")
	Game.rumble(0.5, 0.8, 0.25)
	fx.burst(player.position + Vector2(0, -30), 14, 300, Color.WHITE)
	if astral_active():
		end_projection(true)
	if player.hp <= 0:
		_die()


func hurt_astral() -> void:
	if player.rage:
		return
	if not astral_active() or astral.ret > 0.0 or astral.inv > 0.0:
		return
	astral.inv = 1.0
	player.hp -= 1
	shake = 0.25
	flash_screen(0.3, Color("#a58bff"))
	Sound.play("hurt")
	toast("Your astral form shatters back into your body")
	end_projection(true)
	if player.hp <= 0:
		_die()


func _die() -> void:
	mode = "dead"
	dead_t = 0.0
	Sound.play("death")
	for i in 40:
		fx.part(player.position + Vector2(0, -30), Vector2(randf_range(-200, 200), randf_range(-200, 200)), "wisp", Color("#c9b8ff"))


func _respawn() -> void:
	var s = Game.save_data
	_reset_player()
	player.hp = player.max_hp
	player.inv = 1.0
	fight = null
	hist.clear()
	mode = "play"
	if s:
		load_room(s["room"], Vector2(s["x"], s["y"]))
	else:
		load_room("classroom", Vector2(140, 470))


func _full_potential() -> void:
	player.res = 0.0
	if not player.rage:
		Game.overdraw += 1
	Sound.play("fp")
	flash_screen(0.8, Color("#c9b8ff"))
	shake = 0.5
	hitstop = 0.2
	for i in 60:
		var a = randf() * TAU
		fx.part(player.position + Vector2(0, -30), Vector2(cos(a), sin(a)) * 500.0, "spark", Color("#c9b8ff") if i % 2 else Color("#ffb06a"))
	for e in ents:
		if not is_instance_valid(e) or e.dead:
			continue
		if e.hurt_rect().get_center().distance_to(player.position + Vector2(0, -30)) < 340.0:
			e.hit(5 if e.kind == "ciencia" else 4, int(signf(e.position.x - player.position.x)))
	fx.projectiles.clear()
	toast("FULL POTENTIAL. Something in you stays open." if Game.overdraw == 1 else "Overdraw %s. The open part of you widens." % ["", "I", "II", "III", "IV", "V"][mini(5, Game.overdraw)])


# ---------- story ----------

func _fire_event(ev: String) -> void:
	if ev.begins_with("dlg_"):
		var did = ev.substr(4)
		if not Game.flag("seen_" + did):
			Game.set_flag("seen_" + did)
			start_dialog(did)
		return
	match ev:
		"firstProjection":
			if Game.flag("projected"):
				return
			Game.set_flag("projected")
			Game.ability["project"] = true
			player.velocity.x = 0
			start_dialog("firstProjection", func(): start_projection(true); toast("Reach the sigil behind the chained door"))
		"echoArena":
			if Game.flag("echoDone") or fight != null:
				return
			var begin = func():
				var e = Echo.new()
				e.main = self
				e.setup(Vector2(2950, 470))
				scale_enemy(e)
				ents_root.add_child(e)
				ents.append(e)
				hist.clear()
				fight = {"id": "echo", "name": "HALLWAY ECHO", "sub": "The memory you keep replaying", "e": e}
				Sound.play("gate")
				shake = 0.3
			start_dialog("echoIntro", begin)
		"carrierArena":
			if Game.flag("carrierDone") or fight != null:
				return
			var kai: Node = null
			for e in ents:
				if is_instance_valid(e) and e.kind == "carrier":
					kai = e
			if kai == null:
				return
			var go_c = func():
				kai.state = "idle"
				kai.tm = 1.0
				fight = {"id": "carrier", "name": "THE CARRIER", "sub": "Kai Brooks, speaking in three voices", "e": kai}
				Sound.play("gate")
				shake = 0.3
			start_dialog("carrierIntro", go_c)
		"tideArena":
			if Game.flag("tideDone") or fight != null:
				return
			var tide: Node = null
			for e in ents:
				if is_instance_valid(e) and e.kind == "tide":
					tide = e
			if tide == null:
				return
			var go_t = func():
				tide.state = "idle"
				tide.tm = 1.2
				fight = {"id": "tide", "name": "THE RED TIDE", "sub": "Everything the town drank", "e": tide}
				Sound.play("gate")
				shake = 0.3
			start_dialog("tideIntro", go_t)
		"auditorArena":
			if Game.flag("down_auditor") or fight != null:
				return
			var ab: Node = null
			for e in ents:
				if is_instance_valid(e) and e.kind == "underboss" and e.id == "auditor":
					ab = e
			if ab == null:
				return
			start_dialog("auditorIntro", func(): start_underboss(ab))
		"eliteIntro":
			if Game.flag("eliteIntro") or Game.flag("down_elite_r4"):
				return
			Game.set_flag("eliteIntro")
			start_dialog("eliteIntro")
		"gymIntro":
			if Game.flag("gymIntro"):
				return
			Game.set_flag("gymIntro")
			start_dialog("gymIntro")
		"collectiveArena":
			if Game.flag("collectiveDone") or fight != null:
				return
			var cb: Node = null
			for e in ents:
				if is_instance_valid(e) and e.kind == "collective":
					cb = e
			if cb == null:
				return
			var go4 = func():
				cb.state = "idle"
				cb.tm = 1.0
				fight = {"id": "collective", "name": "COLLECTIVE COGNITION", "sub": "Dr. Ciencia, wired into four hundred minds", "e": cb}
				Sound.play("gate")
				shake = 0.3
			start_dialog("collectiveIntro", go4)
		"cienciaArena":
			if Game.flag("cienciaDone") or fight != null:
				return
			var boss: Node = null
			for e in ents:
				if is_instance_valid(e) and e.kind == "ciencia":
					boss = e
			if boss == null:
				return
			var all_saved = int(Game.flags.get("stabilized", 0)) >= 4
			Game.set_flag("allSaved", all_saved)
			if all_saved:
				boss.hp = 30
				scale_enemy(boss)
			var extra: Array = (Game.DLG["cienciaAllSaved"] if all_saved else Game.DLG["cienciaSomeSaved"]) + Game.DLG["cienciaGo"]
			var begin = func():
				boss.state = "idle"
				boss.tm = 1.0
				fight = {"id": "ciencia", "name": "DR. CIENCIA", "sub": "The Teacher Who Was Fired", "e": boss}
				Sound.play("gate")
				shake = 0.3
			start_dialog("cienciaIntro", begin, extra)


var _choice_cb: Callable


func _on_choice(key: String) -> void:
	ui.hide_choice()
	mode = "play"
	if _choice_cb.is_valid():
		_choice_cb.call(key)


func _show_choice(title: String, sub: String, opts: Array, cb: Callable) -> void:
	mode = "choice"
	_choice_cb = cb
	Sound.play("choice")
	ui.show_choice(title, sub, opts)


var _echo: Node


func _echo_opts(read: bool) -> Array:
	return [{"k": "READ", "disabled": read}, {"k": "REACH", "d": "Admit the memory out loud."}, {"k": "BIND", "d": "Trap it in Room 101. Safe now. It remains."}, {"k": "STRIKE", "d": "Destroy it."}]


func resolve_echo(e: Node) -> void:
	_echo = e
	e.state = "rise"
	e.tm = 0.0
	fx.projectiles.clear()
	get_tree().create_timer(0.5).timeout.connect(func(): _show_choice("HALLWAY ECHO", "It stops moving. It is waiting for you to decide.", _echo_opts(false), _echo_pick))


func _echo_pick(k: String) -> void:
	if k == "READ":
		Game.witness += 1
		say([["narr", "", "READ: The Echo is a memory. Eighth grade. You waved back at someone who was waving at the person behind you."], ["narr", "", "You replay it every night. It learned to walk."]],
			func(): _show_choice("HALLWAY ECHO", "What do you do with it?", _echo_opts(true), _echo_pick))
		return
	Game.set_flag("echoDone")
	fight = null
	if is_instance_valid(_echo):
		boss_reward(70, "hallpass", _echo.position + Vector2(0, -40))
		_echo.dead = true
		fx.burst(_echo.position + Vector2(0, -30), 30, 300, Color("#9fb6ff"))
	match k:
		"REACH":
			Game.tend["connection"] += 1
			say([["max", "worried", "Okay! Fine! In eighth grade I waved at Tasha Okafor and she was waving at her MOM. I think about it every single day!"], ["narr", "", "The Echo stops. For a second it looks almost relieved. Then it is just a hallway again."]])
		"BIND":
			Game.tend["control"] += 1
			say([["narr", "", "You fold the Echo into the corner of Room 101 and hold it there until it stops struggling."], ["narr", "", "It is quiet now. It will still be there tomorrow."]])
		_:
			Game.tend["rupture"] += 1
			say([["narr", "", "The Echo comes apart like wet paper."], ["narr", "", "Later, you will not remember why this hallway used to make you flinch."]])
	Game.write_save(room_id, player.position)


func _ciencia_opts(read: bool) -> Array:
	return [{"k": "READ", "disabled": read, "d": "Psychometry. Touch what he remembers."}, {"k": "REACH", "d": "Make him feel every person he reduced to data."},
		{"k": "BIND", "d": "Bind him to the failing transmitter as a Seal patch."}, {"k": "STRIKE", "d": "Destroy him and the relay. Some knowledge dies too."}]


func resolve_ciencia(_e: Node) -> void:
	_show_choice("DR. CIENCIA", "He is on his knees. The Choir is still humming through the walls.", _ciencia_opts(false), _ciencia_pick)


func _ciencia_pick(k: String) -> void:
	if k == "READ":
		Game.witness += 1
		say([["narr", "", "READ: A fired man alone in an empty lab, apologizing to a microscope."], ["narr", "", "Underneath that: a black sun. It is not in the sky. It is looking back."]],
			func(): _show_choice("DR. CIENCIA", "He is on his knees. The Choir is still humming through the walls.", _ciencia_opts(true), _ciencia_pick))
		return
	Game.set_flag("cienciaDone")
	Game.flags["ending"] = k
	fight = null
	boss_reward(120, "goggles", player.position + Vector2(player.face * 80, -60))
	var lines: Array = {
		"REACH": [["narr", "", "You open his mind and pour them in. Devon. Brayden. Coach Reyes. Four hundred and twelve names, one at a time."], ["ciencia", "sad", "They were... people. Each one so loud. So particular."], ["narr", "", "The transmitter goes quiet. Somewhere above, a cafeteria full of kids picks up their forks."]],
		"BIND": [["narr", "", "You wrap him in his own signal and nail it to the failing transmitter. A man-shaped patch on a broken wall."], ["ciencia", "worried", "You would use me. Good. Then you understand me."], ["narr", "", "The signal holds. For now. You decided that for everyone."]],
		"STRIKE": [["narr", "", "You tear the relay apart and Ciencia with it. The lab goes very bright, then very dark."], ["narr", "", "Whatever he knew about the Choir is gone. So is the one person who could have explained it."]],
	}[k].duplicate()
	if k == "REACH":
		Game.tend["connection"] += 2
	elif k == "BIND":
		Game.tend["control"] += 2
	else:
		Game.tend["rupture"] += 2
	if k != "STRIKE":
		lines.append(["ciencia", "shocked", "No... it was never in my system. It was in theirs. It is in ALL of them."])
	say(lines, func(): start_dialog("ending", func(): _chapter_end(1)))


func set_tide(level: float) -> void:
	for h in room.markers["hazard"]:
		if h.id == "tide":
			h.position.y = level
			h.size.y = 540.0 - level


func tide_awaken(_e: Node) -> void:
	fx.projectiles.clear()
	set_tide(478.0)
	var after = func():
		Game.set_flag("tideClear")
		flash_screen(0.6, Color("#9fe2ff"))
		Sound.play("djump")
	start_dialog("tideAwaken", after)


var _bc = {}


func _boss_choice(title: String, sub: String, opts: Array, read_lines: Array, results: Dictionary, done_flag: String, end_dialog: String, chapter: int) -> void:
	_bc = {"title": title, "sub": sub, "opts": opts, "read": read_lines, "results": results, "flag": done_flag, "end": end_dialog, "chapter": chapter}
	_bc_show(false)


func _bc_show(read: bool) -> void:
	var o: Array = _bc["opts"].duplicate(true)
	o[0]["disabled"] = read
	_show_choice(_bc["title"], _bc["sub"], o, _bc_pick)


func _bc_pick(k: String) -> void:
	if k == "READ":
		Game.witness += 1
		say(_bc["read"], func(): _bc_show(true))
		return
	Game.set_flag(_bc["flag"])
	Game.flags[_bc["flag"] + "_choice"] = k
	fight = null
	var rw: Array = {"carrierDone": [150, "wristband"], "tideDone": [190, "stone"], "collectiveDone": [260, "seal"]}.get(_bc["flag"], [100, ""])
	boss_reward(rw[0], rw[1], player.position + Vector2(player.face * 80, -60))
	Game.tend[{"REACH": "connection", "BIND": "control", "STRIKE": "rupture"}[k]] += 2
	var ch: int = _bc["chapter"]
	var end_d: String = _bc["end"]
	say(_bc["results"][k], func(): start_dialog(end_d, func(): _chapter_end(ch)))


func resolve_carrier(_e: Node) -> void:
	_boss_choice("KAI BROOKS", "Three voices argue inside him. One of them is his.",
		[{"k": "READ"}, {"k": "REACH", "d": "Say his name together with Lana until only his voice answers."}, {"k": "BIND", "d": "Hold the voices asleep inside him. Safe now. They stay."}, {"k": "STRIKE", "d": "Tear the voices out. Some of Kai may come with them."}],
		[["narr", "", "READ: Three voices. Kai's. A woman who drowned in the reservoir in 1962. And something that only counts, very slowly, toward seven."]],
		{"REACH": [["lana", "neutral", "Kai. Kai Brooks. You owe me five dollars and an apology for second grade."], ["max", "neutral", "Kai. Come on back. It's loud out here, but it's ours."], ["narr", "", "The second voice says thank you, and goes. The third does not answer at all."]],
		"BIND": [["narr", "", "You fold the voices down into him and hold them there until he sleeps."], ["narr", "", "He wakes as himself. Sometimes, when it rains, he hums."]],
		"STRIKE": [["narr", "", "You pull the voices out like threads. They come loose. So does something else."], ["narr", "", "Kai wakes up and cannot remember his little sister's name."]]},
		"carrierDone", "c2End", 2)


func resolve_tide(_e: Node) -> void:
	_boss_choice("THE RED TIDE", "Jason holds it still. It is waiting to see who decides.",
		[{"k": "READ"}, {"k": "REACH", "d": "Let Jason ask the water to let go of everyone it remembers."}, {"k": "BIND", "d": "Jason seals it in the reservoir and keeps watch. Forever."}, {"k": "STRIKE", "d": "Boil it apart. The memories it holds go with it."}],
		[["narr", "", "READ: It is not waste. It is memory. Every glass of water this town drank left something behind."]],
		{"REACH": [["jason", "worried", "You can go. All of you. Nobody is going to forget you. I promise."], ["narr", "", "The tide comes apart into warm rain on the pumphouse roof."]],
		"BIND": [["jason", "angry", "You stay down there. I will be listening."], ["narr", "", "The red sinks into the reservoir and goes still. Jason does not sleep well after that."]],
		"STRIKE": [["narr", "", "You and Jason boil it apart. The pumphouse fills with steam that smells like a hundred different kitchens."], ["narr", "", "Something under the reservoir learns Jason's name anyway."]]},
		"tideDone", "c3End", 3)


func resolve_collective(_e: Node) -> void:
	for e in ents:
		if is_instance_valid(e) and (e.kind == "imp" or e.kind == "rider") and e.id.begins_with("sum"):
			e.hit(999, 1)
	fx.projectiles.clear()
	_boss_choice("DR. CIENCIA", "The exhibit sparks. Four hundred minds hang on what you choose.",
		[{"k": "READ"}, {"k": "REACH", "d": "Give every mind back to its owner, one at a time."}, {"k": "BIND", "d": "Seal him inside his own exhibit. First place, forever."}, {"k": "STRIKE", "d": "Tear the exhibit apart, and the network with it."}],
		[["narr", "", "READ: A letterhead. THE DHARMA ORDER · SUBJECT 7 · INOKI, MAX."], ["narr", "", "Under it, in Ciencia's handwriting: He is the receiver. Not me. Never me."]],
		{"REACH": [["max", "angry", "You don't get to be a thought, Doc. You're a person. So are they."], ["narr", "", "Two hundred parents blink at once. Somebody's dad asks where the bathroom is."], ["ciencia", "worried", "I only wanted them to hear it too..."]],
		"BIND": [["narr", "", "You wire him into his own exhibit and lock the glass."], ["ciencia", "worried", "This is... a display case."], ["lana", "smirk", "Congrats on first place."]],
		"STRIKE": [["narr", "", "You tear the exhibit apart. The gym lights burst one by one."], ["narr", "", "The ribbon on the wreckage says HONORABLE MENTION."]]},
		"collectiveDone", "c4End", 4)


func _chapter_end(n: int) -> void:
	mode = "end"
	Sound.play("endsting")
	var has_next: bool = Game.CHAPTERS.has(n + 1)
	if has_next:
		Game.unlock(n + 1)
		var c: Dictionary = Game.CHAPTERS[n + 1]
		Game.chapter = n + 1
		Game.write_save(c["room"], c["spawn"])
	else:
		Game.clear_save()
	var key = {1: "ending", 2: "carrierDone_choice", 3: "tideDone_choice", 4: "collectiveDone_choice", 5: "auditorDone_choice"}[n]
	var k: String = Game.flags.get(key, "")
	var titles = {
		1: {"REACH": "The Signal Goes Quiet", "BIND": "A Patch on a Broken Wall", "STRIKE": "Very Bright, Then Very Dark"},
		2: {"REACH": "One Voice Answers", "BIND": "He Hums When It Rains", "STRIKE": "A Name Left Behind"},
		3: {"REACH": "Warm Rain", "BIND": "The Listener Under the Water", "STRIKE": "A Hundred Kitchens"},
		4: {"REACH": "Four Hundred Minds Come Home", "BIND": "First Place, Forever", "STRIKE": "Honorable Mention"},
		5: {"REACH": "Exposed", "BIND": "The Quiet Room", "STRIKE": "Burned Records"},
	}
	var td: Dictionary = Game.tend
	var lead = "RUPTURE"
	if td["connection"] >= td["control"] and td["connection"] >= td["rupture"]:
		lead = "CONNECTION"
	elif td["control"] >= td["rupture"]:
		lead = "CONTROL"
	var stats = [["Connection", td["connection"]], ["Control", td["control"]], ["Rupture", td["rupture"]], ["Witness", Game.witness],
		["Stabilized", int(Game.flags.get("stabilized", 0))], ["Anchors", "%d / %d" % [Game.anchors.size(), Game.ANCH.size()]], ["Overdraws", Game.overdraw],
		["Party level", Game.prog["level"]], ["Gear found", "%d / %d" % [Game.prog["items"].size(), Game.ITEMS.size()]]]
	if n == 3:
		stats.append(["Workers saved", "%d / 3" % int(Game.flags.get("rescued", 0))])
	ui.show_end(n, titles[n].get(k, "Chapter Complete"), lead, stats, has_next)


# ---------- party ----------

func _check_switch() -> void:
	var want = ""
	var party: Array = Game.party()
	if Input.is_action_just_pressed("switch") and party.size() > 1:
		want = party[(party.find(player.hero) + 1) % party.size()]
	if want != "" and want != player.hero:
		switch_hero(want)


func switch_hero(h: String) -> void:
	if astral_active():
		toast("Return to your body first")
		return
	if not Game.hero_unlocked(h):
		return
	var frac: float = float(player.hp) / float(maxi(1, player.max_hp))
	player.set_hero(h)
	Game.prog["hero"] = h
	player.max_hp = Game.hero_max_hp(h)
	player.hp = clampi(int(ceil(frac * player.max_hp)), 1, player.max_hp)
	player.inv = maxf(player.inv, 0.4)
	player.flurry_t = 0.0
	player.laser_t = 0.0
	Sound.play("swap")
	Sound.play("u_swap", 0.05, -8.0)
	fx.sprite("magic/smoke_poof", player.position + Vector2(0, -40), 150.0, 0.45, 0.0, Color.WHITE, 8)
	fx.burst(player.position + Vector2(0, -34), 26, 320, Color(Game.HEROES[h]["col"]))
	fx.sprite("ring", player.position + Vector2(0, -4), 150.0, 0.35, 0.0, Color(Game.HEROES[h]["col"]), 4, 2)
	toast("Playing as " + Game.HEROES[h]["name"].capitalize())
	if fight != null:
		_spawn_allies()


func _clear_allies() -> void:
	for a in allies:
		if is_instance_valid(a):
			a.queue_free()
	allies.clear()


## Bosses (except the Echo, which is Max's alone) are fought by the whole trio:
## whoever isn't being played fights alongside.
func _spawn_allies() -> void:
	_clear_allies()
	if fight == null or fight_id() == "echo" or not Game.settings.get("allies", true):
		return
	var present = ["max", "lana", "jason"]
	var i = 0
	for h in present:
		if h == player.hero:
			continue
		var a = AllyScript.new()
		a.main = self
		a.hero = h
		a.position = player.position + Vector2(-60 - i * 50, 0)
		a.slot = i
		ents_root.add_child(a)
		allies.append(a)
		fx.burst(a.position + Vector2(0, -30), 20, 260, Color(Game.HEROES[h]["col"]))
		i += 1


func _update_allies(dt: float) -> void:
	if fight == null:
		_allies_spawned = false
		if not allies.is_empty():
			_clear_allies()
		return
	if allies.is_empty() and fight_id() != "echo" and not _allies_spawned:
		_allies_spawned = true
		_spawn_allies()
		say_toast_party()
	for a in allies:
		if is_instance_valid(a):
			a.tick(dt)


var _allies_spawned = false


func say_toast_party() -> void:
	var names = []
	for a in allies:
		names.append(Game.HEROES[a.hero]["name"].capitalize())
	if not names.is_empty():
		toast(" and ".join(names) + " fight beside you")


# ---------- loot & experience ----------

## Called by enemies when they go down: drops experience, health,
## Resonance and (rarely) equipment.
func enemy_defeated(e: Node, xp: int) -> void:
	var at: Vector2 = e.position + Vector2(0, -30)
	var shards = clampi(xp / 5, 2, 10)
	for i in shards:
		_drop("xp", at, {"xp": int(ceil(float(xp) / shards))})
	var luck = 0.28 + Game.mod("luck") + Game.attr(player.hero, "lck") * 0.03
	if randf() < luck:
		_drop("hp", at, {})
	if randf() < 0.3:
		_drop("res", at, {})
	if randf() < 0.07:
		var pool = []
		for it in Game.DROP_POOL:
			if not it in Game.prog["items"]:
				pool.append(it)
		if not pool.is_empty():
			_drop("item", at, {"item": pool[randi() % pool.size()]})


## Boss rewards are granted at once (a chapter may end right after).
func boss_reward(xp: int, item: String, at: Vector2) -> void:
	for i in 30:
		fx.part(at, Vector2(randf_range(-260, 260), randf_range(-320, 60)), "res", Color("#e6dcff"), player)
	if Game.gain_xp(xp) > 0:
		_level_up()
	var got = ["+%d XP" % xp]
	if item != "" and Game.give_item(item):
		got.append(Game.ITEMS[item]["name"])
		Sound.play("unlock")
	toast("Reward: " + " · ".join(got))


func _drop(k: String, at: Vector2, extra: Dictionary) -> void:
	var pk = {"p": at, "v": Vector2(randf_range(-170, 170), -260 - randf() * 180), "k": k, "age": 0.0, "seed": randf() * 6.0}
	pk.merge(extra)
	pickups.append(pk)


func _update_pickups(dt: float) -> void:
	if room == null:
		return
	var c: Node = player
	var pc: Vector2 = c.position + Vector2(0, -28)
	for pk in pickups:
		pk["age"] += dt
		if pk.get("fixed", false):
			if pc.distance_to(pk["p"]) < 34.0 and not astral_active():
				_collect(pk)
			continue
		var d: float = pc.distance_to(pk["p"])
		if pk["age"] > 0.45 and d < 110.0 and not astral_active():
			pk["p"] = pk["p"].move_toward(pc, (380.0 + (110.0 - d) * 8.0) * dt)
			if d < 20.0:
				_collect(pk)
			continue
		pk["v"].y = minf(pk["v"].y + 1500.0 * dt, 700.0)
		pk["v"].x *= 0.985
		var np: Vector2 = pk["p"] + pk["v"] * dt
		var fl: Vector2 = room.floor_below(Vector2(np.x, pk["p"].y))
		if np.y >= fl.y - 6.0 and pk["v"].y > 0.0:
			np.y = fl.y - 6.0
			pk["v"].y *= -0.35
			pk["v"].x *= 0.7
		if np.x < 10 or np.x > room.room_size.x - 10:
			pk["v"].x *= -1
			np.x = clampf(np.x, 10, room.room_size.x - 10)
		pk["p"] = np
		if pk["age"] > 30.0 and pk["k"] in ["xp", "res", "hp"]:
			pk["gone"] = true
	pickups = pickups.filter(func(x): return not x.get("gone", false))


func _collect(pk: Dictionary) -> void:
	pk["gone"] = true
	match pk["k"]:
		"xp":
			Sound.play("pickup", 0.2, -10.0)
			var ups = Game.gain_xp(pk["xp"])
			if ups > 0:
				_level_up()
		"hp":
			Sound.play("heal", 0.05, -4.0)
			if player.hp < player.max_hp:
				player.hp += 1
				fx.text_float(player.position + Vector2(0, -80), "+1", Color("#bfffd0"), 1.0)
		"res":
			Sound.play("pickup", 0.1, -6.0)
			_gain_res(15.0)
		"heart":
			Game.prog["picked"][pk["id"]] = true
			Game.prog["hp_bonus"] = int(Game.prog.get("hp_bonus", 0)) + 1
			player.max_hp = Game.hero_max_hp(player.hero)
			player.hp = player.max_hp
			Sound.play("unlock")
			flash_screen(0.35, Color("#ff9ab0"))
			card = {"name": "Heart Ember", "sub": "Maximum health +1 for the whole party", "t": 0.0}
		"item":
			if pk.has("id"):
				Game.prog["picked"][pk["id"]] = true
			var it: String = pk["item"]
			Game.give_item(it)
			Sound.play("unlock")
			Sound.play("u_item", 0.0, -4.0)
			flash_screen(0.3, Color("#ffd68a"))
			card = {"name": Game.ITEMS[it]["name"], "sub": Game.ITEMS[it]["d"] + "   [" + Game.label("menu") + "] to equip", "t": 0.0}
			var m: int = Game.hero_max_hp(player.hero)
			player.hp = clampi(player.hp + (m - player.max_hp), 1, m)
			player.max_hp = m


func _level_up() -> void:
	Sound.play("levelup")
	flash_screen(0.3, Color("#fff2c8"))
	fx.burst(player.position + Vector2(0, -34), 40, 420, Color("#fff2c8"))
	fx.sprite("ring", player.position, 180.0, 0.4, 0.0, Color("#fff2c8"), 4, 2)
	toast("LEVEL %d · Attribute points to spend [%s]" % [Game.prog["level"], Game.label("menu")])
