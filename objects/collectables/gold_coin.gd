extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export_enum(
	"common",
	"lumina",
	"hidden_common",
	"hidden_lumina"
) var variant = "common"

func _ready() -> void:
	var new_sprite_frames = load("res://objects/collectables/gold_coin_" + str(variant) + ".tres")
	animated_sprite_2d.sprite_frames = new_sprite_frames
	animated_sprite_2d.play()

func _on_collect_body_entered(body: Node2D) -> void:
	if (body is player or body is brick or body is qblock or (body is nokoq and body.shell_state == body.Shellstate.Spin)) and (variant == "common" or variant == "lumina"):
		if variant == "common":
			Globals.coin_amount += 1
			AudioManager.play_sfx(load("res://assets/audio/SFX/CoinCollect.wav"))
		if variant == "lumina":
			Globals.lumina_coin_amount += 1
			AudioManager.play_sfx(load("res://assets/audio/SFX/LuminaCoinCollect.wav"))
		queue_free()
	if body is player:
		if variant == "hidden_common":
			pass
		if variant == "hidden_lumina":
			pass
