extends Node2D
## Plays frame animations built from the character sprite sheets
## (assets/anim/anims.json). Feet sit at the origin; frames face right and
## flip with `face`. Supports a tint, a white hit flash and fading.

const SHADER := """
shader_type canvas_item;
uniform vec4 tint = vec4(0.0);
uniform float flash = 0.0;
void fragment() {
	vec4 c = COLOR;
	c.rgb = mix(c.rgb, tint.rgb, tint.a);
	c.rgb = mix(c.rgb, vec3(1.0), flash);
	COLOR = c;
}
"""
static var _atlas: Dictionary = {}
static var _tex: Dictionary = {}
static var _shader: Shader

var key = "max"
var anim = "idle"
var frame = 0
var face = 1
var speed = 1.0
var size_mul = 1.0
var tint = Color(0, 0, 0, 0)
var flash = 0.0
var alpha = 1.0
var tilt = 0.0
var _t = 0.0
var _done = false
var _mat: ShaderMaterial


static func atlas() -> Dictionary:
	if _atlas.is_empty():
		_atlas = JSON.parse_string(FileAccess.get_file_as_string("res://assets/anim/anims.json"))
	return _atlas


static func has_anim(k: String, a: String) -> bool:
	return atlas()["chars"].has(k) and atlas()["chars"][k].has(a)


static func tex(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load("res://assets/anim/" + path)
	return _tex[path]


func _ready() -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	material = _mat


## Switch animation. Restarts only when the name changes (or `restart`).
func play(name: String, restart := false) -> void:
	if not has_anim(key, name):
		return
	if name != anim or restart:
		anim = name
		frame = 0
		_t = 0.0
		_done = false


## Show a frame by progress 0..1 through the current animation.
func seek(name: String, p: float) -> void:
	play(name)
	var n: int = atlas()["chars"][key][anim]["frames"].size()
	frame = clampi(int(p * n), 0, n - 1)
	_t = -INF


func finished() -> bool:
	return _done


func _process(delta: float) -> void:
	_mat.set_shader_parameter("tint", tint)
	_mat.set_shader_parameter("flash", flash)
	if _t != -INF:
		var a: Dictionary = atlas()["chars"][key].get(anim, {})
		if not a.is_empty():
			_t += delta * speed
			var n: int = a["frames"].size()
			var f = int(_t * float(a["fps"]))
			if a["loop"]:
				frame = f % n
			else:
				frame = mini(f, n - 1)
				_done = f >= n - 1
	queue_redraw()


func _draw() -> void:
	var a: Dictionary = atlas()["chars"].get(key, {}).get(anim, {})
	if a.is_empty():
		return
	var fr: Dictionary = a["frames"][clampi(frame, 0, a["frames"].size() - 1)]
	var t = tex(fr["f"])
	var s: float = atlas()["scale"] * size_mul
	draw_set_transform(Vector2.ZERO, tilt, Vector2(face * s, s))
	draw_texture(t, Vector2(-fr["ax"], -fr["ay"]), Color(1, 1, 1, alpha))
	draw_set_transform(Vector2.ZERO)
