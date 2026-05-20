# WaveManager.gd
extends Node

signal wave_ended

@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_timer: Timer  = $WaveTimer

const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")

const TEX_FAST   := preload("res://assets/sprites/enemy_fast.png")
const TEX_LIGHT  := preload("res://assets/sprites/enemy_light.png")
const TEX_TANK   := preload("res://assets/sprites/enemy_tank.png")
const TEX_ELITE  := preload("res://assets/sprites/enemy_elite.png")
const TEX_BOSS_DASH   := preload("res://assets/sprites/boss_dash.png")
const TEX_BOSS_SHOOT  := preload("res://assets/sprites/boss_shoot.png")
const TEX_BOSS_SUMMON := preload("res://assets/sprites/boss_summon.png")
const TEX_BOSS_FINAL  := preload("res://assets/sprites/boss_final.png")

const ENEMY_TYPES := [
	{"base_hp": 18,  "hp_per_wave": 5,  "speed": 65,  "damage": 8,  "xp": 3,  "mat": 2,  "color": Color(1, 1, 1), "tex": "fast"},
	{"base_hp": 10,  "hp_per_wave": 2,  "speed": 115, "damage": 5,  "xp": 2,  "mat": 1,  "color": Color(1, 1, 1), "tex": "light"},
	{"base_hp": 45,  "hp_per_wave": 9,  "speed": 38,  "damage": 14, "xp": 5,  "mat": 4,  "color": Color(1, 1, 1), "tex": "tank"},
	{"base_hp": 110, "hp_per_wave": 22, "speed": 44,  "damage": 18, "xp": 14, "mat": 10, "color": Color(1, 1, 1), "tex": "elite"},
]

const BOSS_WAVES := [5, 10, 15, 20]
const BOSS_DEFS := [
	{"wave": 5,  "ability": "dash",   "hp_mult": 20.0, "dmg_mult": 1.6, "speed": 70.0,  "xp": 40, "mat": 25, "color": Color(1.0, 0.4, 0.4), "tex": "boss_dash"},
	{"wave": 10, "ability": "shoot",  "hp_mult": 35.0, "dmg_mult": 1.7, "speed": 50.0,  "xp": 60, "mat": 35, "color": Color(0.6, 0.4, 1.0), "tex": "boss_shoot"},
	{"wave": 15, "ability": "summon", "hp_mult": 55.0, "dmg_mult": 1.9, "speed": 55.0,  "xp": 90, "mat": 50, "color": Color(1.0, 0.6, 0.2), "tex": "boss_summon"},
	{"wave": 20, "ability": "dash",   "hp_mult": 100.0,"dmg_mult": 2.4, "speed": 95.0,  "xp": 150,"mat": 80, "color": Color(0.95, 0.1, 0.1), "tex": "boss_final"},
]

func _tex_for(name: String) -> Texture2D:
	match name:
		"fast":        return TEX_FAST
		"light":       return TEX_LIGHT
		"tank":        return TEX_TANK
		"elite":       return TEX_ELITE
		"boss_dash":   return TEX_BOSS_DASH
		"boss_shoot":  return TEX_BOSS_SHOOT
		"boss_summon": return TEX_BOSS_SUMMON
		"boss_final":  return TEX_BOSS_FINAL
	return TEX_FAST

# Арена 1300x1300
const ARENA_MIN    := Vector2(-10, -260)
const ARENA_MAX    := Vector2(1290, 1040)
const VIEW_HALF    := Vector2(640, 360)
const SPAWN_MARGIN := 80.0

var arena_rect: Rect2 = Rect2()
var _boss_spawned: bool = false

func _ready() -> void:
	GameManager.boss_killed.connect(_on_boss_killed)

func start_wave(rect: Rect2) -> void:
	arena_rect = rect
	_boss_spawned = false
	spawn_timer.wait_time = GameManager.get_spawn_interval()
	spawn_timer.start()
	wave_timer.wait_time = GameManager.get_wave_duration()
	wave_timer.start()
	if GameManager.wave in BOSS_WAVES:
		var delay: float = 0.5 if GameManager.wave == 20 else GameManager.get_wave_duration() * 0.5
		get_tree().create_timer(delay).timeout.connect(_try_spawn_boss)

func stop_wave() -> void:
	spawn_timer.stop()
	wave_timer.stop()

func _on_spawn_timer_timeout() -> void:
	var count: int = 1 + int(float(GameManager.wave) / 6.0)
	for i in range(count): _prepare_spawn()

func _on_wave_timer_timeout() -> void:
	if GameManager.wave in BOSS_WAVES:
		# На боссовых волнах ждём смерти босса, таймер крутится дальше
		wave_timer.start()
		return
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
	var sprite := enemy.get_node("Sprite") as Sprite2D
	if sprite:
		sprite.texture = _tex_for(String(t.get("tex", "fast")))
		sprite.modulate = t["color"]
		enemy._orig_color = sprite.modulate
	enemy.global_position = pos

# ─── Boss spawn ──────────────────────────────────────────────────────────────
func _try_spawn_boss() -> void:
	if _boss_spawned or GameManager.game_state != "fight":
		return
	_boss_spawned = true
	var def := _find_boss_def(GameManager.wave)
	if def.is_empty():
		return
	var pos := _random_offscreen_pos()
	var warning := SpawnIndicator.new()
	warning.set_big()   # увеличенный индикатор
	get_parent().get_node("GameObjects").add_child(warning)
	warning.global_position = pos

	warning.finished.connect(func():
		if GameManager.game_state != "fight": return
		var enemy := ENEMY_SCENE.instantiate()
		get_parent().get_node("GameObjects").add_child(enemy)
		var base_t = ENEMY_TYPES[0]
		var hp: float = float(base_t["base_hp"]) * float(def["hp_mult"]) + float(GameManager.wave) * 40.0
		var dmg: float = float(base_t["damage"]) * float(def["dmg_mult"])
		enemy.setup_boss(hp, float(def["speed"]), dmg, int(def["xp"]), int(def["mat"]), String(def["ability"]))
		var sprite := enemy.get_node("Sprite") as Sprite2D
		if sprite:
			sprite.texture = _tex_for(String(def.get("tex", "boss_dash")))
			sprite.modulate = def["color"]
			enemy._orig_color = sprite.modulate
		enemy.global_position = pos
	)

func _find_boss_def(w: int) -> Dictionary:
	for d in BOSS_DEFS:
		if int(d["wave"]) == w:
			return d
	return {}

func _on_boss_killed(_ability: String) -> void:
	if GameManager.game_state != "fight":
		return
	if GameManager.wave == 20:
		stop_wave()
		GameManager.game_won.emit()
	elif GameManager.wave in BOSS_WAVES:
		stop_wave()
		wave_ended.emit()

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
	var duration := 0.85
	var radius   := 22.0
	const BLINK_HZ := 7.0
	var _elapsed := 0.0
	var _alpha   := 0.0
	var _done    := false

	func set_big() -> void:
		duration = 1.5
		radius   = 60.0

	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius, Color(1.0, 0.15, 0.15, _alpha))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.4, 0.4, minf(_alpha * 1.8 + 0.1, 1.0)), 2.5)

	func _process(delta: float) -> void:
		if _done: return
		_elapsed += delta
		_alpha = abs(sin(_elapsed * BLINK_HZ * PI)) * lerpf(0.3, 0.9, _elapsed / duration)
		queue_redraw()
		if _elapsed >= duration:
			_done = true; queue_free(); finished.emit()
