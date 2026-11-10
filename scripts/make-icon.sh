#!/usr/bin/env bash
# 重新生成 Resources/AppIcon.icns。改了 scripts/make-icon.swift 才需要运行，
# 生成结果已提交到仓库，日常构建不会调用本脚本。
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/swift-env.sh

swiftc "${SWIFT_FLAGS[@]}" scripts/make-icon.swift -o build/make-icon
rm -rf build/AppIcon.iconset
build/make-icon build/AppIcon.iconset
iconutil -c icns build/AppIcon.iconset -o Resources/AppIcon.icns
echo "已生成：Resources/AppIcon.icns ($(du -h Resources/AppIcon.icns | cut -f1))"
