shader_type canvas_item;

uniform vec2 game_resolution = vec2(1280.0, 720.0);

// Fog
uniform vec4 fog_color : source_color = vec4(0.894, 0.945, 1.0, 1.0);
uniform float fog_density : hint_range(0.0, 1.0) = 0.4;
uniform float fog_distance : hint_range(0.0, 2000.0) = 400.0;
uniform float fog_noise_strength : hint_range(0.0, 200.0) = 80.0;
uniform float fog_noise_scale : hint_range(0.0, 0.02) = 0.005;
uniform float min_visibility : hint_range(0.0, 1.0) = 0.1;
uniform float max_visibility : hint_range(0.0, 1.0) = 0.8;
uniform sampler2D fog_noise : repeat_enable;
uniform vec2 player_position = vec2(0.0, 0.0);

void fragment() {
    vec2 screen_pos = SCREEN_UV * game_resolution;

    // noise edge
    vec2 fog_noise_uv = screen_pos * fog_noise_scale + vec2(TIME * 0.02, TIME * 0.013);
    float edge_noise = texture(fog_noise, fog_noise_uv).r;
    float noise_offset = (edge_noise * 2.0 - 1.0) * fog_noise_strength;

    // fog factor
    float dist = length(screen_pos - player_position) + noise_offset;
    dist = max(dist, 0.0);
    float fog = 1.0 - exp(-dist / max(fog_distance * 0.5, 0.001));
    fog = pow(fog, 1.0 / max(fog_density, 0.001));
    fog = clamp(fog, 0.0, 1.0);

    // remap
    fog = mix(1.0 - max_visibility, 1.0 - min_visibility, fog);

    COLOR = vec4(fog_color.rgb, fog * fog_color.a);
}