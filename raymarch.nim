{.experimental.}
import vecmath
import math
import freeimage
import times
## primitive is a distance function for our ray marcher

type Primitive* = proc(p: Vec3f): float
proc sphere*(p: Vec3f, r: float): float =
  result = length(p) - r
proc torus*(p: Vec3f, t: Vec2f): float =
  var q = vec2f(length(vec2f(p.x, p.z)) - t.x, p.y)
  return length(q) - t.y
proc plane*(p: Vec3f): float =
  result = p.y
proc map(p: Vec3f): float =
  #result = plane(p + vec3f(0, -2, 0))
  result = sphere(p - vec3f(0,0,20), 2)
  result = min(result, torus(p - vec3f(0.5, 1, 5), vec2f(0.5, 0.2)))
  #result = min(result, plane(p - vec3f(0, 2, 30)))
proc calcNormal(p: Vec3f): Vec3f =
  var eps = 0.001
  var x = map(p + vec3f(eps, 0, 0)) - map(p - vec3f(eps, 0, 0))
  var y = map(p + vec3f(0, eps, 0)) - map(p - vec3f(0, eps, 0))
  var z = map(p + vec3f(0, 0, eps)) - map(p - vec3f(0, 0, eps))
  result = vec3f(x,y,z)
  result = normalize(result)


proc trace*(origin, direction: Vec3f): tuple[t, s: float] =
  var totalDist = 0.0
  const maxSteps = 20
  const minDistance = 0.002
  var steps = 0

  while steps < maxSteps:
    var p = origin + totalDist * direction
    var dist = map(p)
    totalDist += dist
    if dist < minDistance: break
    inc steps
  result.s = 1.0 - float(steps)/float(maxSteps)
  result.t = totalDist

proc lightPoint(p: Vec3f, prim: Primitive): Vec3[uint8] =
  var n = calcNormal(p)
  #var n = normalize(p - vec3f(0,0,10))
  # we hardcode the matrial and light position and whatnot
  # assume all in eye space
  var v = normalize(p)

  # sunlight from the right side of the screen
  var l = normalize(vec3f(-1, 0, 1))
  var h = normalize(l + v)
  var color = vec3f(0,0,0)
  n = -1 * n
  # ambient color
  color += vec3f(0.1, 0.1, 0.1)
  var lambert = dot(n,l)
  if lambert > 0:
    color += 1 * lambert * vec3f(0.5,0.2,0.0)
  color += 1 * pow(dot(n, h), 250.0) * vec3f(0.5, 0.2, 0.0)
  color = vec3f(min(1.0, color.x), min(1.0, color.y), min(1.0, color.z))
  # convert our floating point vector to an integer vector for storage
  result = vec3[uint8](uint8(color.x * float(high(uint8))),
                       uint8(color.y * float(high(uint8))),
                       uint8(color.z * float(high(uint8))))


proc raymarchImagePoint(x,y: int, left, bottom, hstep, vstep, f: float): Vec3[uint8] =
  # direction of ray is s - e but e is always at (0,0,0) since we
  # are gunna raytrace in eye space like a sane human being
  var d = vec3f(left + float(x)*hstep, bottom + float(y)*vstep, f)

  var (t, lum) = trace(vec3f(0,0,0), d)
  #var lum8 = uint8(lum * float(high(uint8)))
  # we now need to do the shading
  if lum > 0:
    result = lightPoint(t * d, map)
  else:
    result = vec3[uint8](0,0,0)
proc raymarchImage*(width, height: int, fov: float, f: float): MatX[Vec3[uint8]] =
  ## fov is the horizontal fov
  var aspect = width.float / height.float
  var vfov = fov / aspect
  var hfov = fov
  result = matX[Vec3[uint8]](width, height)
  # compute the bounding box for our projective plane
  # the plane will end up having these corners and being
  # at z = f depth (the focal length)
  var left = -f * tan(hfov/2)
  var right = f * tan(hfov/2)
  var top = f * tan(vfov/2)
  var bottom = -f * tan(vfov/2)
  # these are positive, since right should be positive, left negitive
  # top positive and bottom negative
  var hstep = (right - left) / width.float
  var vstep = (top - bottom) / height.float
  assert hstep > 0
  assert hstep > 0
  for x in 0..<width:
    for y in 0..<height:
      result[x+1, y+1] = raymarchImagePoint(x,y,left,bottom,hstep,vstep,f)
    #result[x+1, y+1] = vec3[uint8](lum8, lum8, lum8)

when isMainModule:
  const width = 1024
  const height = 1024
  var image: MatX[Vec3[uint8]]
  var t = cpuTime()
  image = raymarchImage(width, height, PI/4, 1)
  var t2 = cpuTime()
  echo "Frame took: ", (t2 - t) * 1000, "ms"
  var bitmap = FreeImage_ConvertFromRawBits(addr image.data[0].data[0], image.cols.int32, image.rows.int32, image.cols.int32 * sizeof(Vec3[uint8]).int32, 24, 0xFF0000'u32, 0x00FF00'u32, 0x0000FF'u32, 1)
  discard FreeImage_Save(FIF_BMP, bitmap, "raymarch.bmp", BMP_DEFAULT)
  FreeImage_DeInitialise()
