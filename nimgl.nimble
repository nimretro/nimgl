# Package

version = "0.0.1"
author = "Saniko"
description = "an OpenGL/GLES2 wrapper"
license = "MIT"

srcDir = "gl"

# Dependencies

when defined(windows):
  requires "nim >= 0.11.0"
else:
  requires "nim >= 0.11.0", "x11 >= 1.1"
