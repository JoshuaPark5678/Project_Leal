extends Area2D

@export_group("Wind")
@export var wind_strength: float = 5.0
@export var wind_speed: float = 2.0
@export var wind_offset: float = 0.0

@export_group("Physics")
@export var stiffness: float = 80.0
@export var damping: float = 10.0

@export_group("Player Interaction")
@export var player_force: float = 120.0
@export var enter_force: float = 180.0
@export var speed_influence: float = 1.2
@export var max_speed_force: float = 2.5

# Spring state
var _bend_angle: float = 0.0
var _bend_velocity: float = 0.0
var _base_rot: float = 0.0

# Cached refs
var _blade1: Sprite2D
var _blade2: Sprite2D
var _player_body: CharacterBody2D = null
var _last_player_x_offset: float = 0.0

func _ready() -> void:
	_blade1 = $blade1
	_blade2 = $blade2
	_base_rot = rotation_degrees
	wind_offset = randf_range(0.0, 10.0)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	# Wind
	var wind := sin(Time.get_ticks_msec() * 0.001 * wind_speed + wind_offset) * wind_strength

	# Player push (continuous while inside)
	if _player_body:
		var speed := _player_body.velocity.length()
		var speed_factor := clampf(speed * speed_influence, 0.2, max_speed_force)
		var dir := 1.0 if _last_player_x_offset > 0.0 else -1.0
		_bend_velocity += dir * player_force * speed_factor * delta

	# Spring physics
	var spring_force := -stiffness * _bend_angle
	var damp_force   := -damping  * _bend_velocity
	_bend_velocity += (spring_force + damp_force) * delta
	_bend_angle    += _bend_velocity * delta

	# Apply to both blades
	var final_rot := _base_rot + wind + _bend_angle
	_blade1.rotation_degrees = final_rot
	_blade2.rotation_degrees = final_rot

func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return
	_player_body = body
	_last_player_x_offset = global_position.x - body.global_position.x
	
	var speed := (_player_body as CharacterBody2D).velocity.length()
	var speed_factor := clampf(speed * speed_influence, 0.5, max_speed_force)
	var dir := 1.0 if _last_player_x_offset > 0.0 else -1.0
	_bend_velocity += dir * enter_force * speed_factor

func _on_body_exited(body: Node2D) -> void:
	if body == _player_body:
		_player_body = null
