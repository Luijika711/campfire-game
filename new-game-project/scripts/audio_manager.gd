extends Node

var music_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS = 10
const SAMPLE_RATE = 22050

var sfx_library: Dictionary = {}

func _ready():
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	# Create SFX players pool
	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

	# Generate procedural SFX library
	_generate_sfx_library()

func play_music(stream: AudioStream, fade_duration: float = 1.0) -> void:
	if music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_duration)
		tween.finished.connect(func():
			music_player.stream = stream
			music_player.play()
			var fade_in = create_tween()
			fade_in.tween_property(music_player, "volume_db", 0, fade_duration)
		)
	else:
		music_player.stream = stream
		music_player.volume_db = -80
		music_player.play()
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", 0, fade_duration)

func stop_music(fade_duration: float = 1.0) -> void:
	if music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_duration)
		tween.finished.connect(func(): music_player.stop())

func play_sfx(stream: AudioStream, pitch_random: float = 0.0) -> void:
	if stream == null:
		return
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			if pitch_random > 0:
				player.pitch_scale = randf_range(1.0 - pitch_random, 1.0 + pitch_random)
			else:
				player.pitch_scale = 1.0
			player.play()
			return

func play_named_sfx(sfx_name: String, pitch_random: float = 0.0) -> void:
	if sfx_library.has(sfx_name):
		play_sfx(sfx_library[sfx_name], pitch_random)

# --- Procedural SFX Generation ---

func _generate_sfx_library() -> void:
	sfx_library["gun_shoot"] = _gen_gun_shoot()
	sfx_library["laser_shoot"] = _gen_laser_shoot()
	sfx_library["sword_swing"] = _gen_sword_swing()
	sfx_library["bullet_impact"] = _gen_bullet_impact()
	sfx_library["jump"] = _gen_jump()
	sfx_library["dash"] = _gen_dash()
	sfx_library["coin_pickup"] = _gen_coin_pickup()
	sfx_library["player_hit"] = _gen_player_hit()
	sfx_library["player_death"] = _gen_player_death()
	sfx_library["enemy_hit"] = _gen_enemy_hit()
	sfx_library["enemy_death"] = _gen_enemy_death()
	sfx_library["weapon_switch"] = _gen_weapon_switch()

func _make_wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav

func _noise(i: int) -> float:
	var n = sin(float(i) * 12.9898 + 78.233) * 43758.5453
	return (n - floor(n)) * 2.0 - 1.0

func _write_sample(data: PackedByteArray, index: int, value: float) -> void:
	var s = int(clampf(value * 32767.0, -32768.0, 32767.0))
	data[index * 2] = s & 0xFF
	data[index * 2 + 1] = (s >> 8) & 0xFF

func _gen_gun_shoot() -> AudioStreamWAV:
	var duration = 0.12
	var num = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(num * 2)
	for i in range(num):
		var t = float(i) / SAMPLE_RATE
		var env = pow(1.0 - t / duration, 3.0)
		var sample = _noise(i) * 0.8 + sin(t * 180.0 * TAU) * 0.2
		_write_sample(data, i, sample * env * 0.9)
	return _make_wav(data)

func _gen_laser_shoot() -> AudioStreamWAV:
	var duration = 0.25
	var num = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(num * 2)
	for i in range(num):
		var t = float(i) / SAMPLE_RATE
		var env = pow(1.0 - t / duration, 1.5)
		var freq = lerpf(1200.0, 300.0, t / duration)
		var sample = sin(t * freq * TAU) * 0.6 + sin(t * freq * 2.0 * TAU) * 0.2
		_write_sample(data, i, sample * env * 0.7)
	return _make_wav(data)

func _gen_sword_swing() -> AudioStreamWAV:
	var duration = 0.15
	var num = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(num * 2)
	for i in range(num):
		var t = float(i) / SAMPLE_RATE
		var env = sin(t / duration * PI)
		var sample = _noise(i) * 0.5 + sin(t * 400.0 * TAU) * 0.3
		_write_sample(data, i, sample * env * 0.6)
	return _make_wav(data)

func _gen_bullet_impact() -> AudioStreamWAV:
	var duration = 0.08
	var num = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(num * 2)
	for i in range(num):
		var t = float(i) / SAMPLE_RATE
		var env = pow(1.0 - t / duration, 4.0)
		var sample = _noise(i) * 0.6 + sin(t * 100.0 * TAU) * 0.4
		_write_sample(data, i, sample * env * 0.7)
	return _make_wav(data)

func _gen_jump() -> AudioStreamWAV:
	var duration = 0.12
	var num = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(num * 2)
	for i in range(num):
		var t = float(i) / SAMPLE_RATE
		var env = pow(1.0 - t / duration, 1.5)
		var freq = lerpf(200.0, 600.0, t / duration)
		_write_sample(data, i, sin(t * freq * TAU) * env * 0.5)
	return _make_wav(data)

func _gen_dash() -> AudioStreamWAV:
	var duration = 0.15
	var num = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(num * 2)
	for i in range(num):
		var t = float(i) / SAMPLE_RATE
		var env = sin(t / duration * PI)
		var freq = lerpf(300.0, 800.0, t / duration)
		var sample = sin(t * freq * TAU) * 0.3 + _noise(i) * 0.3
		_write_sample(data, i, sample * env * 0.5)
	return _make_wav(data)

func _gen_coin_pickup() -> AudioStreamWAV:
	var duration = 0.2
	var num = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(num * 2)
	for i in range(num):
		var t = float(i) / SAMPLE_RATE
		var env = pow(1.0 - t / duration, 1.0)
		var freq = 880.0 if t < 0.1 else 1100.0
		_write_sample(data, i, sin(t * freq * TAU) * env * 0.4)
	return _make_wav(data)

func _gen_player_hit() -> AudioStreamWAV:
	var duration = 0.1
	var num = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(num * 2)
	for i in range(num):
		var t = float(i) / SAMPLE_RATE
		var env = pow(1.0 - t / duration, 3.0)
		var sample = _noise(i) * 0.5 + sin(t * 150.0 * TAU) * 0.5
		_write_sample(data, i, sample * env * 0.6)
	return _make_wav(data)

func _gen_player_death() -> AudioStreamWAV:
	var duration = 0.5
	var num = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(num * 2)
	for i in range(num):
		var t = float(i) / SAMPLE_RATE
		var env = pow(1.0 - t / duration, 1.0)
		var freq = lerpf(400.0, 80.0, t / duration)
		var sample = sin(t * freq * TAU) * 0.5 + _noise(i) * 0.2
		_write_sample(data, i, sample * env * 0.6)
	return _make_wav(data)

func _gen_enemy_hit() -> AudioStreamWAV:
	var duration = 0.08
	var num = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(num * 2)
	for i in range(num):
		var t = float(i) / SAMPLE_RATE
		var env = pow(1.0 - t / duration, 3.0)
		var sample = _noise(i) * 0.6 + sin(t * 200.0 * TAU) * 0.4
		_write_sample(data, i, sample * env * 0.5)
	return _make_wav(data)

func _gen_enemy_death() -> AudioStreamWAV:
	var duration = 0.4
	var num = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(num * 2)
	for i in range(num):
		var t = float(i) / SAMPLE_RATE
		var env = pow(1.0 - t / duration, 1.2)
		var freq = lerpf(300.0, 60.0, t / duration)
		var sample = sin(t * freq * TAU) * 0.5 + _noise(i) * 0.3
		_write_sample(data, i, sample * env * 0.5)
	return _make_wav(data)

func _gen_weapon_switch() -> AudioStreamWAV:
	var duration = 0.06
	var num = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(num * 2)
	for i in range(num):
		var t = float(i) / SAMPLE_RATE
		var env = pow(1.0 - t / duration, 2.0)
		_write_sample(data, i, sin(t * 700.0 * TAU) * env * 0.3)
	return _make_wav(data)
