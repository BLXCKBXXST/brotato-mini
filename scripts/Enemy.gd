# Enemy.gd
extends CharacterBody2D

@onready var health_bar: ProgressBar = $HealthBar
@onready var sprite: Sprite2D        = $Sprite

var hp: float       = 20.0
var max_hp: float   = 20.0
var speed: float    = 70.0
var damage: float   = 8.0
var xp_reward: int  = 3
var mat_reward: int = 2
var damage_timer: float = 0.0
var is_dying: bool  = false
var _orig_color := Color.WHITE

# Boss-поля
var is_boss: bool       = false
var boss_ability: String = ""
var ability_cooldown: float = 2.5
var _ability_timer: float   = 2.5
var _dashing: bool = false
var _dash_target: Vector2 = Vector2.ZERO
var _dash_elapsed: float = 0.0
const DASH_DURATION := 0.45

# Арена 1300x1300, центр (640, 390)
const ARENA_MIN := Vector2(-10, -260)
const ARENA_MAX := Vector2(1290, 1040)
const HALF_E    := Vector2(16, 16)
const HALF_BOSS := Vector2(40, 40)

const DAMAGE_INTERVAL  := 0.5
const DROP_SCENE        := preload("res://scenes/Drop.tscn")
const FLOAT_TEXT_SCENE  := preload("res://scenes/FloatText.tscn")
const ENEMY_BULLET_SCENE := preload("res://scenes/EnemyBullet.tscn")
const ENEMY_SCENE       := preload("res://scenes/Enemy.tscn")
const HIT_PARTICLE_SCENE := preload("res://scenes/HitParticle.tscn")

func _ready() -> void:
	_orig_color = sprite.modulate if sprite else Color.WHITE

func setup(p_hp: float, p_speed: float, p_damage: float, p_xp: int, p_mat: int) -> void:
	hp         = p_hp
	max_hp     = p_hp
	speed      = p_speed
	damage     = p_damage
	xp_reward  = p_xp
	mat_reward = p_mat
	_update_health_bar()

func setup_boss(p_hp: float, p_speed: float, p_damage: float, p_xp: int, p_mat: int, ability: String) -> void:
	setup(p_hp, p_speed, p_damage, p_xp, p_mat)
	is_boss = true
	boss_ability = ability
	add_to_group("bosses")
	_ability_timer = 2.5
	if sprite:
		sprite.scale = Vector2(3.5, 3.5)
	if health_bar:
		health_bar.offset_left = -40; health_bar.offset_right = 40
		health_bar.offset_top  = -50; health_bar.offset_bottom = -44

func _physics_process(delta: float) -> void:
	if GameManager.game_state != "fight" or is_dying:
		velocity = Vector2.ZERO
		return
	if _dashing:
		_update_dash(delta)
	else:
		_seek_player()
	_clamp_to_arena()
	_check_player_contact(delta)
	if is_boss and not _dashing:
		_boss_ai(delta)

func _seek_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	velocity = (player.global_position - global_position).normalized() * speed
	move_and_slide()

func _clamp_to_arena() -> void:
	var half := HALF_BOSS if is_boss else HALF_E
	global_position.x = clampf(global_position.x, ARENA_MIN.x + half.x, ARENA_MAX.x - half.x)
	global_position.y = clampf(global_position.y, ARENA_MIN.y + half.y, ARENA_MAX.y - half.y)

func _check_player_contact(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var contact_dist := 60.0 if is_boss else 30.0
	if global_position.distance_to(player.global_position) < contact_dist:
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
	sprite.modulate = Color.WHITE
	get_tree().create_timer(0.08).timeout.connect(func():
		if is_instance_valid(self) and not is_dying:
			sprite.modulate = _orig_color
	)
	if hp <= 0.0:
		_die()

func _die() -> void:
	if is_dying:
		return
	is_dying = true
	GameManager.player_stats["total_kills"] += 1
	var mat_mult := 1.0 + float(GameManager.player_stats.get("materials_pct", 0.0))
	GameManager.player_stats["materials"] += int(round(mat_reward * mat_mult))
	GameManager.add_xp(xp_reward)
	_spawn_drops()
	# Партиклы цвета врага
	var particle := HIT_PARTICLE_SCENE.instantiate()
	get_tree().current_scene.get_node("GameObjects").add_child(particle)
	(particle as Node2D).global_position = global_position
	if particle.has_method("set_color"):
		particle.call("set_color", _orig_color)
	if is_boss:
		GameManager.boss_killed.emit(boss_ability)
		GameManager.request_shake.emit(10.0)
		AudioBus.play("boss_die")
	else:
		GameManager.request_shake.emit(1.0)
		AudioBus.play("enemy_die")
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
		health_bar.visible = is_boss or hp < max_hp

# ─── Boss AI ─────────────────────────────────────────────────────────────────
func _boss_ai(delta: float) -> void:
	_ability_timer -= delta
	if _ability_timer > 0.0:
		return
	match boss_ability:
		"dash":
			_boss_dash()
			_ability_timer = 3.5
		"shoot":
			_boss_shoot()
			_ability_timer = 2.0
		"summon":
			_boss_summon()
			_ability_timer = 5.5
		_:
			_ability_timer = 5.0

func _boss_dash() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	# Точка приземления — за игроком, ограниченная границами арены
	var dir := (player.global_position - global_position).normalized()
	var dist := global_position.distance_to(player.global_position) + 60.0
	var target := global_position + dir * dist
	target.x = clampf(target.x, ARENA_MIN.x + HALF_BOSS.x, ARENA_MAX.x - HALF_BOSS.x)
	target.y = clampf(target.y, ARENA_MIN.y + HALF_BOSS.y, ARENA_MAX.y - HALF_BOSS.y)
	_dashing = true
	_dash_target = target
	_dash_elapsed = 0.0
	if sprite:
		sprite.modulate = Color(1.0, 0.7, 0.0)   # «зарядка»

func _update_dash(delta: float) -> void:
	_dash_elapsed += delta
	var t: float = clampf(_dash_elapsed / DASH_DURATION, 0.0, 1.0)
	global_position = global_position.lerp(_dash_target, t * 0.4)
	velocity = Vector2.ZERO
	if t >= 1.0:
		_dashing = false
		if sprite:
			sprite.modulate = _orig_color

func _boss_shoot() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var dir := (player.global_position - global_position).normalized()
	# Стреляем веером из 3 пуль
	for i in range(3):
		var angle: float = deg_to_rad(20.0) * (float(i) - 1.0)
		var bullet := ENEMY_BULLET_SCENE.instantiate()
		get_tree().current_scene.get_node("GameObjects").add_child(bullet)
		bullet.global_position = global_position
		bullet.call("setup", dir.rotated(angle), 320.0, damage * 0.8)

func _boss_summon() -> void:
	for i in range(3):
		var minion := ENEMY_SCENE.instantiate()
		get_tree().current_scene.get_node("GameObjects").add_child(minion)
		var angle: float = TAU * float(i) / 3.0
		minion.global_position = global_position + Vector2(cos(angle), sin(angle)) * 80.0
		# Лёгкий быстрый враг
		var w := float(GameManager.wave)
		minion.call("setup", 10.0 + 2.0 * w, 130.0, 5.0, 2, 1)
		var s := minion.get_node_or_null("Sprite") as Sprite2D
		if s: s.modulate = Color(0.67, 0.53, 1.0)
