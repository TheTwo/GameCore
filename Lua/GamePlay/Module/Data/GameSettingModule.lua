local BaseModule = require("BaseModule")

---游戏设置模块
---@class GameSettingModule : BaseModule
local GameSettingModule = class("GameSettingModule", BaseModule)

local ModuleRefer = require("ModuleRefer")
local ClientDataModule = ModuleRefer.ClientDataModule
local ClientDataKeys = require("ClientDataKeys")
local RuntimeDebugSettings = require("RuntimeDebugSettings")

local DEFAULT_LANGUAGE_CODE = "en"

local DEFAULT_MUSIC_VOLUME = 1
local DEFAULT_SOUND_VOLUME = 1
local DEFAULT_ALLOW_VIEW_EQUIP = true
local DEFAULT_DRAW_CARD_BROADCAST = true

local KEY_MUSIC_VOLUME = "music_volume"
local KEY_SOUND_VOLUME = "sound_volume"
local KEY_ALLOW_VIEW_EQUIP = "allow_view_equip"
local KEY_DRAW_CARD_BROADCAST = "draw_card_broadcast"

function GameSettingModule:OnRegister()
    local musicVolume = self:GetMusicVolume() * 100
    local soundVolume = self:GetSoundVolume() * 100
    g_Logger.Trace("Set music volume to %s", musicVolume)
    g_Game.SoundManager:SetBgmVolume(musicVolume)
    g_Logger.Trace("Set sound volume to %s", soundVolume)
    g_Game.SoundManager:SetSfxVolume(soundVolume)
    local languageCode = self:GetLanguageCode()
    self:SetLanguageCode(languageCode)
end

---获取语言代码
---@param self GameSettingModule
function GameSettingModule:GetLanguageCode()
    local result = g_Game.LocalizationManager:GetCurrentLanguage()
    if (not result or result == "") then
        result = ClientDataModule:GetData(ClientDataKeys.GameSetting.LanguageCode)
        if (not result or result == "") then
            return DEFAULT_LANGUAGE_CODE
        end
    end
    return result
end

--- 设置语言代码
---@param self GameSettingModule
---@param code string 语言代码
function GameSettingModule:SetLanguageCode(code)
    local currentCode = g_Game.LocalizationManager:GetCurrentLanguage()
    if (code == currentCode) then return end
    g_Logger.Trace("Set language to %s", code)
    ClientDataModule:SetData(ClientDataKeys.GameSetting.LanguageCode, code)
	g_Game.PlayerPrefsEx:SetString('userLanguage', code)
    g_Game.LocalizationManager:SetCurrentLanguage(code)
    --g_Game.LocalizationManager:Reload(code, true)
    g_Game.LocalizationManager:Reload(code, false)
end

--- 获取音乐音量
---@param self GameSettingModule
---@return number
function GameSettingModule:GetMusicVolume()
	if (not g_Game.PlayerPrefsEx:HasUidKey(KEY_MUSIC_VOLUME)) then
        return DEFAULT_MUSIC_VOLUME
    else
		return g_Game.PlayerPrefsEx:GetFloatByUid(KEY_MUSIC_VOLUME)
    end
end

--- 设置音乐音量
---@param self GameSettingModule
---@param volume number
function GameSettingModule:SetMusicVolume(volume)
	g_Game.PlayerPrefsEx:SetFloatByUid(KEY_MUSIC_VOLUME, math.clamp01(volume))
	g_Game.PlayerPrefsEx:Save()
    g_Game.SoundManager:SetBgmVolume(volume * 100)
    g_Logger.Trace("Set music volume to %s", volume * 100)

end

--- 获取音效音量
---@param self GameSettingModule
---@return number
function GameSettingModule:GetSoundVolume()
	if (not g_Game.PlayerPrefsEx:HasUidKey(KEY_SOUND_VOLUME)) then
        return DEFAULT_SOUND_VOLUME
    else
		return g_Game.PlayerPrefsEx:GetFloatByUid(KEY_SOUND_VOLUME)
    end
end

--- 设置音效音量
---@param self GameSettingModule
---@param volume number
function GameSettingModule:SetSoundVolume(volume)
	g_Game.PlayerPrefsEx:SetFloatByUid(KEY_SOUND_VOLUME, math.clamp01(volume))
	g_Game.PlayerPrefsEx:Save()
    g_Game.SoundManager:SetSfxVolume(volume * 100)
    g_Logger.Trace("Set sound volume to %s", volume * 100)
end

--- 获取是否允许查看装备
---@param self GameSettingModule
---@return boolean
function GameSettingModule:GetAllowViewEquip()
	if (not g_Game.PlayerPrefsEx:HasUidKey(KEY_ALLOW_VIEW_EQUIP)) then
        return DEFAULT_ALLOW_VIEW_EQUIP
    else
		return (g_Game.PlayerPrefsEx:GetIntByUid(KEY_ALLOW_VIEW_EQUIP) > 0)
    end
end

--- 设置是否允许查看装备
---@param self GameSettingModule
---@param allow boolean
function GameSettingModule:SetAllowViewEquip(allow)
    local value = 0
    if (allow) then value = 1 end
	g_Game.PlayerPrefsEx:SetIntByUid(KEY_ALLOW_VIEW_EQUIP, value)
	g_Game.PlayerPrefsEx:Save()
end

--- 获取是否开启抽卡广播
---@param self GameSettingModule
---@return boolean
function GameSettingModule:GetDrawCardBroadcast()
	if (not g_Game.PlayerPrefsEx:HasUidKey(KEY_DRAW_CARD_BROADCAST)) then
        return DEFAULT_DRAW_CARD_BROADCAST
    else
		return (g_Game.PlayerPrefsEx:GetIntByUid(KEY_DRAW_CARD_BROADCAST) > 0)
    end
end

---@param self GameSettingModule
---@param allow boolean
function GameSettingModule:SetDrawCardBroadcast(allow)
    local value = 0
    if (allow) then value = 1 end
	g_Game.PlayerPrefsEx:SetIntByUid(KEY_DRAW_CARD_BROADCAST, value)
	g_Game.PlayerPrefsEx:Save()
end

function GameSettingModule:StartNewGame()
    RuntimeDebugSettings:ClearOverrideAccountConfig()

    if USE_FPXSDK then
        -- 等SDK触发注销逻辑再重启
        ModuleRefer.FPXSDKModule:StartNewGame()
    else
        -- 立刻重启
        g_Game:RestartGame()
    end
end

return GameSettingModule
