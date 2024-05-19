{.push warning[User]: off.}

when defined(windows):
  const dllname* = "libGLESv2.dll"
  const egldll* = "libEGL.dll"
elif defined(macosx):
  const dllname* = "TODO:"
else:
  const dllname* = "libGLESv2.so(|.2)"

{.pop.} # warning[User]: off
