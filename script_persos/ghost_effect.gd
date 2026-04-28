extends Sprite2D

func _ready():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.finished.connect(queue_free)
