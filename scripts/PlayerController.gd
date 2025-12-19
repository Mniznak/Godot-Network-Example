class_name PlayerController
extends CharacterBody3D

@export var speed: float = 6.0
@export var gravity: float = 24.0
@export var local_correction: float = 0.2
@export var remote_correction: float = 0.35
@export var correction_deadzone: float = 0.05
@export var max_correction_per_tick: float = 0.4
@export var snap_threshold: float = 3.0
@export var velocity_correction: float = 0.25
@export var reconcile_threshold: float = 0.15
@export var mouse_sensitivity: float = 0.005
@export var pitch_min: float = deg_to_rad(-60.0)
@export var pitch_max: float = deg_to_rad(60.0)
@export var camera_follow_smoothing: float = 12.0
@export var camera_offset: Vector3 = Vector3(0.0, 1.6, 4.0)
@export var interpolation_delay_ms: int = 100
@export var max_snapshots: int = 32
@export var show_server_ghost: bool = true
@onready var camera: Camera3D = $Camera3D

var peer_id: int = 0
var server_position: Vector3 = Vector3.ZERO
var server_velocity: Vector3 = Vector3.ZERO
var server_yaw: float = 0.0
var has_server_position: bool = false
var ghost: MeshInstance3D = null
var snapshot_buffer: Array[Dictionary] = []
var pitch: float = 0.0

func _ready() -> void:
	_apply_authority()
	_setup_ghost()
	pitch = camera.rotation.x
	camera.position = camera_offset

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		return
	if _is_local_player():
		_apply_local_correction()
		_update_camera(delta)
		_update_ghost_from_buffer()
		return
	_interpolate_remote()

func _apply_local_correction() -> void:
	if not has_server_position:
		return
	var error: Vector3 = server_position - global_position
	var error_len: float = error.length()
	if error_len <= correction_deadzone:
		return
	if error_len >= snap_threshold:
		global_position = server_position
		velocity = server_velocity
		return
	velocity = velocity.lerp(server_velocity, velocity_correction)
	var target: Vector3 = global_position.lerp(server_position, local_correction)
	var step: Vector3 = target - global_position
	if step.length() > max_correction_per_tick:
		step = step.normalized() * max_correction_per_tick
	global_position += step

func _interpolate_remote() -> void:
	var interp_pos: Vector3 = _sample_snapshot_position()
	global_position = interp_pos
	_update_ghost_from_buffer()

func build_input() -> Vector2:
	if _is_console_open():
		return Vector2.ZERO
	var input_dir: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_S):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	return input_dir

func tick_move(input_dir: Vector2, delta: float) -> void:
	var forward: Vector3 = -global_transform.basis.z
	var right: Vector3 = global_transform.basis.x
	var dir: Vector3 = (right * input_dir.x + forward * input_dir.y)
	if dir.length() > 1.0:
		dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func simulate_input(input_dir: Vector2, yaw: float, delta: float) -> void:
	rotation.y = yaw
	tick_move(input_dir, delta)

func apply_snapshot(pos: Vector3, vel: Vector3, yaw: float) -> void:
	server_position = pos
	server_velocity = vel
	server_yaw = yaw
	has_server_position = true
	if not _is_local_player():
		rotation.y = server_yaw
	snapshot_buffer.append({"time_ms": Time.get_ticks_msec(), "pos": pos})
	if snapshot_buffer.size() > max_snapshots:
		snapshot_buffer.pop_front()
	if ghost:
		ghost.global_position = server_position

func reconcile_from_server(pos: Vector3, vel: Vector3, yaw: float, ack_tick: int, history: Array[Dictionary], delta: float, threshold: float) -> Array[Dictionary]:
	server_position = pos
	server_velocity = vel
	server_yaw = yaw
	has_server_position = true
	var error: Vector3 = pos - global_position
	if error.length() <= threshold:
		return _prune_history(history, ack_tick)
	global_position = pos
	velocity = vel
	rotation.y = yaw
	var remaining: Array[Dictionary] = []
	for entry in history:
		var tick: int = entry["tick"]
		if tick <= ack_tick:
			continue
		remaining.append(entry)
		var input_dir: Vector2 = entry["input"]
		var entry_yaw: float = entry["yaw"]
		simulate_input(input_dir, entry_yaw, delta)
	return remaining

func _prune_history(history: Array[Dictionary], ack_tick: int) -> Array[Dictionary]:
	var remaining: Array[Dictionary] = []
	for entry in history:
		var tick: int = entry["tick"]
		if tick > ack_tick:
			remaining.append(entry)
	return remaining

func _apply_authority() -> void:
	camera.current = _is_local_player()

func _is_local_player() -> bool:
	return multiplayer.get_unique_id() == peer_id

func _is_console_open() -> bool:
	var nodes: Array[Node] = get_tree().get_nodes_in_group("dev_console")
	if nodes.is_empty():
		return false
	var console: Node = nodes[0]
	if console.has_method("is_console_open"):
		return console.is_console_open()
	return false

func _setup_ghost() -> void:
	if multiplayer.is_server():
		return
	if not show_server_ghost:
		return
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = 0.5
	capsule.height = 1.0
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.9, 1.0, 0.35)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost = MeshInstance3D.new()
	ghost.mesh = capsule
	ghost.material_override = material
	ghost.visible = true
	get_tree().current_scene.add_child(ghost)

func _unhandled_input(event: InputEvent) -> void:
	if not _is_local_player():
		return
	if _is_console_open():
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		var motion: InputEventMouseMotion = event
		rotation.y -= motion.relative.x * mouse_sensitivity
		pitch = clampf(pitch - motion.relative.y * mouse_sensitivity, pitch_min, pitch_max)
		camera.rotation = Vector3(pitch, 0.0, 0.0)

func _update_camera(delta: float) -> void:
	var t: float = 1.0 - exp(-camera_follow_smoothing * delta)
	camera.position = camera.position.lerp(camera_offset, t)

func get_yaw() -> float:
	return rotation.y

func _sample_snapshot_position() -> Vector3:
	if snapshot_buffer.size() < 2:
		if has_server_position:
			return server_position
		return global_position
	var render_time: int = Time.get_ticks_msec() - interpolation_delay_ms
	while snapshot_buffer.size() >= 2 and snapshot_buffer[1]["time_ms"] <= render_time:
		snapshot_buffer.remove_at(0)
	if snapshot_buffer.size() == 1:
		var snap: Dictionary = snapshot_buffer[0]
		return snap["pos"]
	var s0: Dictionary = snapshot_buffer[0]
	var s1: Dictionary = snapshot_buffer[1]
	var t0: int = s0["time_ms"]
	var t1: int = s1["time_ms"]
	if t1 <= t0:
		return s1["pos"]
	var alpha: float = float(render_time - t0) / float(t1 - t0)
	alpha = clampf(alpha, 0.0, 1.0)
	return s0["pos"].lerp(s1["pos"], alpha)

func _update_ghost_from_buffer() -> void:
	if not ghost:
		return
	var interp_pos: Vector3 = _sample_snapshot_position()
	ghost.global_position = interp_pos
