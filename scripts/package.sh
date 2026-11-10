#!/usr/bin/env bash
# 构建并打成 DMG（拖拽安装）：build/HotLauncher.dmg。
# 内部使用，ad-hoc 签名，未公证；接收方首次打开需按 README 的说明放行。
set -euo pipefail

cd "$(dirname "$0")/.."
APP_NAME="HotLauncher"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)"
DMG="build/$APP_NAME-$VERSION.dmg"

scripts/build.sh

STAGE="build/dmg-stage"
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "build/$APP_NAME.app" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

hdiutil create -quiet -volname "$APP_NAME" -srcfolder "$STAGE" -format UDZO -ov "$DMG"
rm -rf "$STAGE"
hdiutil verify -quiet "$DMG"
echo "已生成：${DMG} ($(du -h "$DMG" | cut -f1))"
