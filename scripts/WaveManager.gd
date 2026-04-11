# WaveManager.gd
extends Node

signal wave_ended

@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_timer: Timer  = $WaveTimer

const ENEMY_SCENE   := preload("res://scenes/Enemy.tscn")
const WARNING_SCENE := preload("res://scenes/SpawnWarning.tscn")

const ENEMY_TYPES := [
	{"base_hp": 18,  "hp_per_wave": 5,  "speed": 65,  "damage": 8,  "xp": 3,  "mat": 2, "color": Color(0.27, 1.0, 0.53)},
	{"base_hp": 10,  "hp_per_wave": 2,  "speed": 115, "damage": 5,  "xp": 2,  "mat": 1, "color": Color(0.67, 0.53, 1.0)},
	{"base_hp": 45,  "hp_per_wave": 9,  "speed": 38,  "damage": 14, "xp": 5,  "mat": 4, "color": Color(0.67, 0.67, 0.67)},
	{"base_hp": 110, "hp_per_wave": 22, "speed": 44,  "damage": 18, "xp": 14, "mat": 10, "color": Color(1.0, 0.27, 0.27)},
]

# Границы арены (строго внутри полотна)
const ARENA_MIN  := Vector2(210, 80)
const ARENA_MAX  := Vector2(1070, 710)
# Отступ от игрока при выборе позиции спавна
const MIN_DIST_FROM_PLAYER := 180.0

var arena_rect: Rect2 = Rect2()

func start_wave(rect: Rect2) -> void:
	print("[WaveManager] start_wave, wave=", GameManager.wave)
	arena_rect = rect
	spawn_timer.wait_time = GameManager.get_spawn_interval()
	spawn_timer.start()
	wave_timer.wait_time = GameManager.get_wave_duration()
	wave_timer.start()

func stop_wave() -> void:
	spawn_timer.stop()
	wave_timer.stop()

func _on_spawn_timer_timeout() -> void:
	var count: int = 1 + int(float(GameManager.wave) / 6.0)
	for i in range(count):
		_prepare_spawn()

func _on_wave_timer_timeout() -> void:
	print("[WaveManager] wave timer done")
	stop_wave()
	wave_ended.emit()

# Показываем индикатор, ждём, спавним
func _prepare_spawn() -> void:
	var pos := _random_arena_pos()

	# создаём индикатор прямо на карте
	var warning := WARNING_SCENE.instantiate() as Node2D
	get_parent().get_node("GameObjects").add_child(warning)
	warning.global_position = pos

	# выбираем тип врага заранее
	var available := ENEMY_TYPES.slice(0, 3)
	if GameManager.wave >= 5:
		available = ENEMY_TYPES.duplicate()
	var t: Dictionary = available[randi() % available.size()]

	# когда индикатор закончил анимацию — спавним
	warning.finished.connect(func():
		# если волна уже кончилась или игра не в состоянии fight — не спавним
		if GameManager.game_state != "fight":
			return
		_do_spawn(pos, t)
	)

func _do_spawn(pos: Vector2, t: Dictionary) -> void:
	var enemy := ENEMY_SCENE.instantiate()
	get_parent().get_node("GameObjects").add_child(enemy)
	var hp: float = float(t["base_hp"]) + float(t["hp_per_wave"]) * float(GameManager.wave)
	enemy.setup(
		hp,
		float(t["speed"]) + float(GameManager.wave) * 2.0,
		float(t["damage"]),
		int(t["xp"]),
		int(t["mat"])
	)
	enemy.get_node("Sprite").color = t["color"]
	enemy.global_position = pos

# Случайная позиция внутри арены, не ближе MIN_DIST_FROM_PLAYER от игрока
func _random_arena_pos() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var player_pos := Vector2(640, 360) if player == null else player.global_position

	for _attempt in range(20):
		var pos := Vector2(
			randf_range(ARENA_MIN.x + 30, ARENA_MAX.x - 30),
			randf_range(ARENA_MIN.y + 30, ARENA_MAX.y - 30)
		)
		if pos.distance_to(player_pos) >= MIN_DIST_FROM_PLAYER:
			return pos

	# fallback: если 20 попыток не дали результат — берём любую
	return Vector2(
		randf_range(ARENA_MIN.x + 30, ARENA_MAX.x - 30),
		randf_range(ARENA_MIN.y + 30, ARENA_MAX.y - 30)
	)
