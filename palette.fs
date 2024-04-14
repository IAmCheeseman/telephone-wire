uniform vec4 rc;
uniform vec4 gc;
uniform vec4 bc;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 pixelCoords) {
  vec4 c = Texel(tex, uv);
  if (c == vec4(1, 0, 0, 1)) {
    return rc;
  }
  
  if (c == vec4(0, 1, 0, 1)) {
    return gc;
  }

  if (c == vec4(0, 0, 1, 1)) {
    return bc;
  }

  return c;
}
