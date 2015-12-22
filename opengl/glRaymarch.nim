import opengl
import glfw
import math
import vecmath
const width = 1920
const height = 1080
const fov = PI/4
const focal = 1.0


proc checkProgramErrors(program: GLuint): (bool, string) =
  var status: GLint
  var infoLogLen: GLint
  glGetProgramiv(program, GL_LINK_STATUS, addr status)
  if status == GL_FALSE:
    glGetProgramiv(program, GL_INFO_LOG_LENGTH.GLenum, addr infoLogLen)
    var errString = newString(infoLogLen)
    glGetProgramInfoLog(program, infoLogLen, nil, errString.cstring)
    return (true, errString)
  return (false, "")

proc checkShaderErrors(program: GLuint): (bool, string) =
  var status: GLint
  var infoLogLen: GLint
  glGetShaderiv(program, GL_COMPILE_STATUS.GLenum, addr status)
  if status == GL_FALSE:
    glGetShaderiv(program, GL_INFO_LOG_LENGTH.GLenum, addr infoLogLen)
    var errString = newString(infoLogLen)
    glGetShaderInfoLog(program, infoLogLen, nil, errString.cstring)
    return (true, errString)
  return (false, "")


proc loadProgram(vs, ps: string): GLuint =
  var source = readFile(vs)
  var sourceStr: cstring = source
  var vsProgram = glCreateShader(GL_VERTEX_SHADER)
  glShaderSource(vsProgram, 1.GLSizei, cast[cstringArray](addr sourceStr), nil)
  glCompileShader(vsProgram)
  var (err, errString) = checkShaderErrors(vsProgram)
  if err:
    echo "error compiling vertex shader"
    echo errString
    quit QuitFailure


  var fsProgram = glCreateShader(GL_FRAGMENT_SHADER)
  source = readFile(ps)
  sourceStr = source
  glShaderSource(fsProgram, 1.GLsizei, cast[cstringArray](addr sourceStr), nil)
  glCompileShader(fsProgram)
  (err, errString) = checkShaderErrors(fsProgram)
  if err:
    echo "error compiling fragment shader"
    echo errString
    quit QuitFailure

  result = glCreateProgram()
  glAttachShader(result, vsProgram)
  glAttachShader(result, fsProgram)
  glLinkProgram(result)

  glDetachShader(result, vsProgram)
  glDetachShader(result, fsProgram)
  glDeleteShader(vsProgram)
  glDeleteShader(fsProgram)

proc setUniforms(program: GLuint) =
  glUseProgram(program)
  var resolutionLoc = glGetUniformLocation(program, "resolution")
  if resolutionLoc == -1: quit("resolution uniform not active")
  var fovLoc = glGetUniformLocation(program, "fov");
  if fovLoc == -1: quit("fov uniform not active")
  var focalLoc = glGetUniformLocation(program, "focal")
  if focalLoc == -1: quit("focal uniform not active")
  var viewMatrixLoc = glGetUniformLocation(program, "viewMatrix")
  #if viewMatrixLoc == -1: quit("view matrix uniform not active")
  glUniform2i(resolutionLoc, width, height)
  glUniform1f(fovLoc, fov)
  glUniform1f(focalLoc, focal)
  var viewMtx = CreateViewMatrix(vec3f(0, -10, -10), vec3f(0,0,20))
  echo vecmath.`$`(viewMtx)
  #var viewMtx = toTranslationMatrix(vec3f(0, -0.2, 0))
  glUniformMatrix4fv(viewMatrixLoc, 1, false, addr viewMtx.data[0])


proc onKeyPress(o: Win, key: Key, scanCode: int, action: KeyAction, modKeys: ModifierKeySet) =
  if action != kaDown: return
  if key == keyA:
    if glIsEnabled(GL_MULTISAMPLE):
      glDisable(GL_MULTISAMPLE)
    else:
      glEnable(GL_MULTISAMPLE)

var vertices = [vec3f(-1, -1, 0), vec3f(1, -1, 0), vec3f(1,1,0), vec3f(-1, 1, 0)]
var indices = [0'u32, 1, 2, 0, 2, 3]

proc main() =
  glfw.init()
  var done = false
  var win = newGlWin(
    dim = (w: width, h: height),
    version = glv44,
    profile = glpCore,
    nMultiSamples = 4
  )
  win.keyCb = onKeyPress
  makeContextCurrent(win)
  loadExtensions()
  glEnable(GL_DEPTH_TEST)
  glDepthFunc(GL_LEQUAL)
  glDepthMask(true)
  glDepthRange(0.0'f32, 1.0'f32)
  glEnable(GL_CULL_FACE)
  glFrontFace(GL_CCW)
  glEnable(GL_MULTISAMPLE)
  var prog = loadProgram("raymarch.vs", "raymarch.fs")
  setUniforms(prog)

  var vao: GLuint
  var vbo: GLuint
  var indexArray: GLuint
  glGenVertexArrays(1, addr vao)
  glBindVertexArray(vao)
  glEnableVertexAttribArray(0)
  glGenBuffers(1, addr vbo)
  glGenBuffers(1, addr indexArray)
  glBindBuffer(GL_ARRAY_BUFFER, vbo)
  glBufferData(GL_ARRAY_BUFFER, GLsizeiptr(len(vertices) * sizeof(Vec3f)), addr vertices[0], GL_STATIC_DRAW)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexArray)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, len(indices) * sizeof(uint32), addr indices[0], GL_STATIC_DRAW)
  glVertexAttribPointer(0, 3, cGL_FLOAT, false, 0.GLsizei, cast[pointer](0))


  while not done and not win.shouldClose:
    glDrawElements(GL_TRIANGLES, len(indices).GLsizei, GL_UNSIGNED_INT, cast[pointer](0))
    win.update()
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)

  win.destroy()
  glfw.terminate()


main()
