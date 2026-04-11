# Shop.gd
extends CanvasLayer

signal continue_pressed

@onready var items_container: HBoxContainer = $Panel/VBox/ItemsContainer
@onready var mats_label: Label = $Panel/VBox/Footer/MatsLabel
@onready var wave_label: Label = $Panel/VBox/WaveLabel

const ITEMS := [
	{"name": "❤️ Аптечка",       "desc": "+30 HP",              "cost": 3,  "rarity": 0},
	{"name": "⚔️ Острый клинок", "desc": "+5 урона",            "cost": 4,  "rarity": 1},
	{"name": "👟 Быстрые ноги",  "desc": "+25 скорости",        "cost": 3,  "rarity": 0},
	{"name": "🔫 Скорострел",    "desc": "+0.3 скор. атаки",    "cost": 5,  "rarity": 1},
	{"name": "🧲 Магнит",        "desc": "+60 радиус подбора",  "cost": 3,  "rarity": 0},
	{"name": "🩸 Вампиризм",     "desc": "+3% жизнекражи",      "cost": 6,  "rarity": 2},
	{"name": "💪 Сила",          "desc": "+8 урона",             "cost": 6,  "rarity": 2},
	{"name": "🏃 Рывок",         "desc": "+40 скорости",         "cost": 5,  "rarity": 1},
	{"name": "💖 Крепкое тело",  "desc": "+20 макс. HP",         "cost": 5,  "rarity": 1},
]

func open_shop() -> void:
	mats_label.text = "Материалы: %d 💜" % int(GameManager.player_stats["materials"])
	wave_label.text = "Волна %d пройдена!" % GameManager.wave
	for child in items_container.get_children():
		child.queue_free()
	var pool: Array = ITEMS.duplicate()
	pool.shuffle()
	var shown: Array = pool.slice(0, 4)
	for item in shown:
		_add_item_card(item)
	show()

func _add_item_card(item: Dictionary) -> void:
	var card := PanelContainer.new()
	var vbox := VBoxContainer.new()
	var name_lbl := Label.new()
	var desc_lbl := Label.new()
	var cost_lbl := Label.new()
	var btn := Button.new()

	name_lbl.text = item["name"]
	desc_lbl.text = item["desc"]
	cost_lbl.text = "Цена: %d 💜" % int(item["cost"])
	btn.text = "Купить"
	btn.pressed.connect(_on_buy.bind(item, btn))

	vbox.add_child(name_lbl)
	vbox.add_child(desc_lbl)
	vbox.add_child(cost_lbl)
	vbox.add_child(btn)
	card.add_child(vbox)
	card.custom_minimum_size = Vector2(160, 0)
	items_container.add_child(card)

func _on_buy(item: Dictionary, btn: Button) -> void:
	var cost: int = int(item["cost"])
	if int(GameManager.player_stats["materials"]) < cost:
		return
	GameManager.player_stats["materials"] -= cost
	_apply_item(item)
	btn.text = "✓ Куплено"
	btn.disabled = true
	mats_label.text = "Материалы: %d 💜" % int(GameManager.player_stats["materials"])

func _apply_item(item: Dictionary) -> void:
	var s: Dictionary = GameManager.player_stats
	match item["name"]:
		"❤️ Аптечка":        s["hp"] = minf(float(s["hp"]) + 30.0, float(s["max_hp"]))
		"⚔️ Острый клинок":  s["damage"] = int(s["damage"]) + 5
		"👟 Быстрые ноги":   s["speed"] = float(s["speed"]) + 25.0
		"🔫 Скорострел":     s["attack_speed"] = float(s["attack_speed"]) + 0.3
		"🧲 Магнит":         s["range"] = float(s["range"]) + 60.0
		"🩸 Вампиризм":      s["lifesteal"] = float(s["lifesteal"]) + 0.03
		"💪 Сила":           s["damage"] = int(s["damage"]) + 8
		"🏃 Рывок":          s["speed"] = float(s["speed"]) + 40.0
		"💖 Крепкое тело":   s["max_hp"] = int(s["max_hp"]) + 20; s["hp"] = float(s["hp"]) + 20.0

func _on_continue_pressed() -> void:
	hide()
	continue_pressed.emit()
