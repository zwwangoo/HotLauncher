#!/usr/bin/env bash
# 编译 → 组装 .app → ad-hoc 签名。不依赖 Xcode，只需 Command Line Tools，仅 arm64。
# 直接调用 swiftc 而不是 SwiftPM：本机 CLT 的 PackageDescription 模块与动态库版本不匹配，
# 任何 Package.swift 都无法链接；本工程无第三方依赖，swiftc 足够。
# 用法：scripts/build.sh [--install]    --install 会复制到 /Applications
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/swift-env.sh

APP_NAME="HotLauncher"
APP="build/$APP_NAME.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -parse-as-library "${SWIFT_FLAGS[@]}" \
    Sources/HotLauncher/*.swift \
    -o "$APP/Contents/MacOS/$APP_NAME"

cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

codesign --force --deep -s - "$APP"
codesign --verify --verbose=1 "$APP"
echo "已生成：${APP} ($(du -sh "$APP" | cut -f1))"

if [ "${1:-}" = "--install" ]; then
    pkill -x "$APP_NAME" 2>/dev/null || true
    rm -rf "/Applications/$APP_NAME.app"
    cp -R "$APP" "/Applications/$APP_NAME.app"
    echo "已安装到 /Applications/$APP_NAME.app"
fi
