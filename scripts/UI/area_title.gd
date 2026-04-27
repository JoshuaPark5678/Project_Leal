# AreaTitleUI.gd
# Sits in your UI scene. Set area_name in the Inspector.
extends Label

@export var area_name: String = ""

var display_duration: float = 1.5

func _ready() -> void:
	text = area_name
	_play_sequence()

func _play_sequence() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	tween.tween_interval(display_duration)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)
