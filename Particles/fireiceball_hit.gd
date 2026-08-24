extends AnimatedSprite2D
@onready var timer: Timer = $Timer
func _ready():
	timer.start()
func _on_timer_timeout() -> void:
	queue_free()
