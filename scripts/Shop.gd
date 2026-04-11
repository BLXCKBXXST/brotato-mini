# Shop.gd
extends CanvasLayer

signal continue_pressed

@onready var items_container: HBoxContainer = $Panel/VBox/ItemsContainer
@onready var mats_label: Label = $Panel/VBox/Footer/MatsLabel
@onready var wave_label: Label = $Panel/VBox/WaveLabel

const SHOP_ITEMS := [
	{"name": "Нож",       "desc": "+8 урона",           "cost": 5,  "icon": "🔪", "fn": "add_damage"},
	{"name": "Кроссовки", "desc": "+35 скорость",        "cost": 5,  "icon": "👟", "fn": "add_speed"},
	{"name": "Аптечка",   "desc": "+25 макс HP + лечит", "cost": 5,  "icon": "💊", "fn": "add_hp"},
	{"name": "Адреналин", "desc": "+0.5 скор. атаки",    "cost": 6,  "icon": "⚡", "fn": "add_atkspd"},
	{"name": "Снайпер",   "desc": "+70 дальность",       "cost": 5,  "icon": "🎯", "fn": "add_range"},
	{"name": "Пирсинг",   "desc": "Пробивание пуль +1",  "cost": 8,  "icon": "💎", "fn": "add_pierce"},
	{"name": "Вампир",    "desc": "Вампиризм +8%",       "cost": 7,  "icon": "🦷", "fn": "add_lifesteal"},
	{"name": "Топор",     "desc": "+14 урона",           "cost": 8,  "icon": "🪓", "fn": "add_damage_2"},
	{"name": "Яблоко",    "desc": "Лечит 40 HP",         "cost": 4,  "icon": "🍎", "fn": "heal"},
]

var _current_offers: Array = []

func open() -> void:
	show()
	wave_label.text = "Волна %d пройдена!" % GameManager.wave
	_generate_offers()
	_refresh_ui()

func _generate_offers() -> void:
	var shuffled := SHOP_ITEMS.duplicate()
	shuffled.shuffle()
	_current_offers = shuffled.slice(0, 4)

func _refresh_ui() -> void:
	mats_label.text = "Материалы: %d 💜" % GameManager.player_stats["materials"]
	# Clear old buttons
	for child in items_container.get_children():
		child.queue_free()
	# Build item cards
	for item in _current_offers:
		var btn := _make_item_card(item)
		items_container.add_child(btn)

func _make_item_card(item: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	var icon_lbl := Label.new()
	var name_lbl := Label.new()
	var desc_lbl := Label.new()
	var cost_lbl := Label.new()
	var buy_btn := Button.new()
	
	icon_lbl.text = item["icon"]
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.text = item["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.text = item["desc"]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.text = "%d 💜" % item["cost"]
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buy_btn.text = "Купить"
	buy_btn.disabled = GameManager.player_stats["materials"] < item["cost"]
	buy_btn.pressed.connect(_on_buy.bind(item))
	
	vbox.add_child(icon_lbl)
	vbox.add_child(name_lbl)
	vbox.add_child(desc_lbl)
	vbox.add_child(cost_lbl)
	vbox.add_child(buy_btn)
	panel.add_child(vbox)
	panel.custom_minimum_size = Vector2(160, 180)
	return panel

func _on_buy(item: Dictionary) -> void:
	if GameManager.player_stats["materials"] < item["cost"]:
		return
	GameManager.player_stats["materials"] -= item["cost"]
	_apply_item(item["fn"])
	_refresh_ui()

func _apply_item(fn_name: String) -> void:
	match fn_name:
		"add_damage":    GameManager.player_stats["damage"] += 8
		"add_damage_2":  GameManager.player_stats["damage"] += 14
		"add_speed":     GameManager.player_stats["speed"] += 35.0
		"add_hp":        GameManager.player_stats["max_hp"] += 25; GameManager.player_stats["hp"] = mini(GameManager.player_stats["hp"] + 25, GameManager.player_stats["max_hp"])
		"add_atkspd":    GameManager.player_stats["attack_speed"] += 0.5
		"add_range":     GameManager.player_stats["range"] += 70.0
		"add_pierce":    GameManager.player_stats["pierce"] += 1
		"add_lifesteal": GameManager.player_stats["lifesteal"] += 0.08
		"heal":          GameManager.player_stats["hp"] = minf(GameManager.player_stats["hp"] + 40.0, GameManager.player_stats["max_hp"])

func _on_continue_pressed() -> void:
	hide()
	continue_pressed.emit()
