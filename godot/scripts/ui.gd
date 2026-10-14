extends Control
## Dialogue box with portraits, choice panel, title, pause and end screens,
## and on-screen touch buttons.

signal choice_made(key: String)

var main: Node
var dlg = null
var _choice_panel: PanelContainer
var _choice_grid: GridContainer
var _choice_title: Label
var _choice_sub: Label
var _choice_armed_at = 0.0
var _title: Control
var _btn_continue: Button
var _pause: PanelContainer
var _btn_diff: Button
var _end: PanelContainer
var _end_body: VBoxContainer
var _touch: Control
var _menu: PanelContainer
var _menu_body: VBoxContainer
var _menu_tab = 0
var _menu_desc: Label
var _map_ctrl: Control = null
var _theme: Theme

const CMD := {"READ": "Observe. Reveals memories, rules and hidden truths.", "REACH": "Emotional or psychic contact. The path toward non-destructive endings.",
	"BIND": "Restrict it with your power. Safe now. It stays.", "STRIKE": "Destroy it. Fast and final. Some things will not come back."}
const CMD_COLOR := {"READ": Color("#9fd0ff"), "REACH": Color("#ffb38a"), "BIND": Color("#c6a8ff"), "STRIKE": Color("#ff8a8a")}


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(960, 540)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_theme = Theme.new()
	# Cyberpunk pixel GUI (craftpix): 9-sliced metal panel and buttons.
	var sb = _tex_box("panel", 12, 20, Color(1, 1, 1, 0.96))
	_theme.set_stylebox("panel", "PanelContainer", sb)
	var bn = _tex_box("button", 10, 10)
	var bh = _tex_box("button_hot", 10, 10)
	var bd = _tex_box("button_off", 10, 10, Color(1, 1, 1, 0.6))
	_theme.set_stylebox("normal", "Button", bn)
	_theme.set_stylebox("hover", "Button", bh)
	_theme.set_stylebox("focus", "Button", bh)
	_theme.set_stylebox("pressed", "Button", bh)
	_theme.set_stylebox("disabled", "Button", bd)
	_theme.set_color("font_disabled_color", "Button", Color(0.75, 0.72, 0.8, 0.5))
	_theme.set_color("font_hover_color", "Button", Color.WHITE)
	_theme.set_color("font_focus_color", "Button", Color.WHITE)
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.1, 0.1, 0.2, 0.9)
	var bar_fg = StyleBoxFlat.new()
	bar_fg.bg_color = Color("#ff5a7a")
	_theme.set_stylebox("background", "ProgressBar", bar_bg)
	_theme.set_stylebox("fill", "ProgressBar", bar_fg)
	var cur = load("res://assets/gui/cursor.png")
	if cur:
		var img: Image = cur.get_image()
		img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
		Input.set_custom_mouse_cursor(ImageTexture.create_from_image(img), Input.CURSOR_ARROW, Vector2(2, 2))
	_theme.set_font("font", "Button", Game.font_display)
	_theme.set_font_size("font_size", "Button", 15)
	_theme.set_color("font_color", "Button", Color("#ece6d8"))
	_theme.set_font("font", "Label", Game.font_body)
	_theme.set_color("font_color", "Label", Color("#d6cfbf"))
	theme = _theme
	_build_title()
	_build_choice()
	_build_pause()
	_build_end()
	_build_menu()
	_build_touch()


func _tex_box(name: String, margin: int, content: int, mod := Color.WHITE) -> StyleBoxTexture:
	var b = StyleBoxTexture.new()
	b.texture = load("res://assets/gui/%s.png" % name)
	b.set_texture_margin_all(margin)
	b.set_content_margin_all(content)
	b.modulate_color = mod
	return b


func _center_panel(min_w: float) -> PanelContainer:
	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(min_w, 0)
	p.visible = false
	add_child(p)
	return p


func _heading(text: String, size := 24) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_override("font", Game.font_display)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color("#ece6d8"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _para(text: String, italic := false) -> Label:
	var l = Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 16)
	if italic:
		l.add_theme_font_override("font", Game.font_italic)
		l.add_theme_color_override("font_color", Color("#9c97a8"))
	return l


# ---------- title ----------

var _title_main: GridContainer
var _sub: PanelContainer
var _sub_kind = ""
var _sub_from_pause = false
var _capture = null


func _build_title() -> void:
	_title = Control.new()
	_title.size = Vector2(960, 540)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	_title_main = GridContainer.new()
	_title_main.columns = 2
	_title_main.position = Vector2(96, 318)
	_title_main.add_theme_constant_override("h_separation", 10)
	_title_main.add_theme_constant_override("v_separation", 6)
	_title.add_child(_title_main)
	_btn_continue = _menu_button("CONTINUE", func(): main.continue_game())
	_title_main.add_child(_btn_continue)
	_title_main.add_child(_menu_button("NEW GAME", func(): main.new_game()))
	var cb = _menu_button("CHAPTERS", func(): show_sub("chapters"))
	cb.name = "Chapters"
	_title_main.add_child(cb)
	_title_main.add_child(_menu_button("LSMG ARCADE", func(): show_sub("arcade")))
	_title_main.add_child(_menu_button("SETTINGS", func(): show_sub("settings")))
	_title_main.add_child(_menu_button("CREDITS", func(): show_sub("credits")))
	if not OS.has_feature("web"):
		_title_main.add_child(_menu_button("QUIT", func(): get_tree().quit()))
	var hint = Label.new()
	hint.name = "Hint"
	hint.position = Vector2(60, 506)
	hint.size = Vector2(840, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color("#9c97a8"))
	_title.add_child(hint)
	_sub = _center_panel(520)


func _menu_button(text: String, cb: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(250, 36)
	b.pressed.connect(func(): Sound.play("tp_menu_confirm", 0.0, -6.0); cb.call())
	b.focus_entered.connect(func(): if b.is_visible_in_tree(): Sound.play("tp_menu_move", 0.0, -10.0))
	return b


func _refresh_diff() -> void:
	pass


func show_title(has_save: bool, unlocked := 1) -> void:
	_title.visible = true
	_title_main.visible = true
	_sub.visible = false
	_title_main.get_node("Chapters").visible = unlocked > 1
	_btn_continue.visible = has_save
	_title.get_node("Hint").text = "Touch controls appear in play." if Game.touch_mode else "%s move · %s jump · %s strike · %s kick · %s special · %s alter ego · %s swap hero · %s menu" % [
		Game.label("move"), Game.label("jump"), Game.label("attack"), Game.label("kick"), Game.label("laser"), Game.label("transform"), Game.label("switch"), Game.label("menu")]
	(_btn_continue if has_save else _title_main.get_child(1)).call_deferred("grab_focus")
	_touch.visible = false


func hide_title() -> void:
	_title.visible = false
	_sub.visible = false
	_touch.visible = Game.touch_mode


# ---------- sub menus: chapters, settings, controls ----------

func show_sub(kind: String, from_pause := false) -> void:
	_sub_kind = kind
	_sub_from_pause = from_pause or _sub_from_pause and kind == "controls"
	_title_main.visible = false
	_pause.visible = false
	_capture = null
	for c in _sub.get_children():
		_sub.remove_child(c)
		c.queue_free()
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_sub.add_child(v)
	var first: Control = null
	match kind:
		"chapters":
			v.add_child(_heading("CHAPTER SELECT", 22))
			for n in Game.CHAPTERS:
				if n > Game.unlocked():
					continue
				var nn = n
				var b = _menu_button("%d · %s" % [n, Game.CHAPTERS[n]["title"]], func(): sub_back(); main.start_chapter(nn, true))
				v.add_child(b)
				if first == null:
					first = b
		"arcade":
			v.add_child(_heading("LSMG ARCADE", 22))
			for cab in [["shot", "LAST SHOT", "high", "8-bit buzzer-beater basketball"], ["knight", "MIGHTY KNIGHT", "high_knight", "Run, jump and slash through the night"],
					["duck", "STEAMER DUCK", "high_duck", "Hop, glide and QUACK across three worlds"]]:
				var cid: String = cab[0]
				var b = _menu_button("%s   ·   HI %d" % [cab[1], int(Game.settings.get(cab[2], 0))], func(): sub_back(); main.open_arcade(cid))
				b.custom_minimum_size = Vector2(440, 38)
				v.add_child(b)
				v.add_child(_small(cab[3], 11, Color("#a8a0b0")))
				if first == null:
					first = b
		"credits":
			v.add_child(_heading("CREDITS", 22))
			var sc = ScrollContainer.new()
			sc.custom_minimum_size = Vector2(700, 340)
			var cv = VBoxContainer.new()
			sc.add_child(cv)
			var cr = [{"section": "SAKAWA: Astral MAX", "lines": ["A Last Shot Media Group game", "Story bible, characters and portraits: SAKAWA team"]}]
			if FileAccess.file_exists("res://assets/third_party/credits.json"):
				var d = JSON.parse_string(FileAccess.get_file_as_string("res://assets/third_party/credits.json"))
				if d is Array:
					cr += d
			for sec in cr:
				var h = _small(str(sec.get("section", "")).to_upper(), 14, Color("#ff8aa0"))
				cv.add_child(h)
				for ln in sec.get("lines", []):
					var l = _small(str(ln), 11)
					l.custom_minimum_size = Vector2(680, 0)
					cv.add_child(l)
			v.add_child(sc)
		"settings":
			v.add_child(_heading("SETTINGS", 22))
			var rows = [["DIFFICULTY: " + Game.diff()["name"], func(): Game.cycle_difficulty(); main.apply_difficulty(); show_sub("settings")],
				["SOUND: " + ("ON" if Sound.sound_on else "OFF"), func(): Sound.set_sound(not Sound.sound_on); show_sub("settings")],
				["MUSIC: " + ("ON" if Sound.music_on else "OFF"), func(): Sound.set_music(not Sound.music_on); show_sub("settings")],
				["CONTROLLER RUMBLE: " + ("ON" if Game.settings.get("rumble", true) else "OFF"), func(): Game.settings["rumble"] = not Game.settings.get("rumble", true); Game.save_settings(); Game.rumble(0.5, 0.5, 0.2); show_sub("settings")],
				["BUTTON ICONS: " + {"auto": "AUTO", "ps": "PLAYSTATION", "xbox": "XBOX"}[Game.settings.get("pad_style", "auto")], func(): _cycle_style(); show_sub("settings")],
				["CONTROLS...", func(): show_sub("controls")]]
			for r in rows:
				var b = _menu_button(r[0], r[1])
				b.custom_minimum_size = Vector2(400, 38)
				v.add_child(b)
				if first == null:
					first = b
			var pads = Input.get_connected_joypads()
			var pn = "No controller detected. PS5 DualSense, PS4 and Xbox controllers work over USB or Bluetooth." if pads.is_empty() else "Controller: " + Input.get_joy_name(pads[0])
			var pl = _small(pn, 12, Color("#a8a0b0"))
			pl.custom_minimum_size = Vector2(400, 0)
			v.add_child(pl)
		"controls":
			v.add_child(_heading("CONTROLS", 22))
			var info = _small("Pick a binding, then press the new key or controller button. Esc cancels. Icons: " + {"ps": "PlayStation", "xbox": "Xbox"}[Game.pad_style()], 12, Color("#a8a0b0"))
			info.custom_minimum_size = Vector2(860, 0)
			v.add_child(info)
			var g = GridContainer.new()
			g.columns = 6
			g.add_theme_constant_override("h_separation", 6)
			g.add_theme_constant_override("v_separation", 4)
			v.add_child(g)
			for col in 2:
				for htxt in ["ACTION", "KEYBOARD", "CONTROLLER"]:
					var hl = _small(htxt, 11, Color("#ff8aa0"))
					hl.autowrap_mode = TextServer.AUTOWRAP_OFF
					g.add_child(hl)
			var half = (Game.REBINDABLE.size() + 1) / 2
			for i in half:
				for col in 2:
					var idx = i + col * half
					if idx >= Game.REBINDABLE.size():
						for k in 3:
							g.add_child(Control.new())
						continue
					var r: Array = Game.REBINDABLE[idx]
					var l = _small(r[1], 12)
					l.custom_minimum_size = Vector2(150, 26)
					l.autowrap_mode = TextServer.AUTOWRAP_OFF
					l.custom_minimum_size = Vector2(150, 0)
					g.add_child(l)
					for pad in [false, true]:
						var act: String = r[0]
						var pp: bool = pad
						var b = Button.new()
						b.custom_minimum_size = Vector2(120, 26)
						b.add_theme_font_size_override("font_size", 11)
						b.text = Game.bind_label(act, pad)
						b.pressed.connect(func(): _begin_capture(act, pp, b))
						g.add_child(b)
						if first == null:
							first = b
			var rb = _menu_button("RESET DEFAULTS", func(): Game.reset_bindings(); show_sub("controls"))
			v.add_child(rb)
	var back = _menu_button("BACK", func(): sub_back())
	v.add_child(back)
	_sub.visible = true
	var f2 = first if first != null else back
	var ff = func(): if is_instance_valid(f2) and f2.is_inside_tree(): f2.grab_focus()
	ff.call_deferred()


func _cycle_style() -> void:
	var order = ["auto", "ps", "xbox"]
	Game.settings["pad_style"] = order[(order.find(Game.settings.get("pad_style", "auto")) + 1) % 3]
	Game.save_settings()


func sub_back() -> void:
	_capture = null
	if _sub_kind == "controls":
		show_sub("settings", _sub_from_pause)
		return
	_sub.visible = false
	if _sub_from_pause:
		_sub_from_pause = false
		show_pause()
	elif main.mode == "title":
		_title_main.visible = true
		_title_main.get_child(1).call_deferred("grab_focus")


func _begin_capture(action: String, pad: bool, b: Button) -> void:
	_capture = {"action": action, "pad": pad, "btn": b, "t": Time.get_ticks_msec()}
	b.text = "press a button..." if pad else "press a key..."


func _input(event: InputEvent) -> void:
	if _capture != null:
		if Time.get_ticks_msec() - _capture["t"] < 150:
			return
		if event is InputEventKey and event.pressed and not event.echo:
			get_viewport().set_input_as_handled()
			if event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE:
				_capture = null
				show_sub("controls")
				return
			if not _capture["pad"]:
				Game.rebind(_capture["action"], event)
				Sound.play("pickup")
				_capture = null
				show_sub("controls")
			return
		if _capture["pad"] and ((event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.7)):
			get_viewport().set_input_as_handled()
			Game.rebind(_capture["action"], event)
			Sound.play("pickup")
			_capture = null
			show_sub("controls")
		return
	if _sub != null and _sub.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		sub_back()


func draw_title(ci: CanvasItem, t: float) -> void:
	var W = 960.0
	var H = 540.0
	var c = Vector2(W * 0.68, 200)
	for i in 6:
		ci.draw_circle(c, 330.0 - i * 50, Color(0.48, 0.36, 1, 0.025))
	ci.draw_circle(c, 78, Color(1, 0.86, 0.69, 0.85))
	ci.draw_circle(c, 74, Color("#050408"))
	for i in 7:
		var rad = 260.0 * (0.28 + i * 0.12)
		var a0 = (t * 0.12 if i % 2 else -t * 0.12) * (1 + i * 0.15) + i * 1.7
		ci.draw_arc(c, rad, a0, a0 + TAU - (0.45 + (i % 3) * 0.35), 80, Color(0.86, 0.78, 1, 0.45), 1.6)
	ci.draw_string(Game.font_display, Vector2(70, 190), "SAKAWA", HORIZONTAL_ALIGNMENT_LEFT, -1, 86, Color("#ece6d8"))
	ci.draw_string(Game.font_display, Vector2(76, 232), "A S T R A L   M A X", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#c9b8ff"))
	ci.draw_line(Vector2(76, 252), Vector2(400, 252), Color(0.93, 0.9, 0.85, 0.5), 1.0)
	ci.draw_string(Game.font_italic, Vector2(76, 282), "The stronger you become, the more of reality you can see.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#b8b1c4"))
	ci.draw_string(Game.font_semi, Vector2(76, 308), "Chapter One · Class Famine", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#8c869a"))


# ---------- dialogue ----------

func start_dialog(lines: Array, on_end: Callable) -> void:
	dlg = {"lines": lines, "i": 0, "chars": 0.0, "on_end": on_end}


func dialog_active() -> bool:
	return dlg != null


func update_dialog(dt: float, advance: bool) -> void:
	if dlg == null:
		return
	var l: Array = dlg["lines"][dlg["i"]]
	var txt = Game.fill(l[2])
	var before = int(dlg["chars"])
	dlg["chars"] = minf(txt.length(), dlg["chars"] + dt * 55.0)
	if int(dlg["chars"]) > before and int(dlg["chars"]) % 3 == 0 and l[0] != "narr" and l[0] != "phone":
		Sound.voice(l[0])
	if advance:
		if dlg["chars"] < txt.length():
			dlg["chars"] = txt.length()
		else:
			dlg["i"] += 1
			dlg["chars"] = 0.0
			Sound.play("select")
			if dlg["i"] >= dlg["lines"].size():
				var cb: Callable = dlg["on_end"]
				dlg = null
				if cb.is_valid():
					cb.call()


func _process(_d: float) -> void:
	if _map_ctrl != null and is_instance_valid(_map_ctrl) and _menu.visible:
		_map_ctrl.queue_redraw()
	for p in [_choice_panel, _pause, _end, _menu, _sub]:
		if p and p.visible:
			var ms: Vector2 = p.get_combined_minimum_size()
			p.size = ms
			p.position = ((Vector2(960, 540) - ms) / 2.0).round()
	queue_redraw()


func hide_choice() -> void:
	_choice_panel.visible = false


func _draw() -> void:
	if main and main.mode in ["title", "boot"]:
		draw_rect(Rect2(0, 0, 960, 540), Color("#05060f"))
		if main.title_art:
			var tex: Texture2D = main.title_art
			var hh = 540.0
			var ww = tex.get_width() * hh / tex.get_height()
			draw_texture_rect(tex, Rect2(960 - ww, 0, ww, hh), false, Color(1, 1, 1, 0.45))
			for i in 24:
				draw_rect(Rect2(i * 28.0, 0, 28, 540), Color(0.02, 0.02, 0.06, clampf(0.95 - i * 0.045, 0, 1)))
		draw_title(self, main.t)
		return
	if dlg == null:
		return
	var l: Array = dlg["lines"][dlg["i"]]
	var who: String = l[0]
	var ex: String = l[1]
	var txt = Game.fill(l[2])
	draw_rect(Rect2(0, 0, 960, 540), Color(0.01, 0.01, 0.03, 0.35))
	var bx = 30.0
	var by = 388.0
	var bw = 900.0
	var bh = 134.0
	draw_rect(Rect2(bx, by, bw, bh), Color(0.02, 0.02, 0.05, 0.9))
	draw_rect(Rect2(bx + 0.5, by + 0.5, bw - 1, bh - 1), Color(0.93, 0.9, 0.85, 0.55), false, 1.0)
	draw_rect(Rect2(bx + 5.5, by + 5.5, bw - 11, bh - 11), Color(0.93, 0.9, 0.85, 0.18), false, 1.0)
	_ornament(Vector2(bx + bw / 2, by))
	_ornament(Vector2(bx + bw / 2, by + bh))
	var tex = Game.portrait(who, ex)
	var left = who == "max"
	var tx = bx + 40.0
	var tw = bw - 80.0
	var talking: bool = dlg["chars"] < txt.length()
	if tex:
		var px = bx + 22.0 if left else bx + bw - 222.0
		var py = by - 214.0
		draw_rect(Rect2(px, py, 200, 236), Color("#120d14"))
		var iw = float(tex.get_width())
		var ih = float(tex.get_height())
		var full = who == "ciencia" or who == "choir"
		var s = maxf(200.0 / iw, 236.0 / ih) if full else minf(194.0 / iw, 230.0 / ih)
		var dw = iw * s
		var dh = ih * s
		var bob = -absf(sin(main.t * 12.0)) * 2.0 if talking else 0.0
		var dst = Rect2(px + (200 - dw) / 2.0, py + 236 - dh + bob, dw, dh)
		if full:
			dst = Rect2(px + (200 - dw) / 2.0, py + (236 - dh) / 2.0, dw, dh)
		var src = Rect2(0, 0, iw, ih)
		var clip_src = src
		var clip_dst = dst
		if full:
			# crop the overflow so the art stays inside the frame
			var vis = Rect2(px, py, 200, 236).intersection(Rect2(dst.position, dst.size))
			clip_src = Rect2((vis.position - dst.position) / s, vis.size / s)
			clip_dst = vis
		var flip = not full and not left
		if flip:
			draw_set_transform(Vector2(2.0 * (px + 100.0), 0), 0.0, Vector2(-1, 1))
		draw_texture_rect_region(tex, clip_dst, clip_src)
		if flip:
			draw_set_transform(Vector2.ZERO)
		if who == "max" and Game.overdraw > 0:
			draw_rect(Rect2(px, py, 200, 236), Color(0.65, 0.55, 1, 0.12))
		draw_rect(Rect2(px + 0.5, py + 0.5, 199, 235), Color(0.93, 0.9, 0.85, 0.6), false, 1.5)
		draw_rect(Rect2(px + 5.5, py + 5.5, 189, 225), Color(0.93, 0.9, 0.85, 0.2), false, 1.0)
		if left:
			tx = bx + 246.0
			tw = bw - 286.0
		else:
			tw = bw - 290.0
		var name: String = Game.SPEAKER.get(who, "")
		var nw = Game.font_display.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		draw_string(Game.font_display, Vector2(tx if left else tx + tw - nw, by + 30), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#c9b8ff") if who == "choir" else Color("#ece6d8"))
	if who == "phone":
		draw_string(Game.font_display, Vector2(tx, by + 30), ex.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#ffd08a"))
	var font: Font = Game.font_italic if who == "narr" else (Game.font_semi if who == "choir" else Game.font_body)
	var col = Color("#d8c9ff") if who == "choir" else (Color("#c9c3d4") if who == "narr" else Color("#ece6d8"))
	var shown = txt.substr(0, int(dlg["chars"]))
	var y = by + 60.0 if (tex != null or who == "phone") else by + 46.0
	draw_multiline_string(font, Vector2(tx, y), shown, HORIZONTAL_ALIGNMENT_LEFT, tw, 20, 4, col)
	if not talking:
		var a = 0.5 + 0.5 * sin(main.t * 6.0)
		draw_colored_polygon(PackedVector2Array([Vector2(bx + bw - 30, by + bh - 24), Vector2(bx + bw - 20, by + bh - 24), Vector2(bx + bw - 25, by + bh - 17)]), Color(0.93, 0.9, 0.85, a))


func _ornament(c: Vector2) -> void:
	draw_rect(Rect2(c.x - 40, c.y - 3, 80, 6), Color("#05060c"))
	draw_line(Vector2(c.x - 38, c.y), Vector2(c.x - 10, c.y), Color(0.93, 0.9, 0.85, 0.7), 1.2)
	draw_line(Vector2(c.x + 10, c.y), Vector2(c.x + 38, c.y), Color(0.93, 0.9, 0.85, 0.7), 1.2)
	draw_polyline(PackedVector2Array([c + Vector2(0, -6), c + Vector2(6, 0), c + Vector2(0, 6), c + Vector2(-6, 0), c + Vector2(0, -6)]), Color(0.93, 0.9, 0.85, 0.7), 1.2)


# ---------- choices ----------

func _build_choice() -> void:
	_choice_panel = _center_panel(560)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_choice_panel.add_child(v)
	_choice_title = _heading("")
	v.add_child(_choice_title)
	_choice_sub = _para("")
	v.add_child(_choice_sub)
	_choice_grid = GridContainer.new()
	_choice_grid.columns = 2
	_choice_grid.add_theme_constant_override("h_separation", 10)
	_choice_grid.add_theme_constant_override("v_separation", 10)
	v.add_child(_choice_grid)


func show_choice(title: String, sub: String, opts: Array) -> void:
	_choice_title.text = title
	_choice_sub.text = sub
	for c in _choice_grid.get_children():
		c.queue_free()
	_choice_armed_at = Time.get_ticks_msec() + 600
	var first: Button = null
	for o in opts:
		var b = Button.new()
		b.custom_minimum_size = Vector2(260, 64)
		b.text = o["k"] + "\n" + o.get("d", CMD[o["k"]])
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", Game.font_body)
		b.add_theme_font_size_override("font_size", 14)
		b.add_theme_color_override("font_color", CMD_COLOR[o["k"]])
		b.add_theme_color_override("font_hover_color", Color("#ffffff"))
		b.add_theme_color_override("font_focus_color", Color("#ffffff"))
		b.disabled = o.get("disabled", false)
		var key: String = o["k"]
		var on_press = func():
			if Time.get_ticks_msec() < _choice_armed_at:
				return
			Sound.play("select")
			_choice_panel.visible = false
			choice_made.emit(key)
		b.pressed.connect(on_press)
		_choice_grid.add_child(b)
		if first == null and not b.disabled:
			first = b
	_choice_panel.visible = true
	if first:
		get_tree().create_timer(0.62).timeout.connect(func(): if is_instance_valid(first): first.grab_focus())


# ---------- character menu ----------

func _build_menu() -> void:
	_menu = _center_panel(820)
	_menu_body = VBoxContainer.new()
	_menu_body.add_theme_constant_override("separation", 8)
	_menu.add_child(_menu_body)


func show_menu() -> void:
	_menu.visible = true
	_refresh_menu()


func hide_menu() -> void:
	_menu.visible = false


func _small(text: String, size := 13, col := Color("#d6cfbf")) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _btn(text: String, cb: Callable, w := 0.0, fs := 13) -> Button:
	var b = Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", fs)
	if w > 0.0:
		b.custom_minimum_size = Vector2(w, 0)
	b.pressed.connect(cb)
	return b


func _menu_go(i: int) -> void:
	_menu_tab = i
	Sound.play("select")
	_refresh_menu(true)


func _refresh_menu(focus_tab := false) -> void:
	for c in _menu_body.get_children():
		_menu_body.remove_child(c)
		c.queue_free()
	var pg: Dictionary = Game.prog
	var head = HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	_menu_body.add_child(head)
	var tabs = ["PARTY", "EQUIPMENT", "ABILITIES", "MAP"]
	var tab_btns = []
	for i in tabs.size():
		var ii = i
		var b = _btn(("▸ " if i == _menu_tab else "") + tabs[i], func(): _menu_go(ii), 150, 14)
		head.add_child(b)
		tab_btns.append(b)
	var lv = _small("   LEVEL %d · %d / %d XP" % [pg["level"], pg["xp"], Game.xp_next(pg["level"])], 15, Color("#fff2c8"))
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(lv)
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 6)
	bar.show_percentage = false
	bar.max_value = Game.xp_next(pg["level"])
	bar.value = pg["xp"]
	_menu_body.add_child(bar)
	_menu_desc = _small("", 13, Color("#bfb6a6"))
	_menu_desc.custom_minimum_size = Vector2(780, 36)
	var first: Control = tab_btns[_menu_tab]
	match _menu_tab:
		0:
			_menu_party()
		1:
			_menu_gear()
		2:
			_menu_skills()
		3:
			_menu_map()
	_menu_body.add_child(_menu_desc)
	var close = _btn("CLOSE  [" + Game.label("menu") + "]", func(): main.close_menu(), 0, 14)
	_menu_body.add_child(close)
	var ff = func(): if is_instance_valid(first) and first.is_inside_tree(): first.grab_focus()
	ff.call_deferred()


func _menu_party() -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_menu_body.add_child(row)
	for h in ["max", "lana", "jason"]:
		var hd: Dictionary = Game.HEROES[h]
		var card = VBoxContainer.new()
		card.custom_minimum_size = Vector2(250, 0)
		card.add_theme_constant_override("separation", 4)
		row.add_child(card)
		var nm = _small(hd["name"], 20, Color(hd["col"]))
		nm.add_theme_font_override("font", Game.font_display)
		card.add_child(nm)
		if not Game.hero_unlocked(h):
			card.add_child(_small("Joins in Chapter %d" % (2 if h == "lana" else 3), 13, Color("#8a8494")))
			continue
		var bl = _small(hd["blurb"], 12, Color("#a8a0b0"))
		bl.custom_minimum_size = Vector2(250, 34)
		card.add_child(bl)
		var pts = int(Game.prog["pts"].get(h, 0))
		card.add_child(_small("Health %d · Strike %d · Special %d Resonance" % [Game.hero_max_hp(h), int(hd["dmg"]) + int(Game.mod("dmg")) + int(Game.attr(h, "pow") / 2), int(Game.special_cost(h))], 12))
		card.add_child(_small("Points to spend: %d" % pts, 13, Color("#fff2c8") if pts > 0 else Color("#8a8494")))
		for a in [["vit", "VITALITY", "+1 health"], ["pow", "POWER", "+1 damage every 2"], ["foc", "FOCUS", "cheaper specials, +10% Resonance"]]:
			var line = HBoxContainer.new()
			var l = _small("%s %d" % [a[1], Game.attr(h, a[0])], 13)
			l.custom_minimum_size = Vector2(120, 0)
			line.add_child(l)
			var hh = h
			var key: String = a[0]
			var desc: String = a[2]
			var b = _btn("+", func(): _spend(hh, key), 36, 14)
			b.disabled = pts <= 0
			b.focus_entered.connect(func(): _menu_desc.text = a[1].capitalize() + ": " + desc)
			b.mouse_entered.connect(func(): _menu_desc.text = a[1].capitalize() + ": " + desc)
			line.add_child(b)
			card.add_child(line)
		if main.player.hero == h:
			card.add_child(_small("● PLAYING", 13, Color(hd["col"])))
		else:
			var hh2 = h
			card.add_child(_btn("PLAY AS " + hd["name"], func(): main.switch_hero(hh2); _refresh_menu(), 0, 12))


func _spend(h: String, a: String) -> void:
	if int(Game.prog["pts"].get(h, 0)) <= 0:
		return
	Game.prog["pts"][h] = int(Game.prog["pts"][h]) - 1
	Game.prog["attr"][h][a] = int(Game.prog["attr"][h][a]) + 1
	Sound.play("pickup")
	if main.player.hero == h:
		var m: int = Game.hero_max_hp(h)
		main.player.hp = clampi(main.player.hp + (m - main.player.max_hp), 1, m)
		main.player.max_hp = m
	_refresh_menu()


func _menu_gear() -> void:
	var pg: Dictionary = Game.prog
	_menu_body.add_child(_small("EQUIPPED (3 slots · shared by the whole party)", 13, Color("#fff2c8")))
	var slots = HBoxContainer.new()
	slots.add_theme_constant_override("separation", 10)
	_menu_body.add_child(slots)
	for i in 3:
		var id: String = pg["equip"][i]
		var ii = i
		var b = _btn(Game.ITEMS[id]["name"] if id != "" else "— empty —", func(): _unequip(ii), 255, 13)
		if id != "" and ResourceLoader.exists("res://assets/third_party/icons/%s.png" % id):
			b.icon = load("res://assets/third_party/icons/%s.png" % id)
		if id != "":
			var d: String = Game.ITEMS[id]["d"]
			b.focus_entered.connect(func(): _menu_desc.text = d + "  (press to unequip)")
			b.mouse_entered.connect(func(): _menu_desc.text = d + "  (press to unequip)")
		slots.add_child(b)
	_menu_body.add_child(_small("FOUND %d / %d" % [pg["items"].size(), Game.ITEMS.size()], 13, Color("#fff2c8")))
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	_menu_body.add_child(grid)
	for id in Game.ITEMS:
		var it: Dictionary = Game.ITEMS[id]
		var owned: bool = id in pg["items"]
		var eq: bool = id in pg["equip"]
		var iid: String = id
		var b = _btn(("✓ " if eq else "") + (it["name"] if owned else "???"), func(): _toggle_item(iid), 255, 12)
		if owned and ResourceLoader.exists("res://assets/third_party/icons/%s.png" % id):
			b.icon = load("res://assets/third_party/icons/%s.png" % id)
			b.expand_icon = false
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not owned
		var d2: String = it["d"] if owned else "Not found yet. Explore, beat bosses and elite riders, or get lucky with drops."
		b.focus_entered.connect(func(): _menu_desc.text = d2)
		b.mouse_entered.connect(func(): _menu_desc.text = d2)
		grid.add_child(b)


func _unequip(i: int) -> void:
	Game.prog["equip"][i] = ""
	Sound.play("select")
	_refresh_menu()


func _toggle_item(id: String) -> void:
	var eq: Array = Game.prog["equip"]
	var at = eq.find(id)
	if at >= 0:
		eq[at] = ""
	else:
		var free = eq.find("")
		if free < 0:
			main.toast("All three slots are full. Unequip something first.")
			Sound.play("glitch")
			return
		eq[free] = id
	Sound.play("select")
	_refresh_menu()


func _menu_skills() -> void:
	var lvl: int = Game.prog["level"]
	for h in Game.party():
		var hd: Dictionary = Game.HEROES[h]
		var nm = _small(hd["name"] + ("  ·  aura: " + hd["aura"]), 15, Color(hd["col"]))
		_menu_body.add_child(nm)
		var moves = "Strike combo [%s] · Kick / dive kick [%s] · Dash [%s] · Focus heal [%s] · Full Potential [%s]" % [Game.label("attack"), Game.label("kick"), Game.label("dash"), Game.label("heal"), Game.label("fp")]
		if h == "max":
			moves += " · Astral projection [%s] · Levitation" % Game.label("project")
		var ml = _small(moves, 12, Color("#a8a0b0"))
		ml.custom_minimum_size = Vector2(780, 0)
		_menu_body.add_child(ml)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_menu_body.add_child(row)
		var sl = _small("SPECIAL [%s]:" % Game.label("laser"), 13)
		sl.autowrap_mode = TextServer.AUTOWRAP_OFF
		sl.custom_minimum_size = Vector2(130, 0)
		row.add_child(sl)
		for sp in hd["specials"]:
			var sd: Dictionary = Game.SPECIALS[sp]
			var locked = lvl < int(sd["lv"])
			var sel: bool = Game.prog["special"].get(h, "") == sp
			var hh = h
			var spp: String = sp
			var b = _btn(("▸ " if sel else "") + sd["name"] + ("  (Lv %d)" % sd["lv"] if locked else ""), func(): _pick_special(hh, spp), 230, 12)
			b.disabled = locked
			var d: String = sd["d"] + "  Cost %d Resonance." % int(sd["cost"])
			b.focus_entered.connect(func(): _menu_desc.text = d)
			b.mouse_entered.connect(func(): _menu_desc.text = d)
			row.add_child(b)


## Screen map (after YKnytt / Knytt Stories): each room of the chapter as a
## box, lit once visited, with where you are blinking.
const MAP := {
	1: [["classroom", 0, 1, 2, 1], ["hallway", 2, 1, 3, 1], ["cafeteria", 5, 0, 2, 2], ["lab", 7, 0, 1, 1]],
	2: [["street", 0, 0, 4, 1], ["hospital", 4, 0, 3, 1]],
	3: [["waterworks", 0, 0, 4, 2], ["pumphouse", 4, 0, 2, 1]],
	4: [["fairhall", 0, 1, 4, 1], ["gym", 4, 0, 3, 2], ["stage", 7, 0, 2, 1]],
}


func _menu_map() -> void:
	var title = _small("CHAPTER %d · %s" % [Game.chapter, Game.CHAPTERS[Game.chapter]["title"]], 15, Color("#fff2c8"))
	_menu_body.add_child(title)
	var mc = Control.new()
	mc.custom_minimum_size = Vector2(780, 230)
	mc.draw.connect(func(): _draw_map(mc))
	mc.set_process(true)
	_menu_body.add_child(mc)
	_map_ctrl = mc
	_menu_body.add_child(_small("Lit rooms are explored. ● you · ■ save bench · ♦ boss. Anchors found: %d / %d" % [Game.anchors.size(), Game.ANCH.size()], 12, Color("#a8a0b0")))


func _draw_map(mc: Control) -> void:
	var rooms: Array = MAP.get(Game.chapter, [])
	var cell = Vector2(84, 84)
	var org = Vector2(20, 20)
	for i in rooms.size():
		var r: Array = rooms[i]
		var rect = Rect2(org + Vector2(r[1], r[2]) * cell, Vector2(r[3], r[4]) * cell - Vector2(6, 6))
		var seen: bool = Game.visited.has(r[0])
		mc.draw_rect(rect, Color(0.2, 0.22, 0.4, 0.95) if seen else Color(0.08, 0.08, 0.14, 0.9))
		mc.draw_rect(rect, Color("#8fb8ff") if seen else Color(1, 1, 1, 0.15), false, 2.0)
		if i > 0:
			var prev: Array = rooms[i - 1]
			var pr = Rect2(org + Vector2(prev[1], prev[2]) * cell, Vector2(prev[3], prev[4]) * cell - Vector2(6, 6))
			var y = clampf(rect.get_center().y, maxf(pr.position.y, rect.position.y) + 10, minf(pr.end.y, rect.end.y) - 10)
			mc.draw_line(Vector2(pr.end.x, y), Vector2(rect.position.x, y), Color(1, 1, 1, 0.5), 4.0)
		var nm = main.meta.get(r[0], {})
		var label = r[0].capitalize() if not seen else Game.ROOM_TITLES.get(r[0], r[0].capitalize())
		mc.draw_string(Game.font_semi, rect.position + Vector2(8, 18), label if seen else "?", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12, 12, Color.WHITE if seen else Color(1, 1, 1, 0.4))
		if r[0] in ["lab", "hospital", "pumphouse", "stage"]:
			mc.draw_string(Game.font_display, rect.end - Vector2(18, 8), "♦", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#ff8aa0"))
		if r[0] in ["hallway", "cafeteria", "street", "hospital", "waterworks", "fairhall", "gym"]:
			mc.draw_rect(Rect2(rect.position + Vector2(8, rect.size.y - 16), Vector2(8, 8)), Color("#ffd6a0"))
		if r[0] == main.room_id and main.room != null:
			var rs: Vector2 = main.room.room_size
			var pp = rect.position + Vector2(main.player.position.x / rs.x * rect.size.x, main.player.position.y / rs.y * rect.size.y)
			if int(main.t * 4.0) % 2 == 0:
				mc.draw_circle(pp, 6, Color(Game.HEROES[main.player.hero]["col"]))
			mc.draw_arc(pp, 9, 0, TAU, 16, Color.WHITE, 1.5)


func _pick_special(h: String, sp: String) -> void:
	Game.prog["special"][h] = sp
	Sound.play("select")
	_refresh_menu()


# ---------- pause ----------

func _build_pause() -> void:
	_pause = _center_panel(420)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_pause.add_child(v)
	v.add_child(_heading("PAUSED"))
	var keys = _para("")
	keys.name = "Keys"
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	keys.add_theme_font_size_override("font_size", 14)
	v.add_child(keys)
	for spec in [["RESUME", func(): main.close_pause()], ["CHARACTER", func(): _pause.visible = false; main.open_menu()],
			["SETTINGS", func(): show_sub("settings", true)], ["CONTROLS", func(): _sub_from_pause = true; show_sub("controls", true)],
			["TITLE", func(): _pause.visible = false; main.show_title()]]:
		var b = Button.new()
		b.text = spec[0]
		b.name = spec[0].split(":")[0].capitalize()
		b.pressed.connect(spec[1])
		if b.name == "Resume":
			v.add_child(b)
		else:
			if not v.has_node("Grid"):
				var g = GridContainer.new()
				g.name = "Grid"
				g.columns = 2
				g.add_theme_constant_override("h_separation", 8)
				g.add_theme_constant_override("v_separation", 8)
				v.add_child(g)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.get_node("Grid").add_child(b)


func show_pause() -> void:
	_refresh_pause()
	_pause.visible = true
	_pause.get_child(0).get_node("Resume").call_deferred("grab_focus")


func hide_pause() -> void:
	_pause.visible = false


func _refresh_pause() -> void:
	var v = _pause.get_child(0)
	var rows = [["move", "Move"], ["jump", "Jump · wall jump · again midair"], ["attack", "Strike · up/down to aim · 3-hit combo"], ["transform", "Alter ego (shinobi form)"],
		["kick", "Kick · in midair, a diving kick"], ["laser", "Special move · costs Resonance"], ["switch", "Swap hero (1 / 2 / 3)"], ["menu", "Gear · skills · stats"], ["dash", "Dash"],
		["heal", "Hold to focus Resonance into healing"], ["project", "Leave or return to your body"], ["fp", "Full Potential (permanent cost)"], ["up", "Talk · rest at benches"]]
	var s = ""
	for r in rows:
		s += Game.label(r[0]) + "  —  " + r[1] + "\n"
	v.get_node("Keys").text = s


# ---------- end ----------

func _build_end() -> void:
	_end = _center_panel(560)
	_end_body = VBoxContainer.new()
	_end_body.add_theme_constant_override("separation", 8)
	_end.add_child(_end_body)


func show_end(chapter: int, title: String, lead: String, stats: Array, has_next: bool) -> void:
	for c in _end_body.get_children():
		c.queue_free()
	_end_body.add_child(_heading("END OF CHAPTER " + Game.CHAPTER_WORD[chapter], 26))
	_end_body.add_child(_heading(title, 16))
	_end_body.add_child(_para("Your choices leaned toward %s. The game will remember." % lead, true))
	var g = GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	for s in stats:
		var cell = VBoxContainer.new()
		cell.custom_minimum_size = Vector2(120, 0)
		var n = _heading(str(s[1]), 22)
		cell.add_child(n)
		var lab = _para(s[0].to_upper())
		lab.add_theme_font_size_override("font_size", 11)
		cell.add_child(lab)
		g.add_child(cell)
	_end_body.add_child(g)
	_end_body.add_child(_para(("Next: Chapter %s · %s" % [Game.CHAPTER_WORD[chapter + 1].capitalize(), Game.CHAPTERS[chapter + 1]["title"]]) if has_next else "Season One continues: The Teacher Who Was Fired · One Minute Outside", true))
	var b = Button.new()
	b.text = ("CONTINUE TO CHAPTER " + Game.CHAPTER_WORD[chapter + 1]) if has_next else "PLAY AGAIN"
	var armed = Time.get_ticks_msec() + 1200
	var on_press = func():
		if Time.get_ticks_msec() < armed:
			return
		_end.visible = false
		if has_next:
			main.start_chapter(chapter + 1, false)
		else:
			main.new_game()
	b.pressed.connect(on_press)
	_end_body.add_child(b)
	var tb = Button.new()
	tb.text = "TITLE"
	tb.pressed.connect(func(): _end.visible = false; main.show_title())
	_end_body.add_child(tb)
	_end.visible = true
	get_tree().create_timer(1.25).timeout.connect(func(): if is_instance_valid(b): b.grab_focus())


func hide_end() -> void:
	_end.visible = false


# ---------- touch ----------

func _circle_tex(r: int, fill: Color, edge: Color) -> ImageTexture:
	var img = Image.create(r * 2, r * 2, false, Image.FORMAT_RGBA8)
	for y in r * 2:
		for x in r * 2:
			var d = Vector2(x - r + 0.5, y - r + 0.5).length()
			if d <= r:
				img.set_pixel(x, y, edge if d > r - 2.5 else fill)
	return ImageTexture.create_from_image(img)


func _build_touch() -> void:
	_touch = Control.new()
	_touch.size = Vector2(960, 540)
	_touch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_touch.visible = false
	add_child(_touch)
	var tex = _circle_tex(30, Color(0.04, 0.05, 0.09, 0.45), Color(0.93, 0.9, 0.85, 0.35))
	var texp = _circle_tex(30, Color(0.65, 0.55, 1, 0.4), Color(0.93, 0.9, 0.85, 0.8))
	var specs = [["left", "◀", Vector2(20, 470)], ["right", "▶", Vector2(150, 470)], ["up", "▲", Vector2(85, 405)], ["down", "▼", Vector2(85, 470)],
		["kick", "KICK", Vector2(810, 340)], ["laser", "SPECIAL", Vector2(875, 340)], ["switch", "SWAP", Vector2(745, 340)], ["menu", "MENU", Vector2(875, 20)], ["transform", "EGO", Vector2(680, 405)],
		["project", "PROJECT", Vector2(745, 405)], ["heal", "FOCUS", Vector2(810, 405)], ["fp", "FULL", Vector2(875, 405)],
		["dash", "DASH", Vector2(745, 470)], ["attack", "STRIKE", Vector2(810, 470)], ["jump", "JUMP", Vector2(875, 470)]]
	for s in specs:
		var b = TouchScreenButton.new()
		b.texture_normal = tex
		b.texture_pressed = texp
		b.action = s[0]
		b.position = s[2]
		b.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
		var l = Label.new()
		l.text = s[1]
		l.add_theme_font_override("font", Game.font_display)
		l.add_theme_font_size_override("font_size", 10)
		l.size = Vector2(60, 60)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		b.add_child(l)
		_touch.add_child(b)
