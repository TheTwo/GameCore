local EventConst = require("EventConst")
local CitizenBTActionSequence = require("CitizenBTActionSequence")
local CityCitizenDefine = require("CityCitizenDefine")
local CitizenBTDefine = require("CitizenBTDefine")
local CityCitizenStateHelper = require("CityCitizenStateHelper")
local CitizenBTActionGoTo = require("CitizenBTActionGoTo")
local CitizenBTActionPlayClip = require("CitizenBTActionPlayClip")
local CitizenBTActionGetWorkPlayClip = require("CitizenBTActionGetWorkPlayClip")
local CityWorkType = require("CityWorkType")
local Delegate = require("Delegate")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionWork:CitizenBTActionNode
---@field new fun():CitizenBTActionWork
---@field super CitizenBTActionNode
local CitizenBTActionWork = class('CitizenBTActionWork', CitizenBTActionNode)

function CitizenBTActionWork:ctor()
    CitizenBTActionWork.super.ctor(self)
    self._subActions = CitizenBTActionSequence.new(false)
    self._uid = nil
    self._workTargetChanged = false
    self._originTargetInfo = nil
    self._subRegisterTargetInfo = nil
    ---@type CityCitizenWorkData
    self._workData = nil
    self._workInteracePoint = nil
end

function CitizenBTActionWork:Enter(context, gContext)
    local citizen = context:GetCitizen()
    local mgr = context:GetMgr()
    local targetInfo, workData = CityCitizenStateHelper.GetTargetInfo(context)
    self._originTargetInfo = targetInfo
    self._workData = workData
    -- local targetPos,redirectTarget
    -- targetPos,targetInfo,redirectTarget = CityCitizenStateHelper.GetWorkTargetPosByTargetInfo(targetInfo, context:GetCitizenData())
    ---@type CityInteractPoint_Impl
    local targetPoint
    local redirectTarget
    targetPoint,targetInfo,redirectTarget = CityCitizenStateHelper.AcquireWorkTargetInteractPointByTargetInfo(targetInfo, context:GetCitizenData())
    local reason = nil
    if workData and workData._config then
        reason = CityCitizenDefine.WorkTargetReason.Base
        local t = workData._config:Type()
        if t == CityWorkType.FurnitureResCollect then
            reason = CityCitizenDefine.WorkTargetReason.Operate
        end
    end
    if not targetPoint then
        self._subActions:Clear()
        self._workTargetChanged = true
        return
    end
    context:BindInteractPoint(targetPoint)
    self._workInteracePoint = targetPoint
    ---@type CitizenBTActionGoToContextParam
    local gotoInfo = {}
    gotoInfo.targetPos = targetPoint:GetWorldPos()
    -- gotoInfo.exitTurnTo = mgr:GetWorkTargetInteractDirPos(targetInfo.id, targetInfo.type, reason)
    gotoInfo.exitDir =  CS.UnityEngine.Quaternion.LookRotation(targetPoint.worldRotation)
    gotoInfo.useRun = true
    gotoInfo.dumpStr = CitizenBTDefine.DumpGotoInfo
    if workData then
        local index,limitTime = workData:GetCurrentTargetIndexGoAndWorkLeftTime()
        if index and limitTime then
            gotoInfo.limitTime = limitTime
        end
    end
    context:Write(CitizenBTDefine.ContextKey.GotoTargetInfo, gotoInfo)
    context:Write(CitizenBTDefine.ContextKey.WorkTargetInfo, targetInfo)
    citizen:ChangeAnimatorState(CityCitizenDefine.AniClip.Idle)
    self._subActions:Clear()
    self._subActions:AddAction(CitizenBTActionGoTo.new())
    self._subActions:AddAction(CitizenBTActionGetWorkPlayClip.new())
    self._subActions:AddAction(CitizenBTActionPlayClip.new())
    self._subActions:Enter(context, gContext)

    self._uid = mgr.city.uid
    self._workTargetChanged = false
    self._subRegisterTargetInfo = nil
    
    if redirectTarget then
        self._subRegisterTargetInfo = targetInfo
    end
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_INPROGRESS_RESOURCE_REMOVED, Delegate.GetOrCreate(self, self.OnInProgressResourceRemove))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_ELEMENT_UPDATE, Delegate.GetOrCreate(self, self.OnCityElementBatchUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_IN_USING_POINT_REMOVED, Delegate.GetOrCreate(self, self.OnInteractPointRemove))
end

function CitizenBTActionWork:Tick(dt, nowTime, context, gContext)
    if self._workTargetChanged then
        return true
    end
    if not self._workData then
        return true
    end
    local workData = context:GetCitizenData():GetWorkData()
    if not workData then
        return true
    end
    if self._workData._id ~= workData._id then
        return true
    end
    local workChangeMap = gContext:Read(CitizenBTDefine.G_ContextKey.cityWorkTargetChange)
    if workChangeMap and workChangeMap[context:GetCitizenId()] then
        return true
    end
    return self._subActions:Tick(dt, nowTime, context, gContext)
end

function CitizenBTActionWork:Exit(context, gContext)
    self._workInteracePoint = nil
    context:BindInteractPoint(nil)
    context:Write(CitizenBTDefine.ContextKey.GotoTargetInfo, nil)
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_INPROGRESS_RESOURCE_REMOVED, Delegate.GetOrCreate(self, self.OnInProgressResourceRemove))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_ELEMENT_UPDATE, Delegate.GetOrCreate(self, self.OnCityElementBatchUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_IN_USING_POINT_REMOVED, Delegate.GetOrCreate(self, self.OnInteractPointRemove))
    self._subActions:Exit(context, gContext)
end

function CitizenBTActionWork:OnInProgressResourceRemove(cityId, elementId, progressInfo, workId)
    if not self._subRegisterTargetInfo or self._uid ~= cityId then
        return
    end
    if self._subRegisterTargetInfo.id ~= elementId then
        return
    end
    self._workTargetChanged = true
end

---@param city City,
---@param evtInfo {Event:string, Add:table<number, boolean>, Remove:table<number, boolean>, Change:table<number, boolean>}
function CitizenBTActionWork:OnCityElementBatchUpdate(city, evtInfo)
    if not city or city.uid ~= self._uid or not evtInfo then return end
    local checkElementId = self._subRegisterTargetInfo and self._subRegisterTargetInfo.id or (self._originTargetInfo and self._originTargetInfo.id)
    if (evtInfo.Remove and evtInfo.Remove[checkElementId]) or (evtInfo.Change and evtInfo.Change[checkElementId]) then
        self._workTargetChanged = true
    end
end

function CitizenBTActionWork:OnInteractPointRemove(point)
    if point and point == self._workInteracePoint then
        self._workTargetChanged = true
    end
end

return CitizenBTActionWork