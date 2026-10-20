# Hide Cursor

macOS、Windows x86/x64、Linux X11/XWayland 原生组件现提供预览版，详见[三平台安装与验证范围](native/README_zh.md)。需要另外运行启动器／辅助程序，普通 Workshop Lua 订阅不会自动加载原生组件。Windows 已在一台真实游戏环境中由用户确认行为与 Mac 一致；Linux 已通过虚拟窗口测试但未做实际游戏验收。

## Windows 安装与启动须知

**只订阅创意工坊不会安装或启动原生辅助程序。** Lua 负责设置和游戏内准星，原生组件负责系统箭头；缺少原生组件时，可能出现准星已隐藏但系统白箭头仍在，或箭头与准星同时显示。

当前预览版使用方法：

1. 订阅并启用新版 Hide Cursor，避免同时启用多个版本。
2. 另行准备与此版本配套的 Windows 原生组件。`native/windows/build/x86/` 和 `build/x64/` 下应分别有 `HideCursor.exe`、`HideCursor.dll`。源码仓库不包含这些二进制文件，需自行构建；仅下载源码不能直接运行。
3. 通过 Steam 正常启动游戏，再双击 `native/windows/attach.cmd`。
4. 看到 **Native component confirmed in PID ...** 才表示加载成功；保持辅助程序运行，直到游戏退出。每次重新启动游戏后都需重新运行一次，请勿对同一游戏进程重复挂载。

正常加载后，「始终显示光标」关闭时隐藏系统箭头，必要的鼠标瞄准道具仍可显示准星；开启时主菜单显示系统箭头，游戏内显示白色／按下左键变红的准星。鼠标移出游戏窗口后恢复桌面光标。若需鼠标控制，请在当前存档目录的 `options.ini` 设置 `MouseControl=1`，并重启游戏。

**一键安装和随游戏自动加载尚未实现。** 默认 Lua 沙箱不能直接安装或启动 EXE/DLL，不能通过订阅实现零操作安装。计划采用首次手动安装一次、之后随游戏加载的方式；当前仍须按上面的步骤运行辅助程序，无需为此添加 `--luadebug`。



## 光标设置

默认关闭「始终显示光标」，保留原有自动隐藏行为。

- 游戏内按 **F10** 打开 Hide Cursor 配置面板。
- 用 **Enter / 左右方向键**切换 `Always Show Cursor`，按 **Esc / F10** 关闭。
- 安装了 Mod Config Menu 时，在 **Hide Cursor → General** 中设置。
- 开启后，游戏中（含暂停界面）持续显示白色准星，按住鼠标左键时变红；不要求鼠标控制或瞄准道具。
- 设置通过游戏插件存档保存，每个存档独立。配置面板打开时会屏蔽角色操作，但不会暂停场景。

此选项控制插件绘制的准星。AB+ 的主菜单没有此绘制回调；使用 macOS 试用启动器时，原生组件在开启「始终显示光标」时于主菜单显示系统箭头，关闭时主菜单也隐藏。进入游戏后隐藏系统箭头以避免双光标，由 Lua 按同一设置或瞄准道具条件绘制准星。移出窗口后系统光标照常恢复。

[English](README.md) | **中文** | [日本語](README_ja.md)

用透明贴图替换游戏原生光标，从而默认**隐藏**鼠标光标。

仅在以下**两个条件同时满足**时，在鼠标位置绘制自定义 64×64 准星（未按左键为白色，按住左键为红色）：

1. `options.ini` 中 `MouseControl=1`
2. 玩家持有下方列表中的瞄准类道具

**纯键盘 / 手柄玩家**（`MouseControl=0`）：不会出现额外准星，光标始终隐藏。  
**不会**关闭鼠标输入，只改光标显示。

| 状态 | 光标 |
|------|------|
| 默认（菜单 / 普通游戏） | 隐藏 |
| 键盘 / 手柄（`MouseControl=0`） | 始终隐藏 |
| `MouseControl=1` 且持有瞄准道具 | 白色准星（按住左键为红） |

瞄准类道具：

- Epic Fetus（168）
- Ludovico Technique（329）
- Marked（394）
- Doctor's Remote（47）
- Analog Stick（465）
- Spear of Destiny（400）

> 游戏无法在运行时真正卸载资源覆盖，因此「恢复光标」是用独立贴图画在鼠标位置。  
> `MouseControl` 从本机 `options.ini` 读取：`=0` 永不恢复；`=1` 或读不到 ini 时，持有瞄准道具会显示。

开源地址：https://github.com/MinuteReversal/hide-cursor-mod

## 本地测试

### 1. 启用调试控制台（只需一次）

编辑 `options.ini`：

- macOS Afterbirth+：  
  `~/Library/Application Support/Binding of Isaac Afterbirth+/options.ini`
- Windows（常见）：  
  `Documents/My Games/Binding of Isaac …/options.ini`

```ini
EnableDebugConsole=1
```

保存后**重启游戏**。

> 开启控制台后，该存档通常**无法再解锁成就**。建议用测试存档。

可选——开启鼠标瞄准（Epic Fetus 红圈会跟鼠标）：

```ini
MouseControl=1
```

### 2. 游戏内打开控制台

按 **`` ` ``**（波浪号 / 反引号，一般在 `Esc` 下方）。

### 3. 给道具

| 指令 | 效果 |
|------|------|
| `g c168` | Epic Fetus |
| `g c329` | Ludovico Technique |
| `g c394` | Marked |
| `g c47` | Doctor's Remote |
| `g c465` | Analog Stick |
| `g c400` | Spear of Destiny |
| `spawn 5.100.168` | 在地上生成 Epic Fetus |

`g` = give，`c` + 数字 = collectible id。

### 4. 测试本 mod

1. 在 Mods 菜单中启用 **Hide Cursor**  
2. 平时系统光标应不可见  
3. `MouseControl=0`：`g c168` 后仍**没有**自定义准星  
4. `MouseControl=1`：改 ini 后重启，再 `g c168`，鼠标处出现准星（按住左键为红）  

修改 `MouseControl` 后需重启（启动 / 开局时读取）。

本地 Mods 目录（Afterbirth+）：

```text
~/Library/Application Support/Binding of Isaac Afterbirth+ Mods/hide cursor
```

从仓库同步：

```bash
rsync -av --exclude '.git/' --exclude '.DS_Store' \
  ~/Documents/github/hide-cursor-mod/ \
  ~/Library/Application\ Support/Binding\ of\ Isaac\ Afterbirth+\ Mods/hide\ cursor/
```

## 工具

[Open ModUploader](<~/Library/Application Support/Steam/steamapps/common/The Binding of Isaac Rebirth/tools/ModUploader/>)
