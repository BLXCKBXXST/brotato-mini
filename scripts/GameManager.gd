# GameManager.gd — Autoload singleton
extends Node

signal wave_changed(wave_number: int)
signal player_died
signal game_won

const TOTAL_WAVES := 20

var wave: int = 1
var game_state: String = "title"

# Базовые статы персонажа (тело)
var player_stats := {
	"max_hp":       100,
	"hp":           100,
	"armor":        0,        # уменьшает входящий урон
	"speed":        200.0,
	"damage":       12,
	"attack_speed": 1.2,
	"range":        220.0,
	"pierce":       1,
	"lifesteal":    0.0,
	"dodge":        0.0,      # шанс уклонения 0.0-1.0
	"level":        1,
	"xp":           0,
	"xp_next":      30,
	"materials":    0,
	"total_kills":  0,
	"total_damage": 0.0,
}

# Прокачки тела: сколько раз куплен каждый стат
var body_upgrades := {}

# Купленные предметы (аксессуары/оружие)
var owned_items: Array[Dictionary] = []

# ─── Описание прокачек тела ───────────────────────────────────────────────────
const BODY_UPGRADES := [
	{"id": "max_hp",       "name": "❤️ Макс. HP",       "desc": "+20 макс. HP",          "cost": 20, "max_level": 10},
	{"id": "armor",        "name": "🛡️ Броня",          "desc": "+2 брони",              "cost": 25, "max_level": 10},
	{"id": "speed",        "name": "👟 Скорость",        "desc": "+20 скорости",          "cost": 15, "max_level": 10},
	{"id": "damage",       "name": "⚔️ Урон",           "desc": "+5 урона",              "cost": 20, "max_level": 15},
	{"id": "attack_speed", "name": "⚡ Скор. атаки",    "desc": "+0.2 скор. атаки",     "cost": 25, "max_level": 10},
	{"id": "range",        "name": "🎯 Дальность",       "desc": "+40 дальности",        "cost": 15, "max_level": 10},
	{"id": "pierce",       "name": "🔱 Пробитие",        "desc": "+1 пробитие",          "cost": 30, "max_level": 5},
	{"id": "lifesteal",    "name": "🩸 Жизнекража",      "desc": "+4% жизнекражи",       "cost": 35, "max_level": 5},
	{"id": "dodge",        "name": "💨 Уклонение",       "desc": "+5% шанс уклонения",  "cost": 30, "max_level": 4},
]

# ─── Предметы (аксессуары и оружие) ──────────────────────────────────────────
const SHOP_ITEMS := [
	# Оружие — меняют тип стрельбы / дают бонус к атаке
	{"id": "knife",       "type": "weapon",    "name": "🔪 Нож",           "desc": "+15% урон, +0.3 скор. атаки",  "cost": 40, "rarity": 1,
		"stats": {"damage_pct": 0.15, "attack_speed": 0.3}},
	{"id": "shotgun",     "type": "weapon",    "name": "💥 Дробовик",       "desc": "+30% урон, пробитие +1",      "cost": 55, "rarity": 2,
		"stats": {"damage_pct": 0.30, "pierce": 1}},
	{"id": "smg",         "type": "weapon",    "name": "🔫 Пистолет-пулемёт","desc": "+0.8 скор. атаки",          "cost": 50, "rarity": 2,
		"stats": {"attack_speed": 0.8}},
	{"id": "sniper",      "type": "weapon",    "name": "🎯 Снайперка",      "desc": "+50% урон, +60 дальности",   "cost": 65, "rarity": 3,
		"stats": {"damage_pct": 0.50, "range": 60.0}},
	{"id": "flamethrower","type": "weapon",    "name": "🔥 Огнемёт",        "desc": "+20% урон, +0.5 скор. атаки", "cost": 60, "rarity": 3,
		"stats": {"damage_pct": 0.20, "attack_speed": 0.5}},
	# Аксессуары — пассивные бонусы
	{"id": "boots",       "type": "accessory", "name": "👢 Сапоги",         "desc": "+50 скорости",               "cost": 30, "rarity": 1,
		"stats": {"speed": 50.0}},
	{"id": "gloves",      "type": "accessory", "name": "🥊 Перчатки",       "desc": "+8 урона",                  "cost": 30, "rarity": 1,
		"stats": {"damage": 8}},
	{"id": "medkit",      "type": "accessory", "name": "💊 Аптечка",        "desc": "+40 макс. HP, +40 HP",       "cost": 35, "rarity": 1,
		"stats": {"max_hp": 40, "hp_heal": 40}},
	{"id": "vampire",     "type": "accessory", "name": "🧛 Вампир",         "desc": "+8% жизнекражи",             "cost": 45, "rarity": 2,
		"stats": {"lifesteal": 0.08}},
	{"id": "shield",      "type": "accessory", "name": "🛡️ Щит",           "desc": "+5 брони",                  "cost": 40, "rarity": 2,
		"stats": {"armor": 5}},
	{"id": "ring",        "type": "accessory", "name": "💍 Кольцо силы",    "desc": "+12 урона, +10 макс. HP",   "cost": 50, "rarity": 2,
		"stats": {"damage": 12, "max_hp": 10}},
	{"id": "amulet",      "type": "accessory", "name": "📿 Амулет скорости","desc": "+0.4 скор. атаки, +30 скорости","cost": 50, "rarity": 2,
		"stats": {"attack_speed": 0.4, "speed": 30.0}},
	{"id": "clover",      "type": "accessory", "name": "🍀 Клевер",         "desc": "+10% уклонение",             "cost": 55, "rarity": 3,
		"stats": {"dodge": 0.10}},
	{"id": "crown",       "type": "accessory", "name": "👑 Корона",         "desc": "+20% урон, +5 брони",        "cost": 70, "rarity": 3,
		"stats": {"damage_pct": 0.20, "armor": 5}},
]

func _ready() -> void:
	wave_changed.connect(func(_w: int): pass)
	player_died.connect(func(): pass)
	game_won.connect(func(): pass)

func reset() -> void:
	wave = 1
	body_upgrades = {}
	owned_items = []
	player_stats = {
		"max_hp":       100,
		"hp":           100,
		"armor":        0,
		"speed":        200.0,
		"damage":       12,
		"attack_speed": 1.2,
		"range":        220.0,
		"pierce":       1,
		"lifesteal":    0.0,
		"dodge":        0.0,
		"level":        1,
		"xp":           0,
		"xp_next":      30,
		"materials":    0,
		"total_kills":  0,
		"total_damage": 0.0,
	}

func get_body_upgrade_level(stat_id: String) -> int:
	return body_upgrades.get(stat_id, 0)

func apply_body_upgrade(upgrade: Dictionary) -> void:
	var sid: String = upgrade["id"]
	body_upgrades[sid] = get_body_upgrade_level(sid) + 1
	var s := player_stats
	match sid:
		"max_hp":       s["max_hp"] = int(s["max_hp"]) + 20; s["hp"] = float(s["hp"]) + 20.0
		"armor":        s["armor"]  = int(s["armor"]) + 2
		"speed":        s["speed"]  = float(s["speed"]) + 20.0
		"damage":       s["damage"] = int(s["damage"]) + 5
		"attack_speed": s["attack_speed"] = float(s["attack_speed"]) + 0.2
		"range":        s["range"]  = float(s["range"]) + 40.0
		"pierce":       s["pierce"] = int(s["pierce"]) + 1
		"lifesteal":    s["lifesteal"] = float(s["lifesteal"]) + 0.04
		"dodge":        s["dodge"]  = minf(float(s["dodge"]) + 0.05, 0.80)

func apply_shop_item(item: Dictionary) -> void:
	owned_items.append(item)
	var s := player_stats
	var stats: Dictionary = item.get("stats", {})
	for key in stats:
		match key:
			"damage_pct":   s["damage"] = int(float(s["damage"]) * (1.0 + float(stats[key])))
			"hp_heal":      s["hp"] = minf(float(s["hp"]) + float(stats[key]), float(s["max_hp"]))
			"max_hp":       s["max_hp"] = int(s["max_hp"]) + int(stats[key])
			"armor":        s["armor"]  = int(s["armor"]) + int(stats[key])
			"speed":        s["speed"]  = float(s["speed"]) + float(stats[key])
			"damage":       s["damage"] = int(s["damage"]) + int(stats[key])
			"attack_speed": s["attack_speed"] = float(s["attack_speed"]) + float(stats[key])
			"range":        s["range"]  = float(s["range"]) + float(stats[key])
			"pierce":       s["pierce"] = int(s["pierce"]) + int(stats[key])
			"lifesteal":    s["lifesteal"] = float(s["lifesteal"]) + float(stats[key])
			"dodge":        s["dodge"]  = minf(float(s["dodge"]) + float(stats[key]), 0.80)

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
