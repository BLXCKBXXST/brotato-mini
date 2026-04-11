# GameManager.gd — Autoload singleton
# Holds global game state shared between scenes
extends Node

signal wave_changed(wave_number: int)
signal player_died
signal game_won

const TOTAL_WAVES := 20

var wave: int = 1
var game_state: String = "title"  # title | fight | shop | gameover | win

# Player persistent stats (survive between waves)
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
	return minf(20.0 + wave * 3.0, 60.0)

func get_spawn_interval() -> float:
	return maxf(0.3, 1.2 - wave * 0.04)

func add_xp(amount: int) -> void:
	player_stats["xp"] += amount
	while player_stats["xp"] >= player_stats["xp_next"]:
		player_stats["xp"] -= player_stats["xp_next"]
		player_stats["level"] += 1
		player_stats["xp_next"] = int(player_stats["xp_next"] * 1.4)
		player_stats["max_hp"] += 5
		player_stats["hp"] = mini(player_stats["hp"] + 10, player_stats["max_hp"])
