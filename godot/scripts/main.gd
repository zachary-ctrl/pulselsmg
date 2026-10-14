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
	show_title()
	if "--autotest" in OS.get_cmdline_user_args():
		add_child(load("res://tools/autotest.gd").new())


# ---------- modes ----------

func show_title() -> void:
	mode = "title"
	fight = null
	ui.hide_end()
	ui.hide_pause()
	ui.show_title(Game.read_save() != null)
	Sound.music("title")
	world.visible = false


func new_game() -> void:
	Game.clear_save()
	Game.new_game()
	_reset_player()
	_enter_play()
	load_room("classroom", Vector2(140, 470))


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
	player.hp = 5
	player.max_hp = 5
	player.res = 0.0
	player.inv = 0.0
	player.velocity = Vector2.ZERO


func _enter_play() -> void:
	ui.hide_title()
	ui.hide_end()
	world.visible = true
	mode = "play"
	fight = null
	hist.clear()


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
	for L in m["layers"]:
		_bg_tex.append({"tex": load("res://assets/rooms/" + L["file"]), "f": L["f"], "w": L["w"], "h": L["h"]})
	world_art.texture = load("res://assets/rooms/%s_world.png" % id)
	_fg_tex = load("res://assets/rooms/%s_fg.png" % id)
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
	for n in room.markers["npc"]:
		var r = Rig.new()
		r.key = n.id
		r.position = n.position
		ents_root.add_child(r)
		npcs.append({"m": n, "node": r, "near": false, "face": n.face})
	zoom = 1.0 if fight != null else 1.22
	var vw = W / zoom
	var vh = H / zoom
	cam = Vector2(clampf(spawn.x - vw / 2, 0, room.room_size.x - vw), clampf(spawn.y - vh * 0.62, 0, room.room_size.y - vh))
	Sound.ambience(id)
	if not Game.visited.has(id):
		Game.visited[id] = true
		card = {"name": room.display_name, "sub": room.subtitle, "t": 0.0}
		Sound.play("gong")
	if id == "classroom" and not Game.flag("intro"):
		Game.set_flag("intro")
		start_dialog("intro")


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
		_:
			return
	ents_root.add_child(e)
	ents.append(e)


func spawn_add() -> void:
	var e = Sleeper.new()
	e.main = self
	e.setup("sx", Vector2(1000 if player.position.x < 560 else 120, 470), 150, false)
	e.state = "notice"
	e.tm = 0.8
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
		"title", "boot", "pause", "choice", "end":
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
	if Input.is_action_just_pressed("fp") and player.res >= 99.0 and not astral_active():
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
			e.step(dt)
	for e in ents:
		if is_instance_valid(e) and e.dead and e.kind != "sleeper":
			e.queue_free()
	ents = ents.filter(func(e): return is_instance_valid(e) and not (e.dead and e.kind != "sleeper"))
	if fight_id() == "echo":
		hist.append({"t": t, "pos": player.position, "face": player.face, "moving": absf(player.velocity.x) > 20.0 and player.is_on_floor(), "air": not player.is_on_floor(), "vy": player.velocity.y, "ph": player.run_ph})
		while hist.size() > 0 and hist[0]["t"] < t - 4.0:
			hist.pop_front()
	fx.step(dt)
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
		Sound.music("title" if mode == "title" else "")
		return
	var c = ctrl()
	zoom = move_toward(zoom, 1.0 if fight != null else 1.22, dt * 0.5)
	var vw = W / zoom
	var vh = H / zoom
	var target = Vector2(clampf(c.position.x - vw / 2 + c.face * 34, 0, maxf(0.0, room.room_size.x - vw)), clampf(c.position.y - vh * 0.62, 0, maxf(0.0, room.room_size.y - vh)))
	cam = cam.lerp(target, minf(1.0, dt * 5.5))
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
	for n in npcs:
		var m: Node = n["m"]
		n["node"].pose = {"face": n["face"], "t": t, "seed": m.position.x}
	bg.queue_redraw()
	fg.queue_redraw()
	var mus = "explore"
	if mode == "end":
		mus = "end"
	elif fight != null:
		mus = "echo" if fight["id"] == "echo" else ("ciencia2" if (is_instance_valid(fight["e"]) and fight["e"].phase2) else "ciencia")
	elif astral_active():
		mus = "astral"
	Sound.music(mus)


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
		if Game.anchors.has(a.id):
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
	var hit = false
	var pogo = false
	for en in ents:
		if not is_instance_valid(en) or en.dead or e.hit_set.has(en):
			continue
		if e.is_astral and not en.astral_only and en.kind != "ciencia":
			continue
		var box: Rect2 = en.hurt_rect()
		if b.intersects(box):
			var dir: int = e.face if e.atk_dir == "side" else (int(signf(en.position.x - e.position.x)) if en.position.x != e.position.x else 1)
			if en.hit(1, dir):
				e.hit_set[en] = true
				hit = true
				if e.atk_dir == "down":
					pogo = true
				player.res = minf(99.0, player.res + 11.0)
				fx.burst(box.get_center(), 10, 300, Color("#ffd6a0"))
				for i in 3:
					fx.part(en.position + Vector2(0, -20), Vector2.ZERO, "res", Color("#ffb06a"), player)
	if not e.is_astral and e.atk_dir == "down" and not pogo:
		if room.hazard_at(Rect2(b.position, b.size + Vector2(0, 6))) != null:
			pogo = true
	if hit:
		hitstop = 0.055
		Sound.play("hit", 0.08)
		shake = maxf(shake, 0.08)
	if pogo and not e.pogo_done:
		e.velocity.y = -640.0
		e.jump_cut = true
		e.used_double = false
		e.air_dash = true
		e.pogo_done = true
	elif hit and e.atk_dir == "side":
		e.recoil_t = 0.07
		e.recoil_v = -e.face * 230.0


func hurt_player(d: int, from_x: float) -> void:
	if player.inv > 0.0 or mode != "play":
		return
	player.hp -= d
	player.inv = 1.3
	player.heal_t = 0.0
	player.dash_t = 0.0
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
	fx.burst(player.position + Vector2(0, -30), 14, 300, Color.WHITE)
	if astral_active():
		end_projection(true)
	if player.hp <= 0:
		_die()


func hurt_astral() -> void:
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
				ents_root.add_child(e)
				ents.append(e)
				hist.clear()
				fight = {"id": "echo", "name": "HALLWAY ECHO", "sub": "The memory you keep replaying", "e": e}
				Sound.play("gate")
				shake = 0.3
			start_dialog("echoIntro", begin)
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
				boss.max_hp = 30
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
	say(lines, func(): start_dialog("ending", _show_end))


func _show_end() -> void:
	mode = "end"
	Game.clear_save()
	Sound.play("endsting")
	var k: String = Game.flags.get("ending", "")
	var title: String = {"REACH": "The Signal Goes Quiet", "BIND": "A Patch on a Broken Wall", "STRIKE": "Very Bright, Then Very Dark"}.get(k, "Chapter Complete")
	var td: Dictionary = Game.tend
	var lead = "RUPTURE"
	if td["connection"] >= td["control"] and td["connection"] >= td["rupture"]:
		lead = "CONNECTION"
	elif td["control"] >= td["rupture"]:
		lead = "CONTROL"
	ui.show_end(title, lead, [["Connection", td["connection"]], ["Control", td["control"]], ["Rupture", td["rupture"]], ["Witness", Game.witness],
		["Stabilized", "%d / 4" % int(Game.flags.get("stabilized", 0))], ["Anchors", "%d / 5" % Game.anchors.size()], ["Overdraws", Game.overdraw]])
