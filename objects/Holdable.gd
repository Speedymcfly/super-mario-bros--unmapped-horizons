class_name Holdable
extends Node

# === Holdable info ===
@export var holdbox: Area2D = null
@export var can_kick: bool

# === General ===
var holder: player # Current object holder

var can_hold := false
var delay := 0 # Frames in which you can't interact with the object
var is_held := false

signal on_kicked(dir: int)

func _ready() -> void:
	delay = 5
	holdbox.body_entered.connect(pick_up)

# Try to pick up the object
func pick_up(body: player) -> void:
	if holder == null:
		if body is not player or not Input.is_action_pressed("run") or not can_hold:
			if can_kick and delay == 0:
				on_kicked.emit(sign(owner.global_position.x - body.global_position.x))
			return

		holder = body # Get the player node
		is_held = true # Set the object as held

func _physics_process(delta: float) -> void:
	if delay > 0:
		delay -= 1
		can_hold = false

	if not is_held or not can_hold:
		if holder:
			holder = null
		return

	if Input.is_action_just_released("run"):
		is_held = false
		on_kicked.emit(holder.facing_direction)
		holder = null

	# Update the object position
	if holder:
		owner.global_position = obj_pos()

# Keep the object tied to the player's position
func obj_pos() -> Vector2:
	return Vector2(holder.global_position.x + 8 * holder.facing_direction, holder.global_position.y)
