class_name NetworkBootstrap
extends Node3D

@export var player_scene: PackedScene = preload("res://scenes/Player.tscn")
@export var listen_port: int = 12345
@export var connect_address: String = "127.0.0.1"
@export var tick_rate: float = 30.0
@export var input_latency_ms: int = 0
@export var snapshot_latency_ms: int = 0
@export var jitter_ms: int = 0
@export var loss_percent: float = 0.0

var ready_peers: Dictionary = {}
var peer_inputs: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var tick_accum: float = 0.0
var tick_id: int = 0
var tick_delta: float = 1.0 / 30.0
var input_queue: Array[Dictionary] = []
var snapshot_queue: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("network_bootstrap")
	rng.randomize()
	tick_delta = 1.0 / tick_rate
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
			"yaw": local_player.get_yaw()
		}

	for player in _get_players():
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
	var input_dir: Vector2 = local_player.build_input()
	local_player.tick_move(input_dir, tick_delta)
	server_receive_input.rpc_id(1, current_tick, input_dir, local_player.get_yaw())

func _send_snapshot(current_tick: int) -> void:
	var player_states: Array[Dictionary] = []
	for player in _get_players():
		player_states.append({
			"id": player.peer_id,
			"pos": player.global_position,
			"vel": player.velocity,
			"yaw": player.rotation.y
		})
	var cube_states: Array[Dictionary] = []
	for cube in _get_cubes():
		cube_states.append({
			"name": cube.name,
			"pos": cube.global_position
		})
	for peer_id in get_ready_peers():
		_queue_snapshot(peer_id, current_tick, player_states, cube_states)

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

func _on_peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server():
		_despawn_player(peer_id)
		ready_peers.erase(peer_id)
		peer_inputs.erase(peer_id)

func _spawn_player(peer_id: int) -> void:
	spawn_player.rpc(peer_id)

func _despawn_player(peer_id: int) -> void:
	despawn_player.rpc(peer_id)

@rpc("authority", "reliable", "call_local")
func spawn_player(peer_id: int) -> void:
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
	_queue_input(sender, input_dir, yaw)

@rpc("authority", "unreliable")
func send_snapshot(_tick: int, player_states: Array[Dictionary], cube_states: Array[Dictionary]) -> void:
	for state in player_states:
		var peer_id: int = state["id"]
		var pos: Vector3 = state["pos"]
		var vel: Vector3 = state["vel"]
		var yaw: float = state["yaw"]
		var player := _get_player(peer_id)
		if player:
			player.apply_snapshot(pos, vel, yaw)
	for state in cube_states:
		var cube_name: String = state["name"]
		var pos: Vector3 = state["pos"]
		var cube := _get_cube(cube_name)
		if cube:
			cube.apply_snapshot(pos)

func set_latency_settings(input_ms: int, snapshot_ms: int, jitter: int, loss: float) -> void:
	input_latency_ms = max(input_ms, 0)
	snapshot_latency_ms = max(snapshot_ms, 0)
	jitter_ms = max(jitter, 0)
	loss_percent = clampf(loss, 0.0, 100.0)

@rpc("any_peer", "reliable")
func set_latency_rpc(input_ms: int, snapshot_ms: int, jitter: int, loss: float) -> void:
	if not multiplayer.is_server():
		return
	set_latency_settings(input_ms, snapshot_ms, jitter, loss)

func _queue_input(peer_id: int, input_dir: Vector2, yaw: float) -> void:
	if _should_drop():
		return
	var deliver_at: int = Time.get_ticks_msec() + _latency_ms(input_latency_ms)
	input_queue.append({
		"time_ms": deliver_at,
		"peer_id": peer_id,
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
			peer_inputs[entry["peer_id"]] = {
				"input": entry["input"],
				"yaw": entry["yaw"]
			}
		else:
			remaining.append(entry)
	input_queue = remaining

func _queue_snapshot(peer_id: int, tick: int, player_states: Array[Dictionary], cube_states: Array[Dictionary]) -> void:
	if _should_drop():
		return
	var deliver_at: int = Time.get_ticks_msec() + _latency_ms(snapshot_latency_ms)
	snapshot_queue.append({
		"time_ms": deliver_at,
		"peer_id": peer_id,
		"tick": tick,
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
			send_snapshot.rpc_id(entry["peer_id"], entry["tick"], entry["players"], entry["cubes"])
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
	return {"input": Vector2.ZERO, "yaw": yaw}

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
