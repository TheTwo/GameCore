local PvPTileAssetHud = require("PvPTileAssetHud")
---@class PvETileAssetHudResourceFieldBar:PvPTileAssetHud
---@field new fun():PvETileAssetHudResourceFieldBar
local PvETileAssetHudResourceFieldBar = class("PvETileAssetHudResourceFieldBar", PvPTileAssetHud)
local KingdomMapUtils = require("KingdomMapUtils")
local DBEntityType = require("DBEntityType")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local Vector3 = CS.UnityEngine.Vector3
local MapHudTransformControl = require("MapHudTransformControl")
local ManualResourceConst = require("ManualResourceConst")

function PvETileAssetHudResourceFieldBar:GetLodPrefab(lod)
    if KingdomMapUtils.InMapNormalLod(lod) then
        return ManualResourceConst.ui3d_progress_territory
    end
    return string.Empty
end

function PvETileAssetHudResourceFieldBar:CanShow()
    if self.view.typeId ~= DBEntityType.ResourceField then
        return false
    end

    ---@type wds.ResourceField
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return false
    end

    return entity.MapStates.Battling and entity.Army.DummyTroopInitFinish and entity.Army.DummyTroopIDs:Count() > 0
end

function PvETileAssetHudResourceFieldBar:OnConstructionSetup()
    PvPTileAssetHud.OnConstructionSetup(self)

    ---@type MapLifebar
    self.behavior = self.root:GetLuaBehaviour("MapLifebar").Instance
    ---@type wds.ResourceField
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    self.curValue, self.maxValue = 0, 0
    for _, armyMemberInfo in pairs(entity.Army.DummyTroopIDs) do
        self.curValue = self.curValue + armyMemberInfo.Hp
        self.maxValue = self.maxValue + armyMemberInfo.HpMax
    end
    self.behavior:SetProgress(self:GetProgress())
    self.behavior:SetLocalPosition(Vector3(0, 100, 0))
    self.behavior:SetCamera(KingdomMapUtils.GetBasicCamera().mainCamera)
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnTickSecond))
end

function PvETileAssetHudResourceFieldBar:OnConstructionShutdown()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnTickSecond))
    if self.behavior then
        self.behavior:SetCamera(nil)
        self.behavior = nil
    end
    PvPTileAssetHud.OnConstructionShutdown(self)
end

function PvETileAssetHudResourceFieldBar:GetProgress()
    if self.maxValue <= 0 then
        return 0
    end
    return self.curValue / self.maxValue
end

function PvETileAssetHudResourceFieldBar:OnTickSecond()
    ---@type wds.ResourceField
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then return end

    self.curValue, self.maxValue = 0, 0
    for _, armyMemberInfo in pairs(entity.Army.DummyTroopIDs) do
        self.curValue = self.curValue + armyMemberInfo.Hp
        self.maxValue = self.maxValue + armyMemberInfo.HpMax
    end
    self.behavior:SetProgress(self:GetProgress())

    if not self:CanShow() then
        self:Hide()
    end
end

return PvETileAssetHudResourceFieldBar