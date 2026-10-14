extends Control
## 8-bit boot screen: the LSMG logo pixel-blocks in, a chiptune jingle plays,
## then "LAST SHOT MEDIA GROUP PRESENTS". Any button skips.

const PF = preload("res://scripts/pixelfont.gd")

var main: Node
var t = 0.0
var logo: Texture2D
var done = false
var img: Image


func _ready() -> void:
	size = Vector2(960, 540)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo = load("res://assets/lsmg/logo8.png")
	img = logo.get_image()
	Sound.play("lsmg_jingle")


func _process(delta: float) -> void:
	t += delta
	if t > 3.6:
		_finish()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if t > 0.4 and ((event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed()):
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	if done:
		return
	done = true
	main.splash_done()
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color.BLACK)
	var px = 8.0
	var lw = logo.get_width() * px
	var lh = logo.get_height() * px
	var pos = Vector2((960 - lw) / 2.0, 150)
	var img_k = clampf(t / 1.0, 0.0, 1.0)
	# Reveal the logo in coarse blocks, like an old cartridge boot.
	var block = int(lerpf(8, 1, img_k))
	var fade = clampf((3.6 - t) / 0.4, 0.0, 1.0)
	for y in range(0, img.get_height(), block):
		for x in range(0, img.get_width(), block):
			var c = img.get_pixel(x, y)
			if c.a > 0.5 and randf() < 0.6 + img_k:
				draw_rect(Rect2(pos + Vector2(x, y) * px, Vector2(block, block) * px), Color(c, fade))
	if t > 1.1:
		PF.draw_text(self, "LAST SHOT MEDIA GROUP", Vector2(480, pos.y + lh + 40), 5.0, Color(1, 1, 1, fade), true)
	if t > 1.7 and int(t * 4.0) % 2 == 0:
		PF.draw_text(self, "PRESENTS", Vector2(480, pos.y + lh + 90), 4.0, Color(0.91, 0.14, 0.23, fade), true)
	for y in range(0, 540, 4):
		draw_rect(Rect2(0, y, 960, 1), Color(0, 0, 0, 0.35))
