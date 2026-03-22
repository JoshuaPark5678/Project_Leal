shader_type canvas_item;

// Sway
uniform bool sway_enabled = false;
uniform sampler2D noise_texture : repeat_enable;
uniform float sway_speed : hint_range(0.0, 5.0) = 0.8;
uniform float sway_strength : hint_range(0.0, 8.0) = 2.0;

// Fog
uniform vec4 fog_color : source_color = vec4(0.725, 0.863, 1.0, 1.0);
uniform float fog_density : hint_range(0.0, 1.0) = 0.2;
uniform float fog_distance : hint_range(0.0, 2000.0) = 500.0;
uniform vec2 player_position = vec2(0.0, 0.0);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec2 pixel_size = TEXTURE_PIXEL_SIZE;
    vec2 snapped_uv = floor(UV / pixel_size) * pixel_size;
    vec2 displaced_uv = snapped_uv;

    if (sway_enabled) {
        float height_factor = 1.0 - snapped_uv.y;
        vec2 noise_uv = vec2(snapped_uv.x * 3.0 + TIME * sway_speed, snapped_uv.y * 2.0);
        float noise = texture(noise_texture, noise_uv).r;
        float offset = (noise * 2.0 - 1.0) * sway_strength * height_factor;
        displaced_uv = snapped_uv + vec2(offset * pixel_size.x, 0.0);
    }

    vec4 sprite_color = texture(TEXTURE, displaced_uv);

    vec2 screen_pos = SCREEN_UV * vec2(1152.0, 648.0);
    float dist = length(screen_pos - player_position);

    float fog_factor = 1.0 - exp(-dist / max(fog_distance * 0.5, 0.001));
    fog_factor = pow(fog_factor, 1.0 / max(fog_density, 0.001));
    fog_factor = clamp(fog_factor, 0.0, 1.0);

    vec2 center_offset = (SCREEN_UV - vec2(0.5)) * 2.0;
    float vignette = 1.0 - dot(center_offset, center_offset) * vignette_strength;
    vignette = clamp(vignette, 0.0, 1.0);

    fog_factor = fog_factor * (1.0 + (1.0 - vignette) * 0.3);
    fog_factor = clamp(fog_factor, 0.0, 1.0);

    vec3 desaturated = vec3(dot(sprite_color.rgb, vec3(0.299, 0.587, 0.114)));
    vec3 fog_blend = mix(sprite_color.rgb, desaturated, fog_factor * 0.4);
    vec3 final_color = mix(fog_blend, fog_color.rgb, fog_factor);

    COLOR = vec4(final_color, sprite_color.a);
}