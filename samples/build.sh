# set -x 1
TRIMUI_HOST="192.168.3.7"

PROGRAM=${1-s01_triangle}
PLAT=${2-win64} # win64 or arm64
MODE=${3-release}

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
elif test $PLAT = "arm32"; then
    # export PATH="$PATH:/home/lilin/opt/trimui_smart_pro/aarch64-linux-gnu-7.5.0-linaro/bin"
    FLAGS="$FLAGS --cpu:arm --os:linux --opt:speed"
    STRIP=arm-linux-gnueabihf-strip
    OUTPUT=$PROGRAM
else
    echo "unknown platform: $PLAT"
    exit 1
fi

echo
echo PROGRAM: $PROGRAM
echo PLAT: $PLAT
echo MODE: $MODE
echo FLAGS: $FLAGS
echo

nim c $FLAGS $PROGRAM.nim
if test $MODE = "release"; then
    $STRIP $OUTPUT
fi

if test $PLAT = "arm64"; then
    # scp *.bmp root@$TRIMUI_HOST:/mnt/SDCARD/Apps/hello/
    scp $PROGRAM root@$TRIMUI_HOST:/mnt/SDCARD/Apps/sdlarch/sdlarch
    # scp $PROGRAM root@$TRIMUI_HOST:/mnt/SDCARD/Apps/hello/hello
elif test $PLAT = "arm32"; then
    # scp *.bmp root@$TRIMUI_HOST:/mnt/SDCARD/Apps/hello/
    # scp $PROGRAM root@$TRIMUI_HOST:/mnt/SDCARD/Apps/sdlarch/sdlarch
    scp $PROGRAM root@192.168.3.10:/mnt/sdcard/work
elif test $PLAT = "win64"; then
    cp $PROGRAM.exe /mnt/h/wsl2/gles
fi
