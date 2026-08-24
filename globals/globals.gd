extends Node

@onready var coin_flower = preload("res://objects/collectables/coin_flower.tscn")

var coin_amount = 0
var lumina_coin_amount = 0
var super_diamond_amount = 0
var lives = 4
var mario_lives = 4
var luigi_lives = 4
var toad_lives = 4
var toadette_lives = 4
var peach_lives = 4
var daisy_lives = 4

var shared_lives = true

var coin_flower_rain = false

var coin_rain_timer := 15.0
var coin_flower_spawn := 0.0
var coin_rain_interval := 0.35

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

	if coin_flower_rain:
		# Count down the total duration of the rain
		coin_rain_timer -= delta
		# Count down until the next flower
		coin_flower_spawn -= delta

		# Spawn a flower
		if coin_flower_spawn <= 0.0:
			spawn_coin_flower()
			coin_flower_spawn = coin_rain_interval

		# Rain has ended
		if coin_rain_timer <= 0.0:
			coin_rain_timer = 0.0
			coin_flower_rain = false
			coin_flower_spawn = 0.0


func spawn_coin_flower() -> void:
	var camera := get_viewport().get_camera_2d()

	if camera == null:
		return

	var screen_size := get_viewport().get_visible_rect().size
	var half_size := (screen_size / camera.zoom) * 0.5
	var cam_center := camera.get_screen_center_position()

	var random_x := randf_range(
		cam_center.x - half_size.x,
		cam_center.x + half_size.x
	)

	var spawn_pos := Vector2(
		random_x,
		cam_center.y - half_size.y - 50.0
	)

	var raining_coin = coin_flower.instantiate()
	raining_coin.global_position = spawn_pos
	get_tree().current_scene.add_child(raining_coin)

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
