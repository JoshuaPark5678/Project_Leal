shader_type canvas_item;

// On / Off
uniform bool shader_enabled = true;

// Game resolution (for pixel snapping)
uniform vec2 game_resolution = vec2(1280.0, 720.0);

// Sway
uniform bool sway_enabled = false;
uniform sampler2D noise_texture : repeat_enable;
uniform float sway_speed : hint_range(0.0, 5.0) = 0.8;
uniform float sway_strength : hint_range(0.0, 8.0) = 2.0;

// Fog
uniform sampler2D fog_noise : repeat_enable;
uniform vec4 fog_color : source_color = vec4(0.894, 0.945, 1.0, 1.0);
uniform float fog_density : hint_range(0.0, 1.0) = 0.1;
uniform float fog_distance : hint_range(0.0, 2000.0) = 400.0;
uniform float fog_noise_strength : hint_range(0.0, 200.0) = 80.0;
uniform float fog_noise_scale : hint_range(0.0, 0.02) = 0.005;
uniform float min_visibility : hint_range(0.0, 1.0) = 0.1;
uniform float max_visibility : hint_range(0.0, 1.0) = 0.8;
uniform vec2 player_position = vec2(0.0, 0.0);

// Campfire
uniform vec2 campfire_position = vec2(0.0, 0.0);
uniform float campfire_distance : hint_range(0.0, 2000.0) = 200.0;
uniform bool campfire_active = false;
// Campfire light
uniform vec4 campfire_light_color : source_color = vec4(1.0, 0.709, 0.353, 1.0);
uniform float campfire_light_distance : hint_range(0.0, 500.0) = 150.0;
uniform float campfire_light_intensity : hint_range(0.0, 1.0) = 0.6;

// See through
uniform bool see_through_enabled = false;
uniform float player_opacity : hint_range(0.0, 1.0) = 0.5;
uniform float player_see_through_radius : hint_range(0.0, 500.0) = 80.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
    if (!shader_enabled) {
        COLOR = texture(TEXTURE, UV);
    } else {
        vec2 pixel_size = TEXTURE_PIXEL_SIZE;

        vec2 snapped_uv = UV;
        vec2 displaced_uv = snapped_uv;

        if (sway_enabled) {
            float height_factor = 1.0 - snapped_uv.y;
            vec2 noise_uv = vec2(snapped_uv.x * 3.0 - TIME * sway_speed, snapped_uv.y * 2.0);
            float noise = texture(noise_texture, noise_uv).r;
            float offset = (noise * 2.0 - 1.0) * sway_strength * height_factor;
            displaced_uv = snapped_uv + vec2(offset * pixel_size.x, 0.0);
        }

        vec4 sprite_color = texture(TEXTURE, displaced_uv);

        vec2 screen_pos = SCREEN_UV * game_resolution;

        // Noise edge
        vec2 fog_noise_uv = screen_pos * fog_noise_scale + vec2(TIME * 0.02, TIME * 0.013);
        float edge_noise = texture(fog_noise, fog_noise_uv).r;
        float noise_offset = (edge_noise * 2.0 - 1.0) * fog_noise_strength;

        // Player fog factor
        float dist = length(screen_pos - player_position) + noise_offset;
        dist = max(dist, 0.0);
        float player_fog = 1.0 - exp(-dist / max(fog_distance * 0.5, 0.001));
        player_fog = pow(player_fog, 1.0 / max(fog_density, 0.001));
        player_fog = clamp(player_fog, 0.0, 1.0);

        float fog_factor = player_fog;

        if (campfire_active) {
            float campfire_dist = length(screen_pos - campfire_position) + noise_offset;
            campfire_dist = max(campfire_dist, 0.0);
            float campfire_fog = 1.0 - exp(-campfire_dist / max(campfire_distance * 0.5, 0.001));
            campfire_fog = pow(campfire_fog, 1.0 / max(fog_density, 0.001));
            campfire_fog = clamp(campfire_fog, 0.0, 1.0);

            // Multiply instead of min -- both light sources contribute
            fog_factor = player_fog * campfire_fog;
        }

        // Min / max visibility
        fog_factor = mix(1.0 - max_visibility, 1.0 - min_visibility, fog_factor);

        vec3 desaturated = vec3(dot(sprite_color.rgb, vec3(0.299, 0.587, 0.114)));
        vec3 fog_blend = mix(sprite_color.rgb, desaturated, fog_factor * 0.4);
        vec3 final_color = mix(fog_blend, fog_color.rgb, fog_factor);

        // Campfire light
        if (campfire_active) {
            float light_dist = length(screen_pos - campfire_position);
            float light_factor = 1.0 - exp(-light_dist / max(campfire_light_distance * 0.5, 0.001));
            light_factor = clamp(1.0 - light_factor, 0.0, 1.0);
            light_factor *= campfire_light_intensity;
            final_color = mix(final_color, campfire_light_color.rgb, light_factor);
        }

        if (see_through_enabled) {
            float see_dist = length(screen_pos - player_position);
            float see_factor = 1.0 - smoothstep(0.0, player_see_through_radius, see_dist);
            COLOR = vec4(final_color, sprite_color.a * COLOR.a * (1.0 - see_factor * (1.0 - player_opacity)));
        } else {
            COLOR = vec4(final_color, sprite_color.a * COLOR.a);
        }
    }
}