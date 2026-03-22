extends Node2D

@export var damage := 10
@export var attack_cooldown := 0.5
@export var max_health := 100
@export var invincibility_duration := 1.0

@onready var player = get_parent() as CharacterBody2D
@onready var sprite = player.get_node("AnimatedSprite2D")

var current_health: int
var is_equipped := false
var is_attacking := false
var attack_cooldown_timer := 0.0
var is_invincible := false
var invincibility_timer := 0.0


func _ready():
	current_health = max_health


func _physics_process(delta):
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false


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
	
	var facing = player.facing_direction
	
	if abs(facing.x) > abs(facing.y):
		sprite.play("axe_attack_side")
		sprite.flip_h = facing.x < 0
	else:
		if facing.y > 0:
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
