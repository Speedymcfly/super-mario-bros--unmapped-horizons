
extends CharacterBody2D

@onready var coin_sprite: AnimatedSprite2D = $CoinSprite

enum CoinType {
	COMMON,
	LUMINA
}
var coin: CoinType

func _ready() -> void:
	coin = [CoinType.COMMON, CoinType.LUMINA].pick_random()
	if coin == CoinType.COMMON:
		coin_sprite.play("Common")
	if coin == CoinType.LUMINA:
		coin_sprite.play("Lumina")
	$StarParticle1.preprocess = 0.0
	$StarParticle2.preprocess = 0.5
	$StarParticle3.preprocess = 1.0
func _physics_process(delta: float) -> void:
	velocity.y = 40
	move_and_slide()
	check_if_below_camera()
func check_if_below_camera() -> void:
	var camera := get_viewport().get_camera_2d()

	if camera == null:
		return

	var screen_size := get_viewport().get_visible_rect().size
	var half_size := (screen_size / camera.zoom) * 0.5
	var cam_center := camera.get_screen_center_position()

	var camera_bottom := cam_center.y + half_size.y

	if global_position.y > camera_bottom + 50.0:
		queue_free()
func _on_coin_collect_body_entered(body: Node2D) -> void:
	if body is player:
		collect()
	if (body is nokoq or body is metto) and body.shell_state == body.Shellstate.Spin:
		collect()
func collect():
	if coin == CoinType.COMMON:
		Globals.coin_amount += 1
		get_tree().get_first_node_in_group("player_ui").update_hud()
		AudioManager.play_sfx(load("res://assets/audio/SFX/CoinCollect.wav"), -5)
		queue_free()
	if coin == CoinType.LUMINA:
		Globals.lumina_coin_amount += 1
		get_tree().get_first_node_in_group("player_ui").update_hud()
		AudioManager.play_sfx(load("res://assets/audio/SFX/LuminaCoinCollect.wav"), -15)
		queue_free()
