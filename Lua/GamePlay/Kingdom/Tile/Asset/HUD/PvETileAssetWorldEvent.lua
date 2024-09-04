local MapTileAssetSolo = require("MapTileAssetSolo")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local KingdomMapUtils = require('KingdomMapUtils')
local DBEntityPath = require('DBEntityPath')
local AddExpedition2RadarParameter = require('AddExpedition2RadarParameter')
local MapHUDFadeDefine = require("MapHUDFadeDefine")
local ProgressType = require('ProgressType')
local ManualResourceConst = require("ManualResourceConst")

---@class PvETileAssetWorldEvent : PvPTileAssetUnit
---@field behaviour PvETileAssetWorldEventBehavior
local PvETileAssetWorldEvent = class("PvETileAssetWorldEvent", MapTileAssetSolo)

---@return string
function PvETileAssetWorldEvent:GetLodPrefab(lod)
    if KingdomMapUtils.InMapMediumLod(lod) then
        return ManualResourceConst.ui3d_bubble_world_events
    end
    return string.Empty
end

---@return CS.UnityEngine.Vector3
function PvETileAssetWorldEvent:GetPosition()
    return self:CalculateCenterPosition()
end

---@return CS.UnityEngine.Vector3
function PvETileAssetWorldEvent:CalculateCenterPosition()
    local uniqueId = self:GetUniqueId()
    local typeId = self:GetTypeId()
    local staticMapData = self:GetStaticMapData()

    local entity = g_Game.DatabaseManager:GetEntity(uniqueId, typeId)
    if entity == nil then
        return string.Empty
    end

    local x, z = KingdomMapUtils.ParseCoordinate(entity.MapBasics.Position.X, entity.MapBasics.Position.Y)
    x = x * staticMapData.UnitsPerTileX
    z = z * staticMapData.UnitsPerTileZ

    return CS.UnityEngine.Vector3(x, 0, z)
end

function PvETileAssetWorldEvent:CanShow()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end

    ---@type wds.Expedition
    local expedition = entity
    local isInTime = true
    if expedition.ExpeditionInfo.ActivateEndTime > 0 then
        isInTime = expedition.ExpeditionInfo.ActivateEndTime > g_Game.ServerTime:GetServerTimestampInSeconds()
    end
    --非本联盟的联盟世界事件 不显示
    local inAlliance = true
    local isAlliance = false
    local config = ConfigRefer.WorldExpeditionTemplate:Find(entity.ExpeditionInfo.Tid)
    local progressType = config:ProgressType()
    if progressType == ProgressType.Alliance then
        isAlliance = true
        if entity.Owner.ExclusiveAllianceId ~= ModuleRefer.AllianceModule:GetAllianceId() then
            inAlliance = false
        end
    end
    --个人世界事件只有自己能看到
    local isMine = entity.Owner.ExclusivePlayerId == ModuleRefer.PlayerModule:GetPlayer().ID
    --多人世界事件都能看到
    local isMulti = entity.Owner.ExclusivePlayerId == 0
    local isCanShow = (isMulti or (not isMulti and isMine))
    if isAlliance then
        isCanShow = inAlliance
    end
    local mapSystem = self:GetMapSystem()
    local lod = mapSystem.Lod
    local isInLod = KingdomMapUtils.InMapMediumLod(lod)
    local isInFilter = ModuleRefer.WorldEventModule:GetFilterType() == wrpc.RadarEntityType.RadarEntityType_Expedition

    local eventCfg =  ConfigRefer.WorldExpeditionTemplate:Find(entity.ExpeditionInfo.Tid)
    local progress = expedition.ExpeditionInfo.PersonalProgress[ModuleRefer.PlayerModule:GetPlayer().ID] or 0
    local percent = math.clamp(progress / eventCfg:MaxProgress(), 0, 1)
    local isFinish = percent >= 1

    local x = math.round(expedition.MapBasics.BuildingPos.X)
    local y = math.round(expedition.MapBasics.BuildingPos.Y)
    local isMistUnlocked = ModuleRefer.MapFogModule:IsFogUnlocked(x, y)

    local inRadar = ModuleRefer.RadarModule:IsInRadar()

    return isCanShow and isInLod and isInTime and isInFilter and not isFinish and isMistUnlocked and not inRadar
end

function PvETileAssetWorldEvent:OnShow()
end

function PvETileAssetWorldEvent:OnHide()
    self.behaviour = nil
end

function PvETileAssetWorldEvent:OnConstructionSetup()
    PvETileAssetWorldEvent.super.OnConstructionSetup(self)
    ---@type wds.EnergyTower
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end

    local inRadar = ModuleRefer.RadarModule:IsInRadar()
    if inRadar then
        self:Hide()
        return
    end

    self.expeditionInfo = entity.ExpeditionInfo
    self.go = self:GetAsset()
    self.go.transform.name = entity.ID
    self.behaviour = self.go:GetLuaBehaviour("PvETileAssetWorldEventBehavior").Instance
    self.behaviour:InitEventByEntity(entity)
    local lod = KingdomMapUtils.GetLOD()
    ModuleRefer.MapHUDModule:InitHUDFade(self.behaviour.materialSetter, KingdomMapUtils.InMapMediumLod(lod))
    
    self:OnConstructionUpdate()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Expedition.MsgPath, Delegate.GetOrCreate(self, self.OnConstructionUpdate))
    g_Game.ServiceManager:AddResponseCallback(AddExpedition2RadarParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetEventQaulity))

end

function PvETileAssetWorldEvent:OnConstructionUpdate(entity, changeTable)
    if self:CanShow() then
        self:Show()
    else
        self:Hide()
    end
    if self.behaviour and changeTable and changeTable.ExpeditionInfo and
     changeTable.ExpeditionInfo.State == wds.ExpeditionState.ExpeditionActive then
        self.behaviour:InitEventByEntity(entity)
    end
    KingdomMapUtils.DirtyMapMark()
end

function PvETileAssetWorldEvent:OnConstructionShutdown()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Expedition.MsgPath, Delegate.GetOrCreate(self, self.OnConstructionUpdate))
    g_Game.ServiceManager:RemoveResponseCallback(AddExpedition2RadarParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetEventQaulity))
end

function PvETileAssetWorldEvent:OnGetEventQaulity(isSuccess, reply, rpc)
    if not isSuccess then
        return
    end

    if self.behaviour then
        self.behaviour:ChangeRangeQuality()
    end
end

function PvETileAssetWorldEvent:OnLodChanged(oldLod, newLod)
    if not self.behaviour then
        return
    end

    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end

    if self:IsFadeIn(entity, oldLod, newLod) then
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.behaviour.materialSetter, MapHUDFadeDefine.FadeIn)
    elseif self:IsFadeOut(entity, oldLod, newLod) then
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.behaviour.materialSetter, MapHUDFadeDefine.FadeOut)
    elseif self:IsStay(entity, oldLod, newLod) then
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.behaviour.materialSetter, MapHUDFadeDefine.Show)
    else
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.behaviour.materialSetter, MapHUDFadeDefine.Hide)
    end
end

function PvETileAssetWorldEvent:IsFadeIn(entity, oldLod, newLod)
    return not KingdomMapUtils.InMapMediumLod(oldLod) and KingdomMapUtils.InMapMediumLod(newLod)
end

function PvETileAssetWorldEvent:IsFadeOut(entity, oldLod, newLod)
    return KingdomMapUtils.InMapMediumLod(oldLod) and not KingdomMapUtils.InMapMediumLod(newLod)
end

function PvETileAssetWorldEvent:IsStay(entity, oldLod, newLod)
    return KingdomMapUtils.InMapMediumLod(oldLod) and KingdomMapUtils.InMapMediumLod(newLod)
end

return PvETileAssetWorldEvent