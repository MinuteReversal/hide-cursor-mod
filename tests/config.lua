-- Run with the game json.lua on LUA_PATH and an absolute main.lua argument.
local json = require('json')
local now, saved, renders, paused = 0, '', 0, false
local triggered = {}
ModCallbacks = {MC_POST_GAME_STARTED=1, MC_POST_RENDER=2, MC_INPUT_ACTION=3, MC_PRE_GAME_EXIT=4}
Keyboard = {KEY_F10=299, KEY_ESCAPE=256, KEY_ENTER=257, KEY_LEFT=263, KEY_RIGHT=262}
InputHook = {GET_ACTION_VALUE=2}
Mouse = {MOUSE_BUTTON_LEFT=0}
local callbacks = {}
local mod = {}
function mod:AddCallback(id, fn) callbacks[id] = fn end
function mod:HasData() return #saved > 0 end
function mod:LoadData() return saved end
function mod:SaveData(s) saved = s end
function RegisterMod() return mod end
Isaac = {GetTime=function() return now end, DebugString=function() end, RenderText=function() end, WorldToScreen=function(p) return p end}
function Isaac.GetPlayer() return {HasCollectible=function() return false end} end
function Game() return {IsPaused=function() return paused end, GetNumPlayers=function() return 1 end} end
Input = {IsButtonTriggered=function(key) return triggered[key] == true end, GetMousePosition=function() return {} end, IsMouseBtnPressed=function() return false end}
function Vector() return {} end
function Sprite() return {Load=function() end, Play=function() end, Update=function() end, Render=function() renders = renders + 1 end} end
local function frame(keys) triggered=keys or {}; callbacks[2](mod); now=now+120 end
dofile(assert(arg[1], 'Pass the absolute path to main.lua'))
callbacks[1](mod)
frame(); assert(renders==0, 'default should hide')
frame({[299]=true}); assert(callbacks[3](mod,nil,2)==0, 'panel blocks action values')
frame({[257]=true}); assert(json.decode(saved).alwaysShowCursor, 'toggle must persist')
assert(renders>0, 'always-show fallback without native must render')
frame({[256]=true}); assert(callbacks[3](mod,nil,2)==nil, 'closing restores input')
paused=true; before=renders; frame(); assert(renders>before, 'always show must work while paused')
ModConfigMenu={OptionType={BOOLEAN=1}, AddSetting=function(_,_,setting) _G.setting=setting end}
frame(); assert(setting.CurrentSetting()==true, 'MCM reads setting')
setting.OnChange(false); assert(json.decode(saved).alwaysShowCursor==false, 'MCM persists OFF')
callbacks[1](mod); assert(setting.CurrentSetting()==false, 'saved setting survives game restart')
saved = '{broken JSON'
callbacks[1](mod)
assert(setting.CurrentSetting()==false, 'corrupt data must fall back to OFF')
print('PASS: defaults, standalone menu, persistence, MCM, paused cursor, input restoration')
