local GUILayout = require("GUILayout")
local GMPage = require("GMPage")

---@class GMPageSound:GMPage
local GMPageSound = class('GMPageSound', GMPage)

function GMPageSound:ctor()
    self._bgm = string.Empty
    self._soundEvent = string.Empty
end

function GMPageSound:OnGUI()
    local soundManager = g_Game.SoundManager
    GUILayout.BeginHorizontal()
    local v = soundManager:GetBgmVolume()
    GUILayout.Label(string.format("bgmV:%0.2f", v), GUILayout.shrinkWidth)
    soundManager:SetBgmVolume(GUILayout.HorizontalSlider(v, 0.0, 100.0))
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    v = soundManager:GetSfxVolume()
    GUILayout.Label(string.format("sfxV:%0.2f", v), GUILayout.shrinkWidth)
    soundManager:SetSfxVolume(GUILayout.HorizontalSlider(v, 0.0, 100.0))
    v = soundManager:GetCustomRTPCValue("bigmap_position_rtpc_x")
    GUILayout.Label(string.format("高度声音衰减:%0.2f", v), GUILayout.shrinkWidth)
    soundManager:SetCustomRTPCValue("bigmap_position_rtpc_x", GUILayout.HorizontalSlider(v, 0.0, 100.0))
    v = soundManager:GetCustomRTPCValue("bigmap_position_rtpc_transverse")
    GUILayout.Label(string.format("左右声音衰减:%0.2f", v), GUILayout.shrinkWidth)
    soundManager:SetCustomRTPCValue("bigmap_position_rtpc_transverse", GUILayout.HorizontalSlider(v, 0.0, 100.0))
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    GUILayout.Label("BGM", GUILayout.shrinkWidth)
    self._bgm = GUILayout.TextField(self._bgm, GUILayout.expandWidth)
    if GUILayout.Button("SetBgm") then
        soundManager:PlayBgm(self._bgm)
    end
    if GUILayout.Button("StopBgm") then
        soundManager:StopBgm()
    end
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    GUILayout.Label("Sound", GUILayout.shrinkWidth)
    self._soundEvent = GUILayout.TextField(self._soundEvent, GUILayout.expandWidth)
    if GUILayout.Button("TriggerSound") then
        soundManager:Play(self._soundEvent)
    end
    if GUILayout.Button("CreateSoundEffect") then
        soundManager:Create(self._soundEvent)
    end
    GUILayout.EndHorizontal()
end

return GMPageSound