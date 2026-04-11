# SpawnWarning.gd
# Мигающий круг на полу перед спавном моба
extends Node2D

const DURATION  := 0.85   # секунд до спавна
const RADIUS    := 22.0
const BLINK_HZ  := 7.0    # миганий в секунду

var _elapsed   := 0.0
var _color     := Color(1.0, 0.18, 0.18, 0.0)   # красный, alpha будем менять
var _done      := false

signal finished

func _draw() -> void:
	# заполненный полупрозрачный круг
	draw_circle(Vector2.ZERO, RADIUS, _color)
	# контур
	var outline := _color
	outline.a = minf(_color.a * 2.0 + 0.15, 1.0)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 32, outline, 2.0)

func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	var t := _elapsed / DURATION          # 0 → 1
	# альфа: вращаемся sinusoid + нарастаем к концу
	_color.a = abs(sin(_elapsed * BLINK_HZ * PI)) * lerpf(0.35, 0.85, t)
	queue_redraw()
	if _elapsed >= DURATION:
		_done = true
		queue_free()
		finished.emit()
