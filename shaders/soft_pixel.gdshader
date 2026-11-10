shader_type canvas_item;

varying vec4 tint;

void vertex() {
 tint = COLOR;
}

// Scale2x reconstructs diagonal corners before light filtering, at draw time.
// Source art and atlas coordinates stay intact; no large replacement textures.
void fragment() {
 vec2 pixel = TEXTURE_PIXEL_SIZE;
 vec2 p = UV / pixel;
 vec2 center = (floor(p) + vec2(0.5)) * pixel;
 vec4 e = texture(TEXTURE, center);
 vec4 b = texture(TEXTURE, center - vec2(0.0, pixel.y));
 vec4 d = texture(TEXTURE, center - vec2(pixel.x, 0.0));
 vec4 f = texture(TEXTURE, center + vec2(pixel.x, 0.0));
 vec4 h = texture(TEXTURE, center + vec2(0.0, pixel.y));
 vec2 subpixel = fract(p);
 vec4 horizontal = subpixel.x < 0.5 ? d : f;
 vec4 vertical = subpixel.y < 0.5 ? b : h;
 float matching = 1.0 - step(0.055, distance(horizontal, vertical));
 float corner = step(0.065, distance(b, h)) * step(0.065, distance(d, f));
 float weight = smoothstep(0.12, 0.48, abs(subpixel.x - 0.5)) * smoothstep(0.12, 0.48, abs(subpixel.y - 0.5));
 vec4 reconstructed = mix(e, (horizontal + vertical) * 0.5, matching * corner * weight);
 COLOR = tint * mix(reconstructed, texture(TEXTURE, UV), 0.24);
}
