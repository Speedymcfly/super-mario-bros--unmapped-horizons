extends Node



var coin_amount = 0
var lumina_coin_amount = 0
var lives = 4
var mario_lives = 4
var luigi_lives = 4
var toad_lives = 4
var toadette_lives = 4
var peach_lives = 4
var daisy_lives = 4




var shared_lives = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	coin_amount = clamp(coin_amount, 0, 999)
	lumina_coin_amount = clamp(lumina_coin_amount, 0, 999)
	lives = clamp(lives, 0, 99)
	mario_lives = clamp(mario_lives, 0, 99)
	luigi_lives = clamp(luigi_lives, 0, 99)
	toad_lives = clamp(toad_lives, 0, 99)
	toadette_lives = clamp(toadette_lives, 0, 99)
	peach_lives = clamp(peach_lives, 0, 99)
	daisy_lives = clamp(daisy_lives, 0, 99)

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
