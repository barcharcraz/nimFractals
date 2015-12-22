#version 440
uniform ivec2 resolution;
uniform float fov;
uniform float focal;
uniform mat4 viewMatrix;
out vec3 fragColor;

float sphere(in vec3 p, in float r) {
  return length(p) - r;
}
float torus(in vec3 p, in vec2 t) {
  vec2 q = vec2(length(p.xz) - t.x, p.y);
  return length(q) - t.y;
}
float map(in vec3 p) {
  float result;
  result = sphere(p - vec3(0,0,20), 1);
  result = min(result, torus(p - vec3(3, 1, 20), vec2(0.5, 0.2)));
  return result;
}

vec3 calcNormal(in vec3 p) {
  float eps = 0.001;
  float x = map(p + vec3(eps, 0, 0)) - map(p - vec3(eps, 0, 0));
  float y = map(p + vec3(0, eps, 0)) - map(p - vec3(0, eps, 0));
  float z = map(p + vec3(0, 0, eps)) - map(p - vec3(0, 0, eps));
  return normalize(vec3(x,y,z));
}

// Light the point using blinn-phong
// it would be interesting to do something
// more physically based here, esp since we have
// lots of scene information (whole scene in map())
vec3 lightPoint(in vec3 p) {
  vec3 n = calcNormal(p);
  vec3 v = normalize(p);

  // TODO: make this a uniform
  //vec3 l = (testMtx * vec4(normalize(vec3(-1, 0, 1)), 0)).xyz;
  vec3 l = vec3(1.5, 1, 20);
  l = normalize(p - l);
  vec3 h = normalize(l + v);

  vec3 color = vec3(0,0,0);
  n = -1 * n;

  //TODO: make ambiant uniform
  color += vec3(0.1, 0.1, 0.1);

  float lambert = dot(n,l);
  if(lambert > 0) {
    // 1 is diffuse intensity, we don't use attenuation
    color += 1 * lambert * vec3(0.5, 0.2, 0.0);
    //add the specular intensity using a shine parameter of 255
    color += 1 * pow(dot(n,h), 250.0) * vec3(0.5,0.2,0.0);
  }
  //color += 1 * pow(dot(n,h), 250.0) * vec3(0.5,0.2,0.0);
  return color;
}
void trace(in vec3 origin, in vec3 direction, out float t, out float s) {
  float totalDist = 0.0;
  const int maxSteps = 150;
  const float minDist = 0.002;
  int steps = 0;
  while(steps < maxSteps) {
    vec3 p = origin + totalDist * direction;
    float dist = map(p);
    totalDist += dist;
    if(dist < minDist) break;
    steps += 1;
  }
  s = 1.0 - float(steps)/float(maxSteps);
  t = totalDist;
}
void main() {
  float aspect = float(resolution.x) / float(resolution.y);
  float vfov = fov / aspect;
  float hfov = fov;
  float left = -focal * tan(hfov/2);
  float right = focal * tan(hfov/2);
  float top = focal * tan(vfov/2);
  float bottom = -focal * tan(vfov/2);

  float hstep = (right - left) / float(resolution.x);
  float vstep = (top - bottom) / float(resolution.y);
  vec3 d = vec3(left + gl_FragCoord.x * hstep, bottom + gl_FragCoord.y * vstep, focal);
  d = mat3(viewMatrix) * d;
  //d = -d;
  float t, lum;
  //d = inverse(transpose(viewMatrix)) * d;
  //trace((viewMatrix * vec4(0,0,0,1)).xyz, d.xyz, t, lum);
  vec4 o = viewMatrix * vec4(0,0,0,1);
  //vec4 o = vec4(0, -1.99, -0.2, 1);
  trace(o.xyz, d.xyz, t, lum);
  gl_FragDepth = 1.0 - lum;
  //trace(vec3(0,0,0), d.xyz, t, lum);
  if(lum > 0) {
    fragColor = vec3(lightPoint(o.xyz + t*d.xyz));
  } else {
    //fragColor = vec3(0,0,0);
    fragColor = d;
  }
}
