# FloatText.gd — Floating damage/pickup numbers
extends Node2D

@onready var label: Label = $Label

var velocity: Vector2 = Vector2(0, -60)
var lifetime: float = 0.9

func setup(text: String, color: Color) -> void:
	label.text = text
	label.modulate = color

func _process(delta: float) -> void:
	global_position += velocity * delta
	lifetime -= delta
	modulate.a = lifetime / 0.9
	if lifetime <= 0:
		queue_free()
