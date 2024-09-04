local CityCitizenDefine = require("CityCitizenDefine")
local CityCitizenState = require("CityCitizenState")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local AudioConsts = require("AudioConsts")
local EventConst = require("EventConst")
local CityWorkTargetType = require("CityWorkTargetType")
local CityWorkType = require("CityWorkType")
local CityCitizenStateHelper = require("CityCitizenStateHelper")

---@class CityCitizenStateSubInteractTarget:CityCitizenState
---@field new fun(cityUnitCitizen:CityUnitCitizen):CityCitizenStateSubInteractTarget
---@field super CityCitizenState
local CityCitizenStateSubInteractTarget = class('CityCitizenStateSubInteractTarget', CityCitizenState)

function CityCitizenStateSubInteractTarget:ctor(cityUnitCitizen)
    CityCitizenState.ctor(self, cityUnitCitizen)
    self._posRange = 0.15
    ---@type CS.DragonReborn.SoundPlayingHandle
    self._soundHandle = nil
    ---@type number|nil
    self._exitFireNotifyCollectEnd = nil
    ---@type CityCitizenTargetInfo
    self._targetInfo = nil
end

function CityCitizenStateSubInteractTarget:Enter()
    self._exitFireNotifyCollectEnd = nil
    self._targetInfo = self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetInfo)
    local workData = self._citizen._data:GetWorkData()
    if self._targetInfo then
        local reason = nil
        if workData and workData._config then
            reason = CityCitizenDefine.WorkTargetReason.Base
            local t = workData._config:Type()
            if t == CityWorkType.FurnitureResCollect then
                reason = CityCitizenDefine.WorkTargetReason.Operate
            end
        end
        local pos = self._citizen._data._mgr:GetWorkTargetInteractDirPos(self._targetInfo.id, self._targetInfo.type, reason)
        if pos then
            self._citizen._moveAgent:StopMoveTurnToPos(pos)
        end
    end
    self._isAutoProduce = workData and workData._isInfinity or false
    self._currentIndex,self._interactTime = self._citizen._data:GetCurrentTargetWorkTime()
    if not self._interactTime and self._currentIndex then
        self._interactTime = self._citizen._data:GetWorkData():GetTargetWorkTime()
    end
    if workData and self._currentIndex then
        local targetId, targetType = workData:GetTarget()
        if targetId and targetType and targetType == CityWorkTargetType.Resource then
            self._exitFireNotifyCollectEnd = targetId
        end
    end
    if self._targetInfo then
        self:PlayInteractAniClip(nil)
        self:PlayInteractSound(nil)
    else
        self:PlayInteractAniClip(workData)
        self:PlayInteractSound( workData)
    end
    self:SyncInfectionVfx()
    self:CheckAndFixPos()
end

function CityCitizenStateSubInteractTarget:Tick(dt)
    if self._isAutoProduce then
        return
    end
    if (not self._interactTime) or self._interactTime <= 0 then
        if self:HasWorkTask() then
            self.stateMachine:ChangeState("CityCitizenStateSubSelectWorkTarget")
        else
            self.stateMachine:ChangeState("CityCitizenStateSubRandomWait")
        end
        return
    end
    self._interactTime = self._interactTime - dt
    if self._targetInfo and self._targetInfo.type == CityWorkTargetType.Building then
        if self._citizen._data._mgr:CheckIsEnemyEffectRange(self._citizen) then
            self._targetInfo = nil
            self._citizen._data._mgr:StopWork(self._citizen.id)
        end
    end
end

function CityCitizenStateSubInteractTarget:Exit()
    self:StopInteractSound()
    if self._exitFireNotifyCollectEnd then
        local id = self._exitFireNotifyCollectEnd
        self._exitFireNotifyCollectEnd = nil
        --city elementId citizenId
        --g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_RESOURCE_COLLECT_ACTION_EXIT, self._citizen._data._mgr._city, id, self._citizen._data._id)
    end
end

function CityCitizenStateSubInteractTarget:OnWalkableChangedCheck(gridRange)
    if gridRange.oldRange and self._citizen:CheckSelfPathInRange(gridRange.oldRange) then
        self._citizen:OffsetMoveAndWayPoints(self._citizen._moveAgent._currentPosition + gridRange.offset)
    end
end

function CityCitizenStateSubInteractTarget:GetInteractAniClip(targetId, targetType)
    if targetType == CityWorkTargetType.Building then
        local cell = self._citizen._data._mgr.city.grid:FindMainCellWithTileId(targetId)
        if cell then
            local c = ConfigRefer.BuildingLevel:Find(cell:ConfigId())
            if c then
                local clip = c:ConstructAction()
                if not string.IsNullOrEmpty(clip) then
                    return clip
                end
            end
        end
        return CityCitizenDefine.AniClip.Building
    end
    if targetType == CityWorkTargetType.Resource then
        ---@type CityElementResource
        local c = self._citizen._data._mgr.city.elementManager:GetElementById(targetId)
        if c then
            local res = c.resourceConfigCell
            if res and not string.IsNullOrEmpty(res:CollectAction()) then
                return res:CollectAction()
            end
        end
        return CityCitizenDefine.AniClip.Logging
    end
    if targetType == CityWorkTargetType.Furniture then
        local cell = self._citizen._data._mgr.city.furnitureManager:GetFurnitureById(targetId)
        if cell then
            local c = ConfigRefer.CityFurnitureLevel:Find(cell:ConfigId())
            if c and not string.IsNullOrEmpty(c:Action()) then
                return c:Action()
            end
        end
    end
    return CityCitizenDefine.AniClip.Crafting
end

---@param workData CityCitizenWorkData
function CityCitizenStateSubInteractTarget:PlayInteractAniClip(workData)
    if workData and self._currentIndex then
        local targetId, targetType = workData:GetTarget()
        self._citizen:ChangeAnimatorState(self:GetInteractAniClip(targetId, targetType))
    else
        self._citizen:ChangeAnimatorState(self:GetInteractAniClip(self._targetInfo and self._targetInfo.id, self._targetInfo and self._targetInfo.type))
    end
end

---@param workData CityCitizenWorkData
function CityCitizenStateSubInteractTarget:PlayInteractSound(workData)
    local targetId
    local targetType
    if workData and self._currentIndex then
        targetId, targetType= workData:GetTarget()
    else
        targetId = self._targetInfo and self._targetInfo.id
        targetType = self._targetInfo and self._targetInfo.type
    end
    if not targetId or not targetType or targetType ~= CityWorkTargetType.Resource then
        return
    end
    local eleConfig = ConfigRefer.CityElementData:Find(targetId)
    if not eleConfig then
        return
    end
    local resConfig = ConfigRefer.CityElementResource:Find(eleConfig:ElementId())
    if not resConfig then
        return
    end
    local itemGroupCfg = ConfigRefer.ItemGroup:Find(resConfig:Reward())
    if not itemGroupCfg then
        return
    end
    local InventoryModule = ModuleRefer.InventoryModule
    for i = 1, itemGroupCfg:ItemGroupInfoListLength() do
        local item = itemGroupCfg:ItemGroupInfoList(i)
        local itemId = item:Items()
        local resType = InventoryModule:GetResTypeByItemId(itemId)
        if resType then
            if resType == 1 then
                self._soundHandle = self._citizen:PlaySound(AudioConsts.sfx_ui_logging)
                return
            elseif resType ==2 then
                self._soundHandle = self._citizen:PlaySound(AudioConsts.sfx_ui_quarrying)
                return
            end
        end
    end
end

function CityCitizenStateSubInteractTarget:StopInteractSound()
    if not self._soundHandle then
        return
    end
    g_Game.SoundManager:Stop(self._soundHandle)
    self._soundHandle = nil
end

function CityCitizenStateSubInteractTarget:CheckAndFixPos()
    if not self._targetInfo then
        return
    end
    local pos = self._citizen:ReadMoveAgentPos()
    if not pos then
        return
    end
    local targetPos,_,_ = CityCitizenStateHelper.GetWorkTargetPosByTargetInfo(self._targetInfo, self._citizen._data)
    if not targetPos then
        return
    end
    if (targetPos - pos).sqrMagnitude > self._posRange then
        self._citizen:StopMove(targetPos)
    end
end

return CityCitizenStateSubInteractTarget

