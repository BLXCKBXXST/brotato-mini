# GameManager.gd — Autoload singleton
extends Node

signal wave_changed(wave_number: int)
signal player_died
signal game_won
signal boss_killed(ability: String)
signal request_shake(amount: float)

const TOTAL_WAVES := 20

# ─── Weapon-система ───────────────────────────────────────────────────────────
const MAX_WEAPON_SLOTS  := 6
const WEAPONS_IN_SHOP   := 4
const MAX_TIER          := 4
const COMBINE_REQUIRED  := 2
const TIER_DAMAGE_MULT    := [1.0, 1.5, 2.2, 3.2]
const TIER_COOLDOWN_MULT  := [1.0, 0.9, 0.8, 0.7]
const TIER_COST_MULT      := [1.0, 2.0, 3.5, 6.0]
const TIER_SELL_REFUND    := 0.5
const TIER_COLORS := [
	Color(0.75, 0.75, 0.75),
	Color(0.4, 0.8, 0.4),
	Color(0.4, 0.6, 1.0),
	Color(0.85, 0.5, 1.0),
]
const TIER_NAMES := ["I", "II", "III", "IV"]

const WEAPON_DEFS := [
	{
		"id": "pistol", "name": "Пистолет", "pattern": "single",
		"base_damage": 14.0, "base_cooldown": 0.83,
		"base_range": 240.0, "base_pierce": 1,
		"bullet_count": 1, "spread_deg": 0.0,
		"bullet_speed": 560.0, "bullet_lifetime": 1.6,
		"base_cost": 30, "color": Color(1.0, 0.9, 0.3),
		"icon": "res://assets/icons/weapon_pistol.png",
	},
	{
		"id": "shotgun", "name": "Дробовик", "pattern": "shotgun",
		"base_damage": 8.0, "base_cooldown": 1.4,
		"base_range": 200.0, "base_pierce": 1,
		"bullet_count": 5, "spread_deg": 30.0,
		"bullet_speed": 500.0, "bullet_lifetime": 0.6,
		"base_cost": 55, "color": Color(1.0, 0.55, 0.2),
		"icon": "res://assets/icons/weapon_shotgun.png",
	},
	{
		"id": "sniper", "name": "Снайперка", "pattern": "sniper",
		"base_damage": 55.0, "base_cooldown": 2.2,
		"base_range": 700.0, "base_pierce": 4,
		"bullet_count": 1, "spread_deg": 0.0,
		"bullet_speed": 1100.0, "bullet_lifetime": 1.4,
		"base_cost": 70, "color": Color(0.4, 0.9, 1.0),
		"icon": "res://assets/icons/weapon_sniper.png",
	},
	{
		"id": "smg", "name": "SMG", "pattern": "smg",
		"base_damage": 5.0, "base_cooldown": 0.20,
		"base_range": 220.0, "base_pierce": 1,
		"bullet_count": 1, "spread_deg": 10.0,
		"bullet_speed": 620.0, "bullet_lifetime": 0.8,
		"base_cost": 55, "color": Color(0.95, 0.95, 0.4),
		"icon": "res://assets/icons/weapon_smg.png",
	},
	{
		"id": "flamer", "name": "Огнемёт", "pattern": "smg",
		"base_damage": 4.0, "base_cooldown": 0.10,
		"base_range": 160.0, "base_pierce": 3,
		"bullet_count": 1, "spread_deg": 20.0,
		"bullet_speed": 380.0, "bullet_lifetime": 0.4,
		"base_cost": 60, "color": Color(1.0, 0.4, 0.1),
		"icon": "res://assets/icons/weapon_flamer.png",
	},
	{
		"id": "minigun", "name": "Миниган", "pattern": "smg",
		"base_damage": 6.0, "base_cooldown": 0.14,
		"base_range": 260.0, "base_pierce": 1,
		"bullet_count": 1, "spread_deg": 6.0,
		"bullet_speed": 700.0, "bullet_lifetime": 0.8,
		"base_cost": 65, "color": Color(0.8, 0.8, 0.85),
		"icon": "res://assets/icons/weapon_minigun.png",
	},
]

var wave: int = 1
var game_state: String = "title"

# Базовые статы персонажа
var player_stats := {
	"max_hp":       100,
	"hp":           100,
	"armor":        0,
	"speed":        200.0,
	"damage":       0,           # legacy для совместимости, не используется в выстреле
	"attack_speed": 0.0,         # legacy
	"range":        0.0,         # legacy
	"pierce":       0,           # legacy
	# Новые модификаторы оружий
	"damage_pct":       0.0,
	"attack_speed_pct": 0.0,
	"range_pct":        0.0,
	"pierce_bonus":     0,
	"lifesteal":    0.0,
	"dodge":        0.0,
	"level":        1,
	"xp":           0,
	"xp_next":      30,
	"materials":    0,
	"total_kills":  0,
	"total_damage": 0.0,
}

var body_upgrades := {}
var owned_items: Array[Dictionary] = []
var player_weapons: Array[Dictionary] = []   # {def_id, tier}

# ─── Описание прокачек тела (теперь все % бонусы) ────────────────────────────
const BODY_UPGRADES := [
	{"id": "max_hp",       "name": "Макс. HP",      "desc": "+20 макс. HP",          "cost": 20, "max_level": 10, "icon": "res://assets/icons/upg_max_hp.png"},
	{"id": "armor",        "name": "Броня",         "desc": "+2 брони",              "cost": 25, "max_level": 10, "icon": "res://assets/icons/upg_armor.png"},
	{"id": "speed",        "name": "Скорость",      "desc": "+20 скорости",          "cost": 15, "max_level": 10, "icon": "res://assets/icons/upg_speed.png"},
	{"id": "damage",       "name": "Урон",          "desc": "+8% урон всем оружиям", "cost": 20, "max_level": 15, "icon": "res://assets/icons/upg_damage.png"},
	{"id": "attack_speed", "name": "Скор. атаки",   "desc": "+10% скор. атаки",      "cost": 25, "max_level": 10, "icon": "res://assets/icons/upg_attack_speed.png"},
	{"id": "range",        "name": "Дальность",     "desc": "+15% дальности",       "cost": 15, "max_level": 10, "icon": "res://assets/icons/upg_range.png"},
	{"id": "pierce",       "name": "Пробитие",      "desc": "+1 пробитие",          "cost": 30, "max_level": 5,  "icon": "res://assets/icons/upg_pierce.png"},
	{"id": "lifesteal",    "name": "Жизнекража",    "desc": "+4% жизнекражи",       "cost": 35, "max_level": 5,  "icon": "res://assets/icons/upg_lifesteal.png"},
	{"id": "dodge",        "name": "Уклонение",     "desc": "+5% шанс уклонения",   "cost": 30, "max_level": 4,  "icon": "res://assets/icons/upg_dodge.png"},
]

# ─── Аксессуары (бывшие SHOP_ITEMS — только пассивные бонусы) ────────────────
const SHOP_ITEMS := [
	{"id": "boots",   "type": "accessory", "name": "Сапоги",         "desc": "+50 скорости",                  "cost": 30, "rarity": 1, "icon": "res://assets/icons/acc_boots.png",
		"stats": {"speed": 50.0}},
	{"id": "gloves",  "type": "accessory", "name": "Перчатки",       "desc": "+8% урон",                      "cost": 30, "rarity": 1, "icon": "res://assets/icons/acc_gloves.png",
		"stats": {"damage_pct": 0.08}},
	{"id": "medkit",  "type": "accessory", "name": "Аптечка",        "desc": "+40 макс. HP, +40 HP",          "cost": 35, "rarity": 1, "icon": "res://assets/icons/acc_medkit.png",
		"stats": {"max_hp": 40, "hp_heal": 40}},
	{"id": "vampire", "type": "accessory", "name": "Вампир",         "desc": "+8% жизнекражи",                "cost": 45, "rarity": 2, "icon": "res://assets/icons/acc_vampire.png",
		"stats": {"lifesteal": 0.08}},
	{"id": "shield",  "type": "accessory", "name": "Щит",            "desc": "+5 брони",                      "cost": 40, "rarity": 2, "icon": "res://assets/icons/acc_shield.png",
		"stats": {"armor": 5}},
	{"id": "ring",    "type": "accessory", "name": "Кольцо силы",    "desc": "+12% урон, +10 макс. HP",       "cost": 50, "rarity": 2, "icon": "res://assets/icons/acc_ring.png",
		"stats": {"damage_pct": 0.12, "max_hp": 10}},
	{"id": "amulet",  "type": "accessory", "name": "Амулет",         "desc": "+10% скор. атаки, +30 скорости","cost": 50, "rarity": 2, "icon": "res://assets/icons/acc_amulet.png",
		"stats": {"attack_speed_pct": 0.10, "speed": 30.0}},
	{"id": "scope",   "type": "accessory", "name": "Прицел",         "desc": "+25% дальности, +1 пробитие",   "cost": 55, "rarity": 2, "icon": "res://assets/icons/acc_scope.png",
		"stats": {"range_pct": 0.25, "pierce_bonus": 1}},
	{"id": "clover",  "type": "accessory", "name": "Клевер",         "desc": "+10% уклонение",                "cost": 55, "rarity": 3, "icon": "res://assets/icons/acc_clover.png",
		"stats": {"dodge": 0.10}},
	{"id": "crown",   "type": "accessory", "name": "Корона",         "desc": "+20% урон, +5 брони",           "cost": 70, "rarity": 3, "icon": "res://assets/icons/acc_crown.png",
		"stats": {"damage_pct": 0.20, "armor": 5}},
]

func _ready() -> void:
	# Глушители «неиспользованных сигналов»
	wave_changed.connect(func(_w: int): pass)
	player_died.connect(func(): pass)
	game_won.connect(func(): pass)
	boss_killed.connect(func(_a: String): pass)
	request_shake.connect(func(_a: float): pass)
	# Autoload должен жить во время паузы
	process_mode = Node.PROCESS_MODE_ALWAYS

func reset() -> void:
	wave = 1
	body_upgrades = {}
	owned_items = []
	player_weapons = []
	player_stats = {
		"max_hp":       100,
		"hp":           100,
		"armor":        0,
		"speed":        200.0,
		"damage":       0,
		"attack_speed": 0.0,
		"range":        0.0,
		"pierce":       0,
		"damage_pct":       0.0,
		"attack_speed_pct": 0.0,
		"range_pct":        0.0,
		"pierce_bonus":     0,
		"lifesteal":    0.0,
		"dodge":        0.0,
		"level":        1,
		"xp":           0,
		"xp_next":      30,
		"materials":    0,
		"total_kills":  0,
		"total_damage": 0.0,
	}
	add_weapon("pistol", 1)

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
		"damage":       s["damage_pct"]       = float(s["damage_pct"]) + 0.08
		"attack_speed": s["attack_speed_pct"] = float(s["attack_speed_pct"]) + 0.10
		"range":        s["range_pct"]        = float(s["range_pct"]) + 0.15
		"pierce":       s["pierce_bonus"]     = int(s["pierce_bonus"]) + 1
		"lifesteal":    s["lifesteal"] = float(s["lifesteal"]) + 0.04
		"dodge":        s["dodge"]  = minf(float(s["dodge"]) + 0.05, 0.80)

func apply_shop_item(item: Dictionary) -> void:
	owned_items.append(item)
	var s := player_stats
	var stats: Dictionary = item.get("stats", {})
	for key in stats:
		match key:
			"hp_heal":            s["hp"] = minf(float(s["hp"]) + float(stats[key]), float(s["max_hp"]))
			"max_hp":             s["max_hp"] = int(s["max_hp"]) + int(stats[key])
			"armor":              s["armor"]  = int(s["armor"]) + int(stats[key])
			"speed":              s["speed"]  = float(s["speed"]) + float(stats[key])
			"damage_pct":         s["damage_pct"] = float(s["damage_pct"]) + float(stats[key])
			"attack_speed_pct":   s["attack_speed_pct"] = float(s["attack_speed_pct"]) + float(stats[key])
			"range_pct":          s["range_pct"] = float(s["range_pct"]) + float(stats[key])
			"pierce_bonus":       s["pierce_bonus"] = int(s["pierce_bonus"]) + int(stats[key])
			"lifesteal":          s["lifesteal"] = float(s["lifesteal"]) + float(stats[key])
			"dodge":              s["dodge"]  = minf(float(s["dodge"]) + float(stats[key]), 0.80)

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
		AudioBus.play("level_up")

# ─── Weapon API ──────────────────────────────────────────────────────────────

func get_weapon_def(def_id: String) -> Dictionary:
	for w in WEAPON_DEFS:
		if w["id"] == def_id:
			return w
	return {}

func add_weapon(def_id: String, tier: int = 1) -> bool:
	if player_weapons.size() >= MAX_WEAPON_SLOTS:
		return false
	if get_weapon_def(def_id).is_empty():
		return false
	player_weapons.append({"def_id": def_id, "tier": clampi(tier, 1, MAX_TIER)})
	return true

func remove_weapon(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= player_weapons.size():
		return {}
	var w: Dictionary = player_weapons[slot_index]
	player_weapons.remove_at(slot_index)
	return w

func can_combine(def_id: String, tier: int) -> bool:
	if tier >= MAX_TIER:
		return false
	var count := 0
	for w in player_weapons:
		if w["def_id"] == def_id and int(w["tier"]) == tier:
			count += 1
			if count >= COMBINE_REQUIRED:
				return true
	return false

func combine_weapons(def_id: String, tier: int) -> bool:
	if not can_combine(def_id, tier):
		return false
	var removed := 0
	var i := 0
	while i < player_weapons.size() and removed < COMBINE_REQUIRED:
		var w: Dictionary = player_weapons[i]
		if w["def_id"] == def_id and int(w["tier"]) == tier:
			player_weapons.remove_at(i)
			removed += 1
		else:
			i += 1
	player_weapons.append({"def_id": def_id, "tier": tier + 1})
	return true

func get_weapon_sell_price(weapon: Dictionary) -> int:
	var def := get_weapon_def(String(weapon.get("def_id", "")))
	if def.is_empty():
		return 0
	var t := clampi(int(weapon.get("tier", 1)), 1, MAX_TIER)
	var full_price := float(def["base_cost"]) * float(TIER_COST_MULT[t - 1])
	return int(round(full_price * TIER_SELL_REFUND))

func get_weapon_buy_price(def_id: String, tier: int) -> int:
	var def := get_weapon_def(def_id)
	if def.is_empty():
		return 0
	var t := clampi(tier, 1, MAX_TIER)
	return int(round(float(def["base_cost"]) * float(TIER_COST_MULT[t - 1])))

func get_weapon_effective_stats(weapon: Dictionary) -> Dictionary:
	var def := get_weapon_def(String(weapon.get("def_id", "")))
	if def.is_empty():
		return {}
	var tier := clampi(int(weapon.get("tier", 1)), 1, MAX_TIER)
	var dmg_mult: float = TIER_DAMAGE_MULT[tier - 1]
	var cd_mult: float  = TIER_COOLDOWN_MULT[tier - 1]
	var s := player_stats
	var damage := float(def["base_damage"]) * dmg_mult * (1.0 + float(s["damage_pct"]))
	var cooldown := float(def["base_cooldown"]) * cd_mult / (1.0 + float(s["attack_speed_pct"]))
	var rng := float(def["base_range"]) * (1.0 + float(s["range_pct"]))
	var pierce := int(def["base_pierce"]) + int(s["pierce_bonus"])
	return {
		"def_id":          def["id"],
		"pattern":         def["pattern"],
		"damage":          damage,
		"cooldown":        cooldown,
		"range":           rng,
		"pierce":          pierce,
		"bullet_count":    int(def["bullet_count"]),
		"spread_deg":      float(def["spread_deg"]),
		"bullet_speed":    float(def["bullet_speed"]),
		"bullet_lifetime": float(def["bullet_lifetime"]),
		"color":           def["color"],
		"tier":            tier,
	}

func roll_shop_weapons(count: int) -> Array[Dictionary]:
	# Тиры взвешены по волне: на ранних — почти всегда I, на поздних — больше II/III
	var offers: Array[Dictionary] = []
	for i in range(count):
		var def: Dictionary = WEAPON_DEFS[randi() % WEAPON_DEFS.size()]
		var tier := _roll_tier_for_wave(wave)
		offers.append({
			"def_id": def["id"],
			"tier":   tier,
			"cost":   get_weapon_buy_price(def["id"], tier),
		})
	return offers

func _roll_tier_for_wave(w: int) -> int:
	# 1..2 → почти всегда I; 5..9 → шанс II; 10+ → шанс III; 15+ → шанс IV
	var r := randf()
	if w >= 15 and r < 0.05:
		return 4
	if w >= 10 and r < 0.20:
		return 3
	if w >= 5 and r < 0.35:
		return 2
	return 1
