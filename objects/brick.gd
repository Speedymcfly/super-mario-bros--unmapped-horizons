class_name brick
extends AnimatableBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_bumped: AudioStreamPlayer2D = $SFXBumped


@export var breakable := false

@export_enum(
	"Overworld",
	"Underground",
	"Castle",
	"Desert",
	"Snow",
	"Ice",
	"Purple",
	"Gold",
) var location = "Overworld"

@export_enum(
	"1",
	"2",
	"3",
	"4"
) var variant = "1"

func _ready() -> void:
	var new_sprite_frames = load("res://objects/Brick_" + str(location) + "_" + str(variant) + ".tres")
	animated_sprite_2d.sprite_frames = new_sprite_frames

	animated_sprite_2d.play("default")

func _on_jump_area_body_entered(body: Node2D) -> void:
	if body is player and body.velocity.y > 0:
		if body.powerup_state != body.Powerupstate.Small:
			breakable = true
		bump_up()

	if body is nokoq and body.velocity.y > 0:
		breakable = true
		bump_up()

func bump_up():
	if breakable:
		break_brick()
	else:
		sfx_bumped.play()
		$AnimationPlayer.play("bump_up")

func bump_down():
	if breakable:
		break_brick()
	else:
		sfx_bumped.play()
		$AnimationPlayer.play("bump_down")


func break_brick():
	AudioManager.play_sfx(load("res://assets/audio/SFX/Brickbreak.wav"))
	visible = false
	$CollisionShape2D.disabled = true
	spawn_debris()
	queue_free()

func spawn_debris():
	for i in range(4):
		var d1 = preload("res://Particles/brick_debris.tscn").instantiate()
		var d2 = preload("res://Particles/brick_debris.tscn").instantiate()
		var d3 = preload("res://Particles/brick_debris.tscn").instantiate()
		var d4 = preload("res://Particles/brick_debris.tscn").instantiate()
		get_parent().add_child(d1)
		get_parent().add_child(d2)
		get_parent().add_child(d3)
		get_parent().add_child(d4)
		d1.global_position = global_position
		d2.global_position = global_position
		d3.global_position = global_position
		d4.global_position = global_position
		d1.velocity.x += 60
		d1.velocity.y += 60
		d2.velocity.x += 60
		d3.velocity.x += -60
		d3.velocity.y += 60
		d4.velocity.x += -60




func _on_side_hit_area_body_entered(body: Node2D) -> void:
	if (body is nokoq or body is metto) and body.shell_state == body.Shellstate.Spin:
		breakable = true
		bump_up()


func _on_pound_area_body_entered(body: Node2D) -> void:
	if body is player and body.movement_state == body.Movementstate.Groundpound:
		if body.powerup_state != body.Powerupstate.Small:
			breakable = true
		bump_down()
