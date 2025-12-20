extends CanvasLayer

@export var toggle_key: int = KEY_QUOTELEFT

@onready var panel: Panel = $Panel
@onready var log_output: RichTextLabel = $Panel/VBox/Log
@onready var input: LineEdit = $Panel/VBox/Input
@onready var latency_panel: Panel = $LatencyPanel
@onready var latency_body: VBoxContainer = $LatencyPanel/Scroll/LatencyVBox/LatencySection/LatencyBody
@onready var reconcile_body: VBoxContainer = $LatencyPanel/Scroll/LatencyVBox/ReconcileSection/ReconcileBody
@onready var interpolation_body: VBoxContainer = $LatencyPanel/Scroll/LatencyVBox/InterpolationSection/InterpolationBody
@onready var movement_body: VBoxContainer = $LatencyPanel/Scroll/LatencyVBox/MovementSection/MovementBody
@onready var other_body: VBoxContainer = $LatencyPanel/Scroll/LatencyVBox/OtherSection/OtherBody
@onready var rtt_slider: HSlider = $LatencyPanel/Scroll/LatencyVBox/LatencySection/LatencyBody/RttRow/RttSlider
@onready var rtt_value: Label = $LatencyPanel/Scroll/LatencyVBox/LatencySection/LatencyBody/RttRow/RttValue
@onready var jitter_slider: HSlider = $LatencyPanel/Scroll/LatencyVBox/LatencySection/LatencyBody/JitterRow/JitterSlider
@onready var jitter_value: Label = $LatencyPanel/Scroll/LatencyVBox/LatencySection/LatencyBody/JitterRow/JitterValue
@onready var loss_slider: HSlider = $LatencyPanel/Scroll/LatencyVBox/LatencySection/LatencyBody/LossRow/LossSlider
@onready var loss_value: Label = $LatencyPanel/Scroll/LatencyVBox/LatencySection/LatencyBody/LossRow/LossValue
@onready var input_delay_slider: HSlider = $LatencyPanel/Scroll/LatencyVBox/OtherSection/OtherBody/InputDelayRow/InputDelaySlider
@onready var input_delay_value: Label = $LatencyPanel/Scroll/LatencyVBox/OtherSection/OtherBody/InputDelayRow/InputDelayValue
@onready var tick_rate_slider: HSlider = $LatencyPanel/Scroll/LatencyVBox/LatencySection/LatencyBody/TickRateRow/TickRateSlider
@onready var tick_rate_value: Label = $LatencyPanel/Scroll/LatencyVBox/LatencySection/LatencyBody/TickRateRow/TickRateValue
@onready var latency_toggle: Button = $LatencyPanel/Scroll/LatencyVBox/LatencySection/LatencyToggle
@onready var correction_toggle: Button = $LatencyPanel/Scroll/LatencyVBox/ReconcileSection/CorrectionToggle
@onready var interpolation_toggle: Button = $LatencyPanel/Scroll/LatencyVBox/InterpolationSection/InterpolationToggle
@onready var movement_toggle: Button = $LatencyPanel/Scroll/LatencyVBox/MovementSection/MovementToggle
@onready var other_toggle: Button = $LatencyPanel/Scroll/LatencyVBox/OtherSection/OtherToggle
@onready var max_correction_slider: HSlider = $LatencyPanel/Scroll/LatencyVBox/ReconcileSection/ReconcileBody/MaxCorrectionRow/MaxCorrectionSlider
@onready var max_correction_value: Label = $LatencyPanel/Scroll/LatencyVBox/ReconcileSection/ReconcileBody/MaxCorrectionRow/MaxCorrectionValue
@onready var spring_freq_slider: HSlider = $LatencyPanel/Scroll/LatencyVBox/ReconcileSection/ReconcileBody/SpringRow/SpringSlider
@onready var spring_freq_value: Label = $LatencyPanel/Scroll/LatencyVBox/ReconcileSection/ReconcileBody/SpringRow/SpringValue
@onready var snap_threshold_slider: HSlider = $LatencyPanel/Scroll/LatencyVBox/ReconcileSection/ReconcileBody/SnapThresholdRow/SnapThresholdSlider
@onready var snap_threshold_value: Label = $LatencyPanel/Scroll/LatencyVBox/ReconcileSection/ReconcileBody/SnapThresholdRow/SnapThresholdValue
@onready var reconcile_velocity_slider: HSlider = $LatencyPanel/Scroll/LatencyVBox/ReconcileSection/ReconcileBody/ReconcileVelocityRow/ReconcileVelocitySlider
@onready var reconcile_velocity_value: Label = $LatencyPanel/Scroll/LatencyVBox/ReconcileSection/ReconcileBody/ReconcileVelocityRow/ReconcileVelocityValue
@onready var vel_deadzone_slider: HSlider = $LatencyPanel/Scroll/LatencyVBox/ReconcileSection/ReconcileBody/VelDeadzoneRow/VelDeadzoneSlider
@onready var vel_deadzone_value: Label = $LatencyPanel/Scroll/LatencyVBox/ReconcileSection/ReconcileBody/VelDeadzoneRow/VelDeadzoneValue
@onready var pos_deadzone_slider: HSlider = $LatencyPanel/Scroll/LatencyVBox/ReconcileSection/ReconcileBody/PosDeadzoneRow/PosDeadzoneSlider
@onready var pos_deadzone_value: Label = $LatencyPanel/Scroll/LatencyVBox/ReconcileSection/ReconcileBody/PosDeadzoneRow/PosDeadzoneValue
@onready var local_interp_slider: HSlider = $LatencyPanel/Scroll/LatencyVBox/InterpolationSection/InterpolationBody/LocalInterpRow/LocalInterpSlider
@onready var local_interp_value: Label = $LatencyPanel/Scroll/LatencyVBox/InterpolationSection/InterpolationBody/LocalInterpRow/LocalInterpValue
@onready var remote_interp_slider: HSlider = $LatencyPanel/Scroll/LatencyVBox/InterpolationSection/InterpolationBody/RemoteInterpRow/RemoteInterpSlider
@onready var remote_interp_value: Label = $LatencyPanel/Scroll/LatencyVBox/InterpolationSection/InterpolationBody/RemoteInterpRow/RemoteInterpValue
@onready var camera_smooth_slider: HSlider = $LatencyPanel/Scroll/LatencyVBox/InterpolationSection/InterpolationBody/CameraSmoothRow/CameraSmoothSlider
@onready var camera_smooth_value: Label = $LatencyPanel/Scroll/LatencyVBox/InterpolationSection/InterpolationBody/CameraSmoothRow/CameraSmoothValue
@onready var accel_slider: HSlider = $LatencyPanel/Scroll/LatencyVBox/MovementSection/MovementBody/AccelRow/AccelSlider
@onready var accel_value: Label = $LatencyPanel/Scroll/LatencyVBox/MovementSection/MovementBody/AccelRow/AccelValue
@onready var decel_slider: HSlider = $LatencyPanel/Scroll/LatencyVBox/MovementSection/MovementBody/DecelRow/DecelSlider
@onready var decel_value: Label = $LatencyPanel/Scroll/LatencyVBox/MovementSection/MovementBody/DecelRow/DecelValue
@onready var net_stats: Label = $NetStats
@onready var net_graph: Control = $NetGraph

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
	_tighten_layout()
	_apply_tooltips()

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
	_update_net_graph()

func _wire_latency_controls() -> void:
	rtt_slider.value_changed.connect(_on_settings_changed)
	jitter_slider.value_changed.connect(_on_settings_changed)
	loss_slider.value_changed.connect(_on_settings_changed)
	max_correction_slider.value_changed.connect(_on_settings_changed)
	spring_freq_slider.value_changed.connect(_on_settings_changed)
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
	interpolation_toggle.pressed.connect(_on_interpolation_toggle)
	movement_toggle.pressed.connect(_on_movement_toggle)
	other_toggle.pressed.connect(_on_other_toggle)

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
	spring_freq_value.text = str(snappedf(spring_freq_slider.value, 0.5))
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
	bootstrap.set_latency_settings(rtt_ms, jitter, loss)
	if not bootstrap.multiplayer.is_server():
		bootstrap.set_latency_rpc.rpc_id(1, rtt_ms, jitter, loss)

func _apply_correction_settings() -> void:
	var max_step: float = float(max_correction_slider.value)
	var spring_hz: float = float(spring_freq_slider.value)
	var snap_dist: float = float(snap_threshold_slider.value)
	var vel_blend: float = float(reconcile_velocity_slider.value)
	for player in _get_players():
		player.max_correction_per_tick = max_step
		player.spring_frequency = spring_hz
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
	spring_freq_slider.value = player.spring_frequency
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
	_toggle_container(reconcile_body)

func _on_interpolation_toggle() -> void:
	_toggle_container(interpolation_body)

func _on_movement_toggle() -> void:
	_toggle_container(movement_body)

func _on_other_toggle() -> void:
	_toggle_container(other_body)

func _on_latency_toggle() -> void:
	_toggle_container(latency_body)

func _toggle_container(container: Control, force_visible: bool = false, use_force: bool = false) -> void:
	if use_force:
		container.visible = force_visible
		return
	container.visible = not container.visible

func _update_section_visibility() -> void:
	_toggle_container(latency_body, true, true)
	_toggle_container(reconcile_body, false, true)
	_toggle_container(interpolation_body, false, true)
	_toggle_container(movement_body, false, true)
	_toggle_container(other_body, false, true)

func _update_net_stats() -> void:
	var bootstrap: NetworkBootstrap = _get_bootstrap()
	if not bootstrap:
		net_stats.text = "Net: n/a"
		return
	var stats: Dictionary = bootstrap.get_net_stats()
	net_stats.text = (
		"Ping: %sms (sim %sms)\n" % [str(int(stats["rtt_ms"])), str(int(stats["rtt_setting_ms"]))] +
		"Tick: %s (%s)\n" % [str(int(stats["tick_rate"])), str(int(stats["tick_id"]))]
	)

func _apply_tooltips() -> void:
	latency_toggle.tooltip_text = "Latency models real network delay. Use it to see how RTT, jitter, and loss affect prediction and correction."
	correction_toggle.tooltip_text = "Reconciliation keeps the client honest. These controls decide when and how strongly we correct drift."
	interpolation_toggle.tooltip_text = "Interpolation smooths remote motion by rendering slightly in the past to hide jitter."
	movement_toggle.tooltip_text = "Movement tuning affects how input turns into velocity, which changes how prediction feels."
	_set_row_tooltip("LatencySection/LatencyBody/RttRow", "Round-trip time (RTT). Higher RTT means inputs and snapshots arrive later. One-way delay is RTT/2.")
	_set_row_tooltip("LatencySection/LatencyBody/JitterRow", "Random variation in delay. Jitter makes timing inconsistent and is a common source of rubber-banding.")
	_set_row_tooltip("LatencySection/LatencyBody/LossRow", "Packet loss rate. Lost inputs/snapshots force prediction to run longer and can increase correction events.")
	_set_row_tooltip("OtherSection/OtherBody/InputDelayRow", "Client send delay in ticks. Adds buffering to smooth jitter but reduces responsiveness.")
	_set_row_tooltip("LatencySection/LatencyBody/TickRateRow", "Simulation tick rate. Higher tick rate reduces per-tick error but increases bandwidth and CPU load.")
	_set_row_tooltip("ReconcileSection/ReconcileBody/ReconcileVelocityRow", "How much we blend toward server velocity when we reconcile. Higher values correct speed quickly but can feel snappy.")
	_set_row_tooltip("ReconcileSection/ReconcileBody/VelDeadzoneRow", "Position error threshold for velocity-only correction. If position drift exceeds this (but is below Pos deadzone), we adjust velocity without snapping position.")
	_set_row_tooltip("ReconcileSection/ReconcileBody/MaxCorrectionRow", "Caps correction distance per tick. Prevents large visible jumps by spreading correction over time.")
	_set_row_tooltip("ReconcileSection/ReconcileBody/SpringRow", "Spring frequency for smoothing corrections. Higher values pull you toward the server faster but can overshoot without damping.")
	_set_row_tooltip("ReconcileSection/ReconcileBody/PosDeadzoneRow", "Position error threshold for full reconciliation. Above this, we correct position (rewind/replay) instead of just blending velocity.")
	_set_row_tooltip("ReconcileSection/ReconcileBody/SnapThresholdRow", "Maximum tolerated error. Beyond this, we snap to the server to avoid runaway divergence.")
	_set_row_tooltip("InterpolationSection/InterpolationBody/LocalInterpRow", "Local interpolation delay. Smaller values feel more responsive but can expose jitter.")
	_set_row_tooltip("InterpolationSection/InterpolationBody/RemoteInterpRow", "Remote interpolation delay. Larger values hide jitter but add visual lag to other players.")
	_set_row_tooltip("InterpolationSection/InterpolationBody/CameraSmoothRow", "Camera smoothing to reduce perceived jerk from small corrections.")
	_set_row_tooltip("MovementSection/MovementBody/AccelRow", "How quickly velocity ramps up. Higher accel feels snappier but less smooth under lag.")
	_set_row_tooltip("MovementSection/MovementBody/DecelRow", "How quickly velocity slows down. Higher decel reduces drift but can feel abrupt.")
	_set_header_tooltip("ReconcileSection/ReconcileBody/VelocityHeader", "Velocity reconciliation corrects speed/direction without hard position snaps.")
	_set_header_tooltip("ReconcileSection/ReconcileBody/PositionHeader", "Position reconciliation corrects accumulated error by snapping or replaying inputs.")
	_set_header_tooltip("ReconcileSection/ReconcileBody/SpringHeader", "Spring smoothing pulls the client toward the server between snapshots.")
	_set_header_tooltip("InterpolationSection/InterpolationBody/LocalHeader", "Local interpolation can trade responsiveness for stability during corrections.")
	_set_header_tooltip("InterpolationSection/InterpolationBody/RemoteHeader", "Remote interpolation smooths other players by rendering slightly in the past.")
	_set_header_tooltip("InterpolationSection/InterpolationBody/CameraHeader", "Camera smoothing hides small correction bumps in view motion.")
	net_graph.tooltip_text = "Blue = velocity reconcile usage, Orange = position reconcile usage. Higher values mean more correction activity."

func _set_row_tooltip(path: String, text: String) -> void:
	var node := _get_latency_node(path)
	if not node:
		return
	var row: HBoxContainer = node as HBoxContainer
	if not row:
		return
	row.tooltip_text = text
	for child in row.get_children():
		if child is Control:
			var control: Control = child
			control.tooltip_text = text

func _set_header_tooltip(path: String, text: String) -> void:
	var node := _get_latency_node(path)
	if not node:
		return
	var label: Label = node as Label
	if label:
		label.tooltip_text = text

func _get_latency_node(relative_path: String) -> Node:
	var full_path := "LatencyPanel/Scroll/LatencyVBox/" + relative_path
	return get_node_or_null(full_path)

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

func _tighten_layout() -> void:
	var labels: Array[Node] = latency_panel.find_children("*", "Label", true, false)
	for node in labels:
		var label: Label = node as Label
		if not label:
			continue
		if label.name.ends_with("Value"):
			label.custom_minimum_size = Vector2(42.0, 0.0)
			label.size_flags_horizontal = Control.SIZE_SHRINK_END
		elif label.name.ends_with("Label"):
			label.custom_minimum_size = Vector2(90.0, 0.0)
			label.size_flags_horizontal = Control.SIZE_SHRINK_END
	var hboxes: Array[Node] = latency_panel.find_children("*", "HBoxContainer", true, false)
	for node in hboxes:
		var hbox: HBoxContainer = node as HBoxContainer
		if hbox:
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.size_flags_stretch_ratio = 1.0
	var sliders: Array[Node] = latency_panel.find_children("*", "HSlider", true, false)
	for node in sliders:
		var slider: HSlider = node as HSlider
		if slider:
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider.custom_minimum_size = Vector2(140.0, 0.0)
	var buttons: Array[Node] = latency_panel.find_children("*", "Button", true, false)
	for node in buttons:
		var button: Button = node as Button
		if button:
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _get_local_player() -> PlayerController:
	var local_id := multiplayer.get_unique_id()
	for player in _get_players():
		if player.peer_id == local_id:
			return player
	return null

func _update_net_graph() -> void:
	var player := _get_local_player()
	if not player:
		return
	var graph := net_graph
	if graph.has_method("push_sample"):
		graph.push_sample(player.vel_reconcile_ratio, player.pos_reconcile_ratio)
