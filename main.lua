local mod = RegisterMod("Hide Cursor", 1)

-- resources/gfx/ui/cursor.png  = transparent (hide native cursor always)
-- resources/gfx/ui/cross_white.png / cross_red.png = user PS icons
-- Show when MouseControl is on and player has a mouse-aim item.
-- White when idle, red while left mouse button is held.
--
-- Do not use the `debug` library (missing in AB+ and aborts the script).

local spriteWhite = nil
local spriteRed = nil
local spritesTried = false

-- nil = unknown; true/false after options.ini probe
local mouseControl = nil

local MOUSE_AIM_ITEMS = {
	168, -- Epic Fetus
	329, -- Ludovico Technique
	394, -- Marked
	47, -- Doctor's Remote
	465, -- Analog Stick
	400, -- Spear of Destiny
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

	-- Absolute path (AB+ often has no os.getenv)
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

	-- Unreadable ini → assume mouse mode on (still requires aim item to draw)
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

local function hasMouseAimItem()
	local n = Game():GetNumPlayers()
	for i = 0, n - 1 do
		local player = Isaac.GetPlayer(i)
		if player ~= nil then
			for j = 1, #MOUSE_AIM_ITEMS do
				if player:HasCollectible(MOUSE_AIM_ITEMS[j]) then
					return true
				end
			end
		end
	end
	return false
end

local function shouldShowCursor()
	-- Controller / MouseControl=0 → never draw
	if mouseControl == false then
		return false
	end
	return hasMouseAimItem()
end

local function getMousePos()
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
	refreshMouseControl()
	spritesTried = false
	spriteWhite = nil
	spriteRed = nil
end

function mod:onRender()
	if Game():IsPaused() then
		return
	end

	if not shouldShowCursor() then
		return
	end

	if not loadSprites() then
		return
	end

	-- White idle / red while LMB held (vanilla menu behaviour)
	local sprite = spriteWhite
	if isLeftMouseHeld() and spriteRed ~= nil then
		sprite = spriteRed
	end

	local pos = getMousePos()
	sprite:Update()
	sprite:Render(pos, Vector(0, 0), Vector(0, 0))
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.onGameStart)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)

refreshMouseControl()
Isaac.DebugString("Hide Cursor: loaded")
print("Hide Cursor: loaded")
