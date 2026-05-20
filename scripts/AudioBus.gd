# AudioBus.gd — Autoload. Процедурные звуки через AudioStreamWAV в памяти.
extends Node

const POOL_SIZE := 10
const SAMPLE_RATE := 22050

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
	_streams["pistol_fire"]  = _make_tone(820.0, 0.06, 0.18)
	_streams["shotgun_fire"] = _make_noise(0.14, 0.45)
	_streams["sniper_fire"]  = _make_tone(240.0, 0.22, 0.30)
	_streams["smg_fire"]     = _make_tone(1200.0, 0.04, 0.12)
	_streams["flamer_fire"]  = _make_noise(0.08, 0.22)
	_streams["minigun_fire"] = _make_tone(1000.0, 0.04, 0.13)
	_streams["enemy_hit"]    = _make_tone(440.0, 0.05, 0.10)
	_streams["enemy_die"]    = _make_noise(0.18, 0.32)
	_streams["player_hurt"]  = _make_tone(180.0, 0.18, 0.45)
	_streams["boss_die"]     = _make_noise(0.55, 0.60)
	_streams["level_up"]     = _make_tone(660.0, 0.20, 0.30)
	_streams["combine"]      = _make_tone(880.0, 0.16, 0.28)
	_streams["buy"]          = _make_tone(520.0, 0.08, 0.20)

func play(id: String) -> void:
	if not _streams.has(id):
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	p.stream = _streams[id]
	p.play()

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
