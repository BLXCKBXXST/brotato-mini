# Player.gd
extends CharacterBody2D

@onready var sprite: Sprite2D            = $Sprite
@onready var collision: CollisionShape2D = $Collision
@onready var range_indicator: Node2D     = $RangeIndicator
@onready var camera: Camera2D            = $Camera2D

const BULLET_SCENE := preload("res://scenes/Bullet.tscn")

const ARENA_MIN := Vector2(-10, -260)
const ARENA_MAX := Vector2(1290, 1040)
const HALF := Vector2(18, 18)

var weapon_cooldowns: Array[float] = []
var is_dead: bool = false

func _ready() -> void:
	_sync_stats()
	if camera:
		camera.enabled = true
		camera.make_current()

func _sync_stats() -> void:
	is_dead = false
	weapon_cooldowns.clear()
	for _w in GameManager.player_weapons:
		weapon_cooldowns.append(0.0)

func _physics_process(delta: float) -> void:
	if GameManager.game_state != "fight" or is_dead:
		velocity = Vector2.ZERO
		return
	# Защита: если количество слотов изменилось вне _sync_stats (например, продажа в магазине → возврат в бой)
	if weapon_cooldowns.size() != GameManager.player_weapons.size():
		_sync_stats()
	_handle_movement(delta)
	_handle_shooting(delta)
	_clamp_to_arena()

func _handle_movement(_delta: float) -> void:
	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir.length() > 0: dir = dir.normalized()
	velocity = dir * float(GameManager.player_stats["speed"])
	move_and_slide()

func _clamp_to_arena() -> void:
	global_position.x = clampf(global_position.x, ARENA_MIN.x + HALF.x, ARENA_MAX.x - HALF.x)
	global_position.y = clampf(global_position.y, ARENA_MIN.y + HALF.y, ARENA_MAX.y - HALF.y)

func _handle_shooting(delta: float) -> void:
	for i in range(GameManager.player_weapons.size()):
		weapon_cooldowns[i] -= delta
		if weapon_cooldowns[i] > 0.0:
			continue
		var weapon: Dictionary = GameManager.player_weapons[i]
		var eff: Dictionary = GameManager.get_weapon_effective_stats(weapon)
		if eff.is_empty():
			weapon_cooldowns[i] = 0.5
			continue
		var target := _find_nearest_enemy_within(float(eff["range"]))
		if target == null:
			weapon_cooldowns[i] = 0.1
			continue
		_fire_weapon(weapon, eff, target)
		weapon_cooldowns[i] = float(eff["cooldown"])

func _find_nearest_enemy_within(r: float) -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var best: Node2D = null
	var best_dist: float = r
	for e in enemies:
		var node := e as Node2D
		if node == null or not is_instance_valid(node):
			continue
		var d := global_position.distance_to(node.global_position)
		if d < best_dist:
			best_dist = d
			best = node
	return best

func _fire_weapon(_weapon: Dictionary, eff: Dictionary, target: Node2D) -> void:
	var base_dir := (target.global_position - global_position).normalized()
	var count := int(eff["bullet_count"])
	var spread := deg_to_rad(float(eff["spread_deg"]))
	if count <= 1:
		var jitter := randf_range(-0.5, 0.5) * spread
		_spawn_bullet(base_dir.rotated(jitter), eff)
	else:
		for i in range(count):
			var t: float = float(i) / float(count - 1) - 0.5
			_spawn_bullet(base_dir.rotated(t * spread), eff)
	# Эффекты выстрела
	AudioBus.play(String(eff["def_id"]) + "_fire")
	var pat := String(eff["pattern"])
	var shake: float = 1.5
	match pat:
		"sniper":  shake = 4.0
		"shotgun": shake = 5.0
		"smg":     shake = 0.6
	GameManager.request_shake.emit(shake)

func _spawn_bullet(dir: Vector2, eff: Dictionary) -> void:
	var bullet := BULLET_SCENE.instantiate()
	get_tree().current_scene.get_node("GameObjects").add_child(bullet)
	bullet.global_position = global_position
	bullet.setup_extended({
		"dir":      dir,
		"damage":   float(eff["damage"]),
		"pierce":   int(eff["pierce"]),
		"speed":    float(eff["bullet_speed"]),
		"lifetime": float(eff["bullet_lifetime"]),
		"pattern":  String(eff["pattern"]),
		"color":    eff["color"],
	})

func take_damage(amount: float) -> void:
	if is_dead or GameManager.game_state != "fight":
		return
	if randf() < float(GameManager.player_stats["dodge"]):
		return
	var armor: int = int(GameManager.player_stats.get("armor", 0))
	var actual: float = maxf(amount - float(armor), 1.0)
	GameManager.player_stats["hp"] = float(GameManager.player_stats["hp"]) - actual
	GameManager.request_shake.emit(3.0)
	AudioBus.play("player_hurt")
	if float(GameManager.player_stats["hp"]) <= 0.0:
		GameManager.player_stats["hp"] = 0
		is_dead = true
		GameManager.player_died.emit()

func heal(amount: float) -> void:
	GameManager.player_stats["hp"] = minf(
		float(GameManager.player_stats["hp"]) + amount,
		float(GameManager.player_stats["max_hp"])
	)
