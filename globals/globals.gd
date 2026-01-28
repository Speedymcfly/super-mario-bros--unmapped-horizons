extends Node




var coin_amount = 0
var lumina_coin_amount = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func is_onscreen(pos: Vector2, region_w := 16, region_h := 16) -> bool:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return false

	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var cam_center: Vector2 = camera.get_screen_center_position()

	# Get the screen half
	var half_size: Vector2 = (screen_size / camera.zoom) * 0.5

	# This checks if the position you're checking is inside this region
	return (
		pos.x > cam_center.x - half_size.x - region_w and
		pos.x < cam_center.x + half_size.x + region_w and
		pos.y > cam_center.y - half_size.y - region_h and
		pos.y < cam_center.y + half_size.y + region_h
		)
