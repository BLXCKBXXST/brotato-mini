# Main.gd
extends Node2D

@onready var player: CharacterBody2D       = $GameObjects/Player
@onready var wave_manager: Node            = $WaveManager
@onready var hud: CanvasLayer              = $HUD
@onready var shop: CanvasLayer             = $Shop
@onready var title_screen: CanvasLayer     = $TitleScreen
@onready var gameover_screen: CanvasLayer  = $GameOverScreen
@onready var win_screen: CanvasLayer       = $WinScreen
@onready var pause_screen: CanvasLayer     = $PauseScreen

# Арена 1300x1300, центр (640, 390)
const ARENA_RECT := Rect2(Vector2(-10, -260), Vector2(1300, 1300))
var wave_timer_ref: float = 0.0

# Screen shake
var _shake_amount: float = 0.0
const SHAKE_DECAY := 12.0
const SHAKE_MAX   := 14.0

func _ready() -> void:
	var start_btn   := title_screen.get_node("Panel/VBox/StartBtn") as Button
	var restart_btn := gameover_screen.get_node("Panel/VBox/RestartBtn") as Button
	var win_btn     := win_screen.get_node("Panel/VBox/RestartBtn") as Button
	var cont_btn    := shop.get_node("Panel/VBox/Footer/ContinueBtn") as Button
	var resume_btn  := pause_screen.get_node("Panel/VBox/ResumeBtn") as Button

	if start_btn   and not start_btn.pressed.is_connected(start_game):     start_btn.pressed.connect(start_game)
	if restart_btn and not restart_btn.pressed.is_connected(start_game):   restart_btn.pressed.connect(start_game)
	if win_btn     and not win_btn.pressed.is_connected(start_game):       win_btn.pressed.connect(start_game)
	if cont_btn    and not cont_btn.pressed.is_connected(_on_shop_continue): cont_btn.pressed.connect(_on_shop_continue)
	if resume_btn  and not resume_btn.pressed.is_connected(_toggle_pause): resume_btn.pressed.connect(_toggle_pause)

	GameManager.player_died.connect(_on_player_died)
	GameManager.game_won.connect(_show_win)
	GameManager.request_shake.connect(_on_request_shake)
	wave_manager.wave_ended.connect(_on_wave_ended)
	set_process_unhandled_input(true)
	_show_title()

func _process(delta: float) -> void:
	if GameManager.game_state == "fight":
		wave_timer_ref -= delta
		wave_timer_ref = maxf(wave_timer_ref, 0.0)
		hud.update_hud(wave_timer_ref)
	_update_shake(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if GameManager.game_state == "fight":
			_toggle_pause()
		elif get_tree().paused:
			_toggle_pause()

func _toggle_pause() -> void:
	var new_state := not get_tree().paused
	get_tree().paused = new_state
	pause_screen.visible = new_state

func _on_request_shake(amount: float) -> void:
	_shake_amount = clampf(maxf(_shake_amount, amount), 0.0, SHAKE_MAX)

func _update_shake(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	if _shake_amount > 0.05:
		cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_amount
		_shake_amount = maxf(0.0, _shake_amount - SHAKE_DECAY * delta)
	else:
		cam.offset = Vector2.ZERO

func start_game() -> void:
	if get_tree().paused:
		get_tree().paused = false
		pause_screen.visible = false
	GameManager.reset()
	_start_wave()

func _start_wave() -> void:
	GameManager.game_state = "fight"
	wave_timer_ref = GameManager.get_wave_duration()
	for node in get_tree().get_nodes_in_group("enemies"): node.queue_free()
	for node in get_tree().get_nodes_in_group("bosses"):  node.queue_free()
	for node in get_tree().get_nodes_in_group("drops"):   node.queue_free()
	for node in get_tree().get_nodes_in_group("enemy_bullets"): node.queue_free()
	player.global_position = ARENA_RECT.get_center()
	player._sync_stats()
	wave_manager.start_wave(ARENA_RECT)
	title_screen.hide(); gameover_screen.hide(); win_screen.hide(); shop.hide(); pause_screen.hide(); hud.show()

func _on_wave_ended() -> void:
	GameManager.game_state = "shop"
	shop.open_shop()

func _on_shop_continue() -> void:
	GameManager.wave += 1
	if GameManager.wave > GameManager.TOTAL_WAVES:
		_show_win(); return
	GameManager.wave_changed.emit(GameManager.wave)
	_start_wave()

func _on_player_died() -> void:
	GameManager.game_state = "gameover"
	wave_manager.stop_wave()
	gameover_screen.get_node("Panel/VBox/WaveLabel").text        = "Ты дошёл до волны %d" % GameManager.wave
	gameover_screen.get_node("Panel/VBox/Stats/KillsVal").text  = str(GameManager.player_stats["total_kills"])
	gameover_screen.get_node("Panel/VBox/Stats/DmgVal").text    = str(int(GameManager.player_stats["total_damage"]))
	gameover_screen.get_node("Panel/VBox/Stats/MatsVal").text   = str(GameManager.player_stats["materials"])
	gameover_screen.get_node("Panel/VBox/Stats/LvlVal").text    = str(GameManager.player_stats["level"])
	hud.hide(); gameover_screen.show()

func _show_title() -> void:
	hud.hide(); shop.hide(); gameover_screen.hide(); win_screen.hide(); pause_screen.hide(); title_screen.show()

func _show_win() -> void:
	GameManager.game_state = "win"
	wave_manager.stop_wave()
	win_screen.get_node("Panel/VBox/Stats/KillsVal").text = str(GameManager.player_stats["total_kills"])
	win_screen.get_node("Panel/VBox/Stats/DmgVal").text   = str(int(GameManager.player_stats["total_damage"]))
	hud.hide(); win_screen.show()
