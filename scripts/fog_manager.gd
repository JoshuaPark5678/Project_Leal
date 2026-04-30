# FogManager.gd
extends Node

@export var enabled: bool = true
@export var cycle_duration: float = 3600.0 
@export var start_time: float = 0.25
@export var materials: Array[ShaderMaterial] = []

var current_time: float = 0.0

# Each state: [time, fog_color, fog_density, fog_distance, max_visibility]
var states: Array = [
	[0.0,  Color(0.05,  0.08,  0.2,   1.0), 0.4,  300.0, 0.6],  # midnight
	[0.2,  Color(0.654, 0.748, 0.893, 1.0), 0.2, 350.0, 0.8],  # morning
	[0.25, Color(0.686, 0.807, 0.972, 1.0), 0.1,  400.0, 0.8],   # early day
	[0.40, Color(0.662, 0.78, 0.948, 1.0), 0.1,  500.0, 0.8],   # day
	[0.55, Color(0.268, 0.353, 0.495, 1.0), 0.2,  400.0, 0.8],  # evening
	[0.75, Color(0.05,  0.08,  0.2,   1.0), 0.5, 200.0, 0.6],  # night
	[1.0,  Color(0.05,  0.08,  0.2,   1.0), 0.4,  300.0, 0.6],  # wrap
]

func _ready() -> void:
	current_time = start_time

func _process(delta: float) -> void:
	if not enabled:
		return
	current_time = fmod(current_time + delta / cycle_duration, 1.0)
	_update_materials()

func _sample() -> Array:
	var from_state = states[0]
	var to_state = states[1]

	for i in range(states.size() - 1):
		if current_time >= states[i][0] and current_time < states[i + 1][0]:
			from_state = states[i]
			to_state = states[i + 1]
			break

	var r = to_state[0] - from_state[0]
	var t = (current_time - from_state[0]) / r
	return [
		from_state[1].lerp(to_state[1], t),
		lerp(from_state[2], to_state[2], t),
		lerp(from_state[3], to_state[3], t),
		lerp(from_state[4], to_state[4], t)
	]

func _update_materials() -> void:
	var result = _sample()
	for mat in materials:
		if mat:
			mat.set_shader_parameter("fog_color", result[0])
			mat.set_shader_parameter("fog_density", result[1])
			mat.set_shader_parameter("fog_distance", result[2])
			mat.set_shader_parameter("max_visibility", result[3])

func set_time(new_time: float, transition_duration: float = 0.0) -> void:
	if transition_duration > 0.0:
		var tween = create_tween()
		tween.tween_property(self, "current_time", new_time, transition_duration)
	else:
		current_time = new_time
