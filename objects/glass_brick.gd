class_name glass_brick
extends AnimatableBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var top_check: Area2D = $TopCheck

@export_enum(
	"Regular",
	"Obsidian"
) var version = "Regular"

@export_enum(
	"1",
	"2",
	"3",
	"4",
	"5",
	"6"
) var variant = "1"


func _ready() -> void:
	var new_sprite_frames = load("res://objects/Glass_Brick_%s_%s.tres" % [version, variant])
	animated_sprite_2d.sprite_frames = new_sprite_frames
	animated_sprite_2d.play("default")


func _on_jump_area_body_entered(body: Node2D) -> void:
	if body is player and body.velocity.y > 0 and body.movement_state != body.Movementstate.Dive:
		break_brick()

	elif body is biroron and body.velocity.y > 0:
		break_brick()

	elif (body is nokoq or body is nokob or body is metto) \
	and body.velocity.y > 0 \
	and (
		body.shell_state == body.Shellstate.InShell
		or body.shell_state == body.Shellstate.Spin
	):
		break_brick()


func _on_side_hit_area_body_entered(body: Node2D) -> void:
	if (body is nokoq or body is nokob or body is metto) \
	and body.shell_state == body.Shellstate.Spin:
		break_brick()
	if body is player and body.movement_state == body.Movementstate.Knockback and body.velocity.x != 0:
		break_brick()
	if body is player and body.movement_state == body.Movementstate.Dive and body.velocity.x != 0:
		break_brick()
func _on_pound_area_body_entered(body: Node2D) -> void:
	if body is player and body.movement_state == body.Movementstate.Groundpound:
		break_brick()


func break_brick() -> void:
	# Affect anything sitting on top of the brick.
	for body in top_check.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			if body.has_method("hit"):
				body.hit()
				body.velocity.y -= 100

		elif body.is_in_group("shelled_enemies"):
			if body.has_method("hit"):
				body.shell_state = body.Shellstate.InShell
				body.velocity.y -= 50

		elif body is player or body.is_in_group("powerup"):
			body.velocity.y -= 50

	AudioManager.play_sfx(load("res://assets/audio/SFX/GlassBreak.wav"), -7)
	AudioManager.play_sfx(load("res://assets/audio/SFX/Bump.wav"), -7)
	visible = false
	$CollisionShape2D.disabled = true

	spawn_debris()

	queue_free()


func spawn_debris() -> void:
	var debris_scene: PackedScene

	match version:
		"Regular":
			debris_scene = preload("res://Particles/glass_debris_regular.tscn")
		"Obsidian":
			debris_scene = preload("res://Particles/glass_debris_obsidian.tscn")
	var velocities = [
		Vector2(60, 60),
		Vector2(60, 0),
		Vector2(-60, 60),
		Vector2(-60, 0)
	]

	for velocity in velocities:
		var debris = debris_scene.instantiate()
		get_parent().add_child(debris)

		debris.global_position = global_position
		debris.velocity = velocity
