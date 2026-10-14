extends Node2D
## Draws a design-sheet figure split at the hip so legs stride, the body bobs
## and leans, and the sprite squashes and stretches. Feet sit at the origin.
## Replace with AnimatedSprite2D or a Skeleton2D rig once frame art exists.

const SPR := {
	"max": {"img": "max_side", "act": "max_act", "h": 72.0, "hip": 0.53, "eye": Vector2(0.8, 0.1)},
	"lana": {"img": "lana_side", "h": 70.0, "hip": 0.5},
	"jason": {"img": "jason_side", "h": 78.0, "hip": 0.5},
	"ciencia": {"img": "ciencia", "h": 104.0, "hip": 0.5, "nolegs": true},
	"returned": {"img": "returned", "h": 72.0, "hip": 0.55, "eye2": [0.44, 0.58, 0.105]},
	"teacher": {"img": "teacher", "h": 70.0, "hip": 0.5, "nolegs": true, "eye2": [0.4, 0.55, 0.1]},
}
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
static var _tex = {}
static var _shader: Shader

var key = "max"
var pose = {}
var tint = Color(0, 0, 0, 0)
var flash = 0.0
var alpha = 1.0
var eyes = ""
var _mat: ShaderMaterial


func _ready() -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	material = _mat


static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		_tex[name] = load("res://assets/characters/%s.png" % name)
	return _tex[name]


func _process(_delta: float) -> void:
	_mat.set_shader_parameter("tint", tint)
	_mat.set_shader_parameter("flash", flash)
	queue_redraw()


static func _rt(rot: float, pos: Vector2) -> Transform2D:
	return Transform2D(rot, pos)


static func _sc(s: Vector2) -> Transform2D:
	return Transform2D(0.0, s, 0.0, Vector2.ZERO)


func _draw() -> void:
	var sp: Dictionary = SPR[key]
	var p = pose
	var atk: String = p.get("atk", "")
	var use_act = atk != "" and sp.has("act")
	var tx = tex(sp["act"] if use_act else sp["img"])
	var iw = float(tx.get_width())
	var ih = float(tx.get_height())
	var hh: float = sp["h"] * (1.14 if use_act else 1.0) * p.get("scale", 1.0)
	var ww = iw * hh / ih
	var k = hh / ih
	var col = Color(1, 1, 1, alpha)
	var face: float = p.get("face", 1)
	var t: float = p.get("t", 0.0)
	var mv: bool = p.get("moving", false)
	var sx = 1.0
	var sy = 1.0
	var brot = 0.0
	if p.get("air", false):
		sy = 1.06 if p.get("vy", 0.0) < 0 else 0.97
		sx = 1.0 / sy
	if p.get("heal", false) or p.get("kneel", false):
		sy = 0.9
		sx = 1.07
	if p.get("dash", false):
		brot = 0.16
		sx = 1.12
		sy = 0.92
	var base = _sc(Vector2(face, 1)) * _rt(brot, Vector2.ZERO) * _sc(Vector2(sx, sy))
	if use_act:
		var kr = -0.35 if atk == "up" else (0.3 if atk == "down" else 0.0)
		draw_set_transform_matrix(base * _rt(kr, Vector2.ZERO))
		draw_texture_rect(tx, Rect2(-ww * 0.45, -hh, ww, hh), false, col)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	var ph: float = p.get("ph", 0.0)
	var bob = 0.0
	if mv:
		bob = -absf(sin(ph)) * 2.6
	elif p.get("slump", false):
		bob = sin(t * 1.5) * 1.5 - 3.0
	else:
		bob = sin(t * 2.1 + p.get("seed", 0.0)) * 0.7
	if sp.get("nolegs", false) or p.get("lying", false):
		var lean = (0.06 if mv else 0.0) + (0.2 if p.get("dash", false) else 0.0) + p.get("tilt", 0.0) * 0.4
		var m = base * _rt(0, Vector2(0, bob)) * _rt(lean, Vector2.ZERO)
		if p.get("lying", false):
			m = base * _rt(-PI / 2.0, Vector2(0, 0))
			draw_set_transform_matrix(m)
			draw_texture_rect(tx, Rect2(-ww / 2.0, -hh * 0.82, ww, hh), false, Color(1, 1, 1, alpha * 0.9))
		else:
			draw_set_transform_matrix(m)
			draw_texture_rect(tx, Rect2(-ww / 2.0, -hh, ww, hh), false, col)
			_eyes(sp, ww, hh, 0.0)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	var hip: float = sp["hip"]
	var hip_y = -hh * (1.0 - hip)
	var left = -ww / 2.0
	var th = 0.0
	if mv:
		th = sin(ph) * 0.36
	elif p.get("air", false):
		th = 0.32 if p.get("vy", 0.0) < 0 else 0.16
	elif p.get("heal", false) or p.get("kneel", false):
		th = 0.25
	var src_hip = ih * hip
	var ov = 1.5 / k
	for side in [-1, 1]:
		var rot = th if side < 0 else -th
		var m = base * _rt(0, Vector2(0, hip_y)) * _rt(rot, Vector2.ZERO) * _rt(0, Vector2(0, -hip_y))
		draw_set_transform_matrix(m)
		var sx0 = 0.0 if side < 0 else iw / 2.0
		draw_texture_rect_region(tx, Rect2(left + sx0 * k, hip_y - 1.5, ww / 2.0, (ih - src_hip) * k + 1.5), Rect2(sx0, src_hip - ov, iw / 2.0, ih - src_hip + ov), col)
	var lean2 = (0.07 if mv else 0.0) + (-0.12 if p.get("slump", false) else 0.0) + (0.05 if p.get("dash", false) else 0.0)
	draw_set_transform_matrix(base * _rt(0, Vector2(0, hip_y)) * _rt(lean2, Vector2.ZERO) * _rt(0, Vector2(0, -hip_y + bob)))
	draw_texture_rect_region(tx, Rect2(left, -hh, ww, src_hip * k + 1.5), Rect2(0, 0, iw, src_hip + ov), col)
	_eyes(sp, ww, hh, 0.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _eyes(sp: Dictionary, ww: float, hh: float, bob: float) -> void:
	var e: String = pose.get("eyes", eyes)
	if e == "":
		return
	var glow = Color(0.65, 0.55, 1.0) if e == "glow" else Color(0.87, 0.9, 1.0)
	var pts: Array = []
	if sp.has("eye") and e != "hollow":
		pts.append(Vector2(-ww / 2.0 + ww * sp["eye"].x, -hh + hh * sp["eye"].y + bob))
	if sp.has("eye2") and e == "hollow":
		pts.append(Vector2(-ww / 2.0 + ww * sp["eye2"][0], -hh + hh * sp["eye2"][2] + bob))
		pts.append(Vector2(-ww / 2.0 + ww * sp["eye2"][1], -hh + hh * sp["eye2"][2] + bob))
	for q in pts:
		draw_circle(q, 6.0, Color(glow, 0.22 * alpha))
		draw_circle(q, 3.2, Color(glow, 0.45 * alpha))
		draw_circle(q, 1.3, Color(1, 1, 1, alpha))
