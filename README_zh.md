# Hide Cursor

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
