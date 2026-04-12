extends CharacterBody2D

@export var move_speed := 150.0

@export var roll_speed := 400.0
@export var roll_duration := 0.4
@export var roll_cooldown := 1.5

@export var blink_min_time := 3.0
@export var blink_max_time := 7.0

@onready var sprite = $AnimatedSprite2D
@onready var combat = $CombatSystem

var fog_materials: Array[ShaderMaterial] = []

var movement := Vector2.ZERO
var facing_direction := Vector2.DOWN

var is_rolling := false
var roll_timer := 0.0
var roll_cooldown_timer := 0.0
var roll_direction := Vector2.ZERO

var blink_timer := 0.0
var is_blinking := false


func _ready():
	randomize()
	reset_blink_timer()
	sprite.animation_finished.connect(_on_animation_finished)
	find_all_fog_materials(get_tree().root)
	enable_all_shaders(true)

# SHADER SHINANIGANS

func find_all_fog_materials(node: Node) -> void:
	for child in node.get_children():
		if child.get("material") and child.material is ShaderMaterial:
			var mat = child.material as ShaderMaterial
			if mat.shader and mat.get_shader_parameter("player_position") != null:
				fog_materials.append(mat)
		find_all_fog_materials(child)

func enable_all_shaders(enable = true) -> void:
	for mat in fog_materials:
		mat.set_shader_parameter("shader_enabled", enable)

func _physics_process(delta):

	update_fog_shader()

	# ---- Roll Cooldown ----
	if roll_cooldown_timer > 0:
		roll_cooldown_timer -= delta

	# ---- Rolling ----
	if is_rolling:
		update_roll(delta)
		return

	# ---- Movement Input ----
	movement = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	if movement.length() > 1:
		movement = movement.normalized()

	# Apply attack speed penalty
	var current_speed = move_speed
	if combat.is_attacking:
		current_speed *= 0.5

	velocity = movement * current_speed
	move_and_slide()

	if movement != Vector2.ZERO:
		facing_direction = movement

	# ---- Roll Input ----
	if Input.is_action_just_pressed("roll") and roll_cooldown_timer <= 0 and movement != Vector2.ZERO and not combat.is_attacking:
		start_roll()
	
	# ---- Equip Input ----
	if Input.is_action_just_pressed("equip"):
		combat.toggle_equipped()
	
	# ---- Attack Input ----
	if Input.is_action_just_pressed("attack") and combat.can_attack():
		combat.attack()

	update_animation()
	update_blink(delta)


# ==================================================
# ROLL SYSTEM
# ==================================================

func start_roll():

	is_rolling = true
	roll_timer = roll_duration
	roll_cooldown_timer = roll_cooldown

	roll_direction = movement.normalized()

	sprite.play("roll")


func update_roll(delta):

	roll_timer -= delta

	var progress = 1.0 - (roll_timer / roll_duration)

	# Fast start, smooth slowdown (ease out curve)
	var speed_factor = pow(1.0 - progress, 2)
	var current_speed = lerp(move_speed, roll_speed, speed_factor)

	velocity = roll_direction * current_speed
	move_and_slide()

	if roll_timer <= 0:
		is_rolling = false


# ==================================================
# ANIMATION SYSTEM
# ==================================================

func update_animation():
	if is_rolling or combat.is_in_combat():
		return

	if movement == Vector2.ZERO:
		play_idle()
		return
	
	is_blinking = false
	reset_blink_timer()
	
	var prefix = "axe_" if combat.is_equipped else ""
	
	if abs(movement.x) > abs(movement.y):
		sprite.play(prefix + "walk_side")
		sprite.flip_h = movement.x < 0
	else:
		if movement.y > 0:
			sprite.play(prefix + "walk_down")
		else:
			sprite.play(prefix + "walk_up")


func play_idle():
	if is_blinking:
		return
	
	var prefix = "axe_" if combat.is_equipped else ""
	
	if abs(facing_direction.x) > abs(facing_direction.y):
		sprite.play(prefix + "idle_side")
		sprite.flip_h = facing_direction.x < 0
	else:
		if facing_direction.y > 0:
			sprite.play(prefix + "idle_down")
		else:
			sprite.play(prefix + "idle_up")


# ==================================================
# BLINK SYSTEM (Random, Idle Only)
# ==================================================

func update_blink(delta):
	# Blink only when idle
	# No up idle
	if movement != Vector2.ZERO or is_rolling or combat.is_in_combat() or facing_direction.y < 0:
		return

	if is_blinking:
		return

	blink_timer -= delta

	if blink_timer <= 0:
		start_blink()


func start_blink():
	var prefix = "axe_" if combat.is_equipped else ""
	
	if abs(facing_direction.x) > abs(facing_direction.y):
		sprite.play(prefix + "idle_side_blink")
		sprite.flip_h = facing_direction.x < 0
		is_blinking = true

	elif facing_direction.y > 0:
		sprite.play(prefix + "idle_down_blink")
		is_blinking = true

	else:
		# No up blink animation, fallback
		sprite.play(prefix + "idle_down_blink")
		is_blinking = true


func reset_blink_timer():
	blink_timer = randf_range(blink_min_time, blink_max_time)


# ==================================================
# SIGNAL
# ==================================================

func _on_animation_finished():
	if sprite.animation.ends_with("blink"):
		is_blinking = false
		reset_blink_timer()
		update_animation()
	
	if sprite.animation.begins_with("axe_attack"):
		combat.finish_attack()
		update_animation()


# ==================================================
# UTIL
# ==================================================

func is_invincible():
	return is_rolling


# ==================================================
# FOG SHADER UPDATE
# ==================================================

func update_fog_shader():
	var viewport = get_viewport()
	if not viewport:
		return
	var canvas_transform = viewport.get_canvas_transform()
	var screen_pos = canvas_transform * global_position
	for mat in fog_materials:
		mat.set_shader_parameter("player_position", screen_pos)