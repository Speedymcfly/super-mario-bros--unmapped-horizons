class_name qblock
extends AnimatableBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_bump: AudioStreamPlayer2D = $SFXBump
@onready var sfx_coin: AudioStreamPlayer2D = $SFXCoin
@onready var sfx_power_up: AudioStreamPlayer2D = $SFXPowerUp
@export var item:PackedScene = null
@onready var sfx_lumina_coin: AudioStreamPlayer2D = $SFXLuminaCoin


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
	"powerup"
) var contents = "coin"


func _ready() -> void:
	var new_sprite_frames = load("res://objects/Question_Block_" + str(variant) + "_" + str(version) + ".tres")
	animated_sprite_2d.sprite_frames = new_sprite_frames

	animated_sprite_2d.play("default")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_jump_area_body_entered(body: Node2D) -> void:
	if body is player and body.velocity.y > 0:
		sfx_bump.play()
		$AnimationPlayer.play("bump_up")
		animated_sprite_2d.play("empty")
		if empty == false and contents == "coin":
			Globals.coin_amount += 1
			var coin_scene = load("res://objects/collectables/common_coin_visual.tscn").instantiate()
			coin_scene.global_position = Vector2(global_position.x, global_position.y - 16)
			get_tree().current_scene.call_deferred("add_child", coin_scene)
			sfx_coin.play()
			empty = true
		if empty == false and contents == "coins":
			Globals.coin_amount += 1
			var coin_scene = load("res://objects/collectables/common_coin_visual.tscn").instantiate()
			coin_scene.global_position = Vector2(global_position.x, global_position.y - 16)
			get_tree().current_scene.call_deferred("add_child", coin_scene)
			sfx_coin.play()
			coin_amount -= 1
		elif empty == false and contents == "lumina_coin":
			Globals.lumina_coin_amount += 1
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
			var item_scene = item.instantiate()
			item_scene.global_position = Vector2(global_position.x, global_position.y - 16)
			get_tree().current_scene.call_deferred("add_child", item_scene)
			sfx_power_up.play()
			empty = true
	if empty == true:
		animated_sprite_2d.play("empty")
	else:
		animated_sprite_2d.play("default")
	if coin_amount <= 1:
		empty = true
