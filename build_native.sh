#!/bin/bash
# ──────────────────────────────────────────────────────────────
# build_native.sh
# บิล libKeyAuthUI_native.dylib สำหรับ iOS arm64
# รัน: bash build_native.sh
# ต้องการ: Mac + Xcode
# ──────────────────────────────────────────────────────────────
set -e

SDK=$(xcrun --sdk iphoneos --show-sdk-path)
CC=$(xcrun --sdk iphoneos --find clang)
OUT="libKeyAuthUI_native.dylib"

echo "═══════════════════════════════════════"
echo " Building $OUT"
echo " SDK: $SDK"
echo "═══════════════════════════════════════"

"$CC" \
  -arch arm64 \
  -isysroot "$SDK" \
  -mios-version-min=14.0 \
  -std=c++17 \
  -fobjc-arc \
  -dynamiclib \
  -install_name @rpath/$OUT \
  -framework UIKit \
  -framework Foundation \
  -O2 \
  -o $OUT \
  KeyAuthUI_native.mm

echo ""
echo "✓ Done → $OUT"
ls -lh $OUT
file $OUT
