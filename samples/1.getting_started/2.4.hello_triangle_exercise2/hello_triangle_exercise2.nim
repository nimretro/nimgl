import ../../common

# settings
const
  SCR_WIDTH = 800
  SCR_HEIGHT = 600

  vertexShaderSource = """#version 320 es
precision highp float;
layout (location = 0) in vec3 aPos;
void main()
{
   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
}"""

  fragmentShaderSource = """#version 320 es
precision highp float;
out vec4 FragColor;
void main()
{
   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}"""

import sdl2
import nimgl

type
  Context = object
    wnd: WindowPtr
    glc: GlContextPtr
    rdr: RendererPtr

    program: GLuint

    vaos, vbos: array[2, GLuint]

  ContextPtr = ptr Context

proc createBuffer(ctx: ContextPtr) =
  # set up vertex data (and buffer(s)) and configure vertex attributes
  # ------------------------------------------------------------------
  var firstTriangle: array[9, GLfloat] = [
    -0.9f, -0.5f, 0.0f, # left
    -0.0f, -0.5f, 0.0f, # right
    -0.45f, 0.5f, 0.0f, # top
  ];

  var secondTriangle: array[9, GLfloat] = [
    0.0f, -0.5f, 0.0f, # left
    0.9f, -0.5f, 0.0f, # right
    0.45f, 0.5f, 0.0f  # top
  ];

  # we can also generate multiple VAOs or buffers at the same time
  glGenVertexArrays(2, addr ctx.vaos[0]);
  glGenBuffers(2, addr ctx.vbos[0]);

  # first triangle setup
  # --------------------
  glBindVertexArray(ctx.vaos[0]);
  glBindBuffer(GL_ARRAY_BUFFER, ctx.vbos[0]);
  glBufferData(GL_ARRAY_BUFFER, (sizeof firstTriangle).GLsizeiptr, addr firstTriangle, GL_STATIC_DRAW);

  # Vertex attributes stay the same
  glVertexAttribPointer(0, 3, cGL_FLOAT, false, 3 * sizeof float, nil);
  glEnableVertexAttribArray(0);
  # glBindVertexArray(0); # no need to unbind at all as we directly bind a different VAO the next few lines

  # second triangle setup
  # ---------------------

  # note that we bind to a different VAO now
  glBindVertexArray(ctx.vaos[1]);
  # and a different VBO
  glBindBuffer(GL_ARRAY_BUFFER, ctx.vbos[1]);
  glBufferData(GL_ARRAY_BUFFER, sizeof(secondTriangle).GLsizeiptr, addr secondTriangle, GL_STATIC_DRAW);
  # because the vertex data is tightly packed we can also specify 0 as the vertex attribute's stride to let OpenGL figure it out
  glVertexAttribPointer(0, 3, cGL_FLOAT, false, 0, nil);
  glEnableVertexAttribArray(0);

  # not really necessary as well, but beware of calls that could affect VAOs while this one is bound (like binding element buffer objects, or enabling/disabling vertex attributes)
  # glBindVertexArray(0);

proc init(ctx: ContextPtr): ContextPtr =
  var wnd = sdl2.createWindow("LearnOpenGL", sdl2.SDL_WINDOWPOS_CENTERED,
      sdl2.SDL_WINDOWPOS_CENTERED, SCR_WIDTH, SCR_HEIGHT,
      sdl2.SDL_WINDOW_OPENGL + sdl2.SDL_WINDOW_SHOWN)

  var glc = createOpenGLContext(wnd)
  if glc == nil:
    quit(1)

  var rdr = sdl2.createRenderer(wnd, -1, Renderer_Accelerated + Renderer_TargetTexture)
  if rdr == nil:
    quit(1)

  discard sdl2.glMakeCurrent(wnd, glc)

  ctx.program = loadShaderProgram(vertexShaderSource, fragmentShaderSource)

  ctx.createBuffer

  ctx.wnd = wnd
  ctx.glc = glc
  ctx.rdr = rdr

  result = ctx

proc destroy(ctx: ContextPtr) =
  ctx.rdr.destroy
  ctx.wnd.destroy

  # optional: de-allocate all resources once they've outlived their purpose:
  # ------------------------------------------------------------------------
  glDeleteVertexArrays(2, addr ctx.vaos[0]);
  glDeleteBuffers(2, addr ctx.vbos[0]);
  glDeleteProgram(ctx.program);

# whenever the window size changed (by OS or user resize) this callback function executes
proc resize(ctx: ContextPtr, width, height: cint) =
  # make sure the viewport matches the new window dimensions; note that width and
  # height will be significantly larger than specified on retina displays.
  glViewport(0, 0, width, height);

proc draw(ctx: ContextPtr) =
  # render
  # ------
  glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);

  glUseProgram(ctx.program);
  # draw first triangle using the data from the first VAO
  glBindVertexArray(ctx.vaos[0]);
  glDrawArrays(GL_TRIANGLES, 0, 3);
  # then we draw the second triangle using the data from the second VAO
  glBindVertexArray(ctx.vaos[1]);
  glDrawArrays(GL_TRIANGLES, 0, 3);

  # sdl: swap buffers
  sdl2.glSwapWindow(ctx.wnd)

proc main(): void =
  var ctx = create(Context, 1).init()
  defer: ctx.destroy

  # when defined(windows):
  #   # uncomment this call to draw in wireframe polygons.
  #   glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

  var e: sdl2.Event
  while true:
    var quit = false

    while sdl2.pollEvent(e):
      if e.kind == sdl2.QuitEvent:
        quit = true
        break
      if e.kind == sdl2.WindowEvent and e.window.event == WindowEvent_Resized:
        ctx.resize(e.window.data1, e.window.data2)

    if quit:
      break

    ctx.draw

main()
