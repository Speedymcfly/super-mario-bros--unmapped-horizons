class_name biroron
extends CharacterBody2D

@onready var jack_in_the_box: biroron = $"."
@onready var disguise: AnimatedSprite2D = $Disguise
@onready var true_form: AnimatedSprite2D = $TrueForm
@onready var box_out_collision: CollisionShape2D = $BoxOutCollision
@onready var box_collision: CollisionShape2D = $Box/BoxCollision
@onready var hurt_shape: CollisionShape2D = $HurtPlayer/HurtShape
@onready var jump_area: Area2D = $JumpArea
@onready var jump_collision: CollisionShape2D = $JumpArea/JumpCollision
@onready var hit_detect: Area2D = $HitDetect
@onready var hit_shape: CollisionShape2D = $HitDetect/HitShape
@onready var sfx_bumped: AudioStreamPlayer2D = $SFXBumped
@onready var sfx_bounce: AudioStreamPlayer2D = $SFXBounce
@onready var sfx_stomped: AudioStreamPlayer2D = $SFXStomped
@onready var ice_collision_big: CollisionShape2D = $IceCollisionBig
@onready var ice_collision_bigger: CollisionShape2D = $IceCollisionBigger
@onready var freeze_timer: Timer = $FreezeTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var screen_enabler: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D

var direction = 0
var hurt = false
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

@export_enum(
	"Closed",
	"Opened",
) var boxstate = "Closed"

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


	if boxstate == "Closed":
		disguise.show()
		true_form.hide()
		hit_detect.set_deferred("disabled", true)
		box_out_collision.set_deferred("disabled", true)
	else:
		disguise.hide()
		true_form.show()

	add_to_group("enemies")
	ice_collision_big.set_deferred("disabled", true)
	ice_collision_bigger.set_deferred("disabled", true)
	$FrozenSpriteBig.hide()
	$FrozenSpriteBigger.hide()
func _physics_process(delta: float) -> void:

	var plr = get_tree().get_first_node_in_group("player")
	var sign_value = sign(plr.global_position.x - global_position.x)
	direction = sign_value

	if hurt and not Globals.is_onscreen(global_position):
		queue_free()
	if frozen and freeze_timer.time_left <= 4:
		animation_player.play("freeze_shake")
	if hurt:
		true_form.rotation += .1
		velocity.y += 8
		move_and_slide()
	elif !hurt:
		move_and_slide()



	if boxstate == "Closed":
		spring_state = Springstate.disguised
		hit_shape.disabled = true
		add_to_group("terrain")
	else:
		hit_shape.disabled = false
		remove_from_group("terrain")
	if spring_state == Springstate.coiled:
		true_form.play("coiled")
	if spring_state == Springstate.sprung:
		true_form.play("sprung")
	if not is_on_floor() and boxstate == "Opened":
		velocity.y += 10
		velocity.y = clamp(velocity.y, -INF, 500)
	if frozen:
		handle_frozen_state(delta)
		return
	if is_on_floor() and boxstate == "Opened" and spring_timer <= 20 and !frozen:
		spring_state = Springstate.coiled
		spring_timer += 1
		velocity.x = 0
	if is_on_floor() and spring_timer == 10 and !frozen:
		velocity.y = -200
		velocity.x = 40 * direction
		spring_timer =0
		sfx_bounce.play()
	if not is_on_floor() and boxstate == "Opened":
		spring_state = Springstate.sprung
func _on_jump_area_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if ((body is player or body is biroron) and body.velocity.y > 0) or ((body is nokoq or body is nokob or body is metto) and body.velocity.y > 0 and (body.shell_state == body.Shellstate.InShell or body.shell_state == body.Shellstate.Spin)) and boxstate == "Closed":
		boxstate = "Opened"
		_ready()
		sfx_bumped.play()
		velocity.y = -125
		if boxstate == "Closed":
			$Disguise.show()
			$TrueForm.hide()
			box_out_collision.set_deferred("disabled", true)
			box_collision.set_deferred("disabled", false)
			jump_collision.set_deferred("disabled", false)
		else:
			$Disguise.hide()
			$TrueForm.show()
			box_out_collision.set_deferred("disabled", false)
			box_collision.set_deferred("disabled", true)
			jump_collision.set_deferred("disabled", true)
func _on_stomp_detect_body_entered(body: Node2D) -> void:
	if hurt:
		return
	if body is player and boxstate == "Opened" and body.velocity.y > 0 and body.global_position.y < global_position.y:
		hit()
		sfx_stomped.play()
		if Input.is_action_pressed("jump"):
			body.velocity.y = -400
		else:
			body.velocity.y = -200




func _on_hit_detect_body_entered(body: Node2D) -> void:
	if (body is nokoq or body is nokob or body is metto) and body.shell_state == body.Shellstate.Spin:
		if frozen:
			unfreeze()
			_ready()
		hit()
		sfx_stomped.play()
		if Input.is_action_pressed("jump"):
			body.velocity.y = -400
		else:
			body.velocity.y = -200

	if (body is nokoq or body is nokob or body is metto) and body.shell_state == body.Shellstate.InShell and body.hold_comp.is_held == true and (body.hold_comp.holder.velocity.x != 0 or body.hold_comp.holder.velocity.y != 0):
		if frozen:
			unfreeze()
			_ready()
		hit()
		body.hit()
		body.hold_comp.is_held = false
		body.hold_comp.holder.current_held_obj = null
	if body != self and body.is_in_group("frozen_carriable") and body.velocity.x != 0:
		if frozen:
			unfreeze()
			_ready()
		hit()
	if body is fireballplr:
		body.hit()
		if frozen:
			unfreeze()
			AudioManager.play_sfx(load("res://assets/audio/SFX/IceMelt.wav"), -10)
			_ready()
	if body is iceballplr and !hurt and spring_state != Springstate.disguised:
		if !frozen:
			freeze()
		freeze_timer.start()
		body.hit()
func hit():
	hurt = true
	box_out_collision.set_deferred("disabled", true)
	box_collision.set_deferred("disabled", true)
	jump_area.set_deferred("disabled", true)
	hit_detect.set_deferred("disabled", true)
	hurt_shape.set_deferred("disabled", true)

func _on_hurt_player_body_entered(body: Node2D) -> void:
	var plr = get_tree().get_first_node_in_group("player")
	if plr.global_position.y < global_position.y -2.5: 
		return
	if body is player and not body.damaged and not body.invincible:
		body.damage()
func handle_frozen_state(delta):
	match freeze_state:
		Freezestate.Still:
			velocity.x = move_toward(velocity.x, 0, slide_friction)
			if !is_on_floor():
				velocity.y += 10
			move_and_slide()
		Freezestate.Held:
			velocity = Vector2.ZERO
			if holder:
				if holder.character == holder.Character.Mario:
					if holder.powerup_state == holder.Powerupstate.Small:
						global_position = holder.global_position + Vector2(0, -8)
					else:
						global_position = holder.global_position + Vector2(0, -19)
				elif holder.character == holder.Character.Luigi:
					if holder.powerup_state == holder.Powerupstate.Small:
						global_position = holder.global_position + Vector2(0, -10)
					else:
						global_position = holder.global_position + Vector2(0, -22)
		Freezestate.Moving:
			if !is_on_floor():
				velocity.y += 20
			else:
				velocity.y = 0
			move_and_slide()
			for i in range(get_slide_collision_count()):
				var collision = get_slide_collision(i)
				var collider = collision.get_collider()
				if collider.is_in_group("enemies") or collider.is_in_group("shelled_enemies"):
					if collider != self and collider.has_method("hit"):
						collider.hit()
						_ready()
				elif (collider.is_in_group("terrain") or collider.is_in_group("frozen_carriable")) and is_on_wall():
					unfreeze()
					_ready()
					hit()
					return
			velocity.x = move_toward(velocity.x, 0, slide_friction)
			if abs(velocity.x) < 15:
				velocity.x = 0
				freeze_state = Freezestate.Still
func pick_up(plr):
	if holder != null:
		return
	holder = plr
	freeze_state = Freezestate.Held
	remove_from_group("frozen_carriable")
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	box_out_collision.set_deferred("disabled", true)
func throw(dir):
	holder = null
	freeze_state = Freezestate.Moving
	add_to_group("frozen_carriable")
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	box_out_collision.set_deferred("disabled", false)
	velocity.x = throw_speed * dir
	velocity.y = 0
func drop(dir):
	holder = null
	freeze_state = Freezestate.Still
	add_to_group("frozen_carriable")
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	box_out_collision.set_deferred("disabled", false)
func freeze():
	frozen = true
	add_to_group("frozen_carriable")
	AudioManager.play_sfx(load("res://assets/audio/SFX/IceballFreeze.wav"), -10)
	direction = 0
	if is_on_floor():
		velocity.x = 0
	if spring_state == Springstate.coiled:
		ice_collision_big.set_deferred("disabled", false)
		$FrozenSpriteBig.show()
	else:
		ice_collision_bigger.set_deferred("disabled", false)
		$FrozenSpriteBigger.show()
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	hurt_shape.set_deferred("disabled", true)
	true_form.stop()
func unfreeze():
	frozen = false
	if holder:
		holder.current_carried_obj = null
		holder.toss_timer.start()
	holder = null
	freeze_state = Freezestate.Unfrozen
	remove_from_group("frozen_carriable")
	AudioManager.play_sfx(load("res://assets/audio/SFX/IceBreak.wav"), -10)
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	hurt_shape.set_deferred("disabled", false)
func _on_freeze_timer_timeout() -> void:
	if frozen:
		unfreeze()
	_ready()
