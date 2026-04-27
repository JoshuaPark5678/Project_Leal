# GameManager.gd
extends Node

@export var area_container: Node
@export var player: Node
@export var camera: Camera2D
var fade_overlay : ColorRect

func _ready() -> void:
	fade_overlay = get_tree().get_first_node_in_group("FadeOverlay")
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 0.0

func travel_to(scene_path: String = "", marker_name: String = "") -> void:
	# fade out
	await _fade(1.0)

	# lock camera
	if camera:
		camera.position_smoothing_enabled = false

	for child in area_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	var new_area = load(scene_path).instantiate()
	area_container.add_child(new_area)
	current_area = new_area.name

	var marker = new_area.find_child(marker_name, true, false)
	if marker and player:
		player.global_position = marker.global_position

	# snap camera to player then re-enable
	if camera:
		camera.reset_smoothing()
		camera.position_smoothing_enabled = true

	# fade in
	await _fade(0.0)

func _fade(target: float) -> void:
	# add a ColorRect to InteractManager's CanvasLayer for this
	# or handle it however your UI is set up
	if fade_overlay:
		print("overlay found")
		var tween = create_tween()
		tween.tween_property(fade_overlay, "modulate:a", target, 0.4)
		await tween.finished

# Flags
var flags: Dictionary = {}

func set_flag(key: String) -> void:
	flags[key] = true

func remove_flag(key: String) -> void:
	flags.erase(key)

func has_flag(key: String) -> bool:
	return flags.get(key, false)

# Act / Area tracking
var current_act: int = 1
var current_area: String = ""
