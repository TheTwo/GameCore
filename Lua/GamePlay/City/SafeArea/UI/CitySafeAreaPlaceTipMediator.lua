--- scene:scene_build_tips_safe_place

local BaseUIMediator = require("BaseUIMediator")

---@class CitySafeAreaPlaceTipMediatorParameter
---@field zoneTitle string
---@field zoneContent string
---@field playAudioId number|nil

---@class CitySafeAreaPlaceTipMediator:BaseUIMediator
---@field new fun():CitySafeAreaPlaceTipMediator
---@field super BaseUIMediator
local CitySafeAreaPlaceTipMediator = class('CitySafeAreaPlaceTipMediator', BaseUIMediator)

function CitySafeAreaPlaceTipMediator:ctor()
    CitySafeAreaPlaceTipMediator.super.ctor(self)
    ---@type CS.DragonReborn.SoundPlayingHandle
    self._audioHandle = nil
end

function CitySafeAreaPlaceTipMediator:OnCreate(param)
    self._p_text_place = self:Text("p_text_place")
    self._p_text_sahint = self:Text("p_text_sahint")
end

---@param param CitySafeAreaPlaceTipMediatorParameter
function CitySafeAreaPlaceTipMediator:OnOpened(param)
    self._p_text_place.text = param.zoneTitle
    self._p_text_sahint.text = param.zoneContent
    if self._audioHandle and self._audioHandle:IsValid() then
        g_Game.SoundManager:Stop(self._audioHandle)
    end
    if param.playAudioId and param.playAudioId ~= 0 then
        self._audioHandle = g_Game.SoundManager:PlayAudio(param.playAudioId)
    end 
end

function CitySafeAreaPlaceTipMediator:OnHide(param)
    if self._audioHandle and self._audioHandle:IsValid() then
        g_Game.SoundManager:Stop(self._audioHandle)
    end
end

return CitySafeAreaPlaceTipMediator