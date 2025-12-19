class_name NetworkBootstrap
extends Node3D

@export var player_scene: PackedScene = preload("res://scenes/Player.tscn")
@export var listen_port: int = 12345
@export var connect_address: String = "127.0.0.1"
@export var tick_rate: float = 30.0
@export var rtt_ms_setting: int = 0
@export var input_latency_ms: int = 0
@export var snapshot_latency_ms: int = 0
@export var jitter_ms: int = 0
@export var loss_percent: float = 0.0
@export var input_delay_ticks: int = 0
@export var ping_interval_ms: int = 1000
@export var bot_bounds_min: Vector2 = Vector2(-8.0, -8.0)
@export var bot_bounds_max: Vector2 = Vector2(8.0, 8.0)
@export var bot_history_size: int = 120
@export var bot_red_rtt_ms: int = 120
@export var bot_green_rtt_ms: int = 40
@export var bot_turn_interval: float = 1.0

var ready_peers: Dictionary = {}
var peer_inputs: Dictionary = {}
var peer_last_tick: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var tick_accum: float = 0.0
var tick_id: int = 0
var tick_delta: float = 1.0 / 30.0
var input_queue: Array[Dictionary] = []
var snapshot_queue: Array[Dictionary] = []
var input_history: Array[Dictionary] = []
var send_queue: Array[Dictionary] = []
var rtt_ms: float = 0.0
var last_ping_ms: int = 0
var ping_seq: int = 0
var ping_out_queue: Array[Dictionary] = []
var ping_response_queue: Array[Dictionary] = []
var bot_dirs: Dictionary = {}
var bot_rtt: Dictionary = {}
var bot_history: Dictionary = {}
var bot_turn_timer: Dictionary = {}
var bot_configs: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("network_bootstrap")
	rng.randomize()
	tick_delta = 1.0 / tick_rate
	_set_rtt_ms(rtt_ms_setting)
	if OS.get_cmdline_args().has("--server"):
		_start_server()
	else:
		_start_client()

func _physics_process(delta: float) -> void:
	tick_accum += delta
	if multiplayer.is_server():
		_process_input_queue()
		_process_snapshot_queue()
	while tick_accum >= tick_delta:
		tick_accum -= tick_delta
		tick_id += 1
		if multiplayer.is_server():
			_server_tick(tick_id)
		else:
			_client_tick(tick_id)

func _process(_delta: float) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	var now: int = Time.get_ticks_msec()
	if multiplayer.is_server():
		_process_ping_response_queue(now)
		return
	_process_ping_send_queue(now)
	if now - last_ping_ms >= ping_interval_ms:
		last_ping_ms = now
		ping_seq += 1
		if _should_drop():
			return
		var send_at: int = now + _latency_ms(input_latency_ms)
		ping_out_queue.append({
			"time_ms": send_at,
			"client_time_ms": now,
			"seq": ping_seq
		})

func _start_server() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err: int = peer.create_server(listen_port)
	if err != OK:
		push_error("Failed to start server on port %s" % listen_port)
		return

	multiplayer.multiplayer_peer = peer
	get_window().title = "Server"
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_spawn_player(multiplayer.get_unique_id())
	_spawn_bots()

func _start_client() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err: int = peer.create_client(connect_address, listen_port)
	if err != OK:
		push_error("Failed to connect to %s:%s" % [connect_address, listen_port])
		return

	multiplayer.multiplayer_peer = peer
	get_window().title = "Client"

func _server_tick(current_tick: int) -> void:
	var local_player: PlayerController = _get_local_player()
	if local_player:
		peer_inputs[1] = {
			"input": local_player.build_input(),
			"yaw": local_player.get_yaw(),
			"tick": current_tick
		}

	for player in _get_players():
		if player.is_bot:
			_update_bot(player)
		else:
			var entry: Dictionary = _get_peer_input(player.peer_id)
			var input_dir: Vector2 = entry["input"]
			var yaw: float = entry["yaw"]
			player.rotation.y = yaw
			player.tick_move(input_dir, tick_delta)

	_send_snapshot(current_tick)

func _client_tick(current_tick: int) -> void:
	var local_player: PlayerController = _get_local_player()
	if not local_player:
		return
	_flush_send_queue(current_tick)
	var input_dir: Vector2 = local_player.build_input()
	var yaw: float = local_player.get_yaw()
	var entry: Dictionary = {
		"tick": current_tick,
		"input": input_dir,
		"yaw": yaw
	}
	input_history.append(entry)
	local_player.simulate_input(input_dir, yaw, tick_delta)
	if input_delay_ticks > 0:
		var send_at: int = current_tick + input_delay_ticks
		send_queue.append({
			"tick": current_tick,
			"input": input_dir,
			"yaw": yaw,
			"send_at": send_at
		})
	else:
		server_receive_input.rpc_id(1, current_tick, input_dir, yaw)

func _flush_send_queue(current_tick: int) -> void:
	if send_queue.is_empty():
		return
	var remaining: Array[Dictionary] = []
	for item in send_queue:
		var entry: Dictionary = item
		if entry["send_at"] <= current_tick:
			server_receive_input.rpc_id(1, entry["tick"], entry["input"], entry["yaw"])
		else:
			remaining.append(entry)
	send_queue = remaining

func _send_snapshot(current_tick: int) -> void:
	var player_states: Array[Dictionary] = []
	var now: int = Time.get_ticks_msec()
	for player in _get_players():
		var pos: Vector3 = player.global_position
		var vel: Vector3 = player.velocity
		var yaw: float = player.rotation.y
		if player.is_bot and bot_rtt.has(player.peer_id):
			var sample := _sample_bot_history(player.peer_id, now - int(bot_rtt[player.peer_id]) / 2)
			pos = sample["pos"]
			vel = sample["vel"]
			yaw = sample["yaw"]
		player_states.append({
			"id": player.peer_id,
			"pos": pos,
			"vel": vel,
			"yaw": yaw
		})
	var cube_states: Array[Dictionary] = []
	for cube in _get_cubes():
		cube_states.append({
			"name": cube.name,
			"pos": cube.global_position
		})
	for peer_id in get_ready_peers():
		var ack_tick: int = 0
		if peer_last_tick.has(peer_id):
			ack_tick = int(peer_last_tick[peer_id])
		_queue_snapshot(peer_id, current_tick, ack_tick, player_states, cube_states)

func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_spawn_player(peer_id)
		ready_peers[peer_id] = false
		var existing: PackedInt32Array = multiplayer.get_peers()
		existing.append(multiplayer.get_unique_id())
		for existing_id in existing:
			var id: int = existing_id
			if id == peer_id:
				continue
			spawn_player.rpc_id(peer_id, id)
		for bot in bot_configs:
			var bot_id: int = bot["id"]
			spawn_player.rpc_id(peer_id, bot_id)
			configure_bot.rpc_id(peer_id, bot_id, bot["color"])

func _on_peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server():
		_despawn_player(peer_id)
		ready_peers.erase(peer_id)
		peer_inputs.erase(peer_id)
		peer_last_tick.erase(peer_id)

func _spawn_player(peer_id: int) -> void:
	_spawn_player_local(peer_id)
	spawn_player.rpc(peer_id)

func _despawn_player(peer_id: int) -> void:
	despawn_player.rpc(peer_id)

@rpc("authority", "reliable")
func spawn_player(peer_id: int) -> void:
	_spawn_player_local(peer_id)

func _spawn_player_local(peer_id: int) -> PlayerController:
	var player: PlayerController = player_scene.instantiate()
	player.name = "Player_%s" % peer_id
	player.peer_id = peer_id
	player.add_to_group("players")
	add_child(player)
	player.set_multiplayer_authority(1)
	player.call_deferred("_apply_authority")
	var x: float = rng.randf_range(-8.0, 8.0)
	var z: float = rng.randf_range(1.0, 8.0)
	player.global_position = Vector3(x, 1.0, z)
	if not multiplayer.is_server() and peer_id == 1:
		client_ready.rpc_id(1)
	return player

@rpc("authority", "reliable", "call_local")
func despawn_player(peer_id: int) -> void:
	var node_name := "Player_%s" % peer_id
	if has_node(node_name):
		get_node(node_name).queue_free()

@rpc("any_peer", "reliable")
func client_ready() -> void:
	if multiplayer.is_server():
		var sender: int = multiplayer.get_remote_sender_id()
		ready_peers[sender] = true

@rpc("any_peer", "unreliable")
func server_receive_input(_tick: int, input_dir: Vector2, yaw: float) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	_queue_input(sender, _tick, input_dir, yaw)

@rpc("authority", "unreliable")
func send_snapshot(_tick: int, ack_tick: int, player_states: Array[Dictionary], cube_states: Array[Dictionary]) -> void:
	for state in player_states:
		var peer_id: int = state["id"]
		var pos: Vector3 = state["pos"]
		var vel: Vector3 = state["vel"]
		var yaw: float = state["yaw"]
		var player := _get_player(peer_id)
		if player:
			if peer_id == multiplayer.get_unique_id():
				input_history = player.reconcile_from_server(
					pos,
					vel,
					yaw,
					ack_tick,
					input_history,
					tick_delta,
					player.velocity_deadzone,
					player.position_deadzone
				)
			else:
				player.apply_snapshot(pos, vel, yaw)
	for state in cube_states:
		var cube_name: String = state["name"]
		var pos: Vector3 = state["pos"]
		var cube := _get_cube(cube_name)
		if cube:
			cube.apply_snapshot(pos)

func set_latency_settings(rtt_value_ms: int, jitter: int, loss: float) -> void:
	_set_rtt_ms(rtt_value_ms)
	jitter_ms = max(jitter, 0)
	loss_percent = clampf(loss, 0.0, 100.0)
	_set_tick_rate(tick_rate)

@rpc("any_peer", "reliable")
func set_latency_rpc(rtt_value_ms: int, jitter: int, loss: float) -> void:
	if not multiplayer.is_server():
		return
	set_latency_settings(rtt_value_ms, jitter, loss)

@rpc("any_peer", "reliable")
func set_rtt_ms_rpc(rtt_value_ms: int) -> void:
	if not multiplayer.is_server():
		return
	_set_rtt_ms(rtt_value_ms)

@rpc("any_peer", "reliable")
func set_tick_rate_rpc(rate: float) -> void:
	if not multiplayer.is_server():
		return
	_set_tick_rate(rate)

func _set_tick_rate(rate: float) -> void:
	tick_rate = clampf(rate, 5.0, 60.0)
	tick_delta = 1.0 / tick_rate

func _set_rtt_ms(rtt_value_ms: int) -> void:
	rtt_ms_setting = clampi(rtt_value_ms, 0, 600)
	var one_way: int = int(floor(float(rtt_ms_setting) * 0.5))
	input_latency_ms = one_way
	snapshot_latency_ms = one_way

func _queue_input(peer_id: int, tick: int, input_dir: Vector2, yaw: float) -> void:
	if _should_drop():
		return
	var deliver_at: int = Time.get_ticks_msec() + _latency_ms(input_latency_ms)
	input_queue.append({
		"time_ms": deliver_at,
		"peer_id": peer_id,
		"tick": tick,
		"input": input_dir,
		"yaw": yaw
	})

func _process_input_queue() -> void:
	if input_queue.is_empty():
		return
	var now: int = Time.get_ticks_msec()
	var remaining: Array[Dictionary] = []
	for item in input_queue:
		var entry: Dictionary = item
		if entry["time_ms"] <= now:
			var peer_id: int = entry["peer_id"]
			var tick: int = entry["tick"]
			peer_inputs[peer_id] = {
				"input": entry["input"],
				"yaw": entry["yaw"],
				"tick": tick
			}
			peer_last_tick[peer_id] = tick
		else:
			remaining.append(entry)
	input_queue = remaining

func _queue_snapshot(peer_id: int, tick: int, ack_tick: int, player_states: Array[Dictionary], cube_states: Array[Dictionary]) -> void:
	if _should_drop():
		return
	var deliver_at: int = Time.get_ticks_msec() + _latency_ms(snapshot_latency_ms)
	snapshot_queue.append({
		"time_ms": deliver_at,
		"peer_id": peer_id,
		"tick": tick,
		"ack": ack_tick,
		"players": player_states,
		"cubes": cube_states
	})

func _process_snapshot_queue() -> void:
	if snapshot_queue.is_empty():
		return
	var now: int = Time.get_ticks_msec()
	var remaining: Array[Dictionary] = []
	for item in snapshot_queue:
		var entry: Dictionary = item
		if entry["time_ms"] <= now:
			send_snapshot.rpc_id(entry["peer_id"], entry["tick"], entry["ack"], entry["players"], entry["cubes"])
		else:
			remaining.append(entry)
	snapshot_queue = remaining

func _latency_ms(base_ms: int) -> int:
	if jitter_ms <= 0:
		return base_ms
	var jitter: int = rng.randi_range(-jitter_ms, jitter_ms)
	return max(base_ms + jitter, 0)

func _should_drop() -> bool:
	if loss_percent <= 0.0:
		return false
	return rng.randf_range(0.0, 100.0) < loss_percent

func get_ready_peers() -> Array[int]:
	var peers: Array[int] = []
	for peer_id in ready_peers.keys():
		if ready_peers[peer_id]:
			peers.append(peer_id)
	return peers

func _get_players() -> Array[PlayerController]:
	var nodes: Array[Node] = get_tree().get_nodes_in_group("players")
	var players: Array[PlayerController] = []
	for node in nodes:
		if node is PlayerController:
			players.append(node)
	return players

func _get_player(peer_id: int) -> PlayerController:
	for player in _get_players():
		if player.peer_id == peer_id:
			return player
	return null

func _get_peer_input(peer_id: int) -> Dictionary:
	if peer_inputs.has(peer_id):
		return peer_inputs[peer_id]
	var player := _get_player(peer_id)
	var yaw: float = 0.0
	if player:
		yaw = player.rotation.y
	return {"input": Vector2.ZERO, "yaw": yaw, "tick": 0}

func _spawn_bots() -> void:
	bot_configs = [
		{"id": -1, "color": Color(1.0, 0.2, 0.2), "rtt": bot_red_rtt_ms},
		{"id": -2, "color": Color(0.2, 1.0, 0.2), "rtt": bot_green_rtt_ms}
	]
	for bot in bot_configs:
		_spawn_bot(bot["id"], bot["color"], bot["rtt"])
		spawn_player.rpc(bot["id"])
		configure_bot.rpc(bot["id"], bot["color"])

func _spawn_bot(bot_id: int, color: Color, rtt_ms: int) -> void:
	var player: PlayerController = _spawn_player_local(bot_id)
	player.name = "Bot_%s" % bot_id
	player.is_bot = true
	player.call_deferred("set_body_color", color)
	bot_dirs[bot_id] = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
	bot_rtt[bot_id] = rtt_ms
	bot_history[bot_id] = []
	bot_turn_timer[bot_id] = 0.0

@rpc("authority", "reliable", "call_local")
func configure_bot(peer_id: int, color: Color) -> void:
	var player := _get_player(peer_id)
	if not player:
		return
	player.is_bot = true
	player.call_deferred("set_body_color", color)

func _update_bot(player: PlayerController) -> void:
	var dir: Vector2 = bot_dirs.get(player.peer_id, Vector2(1.0, 0.0))
	var pos: Vector3 = player.global_position
	var timer: float = float(bot_turn_timer.get(player.peer_id, 0.0))
	timer += tick_delta
	if timer >= bot_turn_interval:
		timer = 0.0
		var angle: float = rng.randf_range(-PI, PI)
		dir = Vector2(cos(angle), sin(angle))
		bot_dirs[player.peer_id] = dir
	bot_turn_timer[player.peer_id] = timer
	if pos.x <= bot_bounds_min.x:
		dir.x = abs(dir.x)
	elif pos.x >= bot_bounds_max.x:
		dir.x = -abs(dir.x)
	if pos.z <= bot_bounds_min.y:
		dir.y = abs(dir.y)
	elif pos.z >= bot_bounds_max.y:
		dir.y = -abs(dir.y)
	if dir.length() < 0.01:
		dir = Vector2(1.0, 0.0)
	dir = dir.normalized()
	bot_dirs[player.peer_id] = dir
	var yaw: float = atan2(-dir.x, -dir.y)
	player.rotation.y = yaw
	player.tick_move(Vector2(0.0, 1.0), tick_delta)
	_record_bot_history(player)

func _record_bot_history(player: PlayerController) -> void:
	var list: Array = bot_history.get(player.peer_id, [])
	list.append({
		"time_ms": Time.get_ticks_msec(),
		"pos": player.global_position,
		"vel": player.velocity,
		"yaw": player.rotation.y
	})
	if list.size() > bot_history_size:
		list.pop_front()
	bot_history[player.peer_id] = list

func _sample_bot_history(bot_id: int, target_time_ms: int) -> Dictionary:
	var list: Array = bot_history.get(bot_id, [])
	if list.size() == 0:
		return {
			"pos": Vector3.ZERO,
			"vel": Vector3.ZERO,
			"yaw": 0.0
		}
	if list.size() == 1:
		return list[0]
	while list.size() >= 2 and list[1]["time_ms"] <= target_time_ms:
		list.pop_front()
	bot_history[bot_id] = list
	if list.size() == 1:
		return list[0]
	var s0: Dictionary = list[0]
	var s1: Dictionary = list[1]
	var t0: int = s0["time_ms"]
	var t1: int = s1["time_ms"]
	if t1 <= t0:
		return s1
	var alpha: float = float(target_time_ms - t0) / float(t1 - t0)
	alpha = clampf(alpha, 0.0, 1.0)
	return {
		"pos": s0["pos"].lerp(s1["pos"], alpha),
		"vel": s0["vel"].lerp(s1["vel"], alpha),
		"yaw": lerp_angle(float(s0["yaw"]), float(s1["yaw"]), alpha)
	}

@rpc("any_peer", "reliable")
func ping_request(client_time_ms: int, seq: int) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if _should_drop():
		return
	var send_at: int = Time.get_ticks_msec() + _latency_ms(snapshot_latency_ms)
	ping_response_queue.append({
		"time_ms": send_at,
		"peer_id": sender,
		"client_time_ms": client_time_ms,
		"seq": seq
	})

@rpc("any_peer", "reliable")
func ping_response(client_time_ms: int, _seq: int) -> void:
	if multiplayer.is_server():
		return
	var now: int = Time.get_ticks_msec()
	rtt_ms = float(now - client_time_ms)

func _process_ping_send_queue(now: int) -> void:
	if ping_out_queue.is_empty():
		return
	var remaining: Array[Dictionary] = []
	for item in ping_out_queue:
		var entry: Dictionary = item
		if entry["time_ms"] <= now:
			ping_request.rpc_id(1, entry["client_time_ms"], entry["seq"])
		else:
			remaining.append(entry)
	ping_out_queue = remaining

func _process_ping_response_queue(now: int) -> void:
	if ping_response_queue.is_empty():
		return
	var remaining: Array[Dictionary] = []
	for item in ping_response_queue:
		var entry: Dictionary = item
		if entry["time_ms"] <= now:
			ping_response.rpc_id(entry["peer_id"], entry["client_time_ms"], entry["seq"])
		else:
			remaining.append(entry)
	ping_response_queue = remaining

func get_net_stats() -> Dictionary:
	return {
		"rtt_ms": rtt_ms,
		"rtt_setting_ms": rtt_ms_setting,
		"tick_rate": tick_rate,
		"tick_id": tick_id,
		"input_delay_ticks": input_delay_ticks,
		"input_latency_ms": input_latency_ms,
		"snapshot_latency_ms": snapshot_latency_ms,
		"jitter_ms": jitter_ms,
		"loss_percent": loss_percent
	}

func _get_local_player() -> PlayerController:
	var local_id := multiplayer.get_unique_id()
	return _get_player(local_id)

func _get_cubes() -> Array[MovingCube]:
	var nodes: Array[Node] = get_tree().get_nodes_in_group("moving_cubes")
	var cubes: Array[MovingCube] = []
	for node in nodes:
		if node is MovingCube:
			cubes.append(node)
	return cubes

func _get_cube(cube_name: String) -> MovingCube:
	for cube in _get_cubes():
		if cube.name == cube_name:
			return cube
	return null
