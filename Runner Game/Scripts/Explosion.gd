extends AnimatedSprite

func _ready() -> void:
	playing = true
	frame = 0


func _on_Explosion_animation_finished() -> void:
	queue_free()
