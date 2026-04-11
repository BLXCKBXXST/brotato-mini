# Bullet.gd
extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var pierce: int = 1
var hits: int = 0
var speed: float = 500.0
var lifetime: float = 1.6

func setup(direction: Vector2, p_damage: float, p_pierce: int) -> void:
	damage = p_damage
	pierce = p_pierce
	velocity = direction.normalized() * speed

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_hit(damage)
		GameManager.player_stats["total_damage"] += damage
		hits += 1
		if hits >= pierce:
			queue_free()
