local MapTileAssetSolo = require("MapTileAssetSolo")
local Utils = require("Utils")
local EventConst = require("EventConst")
local KingdomMapUtils = require("KingdomMapUtils")
local CameraUtils = require('CameraUtils')
local CameraConst = require('CameraConst')
local ConfigRefer = require('ConfigRefer')
local AreaShape = require('AreaShape')
local ProgressType = require('ProgressType')
local ManualResourceConst = require('ManualResourceConst')
local TimerUtility = require('TimerUtility')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local DBEntityPath = require('DBEntityPath')
local AddExpedition2RadarParameter = require('AddExpedition2RadarParameter')
local PlayType = require('PlayType')
local I18N = require('I18N')
local Screen = CS.UnityEngine.Screen
local Vector3 = CS.UnityEngine.Vector3
local MapStateNormal = require("MapStateNormal")
local AllianceExpeditionCreateType = require('AllianceExpeditionCreateType')

---@class PvETileAssetWorldEventCircleRange : MapTileAssetSolo
---@field isSelected boolean
---@field entity wds.Expedition
local PvETileAssetWorldEventCircleRange = class("PvETileAssetWorldEventCircleRange", MapTileAssetSolo)

function PvETileAssetWorldEventCircleRange:GetLodPrefab(lod)
    if lod <= 2 then
        return ManualResourceConst.prefab_test_world_event_circle
    end
    return string.Empty
end

function PvETileAssetWorldEventCircleRange:CanShow()
    if KingdomMapUtils.IsNewbieState() then
        return true
    end

    return ModuleRefer.WorldEventModule:CheckIsShow(self.view.uniqueId, self.view.typeId, function()
        return self:CalculatePosition()
    end)
end

---@return CS.UnityEngine.Vector3
function PvETileAssetWorldEventCircleRange:GetPosition()
    return self:CalculateCenterPosition()
end

---@return CS.UnityEngine.Vector3
function PvETileAssetWorldEventCircleRange:CalculateCenterPosition()
    local uniqueId = self:GetUniqueId()
    local typeId = self:GetTypeId()
    local staticMapData = self:GetStaticMapData()

    local entity = g_Game.DatabaseManager:GetEntity(uniqueId, typeId)
    if entity == nil then
        return string.Empty
    end

    local x = entity.MapBasics.Position.X * staticMapData.UnitsPerTileX
    local z = entity.MapBasics.Position.Y * staticMapData.UnitsPerTileZ
    local y = KingdomMapUtils.SampleHeight(x, z)

    return CS.UnityEngine.Vector3(x, y, z)
end

---@return CS.UnityEngine.Vector3
function PvETileAssetWorldEventCircleRange:CalculatePosition()
    local uniqueId = self:GetUniqueId()
    local typeId = self:GetTypeId()
    local staticMapData = self:GetStaticMapData()

    local entity = g_Game.DatabaseManager:GetEntity(uniqueId, typeId)
    if entity == nil then
        return CS.UnityEngine.Vector3.zero
    end
    self.entity = entity

    local x = entity.MapBasics.BuildingPos.X * staticMapData.UnitsPerTileX
    local z = entity.MapBasics.BuildingPos.Y * staticMapData.UnitsPerTileZ
    local y = KingdomMapUtils.SampleHeight(x, z)

    local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(entity.ExpeditionInfo.Tid)
    self.eventCfg = eventCfg
    local ra = eventCfg:RadiusA()
    if eventCfg:Shape() == AreaShape.Ellipse then
        local rb = eventCfg:RadiusB()
        return CS.UnityEngine.Vector3(x + ra, y, z + rb)
    end
    return CS.UnityEngine.Vector3(x + ra, y, z + ra)
end

function PvETileAssetWorldEventCircleRange:OnConstructionSetup()
    self:UpdateRange()
    if not self.expeditionInfo then
        return
    end
    self.basicCamera = KingdomMapUtils.GetBasicCamera()
    self:ClearTimer()
    local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(self.expeditionInfo.Tid)
    self:OnConstructionUpdate()
    if Utils.IsNull(self.go) then
        return
    end
    self.basicCamera:AddTransformChangeListener(Delegate.GetOrCreate(self, self.UpdateCamera))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Expedition.MsgPath, Delegate.GetOrCreate(self, self.OnConstructionUpdate))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Expedition.ExpeditionInfo.ExpeditionVanishInfo.MsgPath, Delegate.GetOrCreate(self, self.ShowFailReason))
    g_Game.EventManager:AddListener(EventConst.SET_WORLD_EVENT_TOAST_STATE, Delegate.GetOrCreate(self, self.ChangeCanOpenToast))
    g_Game.EventManager:AddListener(EventConst.WORLD_EVENT_PRE_NOTICE_STATE_END, Delegate.GetOrCreate(self, self.OnPreNoticeStateEnd))
    g_Game.ServiceManager:AddResponseCallback(AddExpedition2RadarParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetEventQaulity))
    self.staticMapData = self:GetStaticMapData()
    local radiusA = eventCfg:RadiusA()
    local worldX = radiusA * self.staticMapData.UnitsPerTileX
    self.lengthX = worldX ^ 2
    -- local scaleX = worldX * 2
    -- local eulerAngles
    self.shape = eventCfg:Shape()
    if self.shape == AreaShape.Ellipse then
        local radiusB = eventCfg:RadiusB()
        local worldZ = radiusB * self.staticMapData.UnitsPerBlockZ
        self.lengthZ = worldZ ^ 2
        -- local scaleZ = worldZ * 2
        local shapeRot = instanceCfg:Rot()
        local angle = math.radian2angle(shapeRot)
        self.cosa = math.cos(angle)
        self.sina = math.sin(angle)
        -- eulerAngles = CS.UnityEngine.Vector3(0, math.radian2angle(shapeRot), 0)
    else

    end
    self.circlePos = self.go.transform.position
    self.coord = CS.Grid.MapUtils.CalculateWorldPositionToCoord(self.circlePos, KingdomMapUtils.GetStaticMapData())
    self:UpdateCamera()
    self.isCanOpenToast = true
    if not self.notShowPanel then
        self.timer = TimerUtility.IntervalRepeat(function()
            self:WorldToastSecondTick()
        end, 0.2, -1)
    end
end

function PvETileAssetWorldEventCircleRange:UpdateCamera()
    local ray = self.basicCamera:GetRayFromScreenPosition(Vector3(Screen.width / 2, Screen.height / 2, 0))
    self.cameraHitPos = CameraUtils.GetHitPointLinePlane(ray, CameraConst.PLANE)
    self.lod = KingdomMapUtils.GetKingdomScene():GetLod()
end

function PvETileAssetWorldEventCircleRange:OnConstructionUpdate(entity, changeTable)
    if self:CanShow() then
        self:Show()
    else
        self:Hide()
    end
    KingdomMapUtils.DirtyMapMark()
    self:CheckStateChange(entity, changeTable)
end

function PvETileAssetWorldEventCircleRange:WorldToastSecondTick()
    if not KingdomMapUtils.IsMapState() then
        return
    end
    local isShowToast = ModuleRefer.WorldEventModule:GetShowToast()
    if self.go and self.cameraHitPos then
        local isInScreen
        local x = self.cameraHitPos.x - self.circlePos.x
        local z = self.cameraHitPos.z - self.circlePos.z
        if self.shape == AreaShape.Ellipse then
            local a = (self.cosa * x + self.sina * z) ^ 2
            local b = (self.sina * x - self.cosa * z) ^ 2
            local elipse = a / self.lengthX + b / self.lengthZ
            isInScreen = elipse <= 1
        else
            isInScreen = (x ^ 2 + z ^ 2) <= self.lengthX
        end
        if isInScreen and self.lod <= 2 and not isShowToast and self.isCanOpenToast and self:CurrentKingdomStateIsNormal() and not ModuleRefer.WorldEventModule:IsAllianceBoss(self.entity) then
            local param = {isShow = true, isBoss = false, data = {expeditionInfo = self.expeditionInfo, x = self.posX, y = self.posY, entityId = self.entityId}}
            g_Game.EventManager:TriggerEvent(EventConst.WORLD_EVENT_SHOW_HIDE, param)
            g_Game.EventManager:TriggerEvent(EventConst.HUD_CLOSE_TASK_COMP, false)
        elseif isShowToast and ((self.lod > 2) or (not isInScreen) or not self:CurrentKingdomStateIsNormal()) then
            local param = {isShow = false, isBoss = false, data = {expeditionInfo = self.expeditionInfo, x = self.posX, y = self.posY, entityId = self.entityId}}
            g_Game.EventManager:TriggerEvent(EventConst.WORLD_EVENT_SHOW_HIDE, param)
        end
    end
end

function PvETileAssetWorldEventCircleRange:CurrentKingdomStateIsNormal()
    ---@type KingdomSceneStateMap
    local kingdomState = KingdomMapUtils.GetKingdomState()
    return kingdomState and kingdomState:GetCurrentMapState() and kingdomState:GetCurrentMapState():GetName() == MapStateNormal.Name
end

function PvETileAssetWorldEventCircleRange:OnConstructionShutdown()
    if Utils.IsNull(self.go) then
        return
    end

    self:ClearTimer()
    self.lod = KingdomMapUtils.GetLOD()
    local isFinish = false
    g_Game.EventManager:TriggerEvent(EventConst.HUD_CLOSE_TASK_COMP, true)
    if self.expeditionInfo and ModuleRefer.PlayerModule:GetPlayer() then
        local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(self.expeditionInfo.Tid)
        local progress
        local eventType = eventCfg:ProgressType()
        if eventType == ProgressType.Whole or eventType == ProgressType.Alliance then
            progress = self.expeditionInfo.Progress
        elseif eventType == ProgressType.Personal then
            progress = self.expeditionInfo.PersonalProgress[ModuleRefer.PlayerModule:GetPlayer().ID] or 0
        end
        local percent = math.clamp(progress / eventCfg:MaxProgress(), 0, 1)
        isFinish = percent >= 1
        if isFinish then
            -- 个人事件完成 播特效
            local isMine, isMulti, isAlliance, isBigEvent = ModuleRefer.WorldEventModule:CheckEventType(self.entity)
            if isMine or isMulti then
                ModuleRefer.WorldEventModule:LoadWorldCompletedEffect(self.go.transform)
            end
            g_Game.EventManager:TriggerEvent(EventConst.WORLD_EVENT_FINISH, self.entity.ID)
        end
    end
    if not isFinish then
        local param = {isShow = false, isBoss = false}
        g_Game.EventManager:TriggerEvent(EventConst.WORLD_EVENT_SHOW_HIDE, param)
    end

    self:ClearEffectHandle()
    if self.basicCamera then
        self.basicCamera:RemoveTransformChangeListener(Delegate.GetOrCreate(self, self.UpdateCamera))
    end
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Expedition.MsgPath, Delegate.GetOrCreate(self, self.OnConstructionUpdate))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Expedition.ExpeditionInfo.ExpeditionVanishInfo.MsgPath, Delegate.GetOrCreate(self, self.ShowFailReason))
    g_Game.EventManager:RemoveListener(EventConst.SET_WORLD_EVENT_TOAST_STATE, Delegate.GetOrCreate(self, self.ChangeCanOpenToast))
    g_Game.EventManager:RemoveListener(EventConst.WORLD_EVENT_PRE_NOTICE_STATE_END, Delegate.GetOrCreate(self, self.OnPreNoticeStateEnd))
    g_Game.ServiceManager:RemoveResponseCallback(AddExpedition2RadarParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetEventQaulity))
end

function PvETileAssetWorldEventCircleRange:UpdateRange()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end
    self.entity = entity
    self.entityId = entity.ID
    self.expeditionInfo = entity.ExpeditionInfo
    self.posX = entity.MapBasics.BuildingPos.X
    self.posY = entity.MapBasics.BuildingPos.Y
    self.go = self:GetAsset()
    if Utils.IsNull(self.go) then
        return
    end
    local createType = ModuleRefer.WorldEventModule:GetAllianceActivityExpeditionByExpeditionID(self.expeditionInfo.Tid).CreateType
    self.notShowPanel = createType == AllianceExpeditionCreateType.ItemActivator
    self.go.transform.name = "WorldEventCircle" .. entity.ID
    self.behavior = self.go:GetLuaBehaviour("PvETileAssetWorldEventCircleBehavior").Instance
    self.behavior:ShowRange(entity.ExpeditionInfo, self.view.staticMapData, self.entityId)
    if self.expeditionInfo.State == wds.ExpeditionState.ExpeditionNotice then
        self.noticeHandle = ModuleRefer.WorldEventModule.createHelper:Create(ManualResourceConst.vfx_bigmap_shenmishijian, self.go.transform, function(go)
            go.transform.localPosition = CS.UnityEngine.Vector3(0, 20, 0)
            go.transform.eulerAngles = CS.UnityEngine.Vector3(270, 0, 0)
            go.transform.localScale = CS.UnityEngine.Vector3(5, 5, 5)
            local trigger = go:GetLuaBehaviour("MapUITrigger").Instance
            trigger:SetEnable(true)
            trigger:SetTrigger(Delegate.GetOrCreate(self, self.OnClickSelfTrigger))
        end)
        self.noticeRingHandle = ModuleRefer.WorldEventModule.createHelper:Create(ManualResourceConst.vfx_bigmap_shenmishijian_ring, self.go.transform:GetChild(0), function(go)
            go.transform.localPosition = CS.UnityEngine.Vector3(0, 20, 0)
            go.transform.eulerAngles = CS.UnityEngine.Vector3(270, 0, 0)
            go.transform.localScale = CS.UnityEngine.Vector3(1, 1, 1)
        end)
    end
end

function PvETileAssetWorldEventCircleRange:OnGetEventQaulity(isSuccess, reply, rpc)
    if not isSuccess then
        return
    end

    if self.behavior then
        self.behavior:ChangeRangeQuality()
    end
end

function PvETileAssetWorldEventCircleRange:ClearTimer()
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

function PvETileAssetWorldEventCircleRange:ClearEffectHandle()
    if self.effHandle then
        ModuleRefer.WorldEventModule.createHelper:Delete(self.effHandle)
    end
    self.effHandle = nil
    if self.noticeHandle then
        ModuleRefer.WorldEventModule.createHelper:Delete(self.noticeHandle)
    end
    self.noticeHandle = nil
    if self.noticeRingHandle then
        ModuleRefer.WorldEventModule.createHelper:Delete(self.noticeRingHandle)
    end
    self.noticeRingHandle = nil
end

function PvETileAssetWorldEventCircleRange:ChangeCanOpenToast(isCanOpenToast)
    if not isCanOpenToast then
        ModuleRefer.WorldEventModule:SetShowToast(false)
    end
    self.isCanOpenToast = isCanOpenToast
end

function PvETileAssetWorldEventCircleRange:CheckStateChange(entity, changeTable)
    if not entity or entity.ID ~= self.entityId then
        return
    end
    if not changeTable or not changeTable.ExpeditionInfo or not changeTable.ExpeditionInfo.State then
        return
    end

    if changeTable.ExpeditionInfo.State == wds.ExpeditionState.ExpeditionActive then
        self:OnPreNoticeStateEnd()
    end
end

function PvETileAssetWorldEventCircleRange:OnPreNoticeStateEnd()
    if self.noticeHandle then
        ModuleRefer.WorldEventModule.createHelper:Delete(self.noticeHandle)
    end
    self.noticeHandle = nil
    if self.noticeRingHandle then
        ModuleRefer.WorldEventModule.createHelper:Delete(self.noticeRingHandle)
    end
    self.noticeRingHandle = nil
    self.behavior = self.go:GetLuaBehaviour("PvETileAssetWorldEventCircleBehavior").Instance
    self.behavior:ShowRange(self.entity.ExpeditionInfo, self.view.staticMapData, self.entityId)
end

function PvETileAssetWorldEventCircleRange:ShowFailReason(entity, changeTable)
    if not changeTable.VanishRea then
        return
    end
    if self.eventCfg:PlayType() == PlayType.PersonalChallenge and changeTable.VanishRea == wds.ExpeditionVanishRea.ExpeditionVanishRea_Failed then
        ModuleRefer.ToastModule:AddTopToast({content = I18N.Get("WorldExpedition_taost_Youth_dies")})
    end
end

function PvETileAssetWorldEventCircleRange:OnClickSelfTrigger()
    ModuleRefer.WorldEventModule:GetPreviewPrompt()
end

return PvETileAssetWorldEventCircleRange
