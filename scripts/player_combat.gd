extends Node2D

@export var damage               := 10
@export var attack_cooldown      := 0.5
@export var max_health           := 100
@export var invincibility_duration := 1.0
@export var slash_offset         := 12.0
@export var slash_scene: PackedScene
@export var combo_window         := 0.4
@export var combo_slash_speed    := 0.7

@onready var player: CharacterBody2D   = get_parent()
@onready var sprite: AnimatedSprite2D  = player.get_node("AnimatedSprite2D")
@onready var combo_timer: Timer        = $ComboTimer

var current_health: int
var is_equipped       := false
var is_attacking      := false
var attack_cooldown_timer := 0.0
var is_invincible     := false
var invincibility_timer   := 0.0
var combo_count       := 0
var combo_buffered    := false

var debug_mode        := false
var mouse_position    := Vector2.ZERO


func _ready() -> void:
	current_health = max_health
	combo_timer.wait_time = combo_window
	combo_timer.one_shot  = true
	combo_timer.timeout.connect(_on_combo_timeout)


func _physics_process(delta: float) -> void:
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false

	if Input.is_action_just_pressed("debug1"):
		debug_mode = not debug_mode
		queue_redraw()

	if debug_mode:
		mouse_position = player.get_global_mouse_position()
		queue_redraw()


# ── Combat ──────────────────────────────────────────────────────────────────

func can_attack() -> bool:
	return is_equipped and not is_attacking and attack_cooldown_timer <= 0 and not player.is_rolling


func toggle_equipped() -> void:
	if is_attacking:
		return
	is_equipped = not is_equipped
	if player.movement == Vector2.ZERO:
		player.play_idle()


func attack() -> void:
	is_attacking = true
	attack_cooldown_timer = attack_cooldown
	player.is_blinking = false
	player.reset_blink_timer()

	var dir := (player.get_global_mouse_position() - player.global_position).normalized()
	player.facing_direction = dir

	if abs(dir.x) > abs(dir.y):
		# Horizontal
		sprite.flip_h = dir.x < 0
		if combo_count == 1 and combo_timer.time_left > 0:
			sprite.play("axe_attack_side_2")
			combo_count = 0
			combo_buffered = false
			combo_timer.stop()
			_spawn_slash(dir, true)
		else:
			sprite.play("axe_attack_side")
			combo_count = 1
			combo_buffered = false
			combo_timer.start()
			_spawn_slash(dir, false)

	elif dir.y > 0:
		# Downward
		sprite.flip_h = false
		if combo_count == 1 and combo_timer.time_left > 0:
			sprite.play("axe_attack_down_2")
			combo_count = 0
			combo_buffered = false
			combo_timer.stop()
			_spawn_slash(dir, true)
		else:
			sprite.play("axe_attack_down")
			combo_count = 1
			combo_buffered = false
			combo_timer.start()
			_spawn_slash(dir, false)

	else:
		# Upward
		sprite.flip_h = false
		if combo_count == 1 and combo_timer.time_left > 0:
			sprite.play("axe_attack_up_2")
			combo_count = 0
			combo_buffered = false
			combo_timer.stop()
			_spawn_slash(dir, true)
		else:
			sprite.play("axe_attack_up")
			combo_count = 1
			combo_buffered = false
			combo_timer.start()
			_spawn_slash(dir, false)


func finish_attack() -> void:
	is_attacking = false
	if combo_buffered:
		combo_buffered = false
		attack()
		return
	if player.movement == Vector2.ZERO:
		player.play_idle()


func is_in_combat() -> bool:
	return is_attacking


# ── Slash spawning ───────────────────────────────────────────────────────────

func _spawn_slash(direction: Vector2, is_combo: bool) -> void:
	if not slash_scene:
		return

	var slash := slash_scene.instantiate()
	player.get_parent().add_child(slash)
	var forward_speed := maxf(player.velocity.dot(direction), 0.0)
	var move_offset   := direction * forward_speed * 0.1
	slash.global_position = player.global_position + Vector2(0, -10) + direction * slash_offset + move_offset
	slash.velocity = player.velocity * 0.5 * 0.2
	slash.rotation = direction.angle() + PI / 2

	var slash_sprite: AnimatedSprite2D = slash.get_node("AnimatedSprite2D")
	if slash_sprite:
		slash_sprite.flip_h = direction.x > 0 or direction.y < 0
		if is_combo:
			slash_sprite.speed_scale = combo_slash_speed
			
			slash_sprite.flip_h = not slash_sprite.flip_h
		slash_sprite.play("slash")


# ── Health ───────────────────────────────────────────────────────────────────

func take_damage(amount: int) -> void:
	if is_invincible or player.is_invincible():
		return

	current_health = max(0, current_health - amount)
	is_invincible    = true
	invincibility_timer = invincibility_duration

	if current_health <= 0:
		die()


func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)


func die() -> void:
	print("Player died!")


# ── Combo timer ───────────────────────────────────────────────────────────────

func _on_combo_timeout() -> void:
	combo_count    = 0
	combo_buffered = false


# ── Debug drawing ─────────────────────────────────────────────────────────────

func _draw() -> void:
	if not debug_mode:
		return

	var dir := (mouse_position - player.global_position).normalized()
	var tip  := dir * 50.0
	var angle := dir.angle()

	draw_line(Vector2.ZERO, tip, Color.YELLOW, 3.0)
	draw_line(tip, tip + Vector2(cos(angle + 2.5), sin(angle + 2.5)) * 10.0, Color.YELLOW, 3.0)
	draw_line(tip, tip + Vector2(cos(angle - 2.5), sin(angle - 2.5)) * 10.0, Color.YELLOW, 3.0)

	var mouse_local := mouse_position - player.global_position
	draw_line(Vector2.ZERO, mouse_local, Color.CYAN, 1.0)
	draw_circle(mouse_local, 5.0, Color.RED)
	draw_arc(mouse_local, 8.0, 0, TAU, 32, Color.RED, 2.0)
