import sdl2
import nimgl
import common

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

type
  Context = object
    wnd: WindowPtr
    glc: GlContextPtr
    rdr: RendererPtr

    vao, vbo: GLuint
    shaderProgram: GLuint

  ContextPtr = ptr Context

proc createBuffer(ctx: ContextPtr) =
  # Create Vertex Array Object
  var vao: GLuint
  glGenVertexArrays(1, addr vao)
  glBindVertexArray(vao)

  # Create a Vertex Buffer Object and copy the vertex data to it
  var vbo: GLuint
  glGenBuffers(1, addr vbo)

  var vertices: array[6, GLfloat] = [0.0f, 0.5f, 0.5f, -0.5f, -0.5f, -0.5f]

  glBindBuffer(GL_ARRAY_BUFFER, vbo)
  glBufferData(GL_ARRAY_BUFFER, cint(sizeof vertices), addr vertices, GL_STATIC_DRAW)

  ctx.vao = vao
  ctx.vbo = vbo

proc createShader(ctx: ContextPtr) =
  var shaderProgram = common.loadShaderProgram(vertexSource, fragmentSource)
  glUseProgram(shaderProgram)

  # Specify the layout of the vertex data
  var posAttrib = glGetAttribLocation(shaderProgram, "position")
  glEnableVertexAttribArray(GLuint(posAttrib))
  glVertexAttribPointer(GLuint(posAttrib), 2, cGL_FLOAT, false, 0, nil)

  ctx.shaderProgram = shaderProgram

proc init(ctx: ContextPtr): ContextPtr =
  # // SDL_Init(SDL_INIT_VIDEO)
  var wnd = sdl2.createWindow("test", sdl2.SDL_WINDOWPOS_CENTERED,
      sdl2.SDL_WINDOWPOS_CENTERED, 1280, 720, sdl2.SDL_WINDOW_OPENGL +
      sdl2.SDL_WINDOW_SHOWN)

  var glc = createOpenGLContext(wnd)
  if glc == nil:
    quit(1)

  var rdr = sdl2.createRenderer(wnd, -1, Renderer_Accelerated + Renderer_TargetTexture)
  if rdr == nil:
    quit(1)

  discard sdl2.glMakeCurrent(wnd, glc)

  ctx.wnd = wnd
  ctx.glc = glc
  ctx.rdr = rdr

  ctx.createBuffer
  ctx.createShader

  result = ctx

proc destroy(ctx: ContextPtr) =
  ctx.rdr.destroy
  ctx.wnd.destroy

proc draw(ctx: ContextPtr) =
  # Clear the screen to black
  glClearColor(0.5f, 0.0f, 0.0f, 1.0f)
  glClear(GL_COLOR_BUFFER_BIT)

  # Draw a triangle from the 3 vertices
  glDrawArrays(GL_TRIANGLES, 0, 3)

proc main(): void =
  var ctx = create(Context, 1).init()
  defer: ctx.destroy

  var e: sdl2.Event
  while true:
    var quit = false

    while sdl2.pollEvent(e):
      if e.kind == sdl2.QuitEvent:
        quit = true
        break

    if quit:
      break

    ctx.draw

    sdl2.glSwapWindow(ctx.wnd)

main()
