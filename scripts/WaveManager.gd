# WaveManager.gd
extends Node

signal wave_ended

@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_timer: Timer  = $WaveTimer

const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")

const ENEMY_TYPES := [
	{"base_hp": 18,  "hp_per_wave": 5,  "speed": 65,  "damage": 8,  "xp": 3,  "mat": 2,  "color": Color(0.27, 1.0, 0.53)},
	{"base_hp": 10,  "hp_per_wave": 2,  "speed": 115, "damage": 5,  "xp": 2,  "mat": 1,  "color": Color(0.67, 0.53, 1.0)},
	{"base_hp": 45,  "hp_per_wave": 9,  "speed": 38,  "damage": 14, "xp": 5,  "mat": 4,  "color": Color(0.67, 0.67, 0.67)},
	{"base_hp": 110, "hp_per_wave": 22, "speed": 44,  "damage": 18, "xp": 14, "mat": 10, "color": Color(1.0, 0.27, 0.27)},
]

# Арена 1300x1300
const ARENA_MIN    := Vector2(-10, -260)
const ARENA_MAX    := Vector2(1290, 1040)
const VIEW_HALF    := Vector2(640, 360)
const SPAWN_MARGIN := 80.0

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
	for i in range(count): _prepare_spawn()

func _on_wave_timer_timeout() -> void:
	stop_wave()
	wave_ended.emit()

func _prepare_spawn() -> void:
	var pos := _random_offscreen_pos()
	var warning := SpawnIndicator.new()
	get_parent().get_node("GameObjects").add_child(warning)
	warning.global_position = pos

	var available := ENEMY_TYPES.slice(0, 3)
	if GameManager.wave >= 5: available = ENEMY_TYPES.duplicate()
	var t: Dictionary = available[randi() % available.size()]

	warning.finished.connect(func():
		if GameManager.game_state != "fight": return
		_do_spawn(pos, t)
	)

func _do_spawn(pos: Vector2, t: Dictionary) -> void:
	var enemy := ENEMY_SCENE.instantiate()
	get_parent().get_node("GameObjects").add_child(enemy)
	var hp: float = float(t["base_hp"]) + float(t["hp_per_wave"]) * float(GameManager.wave)
	enemy.setup(hp, float(t["speed"]) + float(GameManager.wave) * 2.0, float(t["damage"]), int(t["xp"]), int(t["mat"]))
	enemy.get_node("Sprite").color = t["color"]
	enemy.global_position = pos

func _random_offscreen_pos() -> Vector2:
	var player_pos := Vector2(640, 390)
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p := players[0] as Node2D
		if p != null and is_instance_valid(p): player_pos = p.global_position

	var cam_left   := player_pos.x - VIEW_HALF.x - SPAWN_MARGIN
	var cam_right  := player_pos.x + VIEW_HALF.x + SPAWN_MARGIN
	var cam_top    := player_pos.y - VIEW_HALF.y - SPAWN_MARGIN
	var cam_bottom := player_pos.y + VIEW_HALF.y + SPAWN_MARGIN

	var ax1 := ARENA_MIN.x + 30.0
	var ax2 := ARENA_MAX.x - 30.0
	var ay1 := ARENA_MIN.y + 30.0
	var ay2 := ARENA_MAX.y - 30.0

	var side := randi() % 4
	var x: float; var y: float
	match side:
		0: x = randf_range(maxf(ax1, cam_left - SPAWN_MARGIN * 2.0), minf(ax2, cam_left));    y = randf_range(ay1, ay2)
		1: x = randf_range(maxf(ax1, cam_right), minf(ax2, cam_right + SPAWN_MARGIN * 2.0));  y = randf_range(ay1, ay2)
		2: x = randf_range(ax1, ax2); y = randf_range(maxf(ay1, cam_top - SPAWN_MARGIN * 2.0), minf(ay2, cam_top))
		3: x = randf_range(ax1, ax2); y = randf_range(maxf(ay1, cam_bottom), minf(ay2, cam_bottom + SPAWN_MARGIN * 2.0))
	return Vector2(clampf(x, ax1, ax2), clampf(y, ay1, ay2))


class SpawnIndicator extends Node2D:
	signal finished
	const DURATION := 0.85
	const RADIUS   := 22.0
	const BLINK_HZ := 7.0
	var _elapsed := 0.0
	var _alpha   := 0.0
	var _done    := false

	func _draw() -> void:
		draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.15, 0.15, _alpha))
		draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, Color(1.0, 0.4, 0.4, minf(_alpha * 1.8 + 0.1, 1.0)), 2.5)

	func _process(delta: float) -> void:
		if _done: return
		_elapsed += delta
		_alpha = abs(sin(_elapsed * BLINK_HZ * PI)) * lerpf(0.3, 0.9, _elapsed / DURATION)
		queue_redraw()
		if _elapsed >= DURATION:
			_done = true; queue_free(); finished.emit()
