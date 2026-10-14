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
var _theme: Theme

const CMD := {"READ": "Observe. Reveals memories, rules and hidden truths.", "REACH": "Emotional or psychic contact. The path toward non-destructive endings.",
	"BIND": "Restrict it with your power. Safe now. It stays.", "STRIKE": "Destroy it. Fast and final. Some things will not come back."}
const CMD_COLOR := {"READ": Color("#9fd0ff"), "REACH": Color("#ffb38a"), "BIND": Color("#c6a8ff"), "STRIKE": Color("#ff8a8a")}


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(960, 540)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_theme = Theme.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.03, 0.05, 0.92)
	sb.border_color = Color(0.93, 0.9, 0.85, 0.35)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(18)
	_theme.set_stylebox("panel", "PanelContainer", sb)
	var bn = StyleBoxFlat.new()
	bn.bg_color = Color(1, 1, 1, 0.03)
	bn.border_color = Color(0.93, 0.9, 0.85, 0.4)
	bn.set_border_width_all(1)
	bn.set_content_margin_all(10)
	var bh = bn.duplicate()
	bh.bg_color = Color(0.65, 0.55, 1, 0.14)
	bh.border_color = Color("#a58bff")
	_theme.set_stylebox("normal", "Button", bn)
	_theme.set_stylebox("hover", "Button", bh)
	_theme.set_stylebox("focus", "Button", bh)
	_theme.set_stylebox("pressed", "Button", bh)
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
	_build_touch()


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

func _build_title() -> void:
	_title = Control.new()
	_title.size = Vector2(960, 540)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	var box = HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.position = Vector2(170, 420)
	box.size = Vector2(620, 48)
	box.add_theme_constant_override("separation", 12)
	_title.add_child(box)
	var b1 = Button.new()
	b1.text = "BEGIN"
	b1.custom_minimum_size = Vector2(160, 44)
	b1.pressed.connect(func(): Sound.play("select"); main.new_game())
	box.add_child(b1)
	_btn_continue = Button.new()
	_btn_continue.text = "CONTINUE"
	_btn_continue.custom_minimum_size = Vector2(160, 44)
	_btn_continue.pressed.connect(func(): Sound.play("select"); main.continue_game())
	box.add_child(_btn_continue)
	_btn_diff = Button.new()
	_btn_diff.custom_minimum_size = Vector2(230, 44)
	_btn_diff.pressed.connect(func(): Sound.play("select"); Game.cycle_difficulty(); _refresh_diff())
	box.add_child(_btn_diff)
	var hint = Label.new()
	hint.name = "Hint"
	hint.position = Vector2(60, 488)
	hint.size = Vector2(840, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color("#9c97a8"))
	_title.add_child(hint)
	var chap = HBoxContainer.new()
	chap.name = "Chapters"
	chap.alignment = BoxContainer.ALIGNMENT_CENTER
	chap.position = Vector2(230, 372)
	chap.size = Vector2(500, 40)
	chap.add_theme_constant_override("separation", 10)
	_title.add_child(chap)
	for n in [1, 2, 3]:
		var cb = Button.new()
		cb.name = "Ch%d" % n
		cb.text = "CHAPTER %d" % n
		cb.custom_minimum_size = Vector2(150, 34)
		cb.add_theme_font_size_override("font_size", 12)
		var nn = n
		cb.pressed.connect(func(): Sound.play("select"); main.start_chapter(nn, true))
		chap.add_child(cb)


func show_title(has_save: bool, unlocked := 1) -> void:
	_title.visible = true
	var chap = _title.get_node("Chapters")
	chap.visible = unlocked > 1
	for n in [1, 2, 3]:
		chap.get_node("Ch%d" % n).visible = n <= unlocked
	_btn_continue.visible = has_save
	_refresh_diff()
	_title.get_node("Hint").text = "Touch controls appear in play." if Game.touch_mode else "A/D move · Space jump · X strike · V kick · B laser · C dash · Q focus · E project · R full potential · W talk · Esc pause · gamepad"
	(_btn_continue if has_save else _title.get_child(0).get_child(0)).call_deferred("grab_focus")
	_touch.visible = false


func hide_title() -> void:
	_title.visible = false
	_touch.visible = Game.touch_mode


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
	for p in [_choice_panel, _pause, _end]:
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


func _refresh_diff() -> void:
	var d: Dictionary = Game.diff()
	_btn_diff.text = "DIFFICULTY: %s" % d["name"]
	_btn_diff.tooltip_text = "%d health" % d["hp"]


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
	for spec in [["RESUME", func(): main.close_pause()], ["SOUND: ON", func(): Sound.set_sound(not Sound.sound_on); _refresh_pause()],
			["MUSIC: ON", func(): Sound.set_music(not Sound.music_on); _refresh_pause()],
			["DIFFICULTY: NORMAL", func(): Game.cycle_difficulty(); main.apply_difficulty(); _refresh_pause()], ["TITLE", func(): _pause.visible = false; main.show_title()]]:
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
	v.get_node("Grid/Sound").text = "SOUND: " + ("ON" if Sound.sound_on else "OFF")
	v.get_node("Grid/Music").text = "MUSIC: " + ("ON" if Sound.music_on else "OFF")
	v.get_node("Grid/Difficulty").text = "DIFFICULTY: " + Game.diff()["name"]
	var rows = [["move", "Move"], ["jump", "Jump · again midair to levitate"], ["attack", "Psychic strike · up/down to aim · 3-hit combo"],
		["kick", "Kick · in midair, a diving kick"], ["laser", "Psychic laser · costs Resonance · hold up to aim"], ["dash", "Dash"],
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
	_end_body.add_child(_para(("Next: Chapter %s · %s" % [Game.CHAPTER_WORD[chapter + 1].capitalize(), Game.CHAPTERS[chapter + 1]["title"]]) if has_next else "Season One continues: #ScienceMatters · The Teacher Who Was Fired", true))
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
		["kick", "KICK", Vector2(810, 340)], ["laser", "LASER", Vector2(875, 340)],
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
