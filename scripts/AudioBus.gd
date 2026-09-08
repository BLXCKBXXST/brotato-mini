# AudioBus.gd — Autoload. Звуки из assets/sfx/*.mp3, фолбэк — процедурные тоны.
extends Node

const POOL_SIZE := 10
const SAMPLE_RATE := 22050
const SFX_DIR := "res://assets/sfx/"

const SFX_IDS := [
	"pistol_fire", "shotgun_fire", "sniper_fire", "smg_fire", "flamer_fire", "minigun_fire",
	"enemy_hit", "enemy_die", "player_hurt", "boss_die", "level_up", "combine", "buy",
]

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)
	for id in SFX_IDS:
		_streams[id] = _load_sfx(id)

func play(id: String) -> void:
	if not _streams.has(id):
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	p.stream = _streams[id]
	p.play()

# Берём mp3 из assets/sfx/, если файла нет — генерируем процедурный тон как раньше
func _load_sfx(id: String) -> AudioStream:
	var path := SFX_DIR + id + ".mp3"
	if ResourceLoader.exists(path):
		var s := load(path)
		if s is AudioStream:
			return s
	return _make_procedural(id)

func _make_procedural(id: String) -> AudioStream:
	match id:
		"pistol_fire":  return _make_tone(820.0, 0.06, 0.18)
		"shotgun_fire": return _make_noise(0.14, 0.45)
		"sniper_fire":  return _make_tone(240.0, 0.22, 0.30)
		"smg_fire":     return _make_tone(1200.0, 0.04, 0.12)
		"flamer_fire":  return _make_noise(0.08, 0.22)
		"minigun_fire": return _make_tone(1000.0, 0.04, 0.13)
		"enemy_hit":    return _make_tone(440.0, 0.05, 0.10)
		"enemy_die":    return _make_noise(0.18, 0.32)
		"player_hurt":  return _make_tone(180.0, 0.18, 0.45)
		"boss_die":     return _make_noise(0.55, 0.60)
		"level_up":     return _make_tone(660.0, 0.20, 0.30)
		"combine":      return _make_tone(880.0, 0.16, 0.28)
		"buy":          return _make_tone(520.0, 0.08, 0.20)
	return _make_tone(440.0, 0.08, 0.15)

func _make_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t * 14.0)
		var s: float = sin(t * freq * TAU) * env * volume
		var v: int = int(clampf(s, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream

func _make_noise(duration: float, volume: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t * 8.0)
		var s: float = randf_range(-1.0, 1.0) * env * volume
		var v: int = int(clampf(s, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream
