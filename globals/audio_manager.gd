extends Node


@onready var music_player = AudioStreamPlayer.new()
@onready var sfx_player = AudioStreamPlayer.new()

var voice_toggle = true

func _ready():
	add_child(music_player)
	add_child(sfx_player)


func play_music(stream: AudioStream, volume_db: float = 0.0):
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()

func play_sfx(stream: AudioStream, volume_db: float = 0.0):
	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	sfx_player.play()

func stop_music():
	music_player.stop()

func globals():
	if Globals.coin_amount + 1:
		AudioManager.play_sfx(load("res://assets/audio/SFX/CoinCollect.wav"))
