# Main.gd
extends Node2D

@onready var player: CharacterBody2D       = $GameObjects/Player
@onready var wave_manager: Node            = $WaveManager
@onready var hud: CanvasLayer              = $HUD
@onready var shop: CanvasLayer             = $Shop
@onready var title_screen: CanvasLayer     = $TitleScreen
@onready var gameover_screen: CanvasLayer  = $GameOverScreen
@onready var win_screen: CanvasLayer       = $WinScreen

# Арена x1.2 ещё: было 1080x792, стало 1296x950
# Центр (640, 390), начало (-8, -85)
const ARENA_RECT := Rect2(Vector2(-8, -85), Vector2(1296, 950))
var wave_timer_ref: float = 0.0

func _ready() -> void:
	print("[Main] _ready start")

	var start_btn  := title_screen.get_node("Panel/VBox/StartBtn") as Button
	var restart_btn := gameover_screen.get_node("Panel/VBox/RestartBtn") as Button
	var win_btn    := win_screen.get_node("Panel/VBox/RestartBtn") as Button
	var cont_btn   := shop.get_node("Panel/VBox/Footer/ContinueBtn") as Button

	if start_btn:
		if not start_btn.pressed.is_connected(start_game):
			start_btn.pressed.connect(start_game)
	if restart_btn:
		if not restart_btn.pressed.is_connected(start_game):
			restart_btn.pressed.connect(start_game)
	if win_btn:
		if not win_btn.pressed.is_connected(start_game):
			win_btn.pressed.connect(start_game)
	if cont_btn:
		if not cont_btn.pressed.is_connected(_on_shop_continue):
			cont_btn.pressed.connect(_on_shop_continue)

	GameManager.player_died.connect(_on_player_died)
	GameManager.game_won.connect(_show_win)
	wave_manager.wave_ended.connect(_on_wave_ended)

	_show_title()

func _process(delta: float) -> void:
	if GameManager.game_state == "fight":
		wave_timer_ref -= delta
		wave_timer_ref = maxf(wave_timer_ref, 0.0)
		hud.update_hud(wave_timer_ref)

func start_game() -> void:
	GameManager.reset()
	_start_wave()

func _start_wave() -> void:
	GameManager.game_state = "fight"
	wave_timer_ref = GameManager.get_wave_duration()
	for node in get_tree().get_nodes_in_group("enemies"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("drops"):
		node.queue_free()
	player.global_position = ARENA_RECT.get_center()
	player._sync_stats()
	wave_manager.start_wave(ARENA_RECT)
	title_screen.hide()
	gameover_screen.hide()
	win_screen.hide()
	shop.hide()
	hud.show()

func _on_wave_ended() -> void:
	GameManager.game_state = "shop"
	shop.open_shop()

func _on_shop_continue() -> void:
	GameManager.wave += 1
	if GameManager.wave > GameManager.TOTAL_WAVES:
		_show_win()
		return
	GameManager.wave_changed.emit(GameManager.wave)
	_start_wave()

func _on_player_died() -> void:
	GameManager.game_state = "gameover"
	wave_manager.stop_wave()
	gameover_screen.get_node("Panel/VBox/WaveLabel").text  = "Ты дошёл до волны %d" % GameManager.wave
	gameover_screen.get_node("Panel/VBox/Stats/KillsVal").text = str(GameManager.player_stats["total_kills"])
	gameover_screen.get_node("Panel/VBox/Stats/DmgVal").text   = str(int(GameManager.player_stats["total_damage"]))
	gameover_screen.get_node("Panel/VBox/Stats/MatsVal").text  = str(GameManager.player_stats["materials"])
	gameover_screen.get_node("Panel/VBox/Stats/LvlVal").text   = str(GameManager.player_stats["level"])
	hud.hide()
	gameover_screen.show()

func _show_title() -> void:
	hud.hide()
	shop.hide()
	gameover_screen.hide()
	win_screen.hide()
	title_screen.show()

func _show_win() -> void:
	GameManager.game_state = "win"
	wave_manager.stop_wave()
	win_screen.get_node("Panel/VBox/Stats/KillsVal").text = str(GameManager.player_stats["total_kills"])
	win_screen.get_node("Panel/VBox/Stats/DmgVal").text   = str(int(GameManager.player_stats["total_damage"]))
	hud.hide()
	win_screen.show()
