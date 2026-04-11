# Player.gd
extends CharacterBody2D

@onready var sprite: ColorRect        = $Sprite
@onready var attack_timer: Timer      = $AttackTimer
@onready var collision: CollisionShape2D = $Collision
@onready var range_indicator: Node2D  = $RangeIndicator

const BULLET_SCENE := preload("res://scenes/Bullet.tscn")

var attack_cooldown: float = 0.0
var is_dead: bool = false

func _ready() -> void:
	print("[Player] _ready OK, pos=", global_position)
	_sync_stats()

func _sync_stats() -> void:
	is_dead = false
	attack_cooldown = 1.0 / float(GameManager.player_stats["attack_speed"])
	print("[Player] stats synced, attack_cooldown=", attack_cooldown)

func _physics_process(delta: float) -> void:
	if GameManager.game_state != "fight" or is_dead:
		velocity = Vector2.ZERO
		return
	_handle_movement(delta)
	_handle_shooting(delta)

func _handle_movement(_delta: float) -> void:
	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir.length() > 0:
		dir = dir.normalized()
	velocity = dir * float(GameManager.player_stats["speed"])
	move_and_slide()

func _handle_shooting(delta: float) -> void:
	attack_cooldown -= delta
	if attack_cooldown <= 0.0:
		var target := _find_nearest_enemy()
		if target != null:
			_shoot(target)
			attack_cooldown = 1.0 / float(GameManager.player_stats["attack_speed"])
		else:
			attack_cooldown = 0.1

func _find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var best: Node2D = null
	var best_dist: float = float(GameManager.player_stats["range"])
	for e in enemies:
		var node := e as Node2D
		if node == null or not is_instance_valid(node):
			continue
		var d := global_position.distance_to(node.global_position)
		if d < best_dist:
			best_dist = d
			best = node
	return best

func _shoot(target: Node2D) -> void:
	var bullet := BULLET_SCENE.instantiate()
	get_tree().current_scene.get_node("GameObjects").add_child(bullet)
	bullet.global_position = global_position
	var shoot_dir: Vector2 = target.global_position - global_position
	bullet.setup(shoot_dir, float(GameManager.player_stats["damage"]), int(GameManager.player_stats["pierce"]))

func take_damage(amount: float) -> void:
	if is_dead or GameManager.game_state != "fight":
		return
	GameManager.player_stats["hp"] = float(GameManager.player_stats["hp"]) - amount
	if float(GameManager.player_stats["hp"]) <= 0.0:
		GameManager.player_stats["hp"] = 0
		is_dead = true
		print("[Player] died!")
		GameManager.player_died.emit()

func heal(amount: float) -> void:
	GameManager.player_stats["hp"] = minf(
		float(GameManager.player_stats["hp"]) + amount,
		float(GameManager.player_stats["max_hp"])
	)
