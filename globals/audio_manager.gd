extends Node


@onready var music_player = AudioStreamPlayer.new()
@onready var sfx_player = AudioStreamPlayer.new()
@onready var mario_voice_player = AudioStreamPlayer.new()
@onready var luigi_voice_player = AudioStreamPlayer.new()
@onready var toad_voice_player = AudioStreamPlayer.new()
@onready var toadette_voice_player = AudioStreamPlayer.new()
@onready var peach_voice_player = AudioStreamPlayer.new()
@onready var daisy_voice_player = AudioStreamPlayer.new()


var voice_toggle = true

func _ready():
	add_child(music_player)
	add_child(sfx_player)
	add_child(mario_voice_player)
	add_child(luigi_voice_player)
	add_child(toad_voice_player)
	add_child(toadette_voice_player)
	add_child(peach_voice_player)
	add_child(daisy_voice_player)



func play_music(stream: AudioStream, volume_db: float = 0.0):
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()

func stop_music():
	music_player.stop()

func play_sfx(stream: AudioStream, volume_db: float = 0.0):
	var temp_player = AudioStreamPlayer.new()
	add_child(temp_player)
	temp_player.stream = stream
	temp_player.volume_db = volume_db
	temp_player.play()
	
	# Free after duration
	var duration = stream.get_length()
	temp_player.call_deferred("queue_free", duration)
	
func play_sfx_2(stream: AudioStream, volume_db: float = 0.0):
	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	sfx_player.play()
	
func mario_voice(stream: AudioStream, volume_db: float = 0.0):
	mario_voice_player.stream = stream
	mario_voice_player.volume_db = volume_db
	mario_voice_player.play()
func luigi_voice(stream: AudioStream, volume_db: float = 0.0):
	luigi_voice_player.stream = stream
	luigi_voice_player.volume_db = volume_db
	luigi_voice_player.play()
func toad_voice(stream: AudioStream, volume_db: float = 0.0):
	toad_voice_player.stream = stream
	toad_voice_player.volume_db = volume_db
	toad_voice_player.play()
func toadette_voice(stream: AudioStream, volume_db: float = 0.0):
	toadette_voice_player.stream = stream
	toadette_voice_player.volume_db = volume_db
	toadette_voice_player.play()
func peach_voice(stream: AudioStream, volume_db: float = 0.0):
	peach_voice_player.stream = stream
	peach_voice_player.volume_db = volume_db
	peach_voice_player.play()
func daisy_voice(stream: AudioStream, volume_db: float = 0.0):
	daisy_voice_player.stream = stream
	daisy_voice_player.volume_db = volume_db
	daisy_voice_player.play() 
func globals():
	if Globals.coin_amount + 1:
		play_sfx(load("res://assets/audio/SFX/CoinCollect.wav"), -5)
