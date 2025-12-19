extends Control

@export var max_samples: int = 120
@export var vel_color: Color = Color(0.2, 0.9, 1.0)
@export var pos_color: Color = Color(1.0, 0.5, 0.1)
@export var background_color: Color = Color(0.05, 0.05, 0.05, 0.6)

var vel_samples: Array[float] = []
var pos_samples: Array[float] = []

func push_sample(vel_value: float, pos_value: float) -> void:
	vel_samples.append(clampf(vel_value, 0.0, 1.0))
	pos_samples.append(clampf(pos_value, 0.0, 1.0))
	if vel_samples.size() > max_samples:
		vel_samples.pop_front()
	if pos_samples.size() > max_samples:
		pos_samples.pop_front()
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, background_color, true)
	_draw_line_series(vel_samples, vel_color)
	_draw_line_series(pos_samples, pos_color)

func _draw_line_series(series: Array[float], color: Color) -> void:
	if series.size() < 2:
		return
	var width: float = size.x
	var height: float = size.y
	var step: float = 0.0
	if series.size() > 1:
		step = width / float(series.size() - 1)
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(series.size()):
		var x: float = float(i) * step
		var y: float = height - (series[i] * height)
		points.append(Vector2(x, y))
	draw_polyline(points, color, 2.0, true)
