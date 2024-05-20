import sdl2
import ../gl/opengl

import sequtils

const
  vertexSource = """#version 320 es
precision highp float;
in vec4 position;
void main() {
  gl_Position = vec4(position.xyz, 1.0);
}
"""

  fragmentSource = """#version 320 es
precision mediump float;
out vec4 fragColor;
void main() {
  fragColor = vec4 (1.0, 1.0, 1.0, 1.0 );
}
"""

const
  SDL_RENDERER_ACCELERATED = 0x00000002
  SDL_RENDERER_TARGETTEXTURE = 0x00000008

proc main(): void =
  # // SDL_Init(SDL_INIT_VIDEO)
  var wnd = sdl2.createWindow("test", sdl2.SDL_WINDOWPOS_CENTERED,
      sdl2.SDL_WINDOWPOS_CENTERED, 1280, 720, sdl2.SDL_WINDOW_OPENGL +
      sdl2.SDL_WINDOW_SHOWN)
  defer: sdl2.destroy(wnd)

  discard sdl2.glSetAttribute(sdl2.SDL_GL_CONTEXT_MAJOR_VERSION, 2)
  discard sdl2.glSetAttribute(sdl2.SDL_GL_CONTEXT_MINOR_VERSION, 0)
  discard sdl2.glSetSwapInterval(0)
  discard sdl2.glSetAttribute(sdl2.SDL_GL_DOUBLEBUFFER, 1)
  discard sdl2.glSetAttribute(sdl2.SDL_GL_DEPTH_SIZE, 24)

  var glc = createOpenGLContext(wnd)
  if glc == nil:
    quit(1)

  var rdr = sdl2.createRenderer(wnd, -1, SDL_RENDERER_ACCELERATED + SDL_RENDERER_TARGETTEXTURE)
  if rdr == nil:
    quit(1)

  discard sdl2.glMakeCurrent(wnd, glc)

  # Create Vertex Array Object
  var vao: GLuint
  glGenVertexArrays(1, addr vao)
  glBindVertexArray(vao)

  # Create a Vertex Buffer Object and copy the vertex data to it
  var vbo: GLuint
  glGenBuffers(1, addr vbo)

  # var info : sdl2.RendererInfo
  # for i in 0..sdl2.getNumRenderDrivers()-1:
  #   discard sdl2.getRenderDriverInfo(i, info)
  #   echo(info)

  var vertices: array[6, GLfloat] = [0.0f, 0.5f, 0.5f, -0.5f, -0.5f, -0.5f]

  glBindBuffer(GL_ARRAY_BUFFER, vbo)
  glBufferData(GL_ARRAY_BUFFER, cint(sizeof vertices), addr vertices, GL_STATIC_DRAW)

  # Create and compile the vertex shader
  var vertexShader = glCreateShader(GL_VERTEX_SHADER)
  var vs = allocCStringArray([vertexSource])
  defer: deallocCStringArray(vs)
  glShaderSource(vertexShader, 1, vs, nil)
  glCompileShader(vertexShader)
  var success: GLint
  glGetShaderiv(vertexShader, GL_COMPILE_STATUS, addr success)
  if success == 0:
    var infoLog: array[512, GLchar]
    glGetShaderInfoLog(vertexShader, 512, nil, addr infoLog[0])
    glDeleteShader(vertexShader)
    echo(cast[string](sequtils.filter(infoLog, proc(x: GLchar): bool = int(
        x) > 0)))
    quit(1)

  # Create and compile the fragment shader
  var fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
  var fs = allocCStringArray([fragmentSource])
  defer: deallocCStringArray(fs)
  glShaderSource(fragmentShader, 1, fs, nil)
  glCompileShader(fragmentShader)
  glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, addr success)
  if success == 0:
    var infoLog: array[512, GLchar]
    glGetShaderInfoLog(fragmentShader, 512, nil, addr infoLog[0])
    glDeleteShader(fragmentShader)
    echo(cast[string](sequtils.filter(infoLog, proc(x: GLchar): bool = int(
        x) > 0)))
    quit(1)

  # Link the vertex and fragment shader into a shader program
  var shaderProgram = glCreateProgram()
  glAttachShader(shaderProgram, vertexShader)
  glAttachShader(shaderProgram, fragmentShader)
  # // glBindFragDataLocation(shaderProgram, 0, "outColor")
  glLinkProgram(shaderProgram)
  glUseProgram(shaderProgram)
  writeStackTrace()

  # Specify the layout of the vertex data
  var posAttrib = glGetAttribLocation(shaderProgram, "position")
  glEnableVertexAttribArray(GLuint(posAttrib))
  glVertexAttribPointer(GLuint(posAttrib), 2, cGL_FLOAT, false, 0, nil)

  var e: sdl2.Event
  while true:
    var quit = false

    while sdl2.pollEvent(e):
      if e.kind == sdl2.QuitEvent:
        quit = true
        break

    if quit:
      break

    # Clear the screen to black
    glClearColor(0.5f, 0.0f, 0.0f, 1.0f)
    glClear(GL_COLOR_BUFFER_BIT)

    # Draw a triangle from the 3 vertices
    glDrawArrays(GL_TRIANGLES, 0, 3)

    sdl2.glSwapWindow(wnd)

main()
