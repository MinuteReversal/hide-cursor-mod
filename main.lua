local mod = RegisterMod("Hide Cursor", 1)
local json = require("json")
local config = { alwaysShowCursor = false }
local menuOpen = false
local menuRegistered = false

local function writeSettings()
	mod:SaveData(json.encode(config))
	Isaac.DebugString("Hide Cursor: native alwaysShow=" .. (config.alwaysShowCursor and "1" or "0"))
end

local function loadSettings()
	local saved = nil
	if mod:HasData() then
		local ok, value = pcall(json.decode, mod:LoadData())
		if ok and type(value) == "table" then saved = value end
	end
	config.alwaysShowCursor = saved ~= nil and saved.alwaysShowCursor == true
	Isaac.DebugString("Hide Cursor: native alwaysShow=" .. (config.alwaysShowCursor and "1" or "0"))
end

local function setAlwaysShow(value)
	config.alwaysShowCursor = value == true
	writeSettings()
end

local function setupConfigMenu()
	if menuRegistered or not ModConfigMenu then return end
	ModConfigMenu.AddSetting("Hide Cursor", "General", {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		CurrentSetting = function() return config.alwaysShowCursor end,
		Display = function() return "Always Show Cursor: " .. (config.alwaysShowCursor and "ON" or "OFF") end,
		OnChange = setAlwaysShow,
		Info = { "Keep the cursor visible inside the game. Default: OFF." },
	})
	menuRegistered = true
end

local function renderConfigMenu()
	setupConfigMenu()
	-- MCM has its own F10 binding. Use the standalone panel only without MCM.
	if not ModConfigMenu and Input.IsButtonTriggered(Keyboard.KEY_F10, 0) then
		menuOpen = not menuOpen
	end
	if not menuOpen then return end
	if Input.IsButtonTriggered(Keyboard.KEY_ESCAPE, 0) then
		menuOpen = false
		return
	end
	if Input.IsButtonTriggered(Keyboard.KEY_ENTER, 0)
		or Input.IsButtonTriggered(Keyboard.KEY_LEFT, 0)
		or Input.IsButtonTriggered(Keyboard.KEY_RIGHT, 0) then
		setAlwaysShow(not config.alwaysShowCursor)
	end
	Isaac.RenderText("Hide Cursor", 50, 50, 1, 1, 1, 1)
	Isaac.RenderText("Always Show Cursor: " .. (config.alwaysShowCursor and "ON" or "OFF"), 50, 66, 1, 1, 1, 1)
	Isaac.RenderText("Enter / Left / Right: change    Esc / F10: close", 50, 82, 1, 1, 1, 1)
end

-- Hide Cursor
-- EN: Transparent native cursor by default. Restores a custom crosshair only when
--     MouseControl=1 and the player holds a mouse-aim item. White idle, red while LMB held.
--     Keyboard/controller (MouseControl=0): no change — cursor stays fully hidden.
-- ZH: 默认隐藏系统光标；仅 MouseControl=1 且持有瞄准类道具时显示自定义准星。
--     未按左键白色，按住左键红色。键盘/手柄玩家无额外效果。
-- JA: デフォルトでシステムカーソルを非表示。MouseControl=1 かつマウス照準アイテム所持時のみ
--     カスタム照準を表示。通常は白、LMB 押し中は赤。キーボード/コントローラは影響なし。
--
-- Assets:
--   resources/gfx/ui/cursor.png       — transparent (always hide native cursor)
--   resources/gfx/ui/cross_white.png  — 64x64 white cross (PS)
--   resources/gfx/ui/cross_red.png    — 64x64 red cross (PS)
--
-- Note: do not use the Lua `debug` library (unavailable in AB+; aborts the script).

local spriteWhite = nil
local spriteRed = nil
local spritesTried = false

-- 64x64 PS assets are large on Isaac's internal resolution; 0.5 ≈ 32px on screen
local CURSOR_SCALE = 0.5


-- nil = not read yet; true/false after options.ini probe
local mouseControl = nil

-- Collectible ids (AB+ enums)
local MOUSE_AIM_ITEMS = {
	168, -- Epic Fetus
	329, -- Ludovico Technique
	394, -- Marked
	47, -- Doctor's Remote
	465, -- Analog Stick
	400, -- Spear of Destiny
}

-- Weapon types that imply mouse-aim style control (see enums.lua)
-- WEAPON_ROCKETS = 6 (Epic Fetus), WEAPON_LUDOVICO_TECHNIQUE = 8
local MOUSE_AIM_WEAPONS = {
	6,
	8,
}

local function tryReadMouseControl(path)
	local f = io.open(path, "r")
	if f == nil then
		return nil
	end
	local content = f:read("*a")
	f:close()
	if content == nil then
		return nil
	end
	local value = string.match(content, "[Mm]ouse[Cc]ontrol%s*=%s*(%d+)")
	if value == nil then
		return nil
	end
	return tonumber(value) == 1
end

local function refreshMouseControl()
	mouseControl = nil
	local paths = {}

	-- Prefer absolute path: AB+ often has no os.getenv
	paths[#paths + 1] = "/Users/zhuang/Library/Application Support/Binding of Isaac Afterbirth+/options.ini"

	if os ~= nil and os.getenv ~= nil then
		local home = os.getenv("HOME")
		if home ~= nil and home ~= "" then
			paths[#paths + 1] = home .. "/Library/Application Support/Binding of Isaac Afterbirth+/options.ini"
			paths[#paths + 1] = home .. "/Library/Application Support/Binding of Isaac Repentance+/options.ini"
			paths[#paths + 1] = home .. "/Library/Application Support/Binding of Isaac Repentance/options.ini"
			paths[#paths + 1] = home .. "/Documents/My Games/Binding of Isaac Afterbirth+/options.ini"
			paths[#paths + 1] = home .. "/Documents/My Games/Binding of Isaac Repentance+/options.ini"
		end
		local up = os.getenv("USERPROFILE")
		if up ~= nil and up ~= "" then
			paths[#paths + 1] = up .. "\\Documents\\My Games\\Binding of Isaac Afterbirth+\\options.ini"
			paths[#paths + 1] = up .. "\\Documents\\My Games\\Binding of Isaac Repentance+\\options.ini"
		end
	end

	for i = 1, #paths do
		local ok, result = pcall(tryReadMouseControl, paths[i])
		if ok and result ~= nil then
			mouseControl = result
			Isaac.DebugString(
				"Hide Cursor: MouseControl=" .. (mouseControl and "1" or "0") .. " @ " .. paths[i]
			)
			return
		end
	end

	-- Unreadable ini → assume mouse mode on (still requires an aim item to draw)
	mouseControl = true
	Isaac.DebugString("Hide Cursor: options.ini unreadable; assuming MouseControl=1")
end

local function loadSprites()
	if spritesTried then
		return spriteWhite ~= nil
	end
	spritesTried = true

	local ok, err = pcall(function()
		local w = Sprite()
		w:Load("gfx/ui/cross_white.anm2", true)
		w:Play("Idle", true)
		spriteWhite = w

		local r = Sprite()
		r:Load("gfx/ui/cross_red.anm2", true)
		r:Play("Idle", true)
		spriteRed = r
	end)

	if not ok then
		Isaac.DebugString("Hide Cursor: sprite load FAILED: " .. tostring(err))
		spriteWhite = nil
		spriteRed = nil
		return false
	end

	Isaac.DebugString("Hide Cursor: cross_white / cross_red loaded")
	return true
end

local function playerNeedsAimCursor(player)
	if player == nil then
		return false
	end

	for j = 1, #MOUSE_AIM_ITEMS do
		if player:HasCollectible(MOUSE_AIM_ITEMS[j]) then
			return true
		end
	end

	-- Fallback: weapon type (Epic Fetus rockets / Ludovico)
	-- HasWeaponType exists on AB+ EntityPlayer
	if player.HasWeaponType ~= nil then
		for j = 1, #MOUSE_AIM_WEAPONS do
			local ok, has = pcall(function()
				return player:HasWeaponType(MOUSE_AIM_WEAPONS[j])
			end)
			if ok and has then
				return true
			end
		end
	end

	return false
end

local function hasMouseAimItem()
	local n = Game():GetNumPlayers()
	for i = 0, n - 1 do
		if playerNeedsAimCursor(Isaac.GetPlayer(i)) then
			return true
		end
	end
	return false
end

local function shouldShowCursor()
	-- MouseControl=0 (keyboard/controller): never draw the custom crosshair
	if mouseControl == false then
		return false
	end
	return hasMouseAimItem()
end

-- Align with in-game mouse aim (Epic Fetus reticle uses world mouse coords).
local function getMousePos()
	local ok, screen = pcall(function()
		local world = Input.GetMousePosition(true)
		return Isaac.WorldToScreen(world)
	end)
	if ok and screen ~= nil then
		return screen
	end
	return Input.GetMousePosition(false)
end

local function isLeftMouseHeld()
	local held = false
	pcall(function()
		held = Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT)
	end)
	return held
end

function mod:onGameStart()
	Isaac.DebugString("Hide Cursor: native phase=game")
	loadSettings()
	writeSettings()
	menuOpen = false
	refreshMouseControl()
	spritesTried = false
	spriteWhite = nil
	spriteRed = nil
end

function mod:onRender()
	renderConfigMenu()
	if Game():IsPaused() and not config.alwaysShowCursor then
		return
	end

	if not config.alwaysShowCursor and not shouldShowCursor() then
		return
	end

	if not loadSprites() then
		return
	end

	-- White idle; red while left mouse button held (vanilla menu-style)
	local sprite = spriteWhite
	if isLeftMouseHeld() and spriteRed ~= nil then
		sprite = spriteRed
	end

	local pos = getMousePos()
	sprite.Scale = Vector(CURSOR_SCALE, CURSOR_SCALE)
	sprite:Update()
	sprite:Render(pos, Vector(0, 0), Vector(0, 0))
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.onGameStart)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)
mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, _, hook)
	if not menuOpen then return end
	if hook == InputHook.GET_ACTION_VALUE then return 0 end
	return false
end)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
	Isaac.DebugString("Hide Cursor: native phase=menu")
	menuOpen = false
	writeSettings()
end)

loadSettings()
setupConfigMenu()
refreshMouseControl()
Isaac.DebugString("Hide Cursor: loaded")
print("Hide Cursor: loaded")
