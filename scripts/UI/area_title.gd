# AreaTitleUI.gd
extends Label

var area_name: String = ""
var display_duration: float = 1.5
var current_tween: Tween

func _ready() -> void:
    modulate.a = 0.0
	
func _play_sequence(display_name: String) -> void:
    text = display_name

    if current_tween:
        current_tween.kill()

    modulate.a = 0.0
    current_tween = create_tween()
    current_tween.tween_property(self, "modulate:a", 1.0, 0.4)
    current_tween.tween_interval(display_duration)
    current_tween.tween_property(self, "modulate:a", 0.0, 0.8)