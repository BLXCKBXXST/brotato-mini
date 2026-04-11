# Bullet.gd
# Area2D — мониторинг включён, collision layer/mask настроены в сцене.
# Дополнительно: overlap-проверка через расстояние как fallback.
extends Area2D

var bullet_velocity: Vector2 = Vector2.ZERO
var damage: float  = 10.0
var pierce: int    = 1
var hits: int      = 0
var speed: float   = 520.0
var lifetime: float = 1.8
var hit_enemies: Array = []

func setup(direction: Vector2, p_damage: float, p_pierce: int) -> void:
	damage  = p_damage
	pierce  = p_pierce
	bullet_velocity = direction.normalized() * speed

func _physics_process(delta: float) -> void:
	global_position += bullet_velocity * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	# fallback: дистанционный хит если Area2D не сработал
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		var node := e as Node2D
		if node == null or not is_instance_valid(node):
			continue
		if node in hit_enemies:
			continue
		if global_position.distance_to(node.global_position) < 22.0:
			_hit(node)
			if hits >= pierce:
				queue_free()
				return

# сигнал из Area2D
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body not in hit_enemies:
		_hit(body)
		if hits >= pierce:
			queue_free()

func _hit(enemy: Node) -> void:
	hit_enemies.append(enemy)
	enemy.call("take_hit", damage)
	GameManager.player_stats["total_damage"] += damage
	hits += 1
