extends StaticBody2D

@onready var animated_sprite = $AnimatedSprite2D
var timer = 0.0
var interval = 5.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Randomize initial timer so trees don't sync
	timer = randf() * interval
	# Randomize interval between 4-6 seconds
	interval = randf_range(4.0, 6.0)
	
	if animated_sprite:
		pick_random_frame()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	if timer >= interval:
		timer = 0.0
		# Randomize next interval
		interval = randf_range(4.0, 6.0)
		pick_random_frame()

func pick_random_frame() -> void:
	if animated_sprite and animated_sprite.sprite_frames:
		var frame_count = animated_sprite.sprite_frames.get_frame_count(animated_sprite.animation)
		if frame_count > 0:
			var random_frame = randi() % frame_count
			animated_sprite.frame = random_frame
