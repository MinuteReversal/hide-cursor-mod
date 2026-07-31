# Hide Cursor

Hides the mouse cursor by replacing the game's native cursor texture with a
transparent image.

When **both** of these are true, a default-style cursor is drawn at the mouse
position again so MouseControl users can still aim:

1. `options.ini` has `MouseControl=1`
2. A player holds a mouse-aim item (list below)

| 状态 | 光标 |
|------|------|
| 默认（菜单 / 普通游戏） | 隐藏 |
| 仅手柄 / `MouseControl=0` | 始终隐藏（拿了瞄准道具也不显示） |
| `MouseControl=1` 且持有下方道具 | 恢复显示（绘制默认风格光标） |

会恢复光标的道具：

- Epic Fetus（168）
- Ludovico Technique（329）
- Marked（394）
- Doctor's Remote（47）
- Analog Stick（465）
- Spear of Destiny（400）

> 说明：游戏无法在运行时真正“卸载”资源覆盖，因此恢复是用独立贴图画在鼠标位置。  
> `MouseControl` 从本机 `options.ini` 读取：`=0` 时永不恢复光标；`=1` 或读不到 ini 时，持有瞄准类道具会显示光标。

## 本地测试

### 1. 启用调试控制台（只需一次）

编辑配置文件 `options.ini`：

- macOS Afterbirth+：
  `~/Library/Application Support/Binding of Isaac Afterbirth+/options.ini`
- Windows / 其他版本常见路径：
  `Documents/My Games/Binding of Isaac …/options.ini`

找到并修改：

```ini
EnableDebugConsole=1
```

保存后**重启游戏**。

> 注意：开启控制台后，该存档通常**无法再解锁成就**。建议用单独的测试存档。

可选：开鼠标瞄准（Epic Fetus 红圈会跟鼠标）：

```ini
MouseControl=1
```

### 2. 游戏内打开控制台

进入一局后，按 **`` ` ``**（波浪号 / 反引号，一般在 `Esc` 下方、数字 `1` 左边）。

### 3. 给道具（控制台指令）

在控制台输入后回车：

| 指令 | 效果 |
|------|------|
| `g c168` | 获得 Epic Fetus（史诗胎儿） |
| `g c329` | 获得 Ludovico Technique |
| `g c394` | 获得 Marked |
| `g c47` | 获得 Doctor's Remote |
| `g c465` | 获得 Analog Stick |
| `g c400` | 获得 Spear of Destiny |
| `spawn 5.100.168` | 在地上生成 Epic Fetus 道具实体 |

`g` = give，`c` + 数字 = collectible id。

### 4. 测试本 mod

1. 确认 Mods 里 **Hide Cursor** 已启用  
2. 平时：系统光标应不可见  
3. **`MouseControl=0`（手柄）**：`g c168` 后仍应**没有**绘制光标  
4. **`MouseControl=1`**：改 ini 后重启，再 `g c168`，鼠标位置应出现恢复光标  
5. 开了鼠标模式时，Epic Fetus 红圈会跟鼠标  

改 `MouseControl` 后需**重启游戏**（mod 在启动 / 开局时读 ini）。

本地 Mods 目录（Afterbirth+）：

```text
~/Library/Application Support/Binding of Isaac Afterbirth+ Mods/hide cursor
```

从仓库同步到游戏目录示例：

```bash
rsync -av --exclude '.git/' --exclude '.DS_Store' \
  ~/Documents/github/hide-cursor-mod/ \
  ~/Library/Application\ Support/Binding\ of\ Isaac\ Afterbirth+\ Mods/hide\ cursor/
```

## Tools

[Open ModUploader](<~/Library/Application Support/Steam/steamapps/common/The Binding of Isaac Rebirth/tools/ModUploader/>)
