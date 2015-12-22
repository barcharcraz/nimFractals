## this package implements several 2D fractals and some methods
## of rendering them (currently brute force and greyscale)
## later orbit trap colors and such can be added, as well as rendering
## based on a distance estimation function

import vecmath
import complex
import freeimage
import math
import fractalData
type ETFormula = proc(z0: Complex, depth: int): int
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
proc mandelbrot*(z0: Complex, depth: int = 128): int {.procvar.} =
  var z: Complex = (0.0, 0.0)
  var k = 0
  while k < depth and distsq(z) < 4:
    z = z * z + z0
    result += 1
    inc(k)
proc burningship*(z0: Complex, depth: int = 128): int =
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
      result[x,y] = burningship((params.tl.x+x.float*params.step.x, params.tl.y+y.float*params.step.y), params.depth).uint8

proc calcMandelbrot*(params: FractalParams): MatX[uint8] =
  result = matX[uint8](params.res.x, params.res.y)
  for x in 1..params.res.x:
    for y in 1..params.res.y:
      result[x,y] = mandelbrot((params.tl.x+x.float*params.step.x, params.tl.y+y.float*params.step.y), params.depth).uint8

when isMainModule:
  proc main() =
    var mtx = calcMandelbrot(calcParams(vec2d(-2, 2), vec2d(2,-2), vec2i(2048,2048)))
    var bitmap = FreeImage_ConvertFromRawBits(addr mtx.data[0], mtx.cols.int32, mtx.rows.int32, mtx.cols.int32, 8, 0, 0, 0, 1)
    discard FreeImage_Save(FIF_BMP, bitmap, "mendelbrot.bmp", BMP_DEFAULT)
    FreeImage_DeInitialise()
  main()
