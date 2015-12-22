import vecmath
type FractalParams* = object
  res*: Vec2i
  step*: Vec2d
  tl*: Vec2d
  br*: Vec2d
  depth*: int
proc calcParams*(tl,br: Vec2d, res: Vec2i, depth: int = 128): FractalParams =
  var dx = br.x - tl.x
  var dy = br.y - tl.y
  var xstep = dx / res.x.float
  var ystep = dy / res.y.float
  result.res = res
  result.tl = tl
  result.br = br
  result.depth = depth
  result.step = vec2d(xstep, ystep)
proc calcParams*(tl,br: Vec2d, res: int, depth: int = 128) : FractalParams =
  var dx = br.x - tl.x
  var dy = br.y - tl.y
  var resx = res
  var resy = res
  var xstep = dx / res.float
  var ystep = dy / res.float
  if dx > dy:
    resy = (dy / xstep).int
  else:
    resx = (dx / ystep).int
  result.res = vec2i(resx,resy)
  result.tl = tl
  result.br = br
  result.depth = depth
  result.step = vec2d(xstep, ystep)
