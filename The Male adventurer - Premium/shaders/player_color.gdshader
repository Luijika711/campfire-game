shader_type canvas_item;

// Player color to replace hair with
uniform vec3 hair_color : hint_color = vec3(1.0, 0.0, 0.0);

// How sensitive the color detection is (0.0-1.0)
// Higher = more forgiving, catches more shades
uniform float color_sensitivity : hint_range(0.0, 1.0) = 0.15;

// Original hair colors (in decimal RGB, not hex)
uniform vec3 hair_dark : hint_color = vec3(0.113, 0.063, 0.200);     // #1D1033
uniform vec3 hair_mid : hint_color = vec3(0.173, 0.114, 0.286);      // #2C1D49
uniform vec3 hair_light : hint_color = vec3(0.235, 0.161, 0.369);    // #3C295E

void fragment() {
    // Get the original pixel color from the texture
    vec4 original = texture(TEXTURE, UV);
    vec3 pixel_color = original.rgb;
    
    // Calculate distance to each hair color
    float dist_dark = distance(pixel_color, hair_dark);
    float dist_mid = distance(pixel_color, hair_mid);
    float dist_light = distance(pixel_color, hair_light);
    
    // Find the closest hair color
    float min_distance = min(dist_dark, min(dist_mid, dist_light));
    
    // If pixel is within sensitivity range of ANY hair color, replace it
    if (min_distance < color_sensitivity) {
        // Replace with player color, preserve original alpha
        COLOR = vec4(hair_color, original.a);
    } else {
        // Keep original color
        COLOR = original;
    }
}
