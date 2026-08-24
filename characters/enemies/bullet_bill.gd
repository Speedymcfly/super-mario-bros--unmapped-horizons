class_name killer
extends CharacterBody2D
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var cloud_spawn_timer: Timer = $CloudSpawnTimer
@onready var cloud_wait_timer: Timer = $CloudWaitTimer
@onready var sfx_jet: AudioStreamPlayer2D = $SFXJet
@onready var on_screen_notifier: VisibleOnScreenNotifier2D = $OnScreenNotifier
@onready var bill_flame: AnimatedSprite2D = $BillFlame

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
@export_enum(
	"Bullet",
	"Bullseye",
	"Nimbus"
) var variant = "Bullet"

@export_enum(
	"Left",
	"Right",
	"Up",
	"Down"
) var direction = "Left"

func _ready() -> void:
	var new_sprite_frames = load("res://characters/enemies/" + str(variant) + "_Bill.tres")
	sprite_2d.sprite_frames = new_sprite_frames
	sprite_2d.play("default")
	if variant == "Nimbus" and !frozen:
		cloud_create()
		cloud_wait_timer.start()
		$BillFlame.hide()

func _physics_process(delta: float) -> void:
	move_and_slide()
	if direction == "Left":
		velocity.x = -75
	if direction == "Right":
		velocity.x = 75
	if variant != "Nimbus" and !sfx_jet.playing:
		sfx_jet.play()
	if on_screen_notifier.is_on_screen():
		sfx_jet.volume_db = 5
	else:
		sfx_jet.volume_db = -20

func cloud_create():
	var cloud = preload("res://objects/bill_cloud_platform.tscn").instantiate()
	get_parent().add_child(cloud)
	cloud.global_position = global_position
	cloud.z_index = -1


func _on_cloud_spawn_timer_timeout() -> void:
	cloud_create()
	cloud_wait_timer.start()
func _on_cloud_wait_timer_timeout() -> void:
	cloud_spawn_timer.start()

func _on_hurt_player_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_hit_detect_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
