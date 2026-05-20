# EnemyBullet.gd — снаряд босса-стрелка
extends Node2D

const ARENA_MIN := Vector2(-10, -260)
const ARENA_MAX := Vector2(1290, 1040)

var velocity_vec: Vector2 = Vector2.ZERO
var damage: float = 10.0
var lifetime: float = 3.0
var hit_radius: float = 24.0
var done: bool = false

func setup(dir: Vector2, speed: float, p_damage: float, color: Color = Color(1, 0.35, 0.35)) -> void:
	velocity_vec = dir.normalized() * speed
	damage = p_damage
	var sprite := get_node_or_null("Sprite") as Sprite2D
	if sprite:
		sprite.modulate = color
		sprite.scale = Vector2(1.6, 1.6)

func _process(delta: float) -> void:
	if done:
		return
	global_position += velocity_vec * delta
	lifetime -= delta
	if lifetime <= 0.0 \
			or global_position.x < ARENA_MIN.x - 50 or global_position.x > ARENA_MAX.x + 50 \
			or global_position.y < ARENA_MIN.y - 50 or global_position.y > ARENA_MAX.y + 50:
		queue_free()
		return
	# Урон по игроку при сближении
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p := players[0] as Node2D
		if p != null and is_instance_valid(p):
			if global_position.distance_to(p.global_position) < hit_radius:
				p.call("take_damage", damage)
				done = true
				queue_free()
