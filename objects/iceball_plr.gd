class_name iceballplr
extends CharacterBody2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D2
@onready var timer: Timer = $Timer
@onready var timer_2: Timer = $Timer2
@export var speed := 200.0
@export var gravity := 900.0
# normal throw
@export var throw_arc := -50.0
# higher arc when holding up
@export var up_throw_arc := -250.0
# regular bounce
@export var bounce_force := -250.0
# stronger/faster bouncing
@export var rapid_bounce_force := -180.0
var direction := 1
var strike = false
var bounce = 0
func _ready():
	velocity.x = speed * direction
	# higher arc if UP is held
	if Input.is_action_pressed("ui_up"):
		velocity.y = up_throw_arc
	else:
		velocity.y = throw_arc
func _physics_process(delta):
	if strike:
		return
	# gravity
	velocity.y += gravity * delta
	# move first
	if !strike:
		move_and_slide()
	# bounce
	if is_on_floor():
		# smaller bounce force = lower bounce
		# lower bounce = reaches floor sooner
		# therefore more frequent bouncing
		velocity.y = rapid_bounce_force
		timer_2.start()
		bounce += 1
		if bounce == 2:
			hit()
	# destroy on wall
	if is_on_wall() or is_on_ceiling():
		hit()
	# sprite facing
	#if velocity.x < 0:
		#gpu_particles_2d.position.x = 8
		
	#elif velocity.x > 0:
		#gpu_particles_2d.position.x = -8
func hit():
	var plr = get_tree().get_first_node_in_group("player")
	AudioManager.play_sfx(load("res://assets/audio/SFX/IceBreak.wav"), -10)
	strike = true
	$Sprite2D.hide()
	collision_shape_2d.set_deferred("disabled", true)
	var f = preload("res://Particles/iceball_hit.tscn").instantiate()
	get_parent().add_child(f)
	f.global_position = global_position
	f.scale.x = abs(f.scale.x) * -direction
	timer.start()
func _on_timer_timeout() -> void:
	queue_free()
func _on_timer_2_timeout() -> void:
	hit()
