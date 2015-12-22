import vecmath
import complex
import math
import fractalData

proc distsq(c: Complex): float =
  var x,y,temp: float
  x = abs(c.re)
  y = abs(c.im)
  if x == 0.0:
    result = y*y
  elif y == 0.0:
    result = x*x
  elif x > y:
    temp = y / x
    result = x * (1.0 + temp * temp)
  else:
    temp = x / y
    result = y * (1.0 + temp * temp)

proc orbit*(z0: Complex, depth: int = 128): int =
  var z: Complex = (0.0, 0.0)
  var k = 0
  while k < depth and abs(z) < 2:
    var zp = (abs(z.re), abs(z.im))
    z = zp*zp + z0
    inc(result)
    inc(k)

proc calcBurningship*(params: FractalParams): MatX[uint8] =
  result = matX[uint8](params.res.x, params.res.y)
  for x in 1..params.res.x:
    for y in 1..params.res.y:
      result[x,y] = orbit((params.tl.x+x.float*params.step.x, params.tl.y+y.float*params.step.y), params.depth).uint8
