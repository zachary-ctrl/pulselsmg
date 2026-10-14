extends Node
## Throwaway harness for the LSMG arcade minigames. Run:
##   godot --path . res://tools/arcade_test.tscn -- knight|duck <outdir>
## Drives the game with Input.action_press and saves screenshots.

class FakeMain:
	extends Node
	func close_arcade() -> void:
		print("ARCADE_TEST close_arcade called")


var game: Control
var which = "knight"
var out = "user://"
var clock = 0.0
var steps: Array = []
var shots = 0
var saved_high = null


func _ready() -> void:
	var args = OS.get_cmdline_user_args()
	if args.size() > 0:
		which = args[0]
	if args.size() > 1:
		out = args[1]
	saved_high = Game.settings.get("high_" + which, null)
	var fm = FakeMain.new()
	add_child(fm)
	var layer = CanvasLayer.new()
	add_child(layer)
	var script = load("res://scripts/arcade_%s.gd" % which)
	game = script.new()
	game.main = fm
	layer.add_child(game)
	if which == "knight":
		steps = [
			[0.8, "shot", "title"], [1.0, "tap", "jump"],
			[1.6, "shot", "start"],
			[2.4, "hold", "jump", 0.5], [3.4, "tap", "attack"], [3.5, "shot", "attack"],
			[4.2, "hold", "jump", 0.4], [5.0, "hold", "jump", 0.2], [6.0, "shot", "run"],
			[6.5, "call", "elapsed50"], [7.0, "hold", "jump", 0.6], [8.0, "tap", "attack"],
			[9.5, "shot", "late"], [10.5, "hold", "jump", 0.6], [12.0, "tap", "attack"], [13.0, "shot", "late2"],
			[14.0, "call", "kill"], [16.0, "shot", "over"], [16.5, "tap", "jump"], [17.5, "shot", "restart"],
			[18.0, "tap", "pause"], [18.5, "quit"]]
	else:
		steps = [[0.8, "shot", "title"], [1.0, "tap", "jump"], [1.8, "shot", "start"], [3.0, "tap", "attack"], [3.15, "shot", "quack"]]
		# hop-and-glide constantly so the run lasts and shows more terrain
		var k = 2.0
		while k < 24.0:
			steps.append([k, "hold", "jump", 0.55])
			k += 0.75
		for i in 9:
			steps.append([4.4 + i * 2.2, "shot", "run%d" % i])
		steps.append_array([[24.5, "call", "kill"], [24.8, "shot", "dying"], [27.0, "shot", "over"], [27.5, "tap", "jump"], [28.5, "shot", "restart"], [29.0, "tap", "pause"], [29.5, "quit"]])


func _physics_process(dt: float) -> void:
	var prev = clock
	clock += dt
	for s in steps:
		if s[0] > prev and s[0] <= clock:
			_do(s)
	for s in steps:
		if s[1] == "hold" and s[0] + s[3] > prev and s[0] + s[3] <= clock:
			Input.action_release(s[2])


func _do(s: Array) -> void:
	match s[1]:
		"shot":
			await RenderingServer.frame_post_draw
			var img = get_viewport().get_texture().get_image()
			shots += 1
			var p = "%s/%s_%02d_%s.png" % [out, which, shots, s[2]]
			img.save_png(p)
			print("ARCADE_TEST shot ", p, " state=", game.state if is_instance_valid(game) else "freed")
		"tap":
			Input.action_press(s[2])
			await get_tree().create_timer(0.1).timeout
			Input.action_release(s[2])
		"hold":
			Input.action_press(s[2])
		"call":
			if not is_instance_valid(game):
				return
			if s[2] == "elapsed50":
				game.elapsed = 50.0
				game.sword_timer = 0.5
			elif s[2] == "far":
				game.debug_skip(260)
			elif s[2] == "kill":
				if which == "knight":
					game.shield = 0.0
					game.lives = 0
					game._damaged()
				else:
					game._die()
		"quit":
			print("ARCADE_TEST done, game freed=", not is_instance_valid(game), " high=", Game.settings.get("high_" + which, null))
			# leave the developer's real high score untouched
			if saved_high == null:
				Game.settings.erase("high_" + which)
			else:
				Game.settings["high_" + which] = saved_high
			Game.save_settings()
			get_tree().quit()
