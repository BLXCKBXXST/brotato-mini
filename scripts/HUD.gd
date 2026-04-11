# HUD.gd
extends CanvasLayer

@onready var hp_bar: ProgressBar = $TopBar/HPSection/HPBar
@onready var hp_label: Label = $TopBar/HPSection/HPLabel
@onready var xp_bar: ProgressBar = $TopBar/XPSection/XPBar
@onready var level_label: Label = $TopBar/XPSection/LevelLabel
@onready var mats_label: Label = $TopBar/MatsLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var timer_label: Label = $TopBar/TimerLabel

func update(wave_time_left: float) -> void:
	var s := GameManager.player_stats
	hp_bar.value = (float(s["hp"]) / float(s["max_hp"])) * 100.0
	hp_label.text = "%d / %d" % [s["hp"], s["max_hp"]]
	xp_bar.value = (float(s["xp"]) / float(s["xp_next"])) * 100.0
	level_label.text = "Lv %d" % s["level"]
	mats_label.text = "💜 %d" % s["materials"]
	wave_label.text = "Волна %d / %d" % [GameManager.wave, GameManager.TOTAL_WAVES]
	timer_label.text = "%ds" % int(maxf(0.0, wave_time_left))
