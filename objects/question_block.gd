class_name qblock
extends AnimatableBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_bump: AudioStreamPlayer2D = $SFXBump
@onready var sfx_coin: AudioStreamPlayer2D = $SFXCoin
@onready var sfx_power_up: AudioStreamPlayer2D = $SFXPowerUp
@export var item:PackedScene = null
@onready var sfx_lumina_coin: AudioStreamPlayer2D = $SFXLuminaCoin
@onready var top_check: Area2D = $TopCheck
@onready var mushroom_scene_file = preload("res://objects/collectables/power-ups/super_mush.tscn")
@onready var mush_retro_scene_file = preload("res://objects/collectables/power-ups/super_mush_retro.tscn")

var empty = false
var coin_amount = 11

@export_enum(
	"Overworld",
	"Underground",
	"Lava",
	"Forest",
	"Castle"
) var variant = "Overworld"

@export_enum(
	"Modern",
	"Retro"
) var version = "Modern"


@export_enum(
	"coin",
	"coins",
	"coin_lumina",
	"coins_lumina",
	"powerup",
	"1up"
) var contents = "coin"


func _ready() -> void:
	var new_sprite_frames = load("res://objects/Question_Block_" + str(variant) + "_" + str(version) + ".tres")
	animated_sprite_2d.sprite_frames = new_sprite_frames

	animated_sprite_2d.play("default")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_jump_area_body_entered(body: Node2D) -> void:
	if ((body is player or body is jack) and body.velocity.y > 0) or ((body is nokoq or body is metto) and body.velocity.y > 0 and (body.shell_state == body.Shellstate.InShell or body.shell_state == body.Shellstate.Spin)):
		sfx_bump.play()
		$AnimationPlayer.play("bump_up")
		above_hit()
		block_item(get_tree().get_first_node_in_group("player"))
	if empty == true:
		animated_sprite_2d.play("empty")
	else:
		animated_sprite_2d.play("default")
	if coin_amount <= 1:
		empty = true
	above_hit()

func _on_side_hit_area_body_entered(body: Node2D) -> void:
	if (body is nokoq or body is metto) and body.shell_state == body.Shellstate.Spin:
		sfx_bump.play()
		$AnimationPlayer.play("bump_up")
		above_hit()
		block_item(get_tree().get_first_node_in_group("player"))
	if empty == true:
		animated_sprite_2d.play("empty")
	else:
		animated_sprite_2d.play("default")
	if coin_amount <= 1:
		empty = true


func block_item(plr: player):
	if empty == false and contents == "coin":
		Globals.coin_amount += 1
		get_tree().get_first_node_in_group("player_ui").update_hud()
		var coin_scene = load("res://objects/collectables/common_coin_visual.tscn").instantiate()
		coin_scene.global_position = Vector2(global_position.x, global_position.y - 16)
		get_tree().current_scene.call_deferred("add_child", coin_scene)
		sfx_coin.play()
		empty = true
	if empty == false and contents == "coins":
		Globals.coin_amount += 1
		get_tree().get_first_node_in_group("player_ui").update_hud()
		var coin_scene = load("res://objects/collectables/common_coin_visual.tscn").instantiate()
		coin_scene.global_position = Vector2(global_position.x, global_position.y - 16)
		get_tree().current_scene.call_deferred("add_child", coin_scene)
		sfx_coin.play()
		coin_amount -= 1
	elif empty == false and contents == "lumina_coin":
		Globals.lumina_coin_amount += 1
		get_tree().get_first_node_in_group("player_ui").update_hud()
		var coin_scene = load("res://objects/collectables/lumina_coin_visual.tscn").instantiate()
		coin_scene.global_position = Vector2(global_position.x, global_position.y - 16)
		get_tree().current_scene.call_deferred("add_child", coin_scene)
		sfx_lumina_coin.play()
		empty = true
	elif empty == false and contents == "lumina_coins":
		Globals.lumina_coin_amount += 1
		var coin_scene = load("res://objects/collectables/lumina_coin_visual.tscn").instantiate()
		coin_scene.global_position = Vector2(global_position.x, global_position.y - 16)
		get_tree().current_scene.call_deferred("add_child", coin_scene)
		sfx_lumina_coin.play()
		coin_amount -= 1
	elif empty == false and item != null:
		if contents == "powerup":
			if plr.powerup_state == plr.Powerupstate.Small:
				var final_mush = mushroom_scene_file if version == "Modern" else mush_retro_scene_file
				var item_scene = mushroom_scene_file.instantiate()
				item_scene.global_position = Vector2(global_position.x, global_position.y - 16)
				get_tree().current_scene.call_deferred("add_child", item_scene)
			else:
				var item_scene = item.instantiate()
				item_scene.global_position = Vector2(global_position.x, global_position.y - 16)
				get_tree().current_scene.call_deferred("add_child", item_scene)
		else:
			var item_scene = item.instantiate()
			item_scene.global_position = Vector2(global_position.x, global_position.y - 16)
			get_tree().current_scene.call_deferred("add_child", item_scene)
		sfx_power_up.play()
		empty = true



func above_hit():
	for body in top_check.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			if body.has_method("hit"):
				body.hit()
		if body.is_in_group("shelled_enemies"):
			if body.has_method("hit"):
				body.shell_state = body.Shellstate.InShell
				body.velocity.y -= 50
		if body is player or body.is_in_group("powerup"):
			body.velocity.y -= 50
