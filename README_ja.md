# Hide Cursor

[English](README.md) | [中文](README_zh.md) | **日本語**

ゲームのネイティブカーソルテクスチャを透明画像に差し替え、マウスカーソルを
**デフォルトで非表示**にします。

次の**両方**が満たされるときだけ、マウス位置にカスタム 64×64 照準を描画します
（通常は白、LMB 押し中は赤）：

1. `options.ini` で `MouseControl=1`
2. プレイヤーが下の照準系アイテムを所持

**キーボードのみ / コントローラ**（`MouseControl=0`）：追加の照準は出ず、
カーソルは常に非表示のままです。マウス入力自体は無効化しません。

| 状態 | カーソル |
|------|----------|
| デフォルト（メニュー / 通常プレイ） | 非表示 |
| キーボード / コントローラ（`MouseControl=0`） | 常に非表示 |
| `MouseControl=1` + 照準アイテム | 白照準（LMB 中は赤） |

照準系アイテム：

- Epic Fetus（168）
- Ludovico Technique（329）
- Marked（394）
- Doctor's Remote（47）
- Analog Stick（465）
- Spear of Destiny（400）

> ランタイムでリソース上書きを外すことはできないため、「復帰」はマウス位置に
> 別スプライトを描画します。`MouseControl` は `options.ini` から読みます
> （`=0` は復帰しない、`=1` または読めない場合 + 照準アイテムで表示）。

ソース：https://github.com/MinuteReversal/hide-cursor-mod

## ローカルテスト

### 1. デバッグコンソールを有効化（一度だけ）

`options.ini` を編集：

- macOS Afterbirth+：  
  `~/Library/Application Support/Binding of Isaac Afterbirth+/options.ini`
- Windows（一般的）：  
  `Documents/My Games/Binding of Isaac …/options.ini`

```ini
EnableDebugConsole=1
```

保存後、**ゲームを再起動**。

> コンソールを有効にすると、そのセーブでは**実績が無効**になることが多いです。
> テスト用セーブを使ってください。

任意 — マウス照準を有効化（Epic Fetus の赤丸がマウスに追従）：

```ini
MouseControl=1
```

### 2. ゲーム内でコンソールを開く

**`` ` ``** キー（チルダ / バッククォート、通常は Esc の下）。

### 3. アイテムを付与

| コマンド | 効果 |
|----------|------|
| `g c168` | Epic Fetus |
| `g c329` | Ludovico Technique |
| `g c394` | Marked |
| `g c47` | Doctor's Remote |
| `g c465` | Analog Stick |
| `g c400` | Spear of Destiny |
| `spawn 5.100.168` | Epic Fetus を床に生成 |

`g` = give、`c` + 数字 = collectible id。

### 4. この mod のテスト

1. Mods メニューで **Hide Cursor** を有効化  
2. 普段はシステムカーソルが見えないこと  
3. `MouseControl=0`：`g c168` 後もカスタム照準が**出ない**こと  
4. `MouseControl=1`：ini 変更後に再起動し `g c168`、マウス位置に照準（LMB 中は赤）  

`MouseControl` 変更後は再起動が必要です（起動時 / ラン開始時に読み込み）。

ローカル Mods フォルダ（Afterbirth+）：

```text
~/Library/Application Support/Binding of Isaac Afterbirth+ Mods/hide cursor
```

リポジトリから同期：

```bash
rsync -av --exclude '.git/' --exclude '.DS_Store' \
  ~/Documents/github/hide-cursor-mod/ \
  ~/Library/Application\ Support/Binding\ of\ Isaac\ Afterbirth+\ Mods/hide\ cursor/
```

## ツール

[Open ModUploader](<~/Library/Application Support/Steam/steamapps/common/The Binding of Isaac Rebirth/tools/ModUploader/>)
