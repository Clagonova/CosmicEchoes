shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_always;

uniform float twinkle_strength = 0.3; // yanıp sönme miktarı

void fragment() {
    vec3 star_color = COLOR.rgb;

    float phase = COLOR.r * 43758.5453; // encode ettiğimiz küçük faz
	float flicker = 1.0 + sin(TIME * 3.0 + phase) * twinkle_strength;

    ALBEDO = star_color;
    EMISSION = COLOR.rgb * flicker;
}
