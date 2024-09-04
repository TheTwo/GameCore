---@class LumbermillCounter
---@field new fun():LumbermillCounter
---@field animator CS.UnityEngine.Animator
local LumbermillCounter = class("LumbermillCounter")
local EventConst = require("EventConst")

function LumbermillCounter:OnEnable()
    if self.animatorId == nil then
        self.animatorId = self.animator:GetInstanceID()
    end

    g_Game.EventManager:TriggerEvent(EventConst.CITY_PET_DRAMA_LUMBERMILL_COUNTER, self.animatorId)
end

return LumbermillCounter