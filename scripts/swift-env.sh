# 被其他脚本 source：设置 SWIFT_FLAGS（编译 Swift 时通用的参数）。
#
# 兼容 CLT 残留文件：/Library/Developer/CommandLineTools/usr/include/swift 下若同时存在
# module.modulemap（旧版残留）和 bridging.modulemap，会报 "redefinition of module 'SwiftBridging'"，
# 导致连 import Foundation 都编译不过。此时用 VFS 覆盖在编译期把旧文件映射为空，不改动系统文件。
# 一劳永逸的修法：sudo rm /Library/Developer/CommandLineTools/usr/include/swift/module.modulemap
#
# 调用前需已 cd 到项目根目录。仅支持 Apple Silicon（arm64）。

mkdir -p build
SWIFT_FLAGS=(-swift-version 5 -target arm64-apple-macos14.0)

SWIFT_INC="/Library/Developer/CommandLineTools/usr/include/swift"
if [ -f "$SWIFT_INC/module.modulemap" ] && [ -f "$SWIFT_INC/bridging.modulemap" ]; then
    : > build/empty.modulemap
    cat > build/vfs.yaml <<EOF
{ "version": 0, "case-sensitive": false, "roots": [ { "name": "$SWIFT_INC", "type": "directory",
  "contents": [ { "name": "module.modulemap", "type": "file", "external-contents": "$PWD/build/empty.modulemap" } ] } ] }
EOF
    SWIFT_FLAGS+=(-vfsoverlay "$PWD/build/vfs.yaml" -Xcc -ivfsoverlay -Xcc "$PWD/build/vfs.yaml")
fi
