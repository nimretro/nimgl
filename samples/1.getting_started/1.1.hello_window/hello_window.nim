# settings
const
  SCR_WIDTH = 800
  SCR_HEIGHT = 600

import sdl2
import nimgl

type
  Context = object
    wnd: WindowPtr
    glc: GlContextPtr
    rdr: RendererPtr

  ContextPtr = ptr Context

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

  ctx.wnd = wnd
  ctx.glc = glc
  ctx.rdr = rdr

  result = ctx

proc destroy(ctx: ContextPtr) =
  ctx.rdr.destroy
  ctx.wnd.destroy

# whenever the window size changed (by OS or user resize) this callback function executes
proc resize(ctx: ContextPtr, width, height: cint) =
  # make sure the viewport matches the new window dimensions; note that width and
  # height will be significantly larger than specified on retina displays.
  glViewport(0, 0, width, height);

proc draw(ctx: ContextPtr) =
  # sdl: swap buffers
  sdl2.glSwapWindow(ctx.wnd)

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
      if e.kind == sdl2.WindowEvent and e.window.event == WindowEvent_Resized:
        ctx.resize(e.window.data1, e.window.data2)

    if quit:
      break

    ctx.draw

main()
