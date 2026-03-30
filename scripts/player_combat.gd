extends Node2D

@export var damage := 10
@export var attack_cooldown := 0.5
@export var max_health := 100
@export var invincibility_duration := 1.0
@export var slash_offset := 10.0  # Distance to offset the slash effect
@export var slash_scene: PackedScene  # Slash effect scene to instantiate

@onready var player = get_parent() as CharacterBody2D
@onready var sprite = player.get_node("AnimatedSprite2D")

var current_health: int
var is_equipped := false
var is_attacking := false
var attack_cooldown_timer := 0.0
var is_invincible := false
var invincibility_timer := 0.0

# Debug visualization
var debug_mode := false
var mouse_position := Vector2.ZERO


func _ready():
	current_health = max_health


func _physics_process(delta):
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false
	
	# Debug input
	if Input.is_action_just_pressed("debug1"):
		debug_mode = not debug_mode
		queue_redraw()
	
	# Update mouse position for debug
	if debug_mode:
		mouse_position = player.get_global_mouse_position()
		queue_redraw()


func can_attack() -> bool:
	return is_equipped and not is_attacking and attack_cooldown_timer <= 0 and not player.is_rolling

func toggle_equipped():
	if is_attacking:
		return
	is_equipped = not is_equipped
	if player.movement == Vector2.ZERO:
		player.play_idle()

func attack():
	is_attacking = true
	attack_cooldown_timer = attack_cooldown
	player.is_blinking = false
	player.reset_blink_timer()
	
	# Get direction to mouse
	var mouse_pos = player.get_global_mouse_position()
	var direction_to_mouse = (mouse_pos - player.global_position).normalized()
	
	# Update player facing direction
	player.facing_direction = direction_to_mouse
	
	# Instantiate and position slash effect
	if slash_scene:
		var slash_instance = slash_scene.instantiate()
		player.get_parent().add_child(slash_instance)
		slash_instance.global_position = player.global_position + direction_to_mouse * slash_offset
		slash_instance.rotation = direction_to_mouse.angle() + PI/2
		
		# Play the slash animation
		var slash_sprite = slash_instance.get_node("AnimatedSprite2D")
		if slash_sprite:
			slash_sprite.play("slash")
	
	# Choose animation based on mouse direction
	if abs(direction_to_mouse.x) > abs(direction_to_mouse.y):
		sprite.play("axe_attack_side")
		sprite.flip_h = direction_to_mouse.x < 0
	else:
		if direction_to_mouse.y > 0:
			sprite.play("axe_attack_down")
		else:
			sprite.play("axe_attack_up")


func take_damage(amount: int):
	if is_invincible or player.is_invincible():
		return
	
	current_health -= amount
	current_health = max(0, current_health)
	
	is_invincible = true
	invincibility_timer = invincibility_duration
	
	if current_health <= 0:
		die()


func heal(amount: int):
	current_health += amount
	current_health = min(current_health, max_health)


func die():
	print("Player died!")
	# Add death logic here (respawn, game over, etc.)


func finish_attack():
	is_attacking = false
	if player.movement == Vector2.ZERO:
		player.play_idle()


func is_in_combat() -> bool:
	return is_attacking


func _draw():
	if not debug_mode:
		return
	
	# Get mouse direction from player
	var direction_to_mouse = (mouse_position - player.global_position).normalized()
	var arrow_length = 50.0
	
	# Draw arrow pointing to mouse
	var arrow_end = direction_to_mouse * arrow_length
	draw_line(Vector2.ZERO, arrow_end, Color.YELLOW, 3.0)
	
	# Draw arrowhead
	var arrow_size = 10.0
	var arrow_angle = direction_to_mouse.angle()
	var tip = arrow_end
	var left = tip + Vector2(cos(arrow_angle + 2.5), sin(arrow_angle + 2.5)) * arrow_size
	var right = tip + Vector2(cos(arrow_angle - 2.5), sin(arrow_angle - 2.5)) * arrow_size
	draw_line(tip, left, Color.YELLOW, 3.0)
	draw_line(tip, right, Color.YELLOW, 3.0)
	
	# Draw line to mouse position
	draw_line(Vector2.ZERO, mouse_position - player.global_position, Color.CYAN, 1.0)
	
	# Draw mouse indicator (circle at mouse position)
	var mouse_local = mouse_position - player.global_position
	draw_circle(mouse_local, 5.0, Color.RED)
	draw_arc(mouse_local, 8.0, 0, TAU, 32, Color.RED, 2.0)
