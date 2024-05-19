# set -x 1

PROGRAM=triangle
PLAT=win64
# PLAT=arm64
MODE=release

FLAGS="-d:nimDebugDlOpen"

if test $MODE = "release"; then
    FLAGS="$FLAGS -d:release --stacktrace:on --linetrace:on"
fi

if test $PLAT = "win64"; then
    FLAGS="$FLAGS -d:mingw --cpu:amd64"
    STRIP=x86_64-w64-mingw32-strip
    OUTPUT="$PROGRAM.exe"
elif test $PLAT = "arm64"; then
    export PATH="$PATH:/home/lilin/opt/trimui_smart_pro/aarch64-linux-gnu-7.5.0-linaro/bin"
    FLAGS="$FLAGS --cpu:arm64 --os:linux"
    STRIP=aarch64-linux-gnu-strip
    OUTPUT=$PROGRAM
else
    echo "unknown platform: $PLAT"
    exit 1
fi

nim c $FLAGS $PROGRAM.nim
if test $MODE = "release"; then
    $STRIP $OUTPUT
fi

if test $PLAT = "arm64"; then
    # scp *.bmp root@trimui:/mnt/SDCARD/Apps/hello/
    scp $PROGRAM root@trimui:/mnt/SDCARD/Apps/hello/hello
elif test $PLAT = "win64"; then
    cp $PROGRAM.exe /mnt/h/wsl2/gles
fi
