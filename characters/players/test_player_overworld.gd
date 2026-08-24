extends CharacterBody2D

# ==================================================
# MOVEMENT SETTINGS
# ==================================================

@export var move_speed := 140.0
@export var acceleration := 1200.0
@export var friction := 1500.0

# ==================================================
# JUMP SETTINGS
# ==================================================

@export var jump_force := 300.0
@export var gravity := 900.0

# ==================================================
# MOVEMENT VARIABLES
# ==================================================

var move_velocity := Vector2.ZERO

# ==================================================
# JUMP VARIABLES
# ==================================================

var jumping := false
var jump_height := 0.0
var jump_velocity := 0.0

# ==================================================
# PHYSICS
# ==================================================

func _physics_process(delta):
	handle_movement(delta)
	handle_jump(delta)

	velocity = move_velocity
	move_and_slide()

# ==================================================
# MOVEMENT
# ==================================================

func handle_movement(delta):
	var input_dir := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	if input_dir != Vector2.ZERO:
		move_velocity = move_velocity.move_toward(
			input_dir * move_speed,
			acceleration * delta
		)
	else:
		move_velocity = move_velocity.move_toward(
			Vector2.ZERO,
			friction * delta
		)

# ==================================================
# JUMP
# ==================================================

func handle_jump(delta):
	if Input.is_action_just_pressed("jump") and not jumping:
		start_jump()

	if jumping:
		jump_velocity -= gravity * delta
		jump_height += jump_velocity * delta

		if jump_height <= 0.0:
			land()

	update_jump_visuals()

func start_jump():
	jumping = true
	jump_height = 0.0
	jump_velocity = jump_force

	# Disable collision with jumpable objects while airborne.
	set_collision_mask_value(2, false)

func land():
	jumping = false
	jump_height = 0.0
	jump_velocity = 0.0

	# Re-enable collision when landing.
	set_collision_mask_value(2, true)

# ==================================================
# VISUALS
# ==================================================

func update_jump_visuals():
	$Sprite2D.position.y = -jump_height
