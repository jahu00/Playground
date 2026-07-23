shader_type canvas_item;
// Tiles the texture, scrolls it in a continuously rotating direction, and
// cycles a color tint over time. Requires the node's texture repeat to be on.

// How many times the texture repeats across the rect.
uniform float tile_scale = 6.0;
// How fast the texture scrolls (constant, capped speed).
uniform float scroll_speed = 0.15;
// How fast the scroll direction rotates.
uniform float direction_change_speed = 0.25;
// How fast the color tint cycles.
uniform float color_speed = 0.4;

void fragment() {
	// The scroll offset is the integral over time of a unit direction vector
	// that rotates at `direction_change_speed`. Integrating the rotating
	// direction (rather than scaling it by TIME) keeps the scroll velocity
	// constant at `scroll_speed`, so the background never accelerates.
	float w = max(direction_change_speed, 0.0001);
	float angle = TIME * w;
	vec2 offset = scroll_speed / w * vec2(sin(angle), 1.0 - cos(angle));

	// Scaled + scrolled UVs. Sampling relies on repeat being enabled.
	vec2 uv = UV * tile_scale + offset;
	vec4 tex = texture(TEXTURE, uv);

	// Cycle the tint through hues by phase-shifting each channel.
	vec3 tint = vec3(
		0.5 + 0.5 * sin(color_speed * TIME),
		0.5 + 0.5 * sin(color_speed * TIME + 2.094),
		0.5 + 0.5 * sin(color_speed * TIME + 4.188)
	);

	COLOR = vec4(tex.rgb * tint, tex.a);
}
