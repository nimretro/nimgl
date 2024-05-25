import sdl2
import nimgl
import common

const
  vertexSource = """#version 300 es
layout(location = 0) in vec4 a_postion;
layout(location = 1) in vec2 a_texCoord;
out vec2 v_texCoord;
void main() {
    gl_Position = a_postion;
    v_texCoord = a_texCoord;
}
"""

  fragmentSource = """#version 300 es
precision mediump float;
in vec2 v_texCoord;
layout(location = 0) out vec4 outColor;
uniform sampler2D s_texture;
void main() {
    outColor = texture(s_texture, v_texCoord);
}
"""

type
  Context = object
    wnd: WindowPtr
    glc: GlContextPtr
    rdr: RendererPtr

    vao, vbo: GLuint
    textureId: GLuint

    shaderProgram: GLuint
    samplerLoc: GLint

  ContextPtr = ptr Context

proc createSimplerTexture2D(ctx: ContextPtr) =
  # Texture object handle
  var textureId: GLuint

  # 2x2 Image, 3 bytes per pixel (R, G, B)
  var pixels: array[4 * 3, GLubyte] = [
    255, 0, 0,
    0, 255, 0,
    0, 0, 255,
    255, 255, 0,
  ]

  # Use tightly packed data
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

  # Generate a texture object
  glGenTextures(1, addr textureId);

  # Bind the texture object
  nimgl.glBindTexture(GL_TEXTURE_2D, textureId);

  # Load the texture
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB.GLint, 2, 2, 0, GL_RGB,
      GL_UNSIGNED_BYTE, addr pixels[0]);

  # Set the filtering mode
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.GLint);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint);

  ctx.textureId = textureId;

proc createBuffer(ctx: ContextPtr) =
  # Create Vertex Array Object
  var vao: GLuint
  glGenVertexArrays(1, addr vao)
  glBindVertexArray(vao)

  # Create a Vertex Buffer Object and copy the vertex data to it
  var vbo: GLuint
  glGenBuffers(1, addr vbo)

  var vertices: array[20, GLfloat] = [
    -1f, 1f, 0.0f,  # Position 0
    0.0f, 0.0f,     # TexCoord 0
    -1f, -1f, 0.0f, # Position 1
    0.0f, 1.0f,     # TexCoord 1
    1f, -1f, 0.0f,  # Position 2
    1.0f, 1.0f,     # TexCoord 2
    1f, 1f, 0.0f,   # Position 3
    1.0f, 0.0f,     # TexCoord 3
  ];

  glBindBuffer(GL_ARRAY_BUFFER, vbo)
  glBufferData(GL_ARRAY_BUFFER, cint(sizeof vertices), addr vertices, GL_STREAM_DRAW)

  ctx.vao = vao
  ctx.vbo = vbo

proc createShader(ctx: ContextPtr) =
  var shaderProgram = common.loadShaderProgram(vertexSource, fragmentSource)
  glUseProgram(shaderProgram)

  ctx.createBuffer

  var a_postion = glGetAttribLocation(shaderProgram, "a_postion").GLuint
  var a_texCoord = glGetAttribLocation(shaderProgram, "a_texCoord").GLuint

  glEnableVertexAttribArray(a_postion)
  glEnableVertexAttribArray(a_texCoord)

  glVertexAttribPointer(a_postion, 3, cGL_FLOAT, false, sizeof(GLfloat) * 5, nil)
  glVertexAttribPointer(a_texCoord, 2, cGL_FLOAT, false, sizeof(GLfloat) * 5, cast[
      pointer](3 * sizeof(GLfloat)))

  ctx.samplerLoc = glGetUniformLocation(shaderProgram, "s_texture")

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

  ctx.createSimplerTexture2D
  ctx.createShader

  result = ctx

proc destroy(ctx: ContextPtr) =
  ctx.rdr.destroy
  ctx.wnd.destroy

proc draw(ctx: ContextPtr) =
  var indices: array[6, GLushort] = [0, 1, 2, 0, 2, 3];

  # Set the viewport
  glViewport(0, 0, 1280, 720);

  # Clear the color buffer
  glClear(GL_COLOR_BUFFER_BIT);

  # Bind the texture
  glActiveTexture(GL_TEXTURE0);
  nimgl.glBindTexture(GL_TEXTURE_2D, ctx.textureId);

  # Set the sampler texture unit to 0
  glUniform1i(ctx.samplerLoc, 0);

  glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, addr indices);

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
