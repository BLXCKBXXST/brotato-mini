# HitParticle.gd — короткоживущие частицы из ColorRect-узлов
extends Node2D

var lifetime: float = 0.4
var max_lifetime: float = 0.4
var velocities: Array[Vector2] = []

func _ready() -> void:
	velocities.clear()
	for child in get_children():
		var dir := Vector2(randf_range(-1, 1), randf_range(-1, 1))
		if dir.length() < 0.1:
			dir = Vector2.RIGHT
		velocities.append(dir.normalized() * randf_range(90.0, 200.0))

func set_color(c: Color) -> void:
	for child in get_children():
		var rect := child as ColorRect
		if rect:
			rect.color = c

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var alpha: float = clampf(lifetime / max_lifetime, 0.0, 1.0)
	for i in range(get_child_count()):
		if i >= velocities.size():
			break
		var c := get_child(i) as ColorRect
		if c == null:
			continue
		c.position += velocities[i] * delta
		var col := c.color
		col.a = alpha
		c.color = col
