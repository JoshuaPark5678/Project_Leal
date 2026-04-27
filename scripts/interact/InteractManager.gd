# InteractManager.gd
extends Label

var current_interactable: Node = null

func _ready() -> void:
    modulate.a = 0.0
    
func set_current(interactable: Node) -> void:
    current_interactable = interactable
    show_prompt()

func clear_current(interactable: Node) -> void:
    if current_interactable == interactable:
        current_interactable = null
        hide_prompt()

func try_interact() -> void:
    if current_interactable:
        current_interactable.on_interact()

func show_prompt() -> void:
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.15)

func hide_prompt() -> void:
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.15)