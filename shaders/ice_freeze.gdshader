shader_type canvas_item;

uniform float freeze_progress : hint_range(0.0, 1.0) = 1.0;
uniform vec4 ice_color : source_color = vec4(0.3, 0.7, 1.0, 1.0);
uniform float ice_thickness : hint_range(0.0, 1.0) = 0.9;

varying vec2 world_position;

void vertex() {
	world_position = VERTEX;
}

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	
	// Multiple ice pattern layers for maximum visibility
	vec2 ice_uv = UV * 8.0;
	
	// Pattern 1: Basic ice crystals
	float ice1 = sin(ice_uv.x * 3.14159) * cos(ice_uv.y * 3.14159);
	ice1 = smoothstep(0.3, 0.7, ice1);
	
	// Pattern 2: Diagonal crystal lines
	float ice2 = sin((ice_uv.x + ice_uv.y) * 6.28318);
	ice2 = smoothstep(0.1, 0.9, ice2);
	
	// Pattern 3: Frost edges
	float edge_distance = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float ice3 = smoothstep(0.0, 0.3, edge_distance);
	ice3 = 1.0 - ice3;
	
	// Pattern 4: Random crystalline noise
	float ice4 = fract(sin(dot(ice_uv, vec2(12.9898, 78.233))) * 43758.5453);
	ice4 = smoothstep(0.4, 0.8, ice4);
	
	// Combine all patterns
	float combined_ice = max(max(ice1, ice2), max(ice3, ice4));
	
	// Create very strong ice overlay
	vec4 final_ice_color = vec4(0.1, 0.6, 1.0, 1.0); // Bright cyan
	vec4 ice_overlay = mix(original_color, final_ice_color, combined_ice * ice_thickness);
	
	// Add bright white crystalline highlights
	float highlight = combined_ice * 0.8;
	ice_overlay.rgb += vec3(highlight * 0.7); // Strong white highlights
	
	// Apply freeze progress with stronger effect
	vec4 result = mix(original_color, ice_overlay, freeze_progress);
	
	// Force strong blue tint regardless of original color
	result.rgb = mix(result.rgb, vec3(0.2, 0.5, 1.0), freeze_progress * 0.7);
	
	// Boost overall brightness
	result.rgb *= 1.3;
	
	COLOR = result;
}