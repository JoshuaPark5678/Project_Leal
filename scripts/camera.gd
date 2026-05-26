extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


@export var follow_speed: float = 5.0

func _process(delta: float) -> void:
	var target = get_parent().global_position
	global_position = global_position.lerp(target, follow_speed * delta)
	global_position = global_position.round()
