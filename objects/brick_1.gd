
extends StaticBody2D


@export var breakable := false
@export var tween = null
@onready var start_pos : Vector2 = self.global_position
var final_pos : Vector2 = Vector2(0, -16)

var start_z_index = 0

func _on_jump_area_body_entered(body: Node2D) -> void:
	if body is player and body.velocity.y > 0:
		AudioManager.play_sfx(load("res://assets/audio/SFX/Bump.wav"))
		tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "global_position", start_pos + final_pos, 0.05).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "global_position", start_pos, 0.01).set_ease(Tween.EASE_IN)


		await tween.finished
		z_index = start_z_index
		tween = null
