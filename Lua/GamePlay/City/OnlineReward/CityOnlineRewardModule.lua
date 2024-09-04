local BaseModule = require("BaseModule")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local PooledGameObjectCreateHelper = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
---@class CityOnlineRewardModule : BaseModule
local CityOnlineRewardModule = class('CityOnlineRewardModule', BaseModule)

function CityOnlineRewardModule:ctor()
    self.createHelper = PooledGameObjectCreateHelper.Create("CityOnlineRewardModule")
    self.rewardObjHandler = nil
    ---@type CityFloatingObjectHotAirBalloon
    self.rewardObj = nil

    self.city = nil
end

function CityOnlineRewardModule:OnRegister()
    g_Game.EventManager:AddListener(EventConst.CITY_SET_ACTIVE, Delegate.GetOrCreate(self, self.OnCitySetActive))
end

function CityOnlineRewardModule:OnRemove()
    g_Game.EventManager:RemoveListener(EventConst.CITY_SET_ACTIVE, Delegate.GetOrCreate(self, self.OnCitySetActive))
end

function CityOnlineRewardModule:OnLoggedIn()
end

function CityOnlineRewardModule:OnCitySetActive(active, city)
    self.city = city
    if active then
        if not self:IsRewardObjExist() then
            self:CreateRewardObj()
        else
            self:ResumeRewardObj()
        end
    end
end

function CityOnlineRewardModule:IsRewardObjExist()
    return self.rewardObj ~= nil
end

function CityOnlineRewardModule:CreateRewardObj()
    if self.rewardObjHandler then
        return
    end
    self.rewardObjHandler = self.createHelper:Create("mdl_hot_air_balloon", self.city.CityRoot.transform, function(go)
        self.rewardObj = go:GetLuaBehaviour("CityFloatingObjectHotAirBalloon").Instance
        self.rewardObj:OnCreate()
    end)
end

function CityOnlineRewardModule:PauseRewardObj()
    self.rewardObj:Pause()
end

function CityOnlineRewardModule:ResumeRewardObj()
end

return CityOnlineRewardModule