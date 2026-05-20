# Bullet.gd
# Area2D — мониторинг включён, collision layer/mask настроены в сцене.
# Дополнительно: overlap-проверка через расстояние как fallback.
extends Area2D

const HIT_PARTICLE_SCENE := preload("res://scenes/HitParticle.tscn")

const TEX_PISTOL  := preload("res://assets/sprites/bullet.png")
const TEX_SHOTGUN := preload("res://assets/sprites/bullet_shotgun.png")
const TEX_SNIPER  := preload("res://assets/sprites/bullet_sniper.png")
const TEX_SMG     := preload("res://assets/sprites/bullet_smg.png")

var bullet_velocity: Vector2 = Vector2.ZERO
var damage: float  = 10.0
var pierce: int    = 1
var hits: int      = 0
var speed: float   = 520.0
var lifetime: float = 1.8
var pattern: String = "single"
var hit_radius: float = 22.0
var hit_enemies: Array = []

func setup(direction: Vector2, p_damage: float, p_pierce: int) -> void:
	# Старый API — оставлен для совместимости
	setup_extended({"dir": direction, "damage": p_damage, "pierce": p_pierce})

func setup_extended(p: Dictionary) -> void:
	damage   = float(p.get("damage", 10.0))
	pierce   = max(1, int(p.get("pierce", 1)))
	speed    = float(p.get("speed", 520.0))
	lifetime = float(p.get("lifetime", 1.8))
	pattern  = String(p.get("pattern", "single"))
	var dir: Vector2 = p.get("dir", Vector2.RIGHT)
	bullet_velocity = dir.normalized() * speed
	var color: Color = p.get("color", Color(1.0, 0.9, 0.3))
	# Визуальная адаптация под паттерн
	var sprite := get_node_or_null("Sprite") as Sprite2D
	if sprite:
		match pattern:
			"sniper":
				sprite.texture = TEX_SNIPER
				sprite.scale = Vector2(1.0, 1.5)
				hit_radius = 28.0
			"shotgun":
				sprite.texture = TEX_SHOTGUN
				sprite.scale = Vector2(1.5, 1.5)
				hit_radius = 18.0
			"smg":
				sprite.texture = TEX_SMG
				sprite.scale = Vector2(1.1, 1.1)
				hit_radius = 16.0
			_:
				sprite.texture = TEX_PISTOL
				sprite.scale = Vector2(1.5, 1.5)
				hit_radius = 22.0
		sprite.modulate = color
		# Поворот спрайта в направлении движения для sniper
		if pattern == "sniper":
			rotation = bullet_velocity.angle() + PI / 2.0

func _physics_process(delta: float) -> void:
	global_position += bullet_velocity * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	# Распределённая fallback-проверка через расстояние
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		var node := e as Node2D
		if node == null or not is_instance_valid(node):
			continue
		if node in hit_enemies:
			continue
		if global_position.distance_to(node.global_position) < hit_radius:
			_hit(node)
			if hits >= pierce:
				queue_free()
				return

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
	if is_instance_valid(enemy) and enemy is Node2D:
		var particle := HIT_PARTICLE_SCENE.instantiate()
		get_tree().current_scene.get_node("GameObjects").add_child(particle)
		(particle as Node2D).global_position = (enemy as Node2D).global_position
	AudioBus.play("enemy_hit")
