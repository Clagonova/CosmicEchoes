shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_always;

uniform float star_density : hint_range(0.0, 1.0) = 0.5;
uniform float star_size : hint_range(0.0, 0.05) = 0.01;
uniform float twinkle_speed : hint_range(0.0, 5.0) = 1.0;

float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec3 p){
    return fract(sin(dot(p ,vec3(12.9898,78.233, 54.53))) * 43758.5453);
}

void fragment() {
    vec3 dir = normalize(VERTEX); // Sphere yönü

    // --- Yıldızlar ---
    vec2 uv = dir.xy * 123.456;
    float r = rand(uv);
    float brightness = step(1.0 - star_density, r);
    float twinkle = sin(TIME * twinkle_speed + r * 10.0) * 0.5 + 0.5;
    brightness *= twinkle;

    // Rastgele renkli yıldızlar
    vec3 star_color = vec3(rand(uv), rand(uv + 1.0), rand(uv + 2.0));
    vec3 final_star = star_color * brightness;

    ALBEDO = final_star;
    ALPHA = 1.0;
}
