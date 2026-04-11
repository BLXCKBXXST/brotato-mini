# WaveManager.gd
extends Node

signal wave_ended

@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_timer: Timer  = $WaveTimer

const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")

const ENEMY_TYPES := [
	{"base_hp": 18,  "hp_per_wave": 5,  "speed": 65,  "damage": 8,  "xp": 3,  "mat": 2, "color": Color(0.27, 1.0, 0.53)},
	{"base_hp": 10,  "hp_per_wave": 2,  "speed": 115, "damage": 5,  "xp": 2,  "mat": 1, "color": Color(0.67, 0.53, 1.0)},
	{"base_hp": 45,  "hp_per_wave": 9,  "speed": 38,  "damage": 14, "xp": 5,  "mat": 4, "color": Color(0.67, 0.67, 0.67)},
	{"base_hp": 110, "hp_per_wave": 22, "speed": 44,  "damage": 18, "xp": 14, "mat": 10, "color": Color(1.0, 0.27, 0.27)},
]

# Спавн строго за пределами арены, чтобы мобы входили с периметра
const SPAWN_MARGIN := 40.0

var arena_rect: Rect2 = Rect2()

func start_wave(rect: Rect2) -> void:
	print("[WaveManager] start_wave, wave=", GameManager.wave, " interval=", GameManager.get_spawn_interval())
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
		_spawn_enemy()

func _on_wave_timer_timeout() -> void:
	print("[WaveManager] wave timer done")
	stop_wave()
	wave_ended.emit()

func _spawn_enemy() -> void:
	var enemy := ENEMY_SCENE.instantiate()
	get_parent().get_node("GameObjects").add_child(enemy)

	var available := ENEMY_TYPES.slice(0, 3)
	if GameManager.wave >= 5:
		available = ENEMY_TYPES.duplicate()
	var t: Dictionary = available[randi() % available.size()]

	var hp: float = float(t["base_hp"]) + float(t["hp_per_wave"]) * float(GameManager.wave)
	enemy.setup(hp, float(t["speed"]) + float(GameManager.wave) * 2.0,
				float(t["damage"]), int(t["xp"]), int(t["mat"]))
	enemy.get_node("Sprite").color = t["color"]
	enemy.global_position = _spawn_pos_on_edge()

func _spawn_pos_on_edge() -> Vector2:
	# Спавн ровно на периметре арены, не за ней
	var r := arena_rect
	match randi() % 4:
		0: return Vector2(randf_range(r.position.x, r.end.x), r.position.y + SPAWN_MARGIN)
		1: return Vector2(r.end.x   - SPAWN_MARGIN, randf_range(r.position.y, r.end.y))
		2: return Vector2(randf_range(r.position.x, r.end.x), r.end.y   - SPAWN_MARGIN)
		_: return Vector2(r.position.x + SPAWN_MARGIN, randf_range(r.position.y, r.end.y))
