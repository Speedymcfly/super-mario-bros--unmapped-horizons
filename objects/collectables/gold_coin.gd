extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collect_2d: CollisionShape2D = $Collect2D
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
	if body is player or body is brick or body is qblock:
		collect()
	if (body is nokoq or body is metto) and body.shell_state == body.Shellstate.Spin:
		collect()
	if body.is_in_group("frozen_carriable"):
		collect()


	if body is player:
		if variant == "hidden_common":
			if hide_coin:
				hide_coin = false
				timer.start()
				collect_2d.set_deferred("disabled", true)
				$AnimatedSprite2D.hide()
		if variant == "hidden_lumina":
			if hide_coin:
				hide_coin = false
				timer.start()
				collect_2d.set_deferred("disabled", true)
				$AnimatedSprite2D.hide()
func collect():
	if variant == "common":
		Globals.coin_amount += 1
		get_tree().get_first_node_in_group("player_ui").update_hud()
		AudioManager.play_sfx(load("res://assets/audio/SFX/CoinCollect.wav"), -5)
		queue_free()
	if variant == "lumina":
		Globals.lumina_coin_amount += 1
		get_tree().get_first_node_in_group("player_ui").update_hud()
		AudioManager.play_sfx(load("res://assets/audio/SFX/LuminaCoinCollect.wav"), -15)
		queue_free()
func _on_timer_timeout() -> void:
	timer.stop()
	animated_sprite_2d.animation = "default"
	if variant == "hidden_common":
		_ready()
		variant = "common"
	if variant == "hidden_lumina":
		_ready()
		variant = "lumina"
	collect_2d.set_deferred("disabled", false)
	$AnimatedSprite2D.show()
