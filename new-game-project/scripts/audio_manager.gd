extends Node

var music_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS = 10

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
