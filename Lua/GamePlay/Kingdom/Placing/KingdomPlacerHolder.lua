
---@class KingdomPlacerHolder
---@field new fun(handle:CS.DragonReborn.AssetTool.PooledGameObjectHandle):KingdomPlacerHolder
local KingdomPlacerHolder = class('KingdomPlacerHolder')

---@param handle CS.DragonReborn.AssetTool.PooledGameObjectHandle
function KingdomPlacerHolder:ctor(handle)
    ---@private
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self.placerHandle = handle
    ---@private
    ---@type KingdomPlacer
    self.placer = nil

    ---@type KingdomPlacerBehavior[]
    self.pendingBehaviors = nil
    ---@type KingdomPlacerContext
    self.pendingContext = nil
    self.pendingBehaviorParameter = nil

    ---@type fun():boolean
    self.pendingValidator = nil
    ---@type {x:number,y:number}
    self.pendingCoord = nil

    self.logicShow = false
    self.placerReadyAction = nil
end

function KingdomPlacerHolder:SetHandle(handle)
    if self.placerHandle and self.placerHandle ~= handle then
        self.placerHandle:Delete()
    end
    self.placerHandle = handle
end

---@param behaviors KingdomPlacerBehavior[]
---@param context KingdomPlacerContext
function KingdomPlacerHolder:Initialize(behaviors, context)
    if self.placer then
        self.placer:Initialize(behaviors, context)
    else
        self.pendingBehaviors = behaviors
        self.pendingContext = context
    end 
end

---@param behaviorParameter table
function KingdomPlacerHolder:SetParameter(behaviorParameter)
    if self.placer then
        self.placer:SetParameter(behaviorParameter)
    else
        self.pendingBehaviorParameter = behaviorParameter
        if self.pendingContext then
            self.pendingContext:SetParameter(behaviorParameter)
        end
    end 
end

---@param go CS.UnityEngine.GameObject
---@param userData any
---@param handle CS.DragonReborn.AssetTool.PooledGameObjectHandle
function KingdomPlacerHolder:OnAssetLoaded(go, userData, handle)
    --测试一个离谱的异步耗时
    -- require("TimerUtility").DelayExecute(function() 
    --     self:DoOnAssetLoaded(go, userData, handle)
    -- end, 5)
    self:DoOnAssetLoaded(go, userData, handle)
end

---@param go CS.UnityEngine.GameObject
---@param userData any
---@param handle CS.DragonReborn.AssetTool.PooledGameObjectHandle
function KingdomPlacerHolder:DoOnAssetLoaded(go, userData, handle)
    if handle ~= self.placerHandle then return end
    local behavior = go:GetLuaBehaviour("KingdomPlacer")
    if not behavior then return end
    ---@type KingdomPlacer
    self.placer = behavior.Instance
    if self.pendingBehaviors then
        self.placer:Initialize(self.pendingBehaviors, self.pendingContext)
        self.pendingBehaviors = nil
        self.pendingContext = nil
    end
    if self.pendingBehaviorParameter then
        self.placer:SetParameter(self.pendingBehaviorParameter)
        self.pendingBehaviorParameter = nil
    end
    if self.pendingValidator then
        self.placer:SetValidator(self.pendingValidator)
        self.pendingValidator = nil
    end
    if self.pendingCoord then
        self.placer:UpdatePosition(self.pendingCoord.x, self.pendingCoord.y)
        self.pendingCoord = nil
    end
    if self.logicShow then
        self.placer:Show()
    end
    local action = self.placerReadyAction
    self.placerReadyAction = nil
    if action then action() end
end

---@return KingdomPlacerContext
function KingdomPlacerHolder:GetContext()
    if self.placer then
        return self.placer.context
    else
        return self.pendingContext
    end
end

function KingdomPlacerHolder:IsDragTarget()
    if not self.placer then
        return false
    end
    return self.placer.dragTarget
end

function KingdomPlacerHolder:IsAllTileValid()
    if not self.placer then
        return false
    end
    return self.placer.allTileValid
end

function KingdomPlacerHolder:Place()
    if self.placer then
        self.placer:Place()
    end
end

function KingdomPlacerHolder:Show()
    if self.logicShow then return end
    self.logicShow = true
    if self.placer then
        self.placer:Show()
    end
end

function KingdomPlacerHolder:Hide()
    if not self.logicShow then return end
    self.logicShow = false
    if self.placer then
        self.placer:Hide()
    end
end

---@param gesture CS.DragonReborn.DragGesture
---@return boolean
function KingdomPlacerHolder:OnDragStart(gesture)
    if self.placer then
        return self.placer:OnDragStart(gesture)
    end
    return false
end

---@param gesture CS.DragonReborn.DragGesture
function KingdomPlacerHolder:OnDragUpdate(gesture)
    if self.placer then
        return self.placer:OnDragUpdate(gesture)
    end
    return false
end

---@param gesture CS.DragonReborn.DragGesture
function KingdomPlacerHolder:OnDragEnd(gesture)
    if self.placer then
        return self.placer:OnDragEnd(gesture)
    end
    return false
end

function KingdomPlacerHolder:Dispose()
    if self.logicShow then
        self:Hide()
    end
    if self.placer then
        self.placer:Dispose()
    end
    self.placer = nil
    if self.placerHandle then
        self.placerHandle:Delete()
    end
    self.placerHandle = nil
end

---@param validator fun():boolean
function KingdomPlacerHolder:SetValidator(validator)
    if self.placer then
        self.placer:SetValidator(validator)
    else
        self.pendingValidator = validator
    end
end

function KingdomPlacerHolder:UpdatePosition(x, y)
    if self.placer then
        self.placer:UpdatePosition(x, y)
    else
        self.pendingCoord = {x = x, y = y}
    end
end

function KingdomPlacerHolder:OnPlaceReady(readyActionOnce)
    if self.placer then
        if readyActionOnce then readyActionOnce() end
    else
        self.placerReadyAction = readyActionOnce
    end
end

return KingdomPlacerHolder