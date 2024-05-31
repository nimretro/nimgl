import ../../common

# settings
const
  SCR_WIDTH = 800
  SCR_HEIGHT = 600

  vertexShaderSource = """#version 320 es
precision highp float;
// In your vertex shader:
// ======================
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;

out vec3 ourColor;

uniform float xOffset;

void main()
{
    gl_Position = vec4(aPos.x + xOffset, aPos.y, aPos.z, 1.0); // add the xOffset to the x position of the vertex position
    ourColor = aColor;
}"""

  fragmentShaderSource = """#version 320 es
precision highp float;
out vec4 FragColor;
in vec3 ourColor;
void main()
{
   FragColor = vec4(ourColor, 1.0f);
}"""

import sdl2
import nimgl

type
  Context = object
    wnd: WindowPtr
    glc: GlContextPtr
    rdr: RendererPtr

    program: GLuint

    vao, vbo: GLuint

  ContextPtr = ptr Context

proc createBuffer(ctx: ContextPtr) =
  # set up vertex data (and buffer(s)) and configure vertex attributes
  # ------------------------------------------------------------------
  var vertices: array[18, GLfloat] = [
    # positions         # colors
    0.5f, -0.5f, 0.0f, 1.0f, 0.0f, 0.0f,          # bottom right
    -0.5f, -0.5f, 0.0f, 0.0f, 1.0f, 0.0f,         # bottom left
    0.0f, 0.5f, 0.0f, 0.0f, 0.0f, 1.0f            # top
  ];

  glGenVertexArrays(1, addr ctx.vao);
  glGenBuffers(1, addr ctx.vbo);
  # bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
  glBindVertexArray(ctx.vao);

  glBindBuffer(GL_ARRAY_BUFFER, ctx.vbo);
  glBufferData(GL_ARRAY_BUFFER, (sizeof vertices).GLsizeiptr, addr vertices,
      GL_STATIC_DRAW);

  # position attribute
  glVertexAttribPointer(0, 3, cGL_FLOAT, false, 6 * sizeof GLfloat, nil);
  glEnableVertexAttribArray(0);
  # color attribute
  glVertexAttribPointer(1, 3, cGL_FLOAT, false, 6 * sizeof GLfloat, cast[pointer](
      3 * sizeof GLfloat));
  glEnableVertexAttribArray(1);

  # You can unbind the VAO afterwards so other VAO calls won't accidentally modify this VAO, but this rarely happens. Modifying other
  # VAOs requires a call to glBindVertexArray anyways so we generally don't unbind VAOs (nor VBOs) when it's not directly necessary.
  # glBindVertexArray(0);

  # as we only have a single shader, we could also just activate our shader once beforehand if we want to
  glUseProgram(ctx.program);

  # In your CPP file:
  # ======================
  # ourShader.setFloat("xOffset", offset);
  var offset: GLfloat = 0.5f
  glUniform1f(glGetUniformLocation(ctx.program, "xOffset"), offset);

proc init(ctx: ContextPtr): ContextPtr =
  var wnd = sdl2.createWindow("LearnOpenGL", sdl2.SDL_WINDOWPOS_CENTERED,
      sdl2.SDL_WINDOWPOS_CENTERED, SCR_WIDTH, SCR_HEIGHT,
      sdl2.SDL_WINDOW_OPENGL + sdl2.SDL_WINDOW_SHOWN + SDL_WINDOW_RESIZABLE)

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
  glDeleteVertexArrays(1, addr ctx.vao);
  glDeleteBuffers(1, addr ctx.vbo);
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

  # render the triangle
  glBindVertexArray(ctx.vao);
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
