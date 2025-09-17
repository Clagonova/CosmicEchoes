shader_type canvas_item;

// Crosshair Color
uniform vec4 crosshair_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Crosshair color
uniform float radius : hint_range(0.0, 0.15, 0.001) = 0.05; // Radius of the crosshair
uniform float opacity : hint_range(0.0, 1.0, 0.01) = 1.0; // Opacity of the crosshair

void fragment() {
    // Get normalized fragment coordinates
    vec2 uv = UV - vec2(0.5); // Center UV (from -0.5 to 0.5)
    float dist = length(uv); // Calculate distance from the center

    // If the distance is less than the radius, display the crosshair color
    if (dist < radius) {
        COLOR = vec4(crosshair_color.rgb, crosshair_color.a * opacity); // Set crosshair color with opacity
    } else {
        discard; // Ignore fragments outside the circle
    }
}
