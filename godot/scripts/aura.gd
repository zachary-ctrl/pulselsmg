extends Node2D
## A flame aura drawn behind a character (additive). Frames come from
## assets/fx/aura/<color>_<n>.png; `target` fades it in and out.

const HEIGHT := 118.0
static var _frames: Dictionary = {}

var color = "violet"
var target = 0.0
var level = 0.0
var face = 1
var _t = 0.0


static func frames(c: String) -> Array:
	if not _frames.has(c):
		var out = []
		for i in 8:
			var p = "res://assets/fx/aura/%s_%d.png" % [c, i]
			if ResourceLoader.exists(p):
				out.append(load(p))
		_frames[c] = out
	return _frames[c]


func _ready() -> void:
	var m = CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	show_behind_parent = true


func _process(delta: float) -> void:
	level = move_toward(level, target, delta * 3.0)
	_t += delta
	queue_redraw()


func _draw() -> void:
	if level <= 0.01:
		return
	var fr: Array = frames(color)
	if fr.is_empty():
		for i in 3:
			draw_circle(Vector2(0, -36), 40.0 - i * 10.0, Color(0.7, 0.6, 1.0, 0.08 * level))
		return
	# Frames 0-1 ignite, 2-6 burn, 7 fades: loop the burning frames.
	var n: int = fr.size()
	var idx = 2 + int(_t * 12.0) % maxi(1, n - 3) if n > 4 else int(_t * 12.0) % n
	var tex: Texture2D = fr[clampi(idx, 0, n - 1)]
	var s = HEIGHT / float(tex.get_height())
	var w = tex.get_width() * s
	draw_texture_rect(tex, Rect2(-w / 2.0, -HEIGHT + 8.0, w, HEIGHT), false, Color(1, 1, 1, 0.85 * level))
