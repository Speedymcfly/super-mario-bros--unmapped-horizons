extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

@export_enum(
	"common",
	"lumina",
	"hidden_common",
	"hidden_lumina"
) var variant = "common"

var hide_coin = true

func _ready() -> void:
	var new_sprite_frames = load("res://objects/collectables/gold_coin_" + str(variant) + ".tres")
	animated_sprite_2d.sprite_frames = new_sprite_frames
	animated_sprite_2d.play()



func _on_collect_body_entered(body: Node2D) -> void:
	if (body is player or body is brick or body is qblock or ((body is nokoq or metto) and body.shell_state == body.Shellstate.Spin)):
		if variant == "common":
			Globals.coin_amount += 1
			get_tree().get_first_node_in_group("player_ui").update_hud()
			AudioManager.play_sfx(load("res://assets/audio/SFX/CoinCollect.wav"))
			queue_free()
		if variant == "lumina":
			Globals.lumina_coin_amount += 1
			get_tree().get_first_node_in_group("player_ui").update_hud()
			AudioManager.play_sfx(load("res://assets/audio/SFX/LuminaCoinCollect.wav"))
			queue_free()
	if body is player:
		if variant == "hidden_common":
			if hide_coin == true:
				hide_coin = false
				timer.start()
				$AnimatedSprite2D.hide()
		if variant == "hidden_lumina":
			if hide_coin == true:
				hide_coin = false
				timer.start()
				$AnimatedSprite2D.hide()


func _on_timer_timeout() -> void:
	timer.stop()
	animated_sprite_2d.animation = "default"
	if variant == "hidden_common":
		_ready()
		variant = "common"
	if variant == "hidden_lumina":
		_ready()
		variant = "lumina"
	$AnimatedSprite2D.show()
