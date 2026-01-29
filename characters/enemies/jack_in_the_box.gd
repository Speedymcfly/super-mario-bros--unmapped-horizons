class_name jack
extends CharacterBody2D

@onready var jack_in_the_box: jack = $"."
@onready var disguise: AnimatedSprite2D = $Disguise
@onready var true_form: AnimatedSprite2D = $TrueForm
@onready var box_out_collision: CollisionShape2D = $BoxOutCollision
@onready var box_collision: CollisionShape2D = $Box/BoxCollision
@onready var jump_area: Area2D = $JumpArea
@onready var hit_detect: Area2D = $HitDetect
@onready var hit_shape: CollisionShape2D = $HitDetect/HitShape
@onready var sfx_bumped: AudioStreamPlayer2D = $SFXBumped
@onready var sfx_bounce: AudioStreamPlayer2D = $SFXBounce
@onready var sfx_stomped: AudioStreamPlayer2D = $SFXStomped



var disguised = true


var hurt = false

@export_enum(
	"Overworld",
	"Underground",
	"Lava",
	"Forest",
	"Castle",
	"Rotating",
) var box = "Overworld"

@export_enum(
	"QBlock",
	"RBlock",
) var variant = "QBlock"

enum Springstate{
	disguised,
	coiled,
	sprung
}
var spring_state:Springstate = Springstate.coiled

var spring_timer = 0

func _ready() -> void:
	var new_box_frames = load("res://characters/enemies/Box_" + str(box) + ".tres")
	disguise.sprite_frames = new_box_frames

	var new_form_frames = load("res://characters/enemies/Jack_" + str(variant) + ".tres")
	true_form.sprite_frames = new_form_frames

	disguise.play("default")

	if disguised == true:
		disguise.show()
		true_form.hide()
		hit_detect.set_deferred("disabled", true)
		box_out_collision.set_deferred("disabled", true)
	else:
		disguise.hide()
		true_form.show()


func _physics_process(delta: float) -> void:


	var plr = get_tree().get_first_node_in_group("player")

	var sign_value = sign(plr.global_position.x - global_position.x)
	var direction = sign_value

	if hurt and not Globals.is_onscreen(global_position):
		queue_free()

	if hurt == true:
		true_form.rotation += .1
		velocity.y += 8
		move_and_slide()
	elif hurt == false:
		move_and_slide()



	if disguised == true:
		spring_state == Springstate.disguised
		hit_shape.disabled = true
	else:
		hit_shape.disabled = false
	if spring_state == Springstate.coiled:
		true_form.play("coiled")
	if spring_state == Springstate.sprung:
		true_form.play("sprung")

	if not is_on_floor() and disguised == false:
		velocity.y += 10

	if is_on_floor() and disguised == false and spring_timer <= 20:
		spring_state = Springstate.coiled
		spring_timer += 1
		velocity.x = 0
	if is_on_floor() and spring_timer == 10:
		velocity.y = -200
		velocity.x = 40 * direction
		spring_timer =0
		sfx_bounce.play()
	if not is_on_floor() and disguised == false:
		spring_state = Springstate.sprung


func _on_jump_area_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if body is player and body.velocity.y > 0 and disguised == true:
		disguised = false
		sfx_bumped.play()
		velocity.y = -125
		if disguised == true:
			$Disguise.show()
			$TrueForm.hide()
			box_out_collision.set_deferred("disabled", true)
			box_collision.set_deferred("disabled", false)
		else:
			$Disguise.hide()
			$TrueForm.show()
			box_out_collision.set_deferred("disabled", false)
			box_collision.set_deferred("disabled", true)


func _on_stomp_detect_body_entered(body: Node2D) -> void:
	if body is player and body.velocity.y > 0 and disguised == false:
		hit()
		sfx_stomped.play()
		if Input.is_action_pressed("jump"):
			body.velocity.y = -400
		else:
			body.velocity.y = -200
		var hurt = true




func _on_hit_detect_body_entered(body: Node2D) -> void:
	if body is nokoq and body.shell_state == body.Shellstate.Spin:
		hit()
		sfx_stomped.play()
		if Input.is_action_pressed("jump"):
			body.velocity.y = -400
		else:
			body.velocity.y = -200
		var hurt = true


func hit():
	true_form.flip_v = true
	box_out_collision.set_deferred("disabled", true)
	box_collision.set_deferred("disabled", true)
	jump_area.set_deferred("disabled", true)
	hit_detect.set_deferred("disabled", true)
