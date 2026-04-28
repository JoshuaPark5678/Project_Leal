# GameManager.gd
extends Node

@export var area_container: Node
@export var player: Node
@export var camera: Camera2D
var fade_overlay : ColorRect
var area_title: Label

func _ready() -> void:
	fade_overlay = get_tree().get_first_node_in_group("FadeOverlay")
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 0.0
	else: 
		print("Warning: No fade overlay found in the scene tree. Please add a ColorRect to a CanvasLayer and assign it to the 'FadeOverlay' group.")
	area_title = get_tree().get_first_node_in_group("AreaTitle")
	if area_title:
		# Get current area
		current_area = get_tree().get_first_node_in_group("Area").get_meta("area_name")
		area_title._play_sequence(current_area)
	else:
		print("Warning: No AreaTitle node found in the scene tree. Please add a Label to your UI and assign it to the 'AreaTitle' group.")


func travel_to(scene_path: String = "", marker_name: String = "") -> void:
	await _fade(1.0)

	if camera:
		camera.position_smoothing_enabled = false

	for child in area_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	var new_area = load(scene_path).instantiate()
	area_container.add_child(new_area)

	# grab title immediately after adding, before any awaits
	if new_area.has_meta("area_name"):
		current_area = new_area.get_meta("area_name")
	else:
		current_area = new_area.name

	var marker = new_area.find_child(marker_name, true, false)
	if marker and player:
		player.global_position = marker.global_position

	if camera:
		camera.reset_smoothing()
		camera.position_smoothing_enabled = true

	await _fade(0.0)

	if area_title:
		area_title._play_sequence(current_area)

func _fade(target: float) -> void:
	# add a ColorRect to InteractManager's CanvasLayer for this
	# or handle it however your UI is set up
	if fade_overlay:
		var tween = create_tween()
		tween.tween_property(fade_overlay, "modulate:a", target, 0.4)
		await tween.finished
	if area_title:
		area_title.modulate.a = 0.0

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
