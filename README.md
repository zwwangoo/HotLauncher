# HotLauncher

macOS 菜单栏小工具：按全局快捷键，启动或切换到指定应用。需求见 [docs/需求文档.md](docs/需求文档.md)。

## 构建与运行

```bash
scripts/build.sh            # 生成 build/HotLauncher.app（约 10 秒）
scripts/build.sh --install  # 同时安装到 /Applications 并重启
open build/HotLauncher.app
```

只需要 Command Line Tools，不需要 Xcode。仅支持 Apple Silicon（arm64），macOS 14+。菜单栏出现 ⌘ 图标后，点「设置…」添加应用并录制快捷键。
配置文件：`~/Library/Application Support/HotLauncher/config.json`。

## 打包给别人用（内部分发）

```bash
scripts/package.sh          # 生成 build/HotLauncher-<版本>.dmg（拖拽安装）
scripts/make-icon.sh        # 仅在修改 scripts/make-icon.swift 后重新生成 Resources/AppIcon.icns
```

没有 Developer ID 证书，应用是 ad-hoc 签名且未公证。接收方首次打开会被 Gatekeeper 拦截，放行方式二选一：

- 系统设置 → 隐私与安全性 → 点「仍要打开」；
- 或终端执行 `xattr -dr com.apple.quarantine /Applications/HotLauncher.app`。

版本号在 `Resources/Info.plist` 的 `CFBundleShortVersionString`。

## 为什么不用 SwiftPM / 为什么脚本里有 VFS 覆盖

在开发这台机器上，Command Line Tools 安装不一致，导致：

1. SwiftPM 的 `PackageDescription` 模块与动态库版本对不上，任何 `Package.swift` 都链接失败，所以直接用 `swiftc`。
2. `/Library/Developer/CommandLineTools/usr/include/swift/` 下同时存在旧残留的 `module.modulemap` 和 `bridging.modulemap`，
   报 `redefinition of module 'SwiftBridging'`，连 `import Foundation` 都编译不过。
   `scripts/swift-env.sh` 检测到这种情况时会用 VFS 覆盖在编译期屏蔽旧文件，不改动系统。

一劳永逸的修法（需要 sudo）：`sudo rm /Library/Developer/CommandLineTools/usr/include/swift/module.modulemap`，
或重装 Command Line Tools。修好后 `build.sh` 会自动不再启用覆盖。
