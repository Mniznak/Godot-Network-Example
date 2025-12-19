extends CanvasLayer

@export var toggle_key: int = KEY_QUOTELEFT

@onready var panel: Panel = $Panel
@onready var log_output: RichTextLabel = $Panel/VBox/Log
@onready var input: LineEdit = $Panel/VBox/Input
@onready var latency_panel: Panel = $LatencyPanel
@onready var rtt_slider: HSlider = $LatencyPanel/LatencyVBox/RttRow/RttSlider
@onready var rtt_value: Label = $LatencyPanel/LatencyVBox/RttRow/RttValue
@onready var jitter_slider: HSlider = $LatencyPanel/LatencyVBox/JitterRow/JitterSlider
@onready var jitter_value: Label = $LatencyPanel/LatencyVBox/JitterRow/JitterValue
@onready var loss_slider: HSlider = $LatencyPanel/LatencyVBox/LossRow/LossSlider
@onready var loss_value: Label = $LatencyPanel/LatencyVBox/LossRow/LossValue
@onready var latency_toggle: Button = $LatencyPanel/LatencyVBox/LatencyToggle
@onready var correction_toggle: Button = $LatencyPanel/LatencyVBox/CorrectionToggle
@onready var camera_toggle: Button = $LatencyPanel/LatencyVBox/CameraToggle
@onready var movement_toggle: Button = $LatencyPanel/LatencyVBox/MovementToggle
@onready var max_correction_slider: HSlider = $LatencyPanel/LatencyVBox/MaxCorrectionRow/MaxCorrectionSlider
@onready var max_correction_value: Label = $LatencyPanel/LatencyVBox/MaxCorrectionRow/MaxCorrectionValue
@onready var snap_threshold_slider: HSlider = $LatencyPanel/LatencyVBox/SnapThresholdRow/SnapThresholdSlider
@onready var snap_threshold_value: Label = $LatencyPanel/LatencyVBox/SnapThresholdRow/SnapThresholdValue
@onready var reconcile_velocity_slider: HSlider = $LatencyPanel/LatencyVBox/ReconcileVelocityRow/ReconcileVelocitySlider
@onready var reconcile_velocity_value: Label = $LatencyPanel/LatencyVBox/ReconcileVelocityRow/ReconcileVelocityValue
@onready var camera_smooth_slider: HSlider = $LatencyPanel/LatencyVBox/CameraSmoothRow/CameraSmoothSlider
@onready var camera_smooth_value: Label = $LatencyPanel/LatencyVBox/CameraSmoothRow/CameraSmoothValue
@onready var accel_slider: HSlider = $LatencyPanel/LatencyVBox/AccelRow/AccelSlider
@onready var accel_value: Label = $LatencyPanel/LatencyVBox/AccelRow/AccelValue
@onready var decel_slider: HSlider = $LatencyPanel/LatencyVBox/DecelRow/DecelSlider
@onready var decel_value: Label = $LatencyPanel/LatencyVBox/DecelRow/DecelValue
@onready var input_delay_slider: HSlider = $LatencyPanel/LatencyVBox/InputDelayRow/InputDelaySlider
@onready var input_delay_value: Label = $LatencyPanel/LatencyVBox/InputDelayRow/InputDelayValue
@onready var tick_rate_slider: HSlider = $LatencyPanel/LatencyVBox/TickRateRow/TickRateSlider
@onready var tick_rate_value: Label = $LatencyPanel/LatencyVBox/TickRateRow/TickRateValue
@onready var vel_deadzone_slider: HSlider = $LatencyPanel/LatencyVBox/VelDeadzoneRow/VelDeadzoneSlider
@onready var vel_deadzone_value: Label = $LatencyPanel/LatencyVBox/VelDeadzoneRow/VelDeadzoneValue
@onready var pos_deadzone_slider: HSlider = $LatencyPanel/LatencyVBox/PosDeadzoneRow/PosDeadzoneSlider
@onready var pos_deadzone_value: Label = $LatencyPanel/LatencyVBox/PosDeadzoneRow/PosDeadzoneValue
@onready var local_interp_slider: HSlider = $LatencyPanel/LatencyVBox/LocalInterpRow/LocalInterpSlider
@onready var local_interp_value: Label = $LatencyPanel/LatencyVBox/LocalInterpRow/LocalInterpValue
@onready var remote_interp_slider: HSlider = $LatencyPanel/LatencyVBox/RemoteInterpRow/RemoteInterpSlider
@onready var remote_interp_value: Label = $LatencyPanel/LatencyVBox/RemoteInterpRow/RemoteInterpValue
@onready var net_stats: Label = $NetStats

func _ready() -> void:
	add_to_group("dev_console")
	panel.visible = false
	latency_panel.visible = true
	input.text_submitted.connect(_on_input_submitted)
	_wire_latency_controls()
	_sync_latency_from_net()
	_sync_correction_from_player()
	_sync_movement_from_player()
	_update_section_visibility()

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

func _process(_delta: float) -> void:
	_update_net_stats()

func _wire_latency_controls() -> void:
	rtt_slider.value_changed.connect(_on_settings_changed)
	jitter_slider.value_changed.connect(_on_settings_changed)
	loss_slider.value_changed.connect(_on_settings_changed)
	max_correction_slider.value_changed.connect(_on_settings_changed)
	snap_threshold_slider.value_changed.connect(_on_settings_changed)
	reconcile_velocity_slider.value_changed.connect(_on_settings_changed)
	camera_smooth_slider.value_changed.connect(_on_settings_changed)
	accel_slider.value_changed.connect(_on_settings_changed)
	decel_slider.value_changed.connect(_on_settings_changed)
	input_delay_slider.value_changed.connect(_on_settings_changed)
	tick_rate_slider.value_changed.connect(_on_settings_changed)
	vel_deadzone_slider.value_changed.connect(_on_settings_changed)
	pos_deadzone_slider.value_changed.connect(_on_settings_changed)
	local_interp_slider.value_changed.connect(_on_settings_changed)
	remote_interp_slider.value_changed.connect(_on_settings_changed)
	latency_toggle.pressed.connect(_on_latency_toggle)
	correction_toggle.pressed.connect(_on_correction_toggle)
	camera_toggle.pressed.connect(_on_camera_toggle)
	movement_toggle.pressed.connect(_on_movement_toggle)

func _on_settings_changed(_value: float) -> void:
	_update_latency_labels()
	_update_correction_labels()
	_update_camera_labels()
	_update_movement_labels()
	_update_input_delay_labels()
	_update_tick_rate_labels()
	_update_deadzone_labels()
	_update_interp_labels()
	_apply_latency_settings()
	_apply_correction_settings()
	_apply_camera_settings()
	_apply_movement_settings()
	_apply_input_delay_settings()
	_apply_tick_rate_settings()
	_apply_deadzone_settings()
	_apply_interp_settings()

func _update_latency_labels() -> void:
	rtt_value.text = str(int(rtt_slider.value))
	jitter_value.text = str(int(jitter_slider.value))
	loss_value.text = str(snappedf(loss_slider.value, 0.5))

func _update_correction_labels() -> void:
	max_correction_value.text = str(snappedf(max_correction_slider.value, 0.05))
	snap_threshold_value.text = str(snappedf(snap_threshold_slider.value, 0.1))
	reconcile_velocity_value.text = str(snappedf(reconcile_velocity_slider.value, 0.05))

func _update_camera_labels() -> void:
	camera_smooth_value.text = str(snappedf(camera_smooth_slider.value, 0.5))

func _update_movement_labels() -> void:
	accel_value.text = str(snappedf(accel_slider.value, 0.5))
	decel_value.text = str(snappedf(decel_slider.value, 0.5))

func _update_input_delay_labels() -> void:
	input_delay_value.text = str(int(input_delay_slider.value))

func _update_tick_rate_labels() -> void:
	tick_rate_value.text = str(int(tick_rate_slider.value))

func _update_deadzone_labels() -> void:
	vel_deadzone_value.text = str(snappedf(vel_deadzone_slider.value, 0.01))
	pos_deadzone_value.text = str(snappedf(pos_deadzone_slider.value, 0.01))

func _update_interp_labels() -> void:
	local_interp_value.text = str(int(local_interp_slider.value))
	remote_interp_value.text = str(int(remote_interp_slider.value))

func _apply_latency_settings() -> void:
	var bootstrap: NetworkBootstrap = _get_bootstrap()
	if not bootstrap:
		return
	var rtt_ms := int(rtt_slider.value)
	var jitter := int(jitter_slider.value)
	var loss := float(loss_slider.value)
	if bootstrap.multiplayer.is_server():
		bootstrap.set_latency_settings(rtt_ms, jitter, loss)
	else:
		bootstrap.set_latency_rpc.rpc_id(1, rtt_ms, jitter, loss)

func _apply_correction_settings() -> void:
	var max_step: float = float(max_correction_slider.value)
	var snap_dist: float = float(snap_threshold_slider.value)
	var vel_blend: float = float(reconcile_velocity_slider.value)
	for player in _get_players():
		player.max_correction_per_tick = max_step
		player.snap_threshold = snap_dist
		player.reconcile_velocity_blend = vel_blend

func _apply_camera_settings() -> void:
	var smooth: float = float(camera_smooth_slider.value)
	for player in _get_players():
		player.camera_follow_smoothing = smooth

func _apply_movement_settings() -> void:
	var accel: float = float(accel_slider.value)
	var decel: float = float(decel_slider.value)
	for player in _get_players():
		player.acceleration = accel
		player.deceleration = decel

func _apply_input_delay_settings() -> void:
	var bootstrap: NetworkBootstrap = _get_bootstrap()
	if not bootstrap:
		return
	bootstrap.input_delay_ticks = int(input_delay_slider.value)

func _apply_tick_rate_settings() -> void:
	var bootstrap: NetworkBootstrap = _get_bootstrap()
	if not bootstrap:
		return
	var rate: float = float(tick_rate_slider.value)
	if bootstrap.multiplayer.is_server():
		bootstrap.call("_set_tick_rate", rate)
	else:
		bootstrap.set_tick_rate_rpc.rpc_id(1, rate)

func _apply_deadzone_settings() -> void:
	var vel_deadzone: float = float(vel_deadzone_slider.value)
	var pos_deadzone: float = float(pos_deadzone_slider.value)
	for player in _get_players():
		player.velocity_deadzone = vel_deadzone
		player.position_deadzone = pos_deadzone

func _apply_interp_settings() -> void:
	var local_delay: int = int(local_interp_slider.value)
	var remote_delay: int = int(remote_interp_slider.value)
	for player in _get_players():
		player.local_interpolation_delay_ms = local_delay
		player.remote_interpolation_delay_ms = remote_delay

func _sync_latency_from_net() -> void:
	var bootstrap: NetworkBootstrap = _get_bootstrap()
	if not bootstrap:
		return
	rtt_slider.value = bootstrap.rtt_ms_setting
	jitter_slider.value = bootstrap.jitter_ms
	loss_slider.value = bootstrap.loss_percent
	_update_latency_labels()
	tick_rate_slider.value = bootstrap.tick_rate
	_update_tick_rate_labels()

func _sync_correction_from_player() -> void:
	var players := _get_players()
	if players.is_empty():
		return
	var player: PlayerController = players[0]
	max_correction_slider.value = player.max_correction_per_tick
	snap_threshold_slider.value = player.snap_threshold
	reconcile_velocity_slider.value = player.reconcile_velocity_blend
	_update_correction_labels()
	vel_deadzone_slider.value = player.velocity_deadzone
	pos_deadzone_slider.value = player.position_deadzone
	_update_deadzone_labels()
	camera_smooth_slider.value = player.camera_follow_smoothing
	_update_camera_labels()

func _sync_movement_from_player() -> void:
	var players := _get_players()
	if players.is_empty():
		return
	var player: PlayerController = players[0]
	accel_slider.value = player.acceleration
	decel_slider.value = player.deceleration
	_update_movement_labels()
	_sync_input_delay_from_net()
	_sync_interp_from_player()

func _sync_input_delay_from_net() -> void:
	var bootstrap: NetworkBootstrap = _get_bootstrap()
	if not bootstrap:
		return
	input_delay_slider.value = bootstrap.input_delay_ticks
	_update_input_delay_labels()


func _sync_interp_from_player() -> void:
	var players := _get_players()
	if players.is_empty():
		return
	var player: PlayerController = players[0]
	local_interp_slider.value = player.local_interpolation_delay_ms
	remote_interp_slider.value = player.remote_interpolation_delay_ms
	_update_interp_labels()

func _on_correction_toggle() -> void:
	_toggle_section([
		$LatencyPanel/LatencyVBox/MaxCorrectionRow,
		$LatencyPanel/LatencyVBox/ReconcileVelocityRow,
		$LatencyPanel/LatencyVBox/VelDeadzoneRow,
		$LatencyPanel/LatencyVBox/PosDeadzoneRow,
		$LatencyPanel/LatencyVBox/SnapThresholdRow
	])

func _on_camera_toggle() -> void:
	_toggle_section([
		$LatencyPanel/LatencyVBox/CameraSmoothRow
	])

func _on_movement_toggle() -> void:
	_toggle_section([
		$LatencyPanel/LatencyVBox/AccelRow,
		$LatencyPanel/LatencyVBox/DecelRow
	])

func _on_latency_toggle() -> void:
	_toggle_section([
		$LatencyPanel/LatencyVBox/RttRow,
		$LatencyPanel/LatencyVBox/JitterRow,
		$LatencyPanel/LatencyVBox/LossRow,
		$LatencyPanel/LatencyVBox/InputDelayRow,
		$LatencyPanel/LatencyVBox/TickRateRow,
		$LatencyPanel/LatencyVBox/LocalInterpRow,
		$LatencyPanel/LatencyVBox/RemoteInterpRow
	])

func _toggle_section(nodes: Array[Node], force_visible: bool = false, use_force: bool = false) -> void:
	if nodes.is_empty():
		return
	var visible: bool = not nodes[0].visible
	if use_force:
		visible = force_visible
	for node in nodes:
		node.visible = visible

func _update_section_visibility() -> void:
	_toggle_section([
		$LatencyPanel/LatencyVBox/RttRow,
		$LatencyPanel/LatencyVBox/JitterRow,
		$LatencyPanel/LatencyVBox/LossRow,
		$LatencyPanel/LatencyVBox/InputDelayRow,
		$LatencyPanel/LatencyVBox/TickRateRow,
		$LatencyPanel/LatencyVBox/LocalInterpRow,
		$LatencyPanel/LatencyVBox/RemoteInterpRow
	], true, true)
	_toggle_section([
		$LatencyPanel/LatencyVBox/MaxCorrectionRow,
		$LatencyPanel/LatencyVBox/ReconcileVelocityRow,
		$LatencyPanel/LatencyVBox/VelDeadzoneRow,
		$LatencyPanel/LatencyVBox/PosDeadzoneRow,
		$LatencyPanel/LatencyVBox/SnapThresholdRow
	], false, true)
	_toggle_section([
		$LatencyPanel/LatencyVBox/CameraSmoothRow
	], false, true)
	_toggle_section([
		$LatencyPanel/LatencyVBox/AccelRow,
		$LatencyPanel/LatencyVBox/DecelRow
	], false, true)

func _update_net_stats() -> void:
	var bootstrap: NetworkBootstrap = _get_bootstrap()
	if not bootstrap:
		net_stats.text = "Net: n/a"
		return
	var stats: Dictionary = bootstrap.get_net_stats()
	net_stats.text = (
		"Ping: %sms (sim %sms)\n" % [str(int(stats["rtt_ms"])), str(int(stats["rtt_setting_ms"]))] +
		"Tick: %s (%s)\n" % [str(int(stats["tick_rate"])), str(int(stats["tick_id"]))] +
		"Input delay: %s ticks\n" % str(int(stats["input_delay_ticks"])) +
		"One-way: %sms  Jitter: %sms\n" % [str(int(stats["input_latency_ms"])), str(int(stats["jitter_ms"]))] +
		"Loss: %s%%" % str(snappedf(float(stats["loss_percent"]), 0.5))
	)

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
