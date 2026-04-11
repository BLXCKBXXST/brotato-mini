# Player.gd
extends CharacterBody2D

@onready var sprite: ColorRect = $Sprite
@onready var attack_timer: Timer = $AttackTimer
@onready var collision: CollisionShape2D = $Collision
@onready var range_indicator: Node2D = $RangeIndicator

const BULLET_SCENE := preload("res://scenes/Bullet.tscn")

var attack_cooldown: float = 0.0

func _ready() -> void:
	_sync_stats()

func _sync_stats() -> void:
	attack_cooldown = 1.0 / GameManager.player_stats["attack_speed"]

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_shooting(delta)

func _handle_movement(_delta: float) -> void:
	var dir: Vector2 = Vector2.ZERO
	dir.x = Input.get_axis("move_left", "move_right")
	dir.y = Input.get_axis("move_up", "move_down")
	if dir.length() > 0:
		dir = dir.normalized()
	velocity = dir * float(GameManager.player_stats["speed"])
	move_and_slide()

func _handle_shooting(delta: float) -> void:
	attack_cooldown -= delta
	if attack_cooldown <= 0.0:
		var target: Node2D = _find_nearest_enemy()
		if target != null:
			_shoot(target)
			attack_cooldown = 1.0 / float(GameManager.player_stats["attack_speed"])

func _find_nearest_enemy() -> Node2D:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var best: Node2D = null
	var best_dist: float = float(GameManager.player_stats["range"])
	for e in enemies:
		var node := e as Node2D
		if node == null:
			continue
		var d: float = global_position.distance_to(node.global_position)
		if d < best_dist:
			best_dist = d
			best = node
	return best

func _shoot(target: Node2D) -> void:
	var bullet := BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	var shoot_dir: Vector2 = target.global_position - global_position
	bullet.setup(
		shoot_dir,
		int(GameManager.player_stats["damage"]),
		int(GameManager.player_stats["pierce"])
	)

func take_damage(amount: float) -> void:
	GameManager.player_stats["hp"] -= amount
	if GameManager.player_stats["hp"] <= 0:
		GameManager.player_stats["hp"] = 0
		GameManager.player_died.emit()

func heal(amount: float) -> void:
	GameManager.player_stats["hp"] = minf(
		GameManager.player_stats["hp"] + amount,
		GameManager.player_stats["max_hp"]
	)
