# WaveManager.gd
extends Node

signal wave_ended

@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_timer: Timer = $WaveTimer

const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")

const ENEMY_TYPES := [
	{"base_hp": 18, "hp_per_wave": 5,  "speed": 65,  "damage": 8,  "xp": 3,  "mat": 2, "color": Color(0.27, 1.0, 0.53)},
	{"base_hp": 10, "hp_per_wave": 2,  "speed": 115, "damage": 5,  "xp": 2,  "mat": 1, "color": Color(0.67, 0.53, 1.0)},
	{"base_hp": 45, "hp_per_wave": 9,  "speed": 38,  "damage": 14, "xp": 5,  "mat": 4, "color": Color(0.67, 0.67, 0.67)},
	{"base_hp": 110,"hp_per_wave": 22, "speed": 44,  "damage": 18, "xp": 14, "mat": 10, "color": Color(1.0, 0.27, 0.27)},
]

var arena_rect: Rect2 = Rect2()

func start_wave(rect: Rect2) -> void:
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
	stop_wave()
	wave_ended.emit()

func _spawn_enemy() -> void:
	var enemy := ENEMY_SCENE.instantiate()
	get_parent().add_child(enemy)

	var available_types: Array = ENEMY_TYPES.slice(0, 3)
	if GameManager.wave >= 5:
		available_types = ENEMY_TYPES.duplicate()

	var t: Dictionary = available_types[randi() % available_types.size()]
	var hp: float = float(t["base_hp"]) + float(t["hp_per_wave"]) * float(GameManager.wave)
	enemy.setup(hp, float(t["speed"]) + float(GameManager.wave) * 2.0,
		float(t["damage"]), int(t["xp"]), int(t["mat"]))
	enemy.get_node("Sprite").color = t["color"]
	enemy.global_position = _random_spawn_pos()

func _random_spawn_pos() -> Vector2:
	var side: int = randi() % 4
	match side:
		0: return Vector2(randf_range(arena_rect.position.x, arena_rect.end.x), arena_rect.position.y - 25)
		1: return Vector2(arena_rect.end.x + 25, randf_range(arena_rect.position.y, arena_rect.end.y))
		2: return Vector2(randf_range(arena_rect.position.x, arena_rect.end.x), arena_rect.end.y + 25)
		_: return Vector2(arena_rect.position.x - 25, randf_range(arena_rect.position.y, arena_rect.end.y))
