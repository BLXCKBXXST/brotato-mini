# Shop.gd — двухвкладочный магазин: прокачка тела + предметы
extends CanvasLayer

signal continue_pressed

@onready var wave_label:   Label         = $Panel/VBox/WaveLabel
@onready var mats_label:   Label         = $Panel/VBox/MatsLabel
@onready var tab_body_btn: Button        = $Panel/VBox/Tabs/TabBodyBtn
@onready var tab_item_btn: Button        = $Panel/VBox/Tabs/TabItemBtn
@onready var body_section: ScrollContainer = $Panel/VBox/Content/BodySection
@onready var item_section: ScrollContainer = $Panel/VBox/Content/ItemSection
@onready var body_grid:    GridContainer = $Panel/VBox/Content/BodySection/BodyGrid
@onready var item_grid:    GridContainer = $Panel/VBox/Content/ItemSection/ItemGrid
@onready var continue_btn: Button        = $Panel/VBox/Footer/ContinueBtn

const RARITY_COLORS := [
	Color(0.75, 0.75, 0.75),  # 0 обычный — серый
	Color(0.4, 0.8, 0.4),     # 1 необычный — зелёный
	Color(0.4, 0.6, 1.0),     # 2 редкий — синий
	Color(0.85, 0.5, 1.0),    # 3 эпический — фиолетовый
]

var _current_tab := "body"
var _item_pool: Array[Dictionary] = []

func open_shop() -> void:
	mats_label.text = "💜 Материалы: %d" % int(GameManager.player_stats["materials"])
	wave_label.text = "✅ Волна %d пройдена!" % GameManager.wave
	_build_item_pool()
	_build_body_grid()
	_build_item_grid()
	_switch_tab("body")
	show()

func _build_item_pool() -> void:
	_item_pool = []
	var pool := GameManager.SHOP_ITEMS.duplicate()
	pool.shuffle()
	var shown := pool.slice(0, 4)
	for item in shown:
		_item_pool.append(item)

# ─── Вкладка: Прокачка тела ───────────────────────────────────────────────────
func _build_body_grid() -> void:
	for c in body_grid.get_children(): c.queue_free()
	for upg in GameManager.BODY_UPGRADES:
		_add_body_card(upg)

func _add_body_card(upg: Dictionary) -> void:
	var lvl := GameManager.get_body_upgrade_level(upg["id"])
	var maxed: bool = lvl >= int(upg["max_level"])
	var cost_now: int = int(upg["cost"]) + lvl * int(upg["cost"]) / 3

	var card := PanelContainer.new()
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(160, 0)

	var icon_lbl := Label.new()
	icon_lbl.text = upg["name"]
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 14)

	var desc_lbl := Label.new()
	desc_lbl.text = upg["desc"]
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD

	var lvl_lbl := Label.new()
	lvl_lbl.text = "Ур. %d / %d" % [lvl, upg["max_level"]]
	lvl_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	lvl_lbl.add_theme_font_size_override("font_size", 11)

	var cost_lbl := Label.new()
	cost_lbl.text = "Цена: %d 💜" % cost_now if not maxed else "МАКС."
	cost_lbl.add_theme_font_size_override("font_size", 11)

	var btn := Button.new()
	btn.text = "Прокачать" if not maxed else "Максимум"
	btn.disabled = maxed or int(GameManager.player_stats["materials"]) < cost_now
	btn.pressed.connect(_on_buy_body.bind(upg, btn, lvl_lbl, cost_lbl))

	vbox.add_child(icon_lbl)
	vbox.add_child(desc_lbl)
	vbox.add_child(lvl_lbl)
	vbox.add_child(cost_lbl)
	vbox.add_child(btn)
	card.add_child(vbox)
	body_grid.add_child(card)

func _on_buy_body(upg: Dictionary, btn: Button, lvl_lbl: Label, cost_lbl: Label) -> void:
	var lvl := GameManager.get_body_upgrade_level(upg["id"])
	var cost_now: int = int(upg["cost"]) + lvl * int(upg["cost"]) / 3
	if int(GameManager.player_stats["materials"]) < cost_now: return
	GameManager.player_stats["materials"] -= cost_now
	GameManager.apply_body_upgrade(upg)
	var new_lvl := GameManager.get_body_upgrade_level(upg["id"])
	var maxed: bool = new_lvl >= int(upg["max_level"])
	var new_cost: int = int(upg["cost"]) + new_lvl * int(upg["cost"]) / 3
	lvl_lbl.text = "Ур. %d / %d" % [new_lvl, upg["max_level"]]
	cost_lbl.text = "Цена: %d 💜" % new_cost if not maxed else "МАКС."
	btn.text = "Прокачать" if not maxed else "Максимум"
	btn.disabled = maxed or int(GameManager.player_stats["materials"]) < new_cost
	mats_label.text = "💜 Материалы: %d" % int(GameManager.player_stats["materials"])
	# Обновить доступность других кнопок
	_refresh_body_btns()

func _refresh_body_btns() -> void:
	for card in body_grid.get_children():
		var vbox = card.get_child(0)
		if vbox == null: continue
		var btn = vbox.get_child(vbox.get_child_count() - 1) as Button
		if btn == null or btn.disabled: continue
		# Найти соответствующий upg по индексу
	var idx := 0
	for card in body_grid.get_children():
		if idx >= GameManager.BODY_UPGRADES.size(): break
		var upg: Dictionary = GameManager.BODY_UPGRADES[idx]
		var lvl := GameManager.get_body_upgrade_level(upg["id"])
		var cost_now: int = int(upg["cost"]) + lvl * int(upg["cost"]) / 3
		var maxed: bool = lvl >= int(upg["max_level"])
		var vbox = card.get_child(0)
		if vbox:
			var btn = vbox.get_child(vbox.get_child_count() - 1) as Button
			if btn:
				btn.disabled = maxed or int(GameManager.player_stats["materials"]) < cost_now
		idx += 1

# ─── Вкладка: Предметы ────────────────────────────────────────────────────────
func _build_item_grid() -> void:
	for c in item_grid.get_children(): c.queue_free()
	for item in _item_pool:
		_add_item_card(item)

func _add_item_card(item: Dictionary) -> void:
	var rarity: int = item.get("rarity", 0)
	var rarity_color: Color = RARITY_COLORS[clamp(rarity, 0, 3)]
	var itype: String = item.get("type", "accessory")
	var type_label: String = "[🔫 Оружие]" if itype == "weapon" else "[💍 Аксессуар]"

	var card := PanelContainer.new()
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(170, 0)

	var type_lbl := Label.new()
	type_lbl.text = type_label
	type_lbl.add_theme_color_override("font_color", rarity_color)
	type_lbl.add_theme_font_size_override("font_size", 10)

	var name_lbl := Label.new()
	name_lbl.text = item["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", rarity_color)
	name_lbl.add_theme_font_size_override("font_size", 14)

	var desc_lbl := Label.new()
	desc_lbl.text = item["desc"]
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD

	var cost_lbl := Label.new()
	cost_lbl.text = "Цена: %d 💜" % int(item["cost"])
	cost_lbl.add_theme_font_size_override("font_size", 11)

	var btn := Button.new()
	btn.text = "Купить"
	btn.disabled = int(GameManager.player_stats["materials"]) < int(item["cost"])
	btn.pressed.connect(_on_buy_item.bind(item, btn))

	vbox.add_child(type_lbl)
	vbox.add_child(name_lbl)
	vbox.add_child(desc_lbl)
	vbox.add_child(cost_lbl)
	vbox.add_child(btn)
	card.add_child(vbox)
	item_grid.add_child(card)

func _on_buy_item(item: Dictionary, btn: Button) -> void:
	var cost: int = int(item["cost"])
	if int(GameManager.player_stats["materials"]) < cost: return
	GameManager.player_stats["materials"] -= cost
	GameManager.apply_shop_item(item)
	btn.text = "✓ Куплено"
	btn.disabled = true
	mats_label.text = "💜 Материалы: %d" % int(GameManager.player_stats["materials"])
	_refresh_body_btns()

# ─── Вкладки ──────────────────────────────────────────────────────────────────
func _switch_tab(tab: String) -> void:
	_current_tab = tab
	body_section.visible = (tab == "body")
	item_section.visible = (tab == "item")
	tab_body_btn.modulate = Color.WHITE if tab == "body" else Color(0.6, 0.6, 0.6)
	tab_item_btn.modulate = Color.WHITE if tab == "item" else Color(0.6, 0.6, 0.6)

func _on_tab_body() -> void:
	_switch_tab("body")

func _on_tab_item() -> void:
	_switch_tab("item")

func _on_continue_pressed() -> void:
	hide()
	continue_pressed.emit()
