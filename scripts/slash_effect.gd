extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var velocity := Vector2.ZERO


func _ready() -> void:
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)


func _process(delta: float) -> void:
	global_position += velocity * delta


func _on_animation_finished() -> void:
	queue_free()
