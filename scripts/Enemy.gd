# Enemy.gd
extends CharacterBody2D

@onready var health_bar: ProgressBar = $HealthBar
@onready var sprite: ColorRect = $Sprite

var hp: float = 20.0
var max_hp: float = 20.0
var speed: float = 70.0
var damage: float = 8.0
var xp_reward: int = 3
var mat_reward: int = 2
var damage_timer: float = 0.0

const DAMAGE_INTERVAL := 0.1
const DROP_SCENE := preload("res://scenes/Drop.tscn")
const FLOAT_TEXT_SCENE := preload("res://scenes/FloatText.tscn")

func setup(p_hp: float, p_speed: float, p_damage: float, p_xp: int, p_mat: int) -> void:
	hp = p_hp
	max_hp = p_hp
	speed = p_speed
	damage = p_damage
	xp_reward = p_xp
	mat_reward = p_mat
	_update_health_bar()

func _physics_process(delta: float) -> void:
	_seek_player(delta)
	_check_player_contact(delta)

func _seek_player(_delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var dir: Vector2 = (player.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

func _check_player_contact(delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	if global_position.distance_to(player.global_position) < 28.0:
		damage_timer += delta
		if damage_timer >= DAMAGE_INTERVAL:
			damage_timer = 0.0
			player.call("take_damage", damage * DAMAGE_INTERVAL)
	else:
		damage_timer = 0.0

func take_hit(dmg: float) -> void:
	hp -= dmg
	_update_health_bar()
	_show_damage_number(dmg)

	var ls: float = float(GameManager.player_stats["lifesteal"])
	if ls > 0.0:
		var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if player != null:
			player.call("heal", dmg * ls)

	sprite.color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		sprite.color = _get_color()

	if hp <= 0:
		_die()

func _die() -> void:
	GameManager.player_stats["total_kills"] += 1
	GameManager.add_xp(xp_reward)
	_spawn_drops()
	queue_free()

func _spawn_drops() -> void:
	for i in range(mat_reward):
		var drop := DROP_SCENE.instantiate()
		get_parent().add_child(drop)
		drop.global_position = global_position + Vector2(
			randf_range(-20, 20), randf_range(-20, 20)
		)

func _show_damage_number(dmg: float) -> void:
	var ft := FLOAT_TEXT_SCENE.instantiate()
	get_parent().add_child(ft)
	ft.global_position = global_position + Vector2(0, -30)
	ft.call("setup", "-" + str(int(dmg)), Color.YELLOW)

func _update_health_bar() -> void:
	if health_bar:
		health_bar.value = (hp / max_hp) * 100.0
		health_bar.visible = hp < max_hp

func _get_color() -> Color:
	return sprite.color
