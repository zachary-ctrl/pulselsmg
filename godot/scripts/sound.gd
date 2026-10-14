extends Node
## Plays the pre-rendered sound effects, music loops and room ambience.

var sound_on = true
var music_on = true
var _sfx = {}
var _pool: Array[AudioStreamPlayer] = []
var _next = 0
var _music: Array[AudioStreamPlayer] = []
var _music_idx = 0
var _music_name = ""
var _amb: AudioStreamPlayer
var _amb_name = ""
var _focus: AudioStreamPlayer

const SFX := ["slash", "hit", "step_wood", "step_tile", "step_lino", "step_metal", "step_astral", "land", "jump", "djump", "dash", "hurt",
	"focus", "heal", "phone", "project", "return", "tick", "fp", "ehit", "lunge", "stabilize", "whisper", "zap", "pop", "rewind", "shards",
	"glitch", "charge", "beam", "chain", "throw", "glass", "lock", "boom", "stagger", "phase2", "defeat", "unlock", "gate", "rest", "whoosh",
	"gong", "death", "heartbeat", "select", "choice", "pause", "endsting", "door", "voice_max", "voice_lana", "voice_jason", "voice_ciencia",
	"voice_choir", "voice_echo"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in SFX:
		_sfx[n] = load("res://assets/audio/%s.wav" % n)
	for i in 16:
		var p = AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	for i in 2:
		var m = AudioStreamPlayer.new()
		m.volume_db = -80
		add_child(m)
		_music.append(m)
	_amb = AudioStreamPlayer.new()
	_amb.volume_db = -6
	add_child(_amb)
	_focus = AudioStreamPlayer.new()
	add_child(_focus)


func play(name: String, pitch_var := 0.0, volume_db := 0.0) -> void:
	if not sound_on or not _sfx.has(name):
		return
	if name == "focus":
		_focus.stream = _sfx[name]
		_focus.play()
		return
	var p = _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = _sfx[name]
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.volume_db = volume_db
	p.play()


func stop_focus() -> void:
	_focus.stop()


func voice(who: String) -> void:
	play("voice_" + who, 0.12, -4.0)


func _looped(path: String) -> AudioStreamWAV:
	var s: AudioStreamWAV = load(path)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = int(s.get_length() * s.mix_rate)
	return s


func music(name: String) -> void:
	if name == _music_name:
		return
	_music_name = name
	var old = _music[_music_idx]
	_music_idx = 1 - _music_idx
	var cur = _music[_music_idx]
	var tw = create_tween().set_parallel(true)
	tw.tween_property(old, "volume_db", -80.0, 1.2)
	if name == "":
		return
	cur.stream = _looped("res://assets/audio/mus_%s.wav" % name)
	cur.volume_db = -80
	cur.play()
	tw.tween_property(cur, "volume_db", -6.0 if music_on else -80.0, 1.2)


func ambience(room_id: String) -> void:
	if room_id == _amb_name:
		return
	_amb_name = room_id
	_amb.stream = _looped("res://assets/audio/amb_%s.wav" % room_id)
	_amb.play()


func set_sound(on: bool) -> void:
	sound_on = on
	AudioServer.set_bus_mute(0, not on)


func set_music(on: bool) -> void:
	music_on = on
	_music[_music_idx].volume_db = -6.0 if on else -80.0
