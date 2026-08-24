class_name nokoshellb
extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hurt_shape: CollisionShape2D = $HurtPlayer/HurtShape
@onready var stomp_shape: CollisionShape2D = $StompDetect/StompShape
@onready var hit_shape: CollisionShape2D = $HitDetect/HitShape

@onready var sfx_bumped: AudioStreamPlayer2D = $SFXBumped
@onready var sfx_hit: AudioStreamPlayer2D = $SFXHit
@onready var sfx_knock: AudioStreamPlayer2D = $SFXKnock

var direction = -1
var turning = false
var frozen = false
var frozen_held = false
var holder: player = null
var throw_speed := 260.0
var slide_friction := 1.0
enum Freezestate{
	Unfrozen,
	Still,
	Held,
	Moving,
}
var freeze_state:Freezestate=Freezestate.Unfrozen
var hurt = false
var held = false
var delay = 10
@export_enum(
	"Green",
	"Red",
	"Blue",
	"Yellow",
	"Purple",
	"Gold"
) var colour = "Green"
enum Shellstate{
	Still,
	Spin,
}
var shell_state:Shellstate=Shellstate.Still


func _ready() -> void:
	var new_sprite_frames = load("res://objects/Noko_Shell_" + str(colour) + "_B.tres")
	animated_sprite_2d.sprite_frames = new_sprite_frames
	if shell_state == Shellstate.Spin:
		held = false
func _physics_process(delta: float) -> void:
	pass
	if shell_state == Shellstate.Spin and !frozen:
		animated_sprite_2d.play("spin")
		velocity.x = 150 * direction
		if is_on_wall():
			sfx_bumped.play()
			direction *= -1
			velocity.x = 150 * direction

func _on_hurt_player_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_stomp_detect_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_bump_detect_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_hit_detect_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
