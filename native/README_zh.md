# 三平台原生光标预览版

需要同时安装本仓库的 `main.lua` 和 `resources/`。普通 Workshop Lua 订阅不能自动安装或启动这些原生组件。

统一行为：

| Always Show Cursor | 外层菜单 | 游戏内（含暂停） |
|---|---|---|
| OFF（默认） | 隐藏 | 隐藏；鼠标瞄准道具需要时显示准星 |
| ON | 系统箭头 | 持续显示白／红准星 |

三平台使用相同的 Lua 存档、F10 / Mod Config Menu 设置和日志状态协议。系统光标仅在游戏内容区域内处理，不锁定、捕获鼠标，不更换系统光标资源。移出窗口或切换应用后释放处理。

## macOS 原生 Afterbirth+

沿用 `macos/try.command`，需要本机已有的 IsaacDyldShim 启动修复。
启动器加载 `HideCursor.dylib`；普通 Steam 启动不会自动加载。
支持 Intel 游戏进程。Apple Silicon 运行 Intel 游戏需要 Rosetta，尚未在本次验证。

## Windows 原生版

1. 安装新版 Lua 插件，正常启动游戏。
2. 双击 `windows/attach.cmd`，保持控制台打开。
3. 脚本根据游戏二进制自动选择 x86 / x64 组件，并从游戏 `savedatapath.txt` 查找当前日志。
4. 只有收到 `Native component confirmed` 才算原生组件加载成功。

自动识别失败时，在 PowerShell 中运行：

```powershell
.\native\windows\attach.ps1 -GameProcessId 1234 -LogPath 'D:\实际存档目录\log.txt'
```

组件仅挂到指定 Isaac 进程的窗口线程，不安装系统服务。窗口消息处理函数会保留到该游戏进程结束；需要停用时正常退出游戏，再直接通过 Steam 启动。不要在同一游戏进程上重复挂载。

源码构建需要 MinGW-w64 的 i686 和 x86_64 编译器，在 Bash 下运行 `windows/build.sh`。

Windows 已完成 x86 / x64 编译，并在一台真实 Windows 游戏环境中由用户确认：加载原生辅助程序后行为与 Mac 一致。此前仅订阅 Workshop 时系统白箭头仍在，加载辅助程序后恢复正常。这不代表窗口、无边框、全屏、Alt+Tab 和 Steam Overlay 的全部组合均已验收。

源码仓库不包含预编译 EXE/DLL；仅下载源码或订阅 Workshop 后不能直接使用原生组件。当前每次启动游戏后均需运行一次 `attach.cmd`。一键安装器及随游戏自动加载尚未实现，默认 Lua 沙箱不能替代这一步，也无需添加 `--luadebug`。

## Linux 原生版：X11 / XWayland

Steam 官方 appdetails API 的 Afterbirth+（570660）平台列表包含 Linux。

1. 安装新版 Lua 插件并正常启动原生游戏。
2. Debian / Ubuntu 构建依赖为 `build-essential pkg-config libx11-dev`。
3. 运行 `sh native/linux/build.sh`，然后 `sh native/linux/attach.sh`。
4. 保持辅助程序运行；Ctrl+C 正常退出会恢复窗口原有光标。

自动识别失败时：

```sh
sh native/linux/attach.sh 1234 '/实际存档目录/log.txt'
```

这是独立的 X11 辅助进程，直接操作目标窗口的光标，不要求与游戏相同的 32 / 64 位架构。支持 X11；Wayland 桌面下仅适用于运行在 XWayland 中的游戏窗口。

**不支持原生 Wayland 窗口；没有自动适配 Proton / Steam Deck。** 后者属于 Windows 游戏与兼容层的组合，不能用原生 Linux 验证代替。

Linux 的 Xvfb 测试检查真实 X11 光标像素、菜单开关、游戏阶段、移出窗口、失焦和正常退出恢复；这不是实际 Isaac 游戏验收。

## 验证与发布范围

所有平台原生组件都是本地预览版。macOS 和 Windows 已由用户试用确认；Windows 仍需扩大场景验证，Linux 尚需真实目标游戏验证。原生二进制未通过 Steam Workshop 分发；当前未创建发布或修改 Steam 启动参数。

共用策略测试：`cc tests/cursor_state.c -o /tmp/hc-state && /tmp/hc-state`。
Linux 虚拟窗口测试：构建 `tests/Dockerfile.linux`，在容器中挂载仓库并运行 `tests/linux-check.sh`。
