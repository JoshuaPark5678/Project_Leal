# Bird.gd
extends Node2D

@export var flee_distance: float = 60.0
@export var fly_speed: float = 180.0
@export var hop_distance: float = 10.0
@export var hop_interval_min: float = 1.5
@export var hop_interval_max: float = 4.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: Node2D = get_tree().get_first_node_in_group("Player")

var fleeing: bool = false
var fly_direction: Vector2
var current_velocity: Vector2
var time: float = 0.0

var origin: Vector2
var hop_target: Vector2
var hop_timer: float = 0.0
var hopping: bool = false

func _ready() -> void:
    var dir = 1 if randf() > 0.5 else -1
    fly_direction = Vector2(dir, -1)
    sprite.flip_h = dir < 0
    sprite.play("idle")
    origin = global_position
    hop_target = global_position
    _schedule_hop()

func _process(delta: float) -> void:
    if fleeing:
        time += delta
        var wobble = sin(time * 4.0) * 0.3
        var wobbled_dir = fly_direction.rotated(wobble)
        var speed = fly_speed * min(1.0 + time * 0.5, 2.0)
        current_velocity = current_velocity.lerp(wobbled_dir.normalized() * speed, delta * 4.0)
        global_position += current_velocity * delta
        if global_position.distance_to(get_viewport_rect().get_center()) > 1200.0:
            queue_free()
        return

    if player and global_position.distance_to(player.global_position) < flee_distance:
        _flee()
        return

    if hopping:
        global_position = global_position.move_toward(hop_target, fly_speed * 0.3 * delta)
        if global_position == hop_target:
            hopping = false
            _schedule_hop()
    else:
        hop_timer -= delta
        if hop_timer <= 0.0:
            _do_hop()

func _schedule_hop() -> void:
    hop_timer = randf_range(hop_interval_min, hop_interval_max)

func _do_hop() -> void:
    var angle = randf() * TAU
    var dist = randf_range(4.0, hop_distance)
    hop_target = origin + Vector2(cos(angle), sin(angle) * 0.3) * dist
    # flip once at hop start based on direction of travel
    var diff = hop_target.x - global_position.x
    if abs(diff) > 0.5:
        sprite.flip_h = diff < 0.0
    hopping = true

func _flee() -> void:
    fleeing = true
    current_velocity = Vector2(fly_direction.x * 30.0, -20.0)
    sprite.play("fly")