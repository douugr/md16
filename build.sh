#!/bin/bash
# Retro16: emulador de Mega Drive / Master System / Game Gear para iPad com iOS 8 (armv7).
# Core: Genesis Plus GX (libretro), compilado junto no app. Controle Bluetooth via BTstack.
#
# Uso:  ./build.sh            -> compila (build/Retro16.app)
#       ./build.sh install    -> compila e instala em /Applications do iPad (fora do sandbox, por causa do BTstack)
#       ./build.sh roms       -> envia as ROMs de ../roms para o iPad
#
# Variáveis: IPAD=192.168.1.105, X13=.../Xcode-13.4.1.app/Contents/Developer
set -euo pipefail
cd "$(dirname "$0")"

APP=Retro16
IPAD="${IPAD:-192.168.1.105}"
SSH_OPTS=(-o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa
          -o KexAlgorithms=+diffie-hellman-group14-sha1,diffie-hellman-group1-sha1)
ROOT="$(cd .. && pwd)"
GPGX_REPO=https://github.com/libretro/Genesis-Plus-GX.git
GPGX_COMMIT=b9c2316441978d4015ba30e9a95d9b0e6f8ee981

if [ "${1:-}" = "roms" ]; then
    SRC="$ROOT/roms"
    [ -d "$SRC" ] || { echo "Crie a pasta $SRC e coloque as ROMs nela." >&2; exit 1; }
    echo "==> Enviando ROMs de $SRC"
    ssh "${SSH_OPTS[@]}" "root@$IPAD" 'mkdir -p /var/mobile/Documents/Retro16/roms'
    COPYFILE_DISABLE=1 tar -C "$SRC" -cf - . | ssh "${SSH_OPTS[@]}" "root@$IPAD" \
        'tar -C /var/mobile/Documents/Retro16/roms -xf - && chown -R mobile:mobile /var/mobile/Documents/Retro16 && ls -la /var/mobile/Documents/Retro16/roms'
    exit 0
fi

X13="${X13:-$ROOT/Xcode-13.4.1.app/Contents/Developer}"
TC="$X13/Toolchains/XcodeDefault.xctoolchain/usr/bin"
SDK="$(ls -d "$X13"/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS*.sdk 2>/dev/null | head -1 || true)"
[ -x "$TC/clang" ] && [ -n "$SDK" ] || { echo "Toolchain do Xcode 13 não encontrado em: $X13" >&2; exit 1; }
export DEVELOPER_DIR="$X13"
JOBS="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

# --- BTstack (biblioteca do próprio iPad) ---
if [ ! -s vendor/libBTstack.dylib ]; then
    echo "==> Baixando /usr/lib/libBTstack.dylib do iPad ($IPAD)"
    ssh "${SSH_OPTS[@]}" "root@$IPAD" 'cat /usr/lib/libBTstack.dylib' > vendor/libBTstack.dylib.tmp || true
    [ -s vendor/libBTstack.dylib.tmp ] || { echo "Não consegui copiar a libBTstack.dylib do iPad." >&2; exit 1; }
    mv -f vendor/libBTstack.dylib.tmp vendor/libBTstack.dylib
fi
python3 tools/make_link_stub.py vendor/libBTstack.dylib vendor/libBTstackLink.dylib >/dev/null

# --- Core Genesis Plus GX ---
if [ ! -d core/gpgx/.git ]; then
    echo "==> Baixando Genesis Plus GX ($GPGX_COMMIT)"
    mkdir -p core
    git clone -q "$GPGX_REPO" core/gpgx
    git -C core/gpgx checkout -q "$GPGX_COMMIT"
fi

CORE_FLAGS=(-arch armv7 -isysroot "$SDK" -miphoneos-version-min=8.0 -O3 -DNDEBUG -w
    -DUSE_LIBTREMOR -DUSE_PER_SOUND_CHANNELS_CONFIG
    -I./core -I./core/z80 -I./core/m68k -I./core/ntsc -I./core/sound -I./core/sound/minimp3
    -I./core/input_hw -I./core/cd_hw -I./core/cart_hw -I./core/cart_hw/svp
    -I./libretro -I./libretro/libretro-common/include
    -DUSE_16BPP_RENDERING -DFRONTEND_SUPPORTS_RGB565 -DLSB_FIRST -DBYTE_ORDER=LITTLE_ENDIAN -DHAVE_ZLIB
    -D__LIBRETRO__ -DUSE_LIBRETRO_VFS -DM68K_OVERCLOCK_SHIFT=20 -DZ80_OVERCLOCK_SHIFT=20
    -DHAVE_YM3438_CORE -DHAVE_OPLL_CORE -DMAXROMSIZE=33554432 "-DINLINE=static inline")

OBJDIR="$PWD/build-core"
CORE_LIB="$OBJDIR/libgpgx.a"
if [ ! -f "$CORE_LIB" ]; then
    echo "==> Compilando o core (primeira vez demora alguns minutos)"
    mkdir -p "$OBJDIR"
    SOURCES=$(make -s -C core/gpgx -f Makefile.libretro platform=ios IOSSDK="$SDK" HAVE_CHD=0 print-SOURCES_C | sed 's/^SOURCES_C=//')
    printf '%s\n' $SOURCES > "$OBJDIR/sources.txt"
    export TC OBJDIR
    export CORE_FLAGS_STR="$(printf '%q ' "${CORE_FLAGS[@]}")"
    (cd core/gpgx && xargs -P "$JOBS" -n 1 bash -c 'eval "flags=($CORE_FLAGS_STR)"; o="$OBJDIR/$(echo "$0" | sed "s#^\./##; s#/#_#g").o"; "$TC/clang" "${flags[@]}" -c "$0" -o "$o" || exit 255' < "$OBJDIR/sources.txt")
    "$TC/libtool" -static -o "$CORE_LIB" "$OBJDIR"/*.o
    echo "==> Core: $(ls "$OBJDIR"/*.o | wc -l | tr -d ' ') arquivos objeto"
fi

# --- App ---
OUT="build/$APP.app"
rm -rf build && mkdir -p "$OUT"
echo "==> Compilando o app (armv7, iOS 8.0)"
"$TC/clang" -arch armv7 -isysroot "$SDK" -miphoneos-version-min=8.0 -B "$TC" \
    -fobjc-arc -O2 -Wall -Wno-unused-parameter -Wunguarded-availability \
    -I src -I vendor/btstack -I core/gpgx/libretro/libretro-common/include \
    src/*.m "$CORE_LIB" -o "$OUT/$APP" \
    -L vendor -lBTstackLink \
    -framework Foundation -framework UIKit -framework CoreGraphics -framework QuartzCore \
    -framework GLKit -framework OpenGLES -framework AudioToolbox -framework AVFoundation

cp Info.plist "$OUT/"
cp resources/*.png "$OUT/"
if command -v ldid >/dev/null 2>&1; then ldid -S "$OUT/$APP"; else codesign -f -s - "$OUT/$APP"; fi
lipo -info "$OUT/$APP"
echo "==> OK: $OUT ($(du -sh "$OUT" | cut -f1))"

if [ "${1:-}" = "install" ]; then
    echo "==> Instalando em /Applications/$APP.app"
    COPYFILE_DISABLE=1 tar -C build -cf - "$APP.app" | ssh "${SSH_OPTS[@]}" "root@$IPAD" \
        "rm -rf /Applications/$APP.app && tar -C /Applications -xf - && chown -R root:wheel /Applications/$APP.app && chmod -R 755 /Applications/$APP.app && mkdir -p /var/mobile/Documents/Retro16/roms && chown -R mobile:mobile /var/mobile/Documents/Retro16 && (su mobile -c uicache || uicache)"
    echo "==> Instalado."
fi
