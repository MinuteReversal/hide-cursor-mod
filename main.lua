local mod = RegisterMod("Hide Cursor", 1)

-- resources/gfx/ui/cursor.png is transparent (native cursor always hidden).
-- Draw a stand-in cursor when mouse-aim items are held, gated by MouseControl.
--
-- IMPORTANT: AB+ Lua has no `debug` library — using it aborts the whole script.

local cursorSprite = nil
local cursorReady = false

-- nil  = options.ini not readable (show cursor with aim items; best-effort)
-- true = MouseControl=1
-- false = MouseControl=0 (never show; controller-friendly)
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

	if os ~= nil and os.getenv ~= nil then
		local home = os.getenv("HOME")
		if home ~= nil and home ~= "" then
			paths[#paths + 1] = home .. "/Library/Application Support/Binding of Isaac Afterbirth+/options.ini"
			paths[#paths + 1] = home .. "/Library/Application Support/Binding of Isaac Repentance+/options.ini"
			paths[#paths + 1] = home .. "/Library/Application Support/Binding of Isaac Repentance/options.ini"
			paths[#paths + 1] = home .. "/Documents/My Games/Binding of Isaac Afterbirth+/options.ini"
			paths[#paths + 1] = home .. "/Documents/My Games/Binding of Isaac Repentance+/options.ini"
			paths[#paths + 1] = home .. "/Documents/My Games/Binding of Isaac Repentance/options.ini"
		end
		local userprofile = os.getenv("USERPROFILE")
		if userprofile ~= nil and userprofile ~= "" then
			paths[#paths + 1] = userprofile .. "\\Documents\\My Games\\Binding of Isaac Afterbirth+\\options.ini"
			paths[#paths + 1] = userprofile .. "\\Documents\\My Games\\Binding of Isaac Repentance+\\options.ini"
			paths[#paths + 1] = userprofile .. "\\Documents\\My Games\\Binding of Isaac Repentance\\options.ini"
		end
	end

	for i = 1, #paths do
		local ok, result = pcall(tryReadMouseControl, paths[i])
		if ok and result ~= nil then
			mouseControl = result
			Isaac.DebugString(
				"Hide Cursor: MouseControl=" .. (mouseControl and "1" or "0") .. " from " .. paths[i]
			)
			return
		end
	end

	Isaac.DebugString("Hide Cursor: options.ini unreadable; aim-item cursor allowed")
end

local function loadCursorSprite()
	if cursorReady then
		return cursorSprite ~= nil
	end
	cursorReady = true

	local ok, err = pcall(function()
		local s = Sprite()
		s:Load("gfx/ui/default_cursor.anm2", true)
		s:Play("Idle", true)
		cursorSprite = s
	end)

	if not ok then
		Isaac.DebugString("Hide Cursor: sprite load failed: " .. tostring(err))
		cursorSprite = nil
		return false
	end

	Isaac.DebugString("Hide Cursor: cursor sprite OK")
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
	-- Explicitly disabled in options → never (controller players)
	if mouseControl == false then
		return false
	end
	-- true or nil (unreadable): show when holding an aim item
	return hasMouseAimItem()
end

function mod:onGameStart()
	refreshMouseControl()
end

function mod:onRender()
	if Game():IsPaused() then
		return
	end

	if not shouldShowCursor() then
		return
	end

	if not loadCursorSprite() then
		return
	end

	local pos = Input.GetMousePosition(false)
	cursorSprite:Render(pos, Vector(0, 0), Vector(0, 0))
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.onGameStart)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)

refreshMouseControl()
Isaac.DebugString("Hide Cursor: loaded")
print("Hide Cursor: loaded")
