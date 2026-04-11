# HUD.gd
extends CanvasLayer

@onready var hp_bar: ProgressBar = $TopBar/HPSection/HPBar
@onready var hp_label: Label = $TopBar/HPSection/HPLabel
@onready var xp_bar: ProgressBar = $TopBar/XPSection/XPBar
@onready var level_label: Label = $TopBar/XPSection/LevelLabel
@onready var mats_label: Label = $TopBar/MatsLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var timer_label: Label = $TopBar/TimerLabel

func update_hud(time_left: float) -> void:
	var s: Dictionary = GameManager.player_stats
	hp_bar.max_value = float(s["max_hp"])
	hp_bar.value = float(s["hp"])
	hp_label.text = "%d / %d" % [int(s["hp"]), int(s["max_hp"])]
	xp_bar.max_value = float(s["xp_next"])
	xp_bar.value = float(s["xp"])
	level_label.text = "Lv %d" % int(s["level"])
	mats_label.text = "💜 %d" % int(s["materials"])
	wave_label.text = "Волна %d / %d" % [GameManager.wave, GameManager.TOTAL_WAVES]
	timer_label.text = "%ds" % int(time_left)
