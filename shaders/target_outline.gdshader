shader_type canvas_item;
uniform bool selected = false;
uniform vec4 outline_color : source_color = vec4(0.62, 0.89, 0.67, 0.86);
varying vec4 sprite_tint;

void vertex() {
 sprite_tint = COLOR;
}

void fragment() {
 vec4 texel = texture(TEXTURE, UV);
 COLOR = texel * sprite_tint;
 if (selected) {
  vec2 offset = TEXTURE_PIXEL_SIZE * 2.4;
  float edge = texture(TEXTURE, UV + vec2(offset.x, 0.0)).a;
  edge = max(edge, texture(TEXTURE, UV - vec2(offset.x, 0.0)).a);
  edge = max(edge, texture(TEXTURE, UV + vec2(0.0, offset.y)).a);
  edge = max(edge, texture(TEXTURE, UV - vec2(0.0, offset.y)).a);
  edge = max(edge, texture(TEXTURE, UV + offset).a);
  edge = max(edge, texture(TEXTURE, UV - offset).a);
  edge = max(edge, texture(TEXTURE, UV + vec2(offset.x, -offset.y)).a);
  edge = max(edge, texture(TEXTURE, UV + vec2(-offset.x, offset.y)).a);
  float border = (1.0 - step(0.2, texel.a)) * edge * outline_color.a;
  if (border > COLOR.a) {
   COLOR = vec4(outline_color.rgb, border * sprite_tint.a);
  }
 }
}
