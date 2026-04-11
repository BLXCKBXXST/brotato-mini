# GameManager.gd — Autoload singleton
extends Node

signal wave_changed(wave_number: int)
signal player_died
signal game_won

const TOTAL_WAVES := 20

var wave: int = 1
var game_state: String = "title"

var player_stats := {
	"max_hp": 100,
	"hp": 100,
	"speed": 200.0,
	"damage": 12,
	"attack_speed": 1.2,
	"range": 220.0,
	"pierce": 1,
	"lifesteal": 0.0,
	"level": 1,
	"xp": 0,
	"xp_next": 30,
	"materials": 0,
	"total_kills": 0,
	"total_damage": 0.0,
}

func _ready() -> void:
	# Signals are connected externally via Main.gd
	wave_changed.connect(func(_w: int): pass)
	player_died.connect(func(): pass)
	game_won.connect(func(): pass)

func reset() -> void:
	wave = 1
	player_stats = {
		"max_hp": 100,
		"hp": 100,
		"speed": 200.0,
		"damage": 12,
		"attack_speed": 1.2,
		"range": 220.0,
		"pierce": 1,
		"lifesteal": 0.0,
		"level": 1,
		"xp": 0,
		"xp_next": 30,
		"materials": 0,
		"total_kills": 0,
		"total_damage": 0.0,
	}

func get_wave_duration() -> float:
	return minf(20.0 + float(wave) * 3.0, 60.0)

func get_spawn_interval() -> float:
	return maxf(0.3, 1.2 - float(wave) * 0.04)

func add_xp(amount: int) -> void:
	player_stats["xp"] += amount
	while player_stats["xp"] >= player_stats["xp_next"]:
		player_stats["xp"] -= player_stats["xp_next"]
		player_stats["level"] += 1
		player_stats["xp_next"] = int(float(player_stats["xp_next"]) * 1.4)
		player_stats["max_hp"] = int(player_stats["max_hp"]) + 5
		player_stats["hp"] = minf(float(player_stats["hp"]) + 10.0, float(player_stats["max_hp"]))
