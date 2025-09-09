shader_type canvas_item;

uniform float screen_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 0.3);

void fragment() {
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec4 flash = flash_color * screen_flash;
	COLOR = mix(screen_color, flash, screen_flash);
}
