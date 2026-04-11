# Enemy.gd
extends CharacterBody2D

@onready var health_bar: ProgressBar = $HealthBar
@onready var sprite: ColorRect       = $Sprite

var hp: float        = 20.0
var max_hp: float    = 20.0
var speed: float     = 70.0
var damage: float    = 8.0
var xp_reward: int   = 3
var mat_reward: int  = 2
var damage_timer: float = 0.0
var is_dying: bool   = false

const DAMAGE_INTERVAL := 0.5
const DROP_SCENE       := preload("res://scenes/Drop.tscn")
const FLOAT_TEXT_SCENE := preload("res://scenes/FloatText.tscn")

func setup(p_hp: float, p_speed: float, p_damage: float, p_xp: int, p_mat: int) -> void:
	hp        = p_hp
	max_hp    = p_hp
	speed     = p_speed
	damage    = p_damage
	xp_reward = p_xp
	mat_reward = p_mat
	_update_health_bar()

func _physics_process(delta: float) -> void:
	if GameManager.game_state != "fight" or is_dying:
		velocity = Vector2.ZERO
		return
	_seek_player()
	_check_player_contact(delta)

func _seek_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	velocity = (player.global_position - global_position).normalized() * speed
	move_and_slide()

func _check_player_contact(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	if global_position.distance_to(player.global_position) < 30.0:
		damage_timer += delta
		if damage_timer >= DAMAGE_INTERVAL:
			damage_timer = 0.0
			player.call("take_damage", damage)
	else:
		damage_timer = 0.0

func take_hit(dmg: float) -> void:
	if is_dying:
		return
	hp -= dmg
	_update_health_bar()
	_show_damage_number(dmg)

	var ls: float = float(GameManager.player_stats["lifesteal"])
	if ls > 0.0:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null:
			player.call("heal", dmg * ls)

	# flash white
	sprite.color = Color.WHITE
	get_tree().create_timer(0.08).timeout.connect(func():
		if is_instance_valid(self) and not is_dying:
			sprite.color = _orig_color
	)

	if hp <= 0.0:
		_die()

var _orig_color := Color.WHITE

func _ready() -> void:
	_orig_color = sprite.color if sprite else Color.WHITE

func _die() -> void:
	if is_dying:
		return
	is_dying = true
	GameManager.player_stats["total_kills"] += 1
	GameManager.player_stats["materials"]   += mat_reward
	GameManager.add_xp(xp_reward)
	print("[Enemy] died, kills=", GameManager.player_stats["total_kills"])
	_spawn_drops()
	queue_free()

func _spawn_drops() -> void:
	for i in range(mat_reward):
		var drop := DROP_SCENE.instantiate()
		get_tree().current_scene.get_node("GameObjects").add_child(drop)
		drop.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))

func _show_damage_number(dmg: float) -> void:
	var ft := FLOAT_TEXT_SCENE.instantiate()
	get_tree().current_scene.get_node("GameObjects").add_child(ft)
	ft.global_position = global_position + Vector2(0, -30)
	ft.call("setup", str(int(dmg)), Color.YELLOW)

func _update_health_bar() -> void:
	if health_bar:
		health_bar.value   = (hp / max_hp) * 100.0
		health_bar.visible = hp < max_hp

func _get_color() -> Color:
	return _orig_color
