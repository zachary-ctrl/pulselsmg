extends Node
## Online co-op (autoload "Net"). One host runs the game; one guest joins
## and plays the second hero. The host is authoritative, in the spirit of
## TetraForce's map-host networking (MIT, Joseph Lesko and contributors):
## the guest sends its buttons every physics frame, the host simulates
## everything and streams snapshots back. ENet needs a desktop build; a
## browser page can neither host nor open raw UDP connections.

const PORT := 24680
const SNAP_RATE := 1.0 / 20.0

var role = ""
var guest_id = 0
var status = ""
var main: Node
var _snap_t = 0.0
var sound_queue: Array = []
var _rumble: Array = []
var last_snap_ms = 0


func online_supported() -> bool:
	return not OS.has_feature("web")


func is_host() -> bool:
	return role == "host" and guest_id != 0


func is_guest() -> bool:
	return role == "guest"


func addresses() -> String:
	var out = []
	for a in IP.get_local_addresses():
		if a.count(".") == 3 and not a.begins_with("127.") and not a.begins_with("169.254"):
			out.append(a)
	return ", ".join(out) if not out.is_empty() else "unknown"


func host() -> bool:
	leave(false)
	var p = ENetMultiplayerPeer.new()
	var err = p.create_server(PORT, 1)
	if err != OK:
		status = "Couldn't open port %d (error %d)." % [PORT, err]
		return false
	multiplayer.multiplayer_peer = p
	role = "listen"
	status = "Hosting on port %d. Tell your friend to join: %s" % [PORT, addresses()]
	_connect_signals()
	return true


func join(ip: String) -> bool:
	leave(false)
	var p = ENetMultiplayerPeer.new()
	var err = p.create_client(ip.strip_edges(), PORT)
	if err != OK:
		status = "Couldn't connect (error %d)." % err
		return false
	multiplayer.multiplayer_peer = p
	role = "joining"
	status = "Connecting to %s..." % ip
	_connect_signals()
	return true


func leave(notify := true) -> void:
	if multiplayer.multiplayer_peer != null and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	var was = role
	role = ""
	guest_id = 0
	status = ""
	if notify and main != null:
		if was == "guest":
			main.guest_left()
		elif main.coop == "host":
			main.remove_partner()


func _connect_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_peer_connected):
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
		multiplayer.connected_to_server.connect(_connected)
		multiplayer.connection_failed.connect(_failed)
		multiplayer.server_disconnected.connect(_server_gone)


func _peer_connected(id: int) -> void:
	if role != "listen" and role != "host":
		return
	guest_id = id
	role = "host"
	status = "Player 2 connected."
	main.add_partner("remote")
	if main.room != null and main.mode != "title":
		send_room()


func _peer_disconnected(id: int) -> void:
	if id == guest_id:
		guest_id = 0
		role = "listen"
		status = "Player 2 disconnected. Still hosting on port %d." % PORT
		main.remove_partner()


func _connected() -> void:
	role = "guest"
	status = "Connected. Waiting for the host to start..."
	main.guest_joined()


func _failed() -> void:
	status = "Couldn't reach the host. Check the address and that port %d is open." % PORT
	role = ""
	if main != null:
		main.toast(status)


func _server_gone() -> void:
	leave(true)
	if main != null:
		main.toast("The host ended the session")


func _physics_process(dt: float) -> void:
	if main == null:
		return
	if role == "guest":
		_input_rpc.rpc_id(1, main.VInput.local_bits())
	elif is_host():
		_snap_t -= dt
		if _snap_t <= 0.0 and main.room != null:
			_snap_t = SNAP_RATE
			var s: Dictionary = main.build_snapshot()
			s["snd"] = sound_queue
			s["rb"] = _rumble
			sound_queue = []
			_rumble = []
			_snap_rpc.rpc_id(guest_id, s)


func queue_sound(n: String, pitch: float, vol: float) -> void:
	if is_host() and sound_queue.size() < 24:
		sound_queue.append([n, pitch, vol])


func rumble_guest(w: float, s: float, d: float) -> void:
	if is_host():
		_rumble = [w, s, d]


func send_room() -> void:
	if not is_host():
		return
	var flags_copy = Game.flags.duplicate(true)
	_room_rpc.rpc_id(guest_id, main.room_id, main.player.position, flags_copy, Game.chapter, Game.ability, Game.prog, Game.anchors)


func send_end(args: Array) -> void:
	if is_host():
		_end_rpc.rpc_id(guest_id, args)


func send_title() -> void:
	if is_host():
		_title_rpc.rpc_id(guest_id)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _input_rpc(bits: int) -> void:
	if role == "host" and multiplayer.get_remote_sender_id() == guest_id and main.partner_ok():
		main.partner.inp.remote_bits = bits


@rpc("authority", "call_remote", "unreliable_ordered")
func _snap_rpc(s: Dictionary) -> void:
	if role == "guest":
		last_snap_ms = Time.get_ticks_msec()
		main.apply_snapshot(s)


@rpc("authority", "call_remote", "reliable")
func _room_rpc(id: String, pos: Vector2, flags: Dictionary, chapter: int, ability: Dictionary, prog: Dictionary, anchors: Dictionary) -> void:
	if role == "guest":
		Game.flags = flags
		Game.chapter = chapter
		Game.ability = ability
		Game.prog = prog
		Game.anchors = anchors
		main.guest_load_room(id, pos)


@rpc("authority", "call_remote", "reliable")
func _end_rpc(args: Array) -> void:
	if role == "guest":
		main.guest_show_end(args)


@rpc("authority", "call_remote", "reliable")
func _title_rpc() -> void:
	if role == "guest":
		main.guest_waiting("The host went back to the title screen.")
