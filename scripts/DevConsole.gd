extends CanvasLayer

@export var toggle_key: int = KEY_QUOTELEFT

@onready var panel: Panel = $Panel
@onready var log_output: RichTextLabel = $Panel/VBox/Log
@onready var input: LineEdit = $Panel/VBox/Input
@onready var latency_panel: Panel = $LatencyPanel
@onready var input_slider: HSlider = $LatencyPanel/LatencyVBox/InputRow/InputSlider
@onready var input_value: Label = $LatencyPanel/LatencyVBox/InputRow/InputValue
@onready var snapshot_slider: HSlider = $LatencyPanel/LatencyVBox/SnapshotRow/SnapshotSlider
@onready var snapshot_value: Label = $LatencyPanel/LatencyVBox/SnapshotRow/SnapshotValue
@onready var jitter_slider: HSlider = $LatencyPanel/LatencyVBox/JitterRow/JitterSlider
@onready var jitter_value: Label = $LatencyPanel/LatencyVBox/JitterRow/JitterValue
@onready var loss_slider: HSlider = $LatencyPanel/LatencyVBox/LossRow/LossSlider
@onready var loss_value: Label = $LatencyPanel/LatencyVBox/LossRow/LossValue
@onready var max_correction_slider: HSlider = $LatencyPanel/LatencyVBox/MaxCorrectionRow/MaxCorrectionSlider
@onready var max_correction_value: Label = $LatencyPanel/LatencyVBox/MaxCorrectionRow/MaxCorrectionValue
@onready var snap_threshold_slider: HSlider = $LatencyPanel/LatencyVBox/SnapThresholdRow/SnapThresholdSlider
@onready var snap_threshold_value: Label = $LatencyPanel/LatencyVBox/SnapThresholdRow/SnapThresholdValue
@onready var camera_smooth_slider: HSlider = $LatencyPanel/LatencyVBox/CameraSmoothRow/CameraSmoothSlider
@onready var camera_smooth_value: Label = $LatencyPanel/LatencyVBox/CameraSmoothRow/CameraSmoothValue

func _ready() -> void:
	add_to_group("dev_console")
	panel.visible = false
	latency_panel.visible = false
	input.text_submitted.connect(_on_input_submitted)
	_wire_latency_controls()
	_sync_latency_from_net()
	_sync_correction_from_player()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == toggle_key:
			_toggle_console()
			get_viewport().set_input_as_handled()

func _toggle_console() -> void:
	panel.visible = not panel.visible
	if panel.visible:
		input.grab_focus()
	else:
		input.release_focus()

func _on_input_submitted(text: String) -> void:
	var command: String = text.strip_edges()
	if command.is_empty():
		return
	log_output.append_text(command + "\n")
	input.clear()
	_execute_command(command)

func _execute_command(command: String) -> void:
	var parts: PackedStringArray = command.split(" ", false)
	if parts.size() >= 2 and parts[0] == "dev" and parts[1] == "lat":
		latency_panel.visible = not latency_panel.visible
		_sync_latency_from_net()
		return
	log_output.append_text("Unknown command\n")

func is_console_open() -> bool:
	return panel.visible

func _wire_latency_controls() -> void:
	input_slider.value_changed.connect(_on_settings_changed)
	snapshot_slider.value_changed.connect(_on_settings_changed)
	jitter_slider.value_changed.connect(_on_settings_changed)
	loss_slider.value_changed.connect(_on_settings_changed)
	max_correction_slider.value_changed.connect(_on_settings_changed)
	snap_threshold_slider.value_changed.connect(_on_settings_changed)
	camera_smooth_slider.value_changed.connect(_on_settings_changed)

func _on_settings_changed(_value: float) -> void:
	_update_latency_labels()
	_update_correction_labels()
	_update_camera_labels()
	_apply_latency_settings()
	_apply_correction_settings()
	_apply_camera_settings()

func _update_latency_labels() -> void:
	input_value.text = str(int(input_slider.value))
	snapshot_value.text = str(int(snapshot_slider.value))
	jitter_value.text = str(int(jitter_slider.value))
	loss_value.text = str(snappedf(loss_slider.value, 0.5))

func _update_correction_labels() -> void:
	max_correction_value.text = str(snappedf(max_correction_slider.value, 0.05))
	snap_threshold_value.text = str(snappedf(snap_threshold_slider.value, 0.1))

func _update_camera_labels() -> void:
	camera_smooth_value.text = str(snappedf(camera_smooth_slider.value, 0.5))

func _apply_latency_settings() -> void:
	var bootstrap: NetworkBootstrap = _get_bootstrap()
	if not bootstrap:
		return
	var input_ms := int(input_slider.value)
	var snapshot_ms := int(snapshot_slider.value)
	var jitter := int(jitter_slider.value)
	var loss := float(loss_slider.value)
	if bootstrap.multiplayer.is_server():
		bootstrap.set_latency_settings(input_ms, snapshot_ms, jitter, loss)
	else:
		bootstrap.set_latency_rpc.rpc_id(1, input_ms, snapshot_ms, jitter, loss)

func _apply_correction_settings() -> void:
	var max_step: float = float(max_correction_slider.value)
	var snap_dist: float = float(snap_threshold_slider.value)
	for player in _get_players():
		player.max_correction_per_tick = max_step
		player.snap_threshold = snap_dist

func _apply_camera_settings() -> void:
	var smooth: float = float(camera_smooth_slider.value)
	for player in _get_players():
		player.camera_follow_smoothing = smooth

func _sync_latency_from_net() -> void:
	var bootstrap: NetworkBootstrap = _get_bootstrap()
	if not bootstrap:
		return
	input_slider.value = bootstrap.input_latency_ms
	snapshot_slider.value = bootstrap.snapshot_latency_ms
	jitter_slider.value = bootstrap.jitter_ms
	loss_slider.value = bootstrap.loss_percent
	_update_latency_labels()

func _sync_correction_from_player() -> void:
	var players := _get_players()
	if players.is_empty():
		return
	var player: PlayerController = players[0]
	max_correction_slider.value = player.max_correction_per_tick
	snap_threshold_slider.value = player.snap_threshold
	_update_correction_labels()
	camera_smooth_slider.value = player.camera_follow_smoothing
	_update_camera_labels()

func _get_bootstrap() -> NetworkBootstrap:
	var nodes: Array[Node] = get_tree().get_nodes_in_group("network_bootstrap")
	if nodes.is_empty():
		return null
	return nodes[0] as NetworkBootstrap

func _get_players() -> Array[PlayerController]:
	var nodes: Array[Node] = get_tree().get_nodes_in_group("players")
	var players: Array[PlayerController] = []
	for node in nodes:
		if node is PlayerController:
			players.append(node)
	return players
