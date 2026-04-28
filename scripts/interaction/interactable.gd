# Interactable.gd
extends Area2D

@export var prompt_label: String = "[E] Interact"
@export var teleport: bool = false
@export_file("*.tscn") var scene_path: String = ""
@export var destination_marker: String = "SpawnPoint"

@onready var interact_manager = get_tree().get_first_node_in_group("Interact")
@onready var gm = get_tree().get_first_node_in_group("GameManager")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		interact_manager.set_current(self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		interact_manager.clear_current(self)

func on_interact() -> void:
	if teleport and scene_path != "":
		gm.travel_to(scene_path, destination_marker)
