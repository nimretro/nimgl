import nimgl
import sequtils
import std/strutils
import std/strformat

proc die*(args: varargs[string, `$`]) =
  echo(args.join(" "))
  writeStackTrace()
  quit(1)

proc compileShader*(typ: GLenum, source: string): GLuint =
  # Create and compile the fragment shader
  var shader = glCreateShader(typ)
  var csa = allocCStringArray([source])
  defer: deallocCStringArray(csa)
  glShaderSource(shader, 1, csa, nil)
  glCompileShader(shader)
  var success: GLint
  glGetShaderiv(shader, GL_COMPILE_STATUS, addr success)
  if success == 0:
    var infoLog: array[512, GLchar]
    glGetShaderInfoLog(shader, 512, nil, cast[cstring](addr infoLog[0]))
    glDeleteShader(shader)

    var buffer = cast[string](sequtils.filter(infoLog, proc(
        x: GLchar): bool = x > 0))

    if typ == GL_VERTEX_SHADER:
      die(fmt("Failed to compile vertex shader: {buffer}"))
    else:
      die(fmt("Failed to compile fragment shader: {buffer}"))

  shader

proc loadShaderProgram*(vertexSource, fragmentSource: string): GLuint =
  # Create and compile the vertex shader
  var vertexShader = compileShader(GL_VERTEX_SHADER, vertexSource)

  # Create and compile the fragment shader
  var fragmentShader = compileShader(GL_FRAGMENT_SHADER, fragmentSource)

  # Link the vertex and fragment shader into a shader program
  var shaderProgram = glCreateProgram()
  glAttachShader(shaderProgram, vertexShader)
  glAttachShader(shaderProgram, fragmentShader)

  glLinkProgram(shaderProgram)

  # glDeleteShader(vertexShader)
  # glDeleteShader(fragmentShader)

  glValidateProgram(shaderProgram)

  var status: GLint
  glGetProgramiv(shaderProgram, GL_LINK_STATUS, addr status)

  if status == GL_FALSE:
    var buffer: array[4096, char]
    glGetProgramInfoLog(shaderProgram, GLsizei(sizeof buffer), nil, cast[
        cstring](addr buffer))
    die("Failed to link shader program: %s", buffer)

  shaderProgram
