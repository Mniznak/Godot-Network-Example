class_name MovingCube
extends StaticBody3D

@export var move_range: float = 4.0
@export var speed: float = 1.0
@export var offset: float = 0.0
@export var interpolation_delay_ms: int = 100
@export var max_snapshots: int = 32
@export var show_server_ghost: bool = true

var base_position: Vector3 = Vector3.ZERO
var time_accum: float = 0.0
var server_position: Vector3 = Vector3.ZERO
var has_server_position: bool = false
var snapshot_buffer: Array[Dictionary] = []
var ghost: MeshInstance3D = null

func _ready() -> void:
	add_to_group("moving_cubes")
	base_position = global_position
	time_accum = offset
	if not multiplayer.is_server():
		_setup_ghost()

func _physics_process(delta: float) -> void:
	time_accum += delta * speed
	var x: float = sin(time_accum) * move_range
	if multiplayer.is_server():
		global_position = base_position + Vector3(x, 0.0, 0.0)
	else:
		_interpolate_remote()

func apply_snapshot(pos: Vector3) -> void:
	server_position = pos
	has_server_position = true
	snapshot_buffer.append({"time_ms": Time.get_ticks_msec(), "pos": pos})
	if snapshot_buffer.size() > max_snapshots:
		snapshot_buffer.pop_front()
	if ghost:
		ghost.global_position = server_position

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

func _interpolate_remote() -> void:
	var interp_pos: Vector3 = _sample_snapshot_position()
	global_position = interp_pos

func _setup_ghost() -> void:
	if not show_server_ghost:
		return
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(1.5, 1.5, 1.5)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.5, 0.1, 0.35)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost = MeshInstance3D.new()
	ghost.mesh = mesh
	ghost.material_override = material
	ghost.visible = true
	get_tree().current_scene.add_child(ghost)

func _update_ghost_from_buffer() -> void:
	if not ghost:
		return
	var interp_pos: Vector3 = _sample_snapshot_position()
	ghost.global_position = interp_pos
