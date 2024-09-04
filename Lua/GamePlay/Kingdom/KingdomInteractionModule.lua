local Delegate = require("Delegate")
local KingdomConstant = require('KingdomConstant')
local BaseModule = require('BaseModule')
local KingdomMapUtils = require('KingdomMapUtils')
local CameraConst = require('CameraConst')
local CameraUtils = require('CameraUtils')
local EventConst= require('EventConst')
local Utils = require('Utils')
local Layers = require("Layers")
local LayerMask = require("LayerMask")

local Vector3 = CS.UnityEngine.Vector3

---@alias OperationDelegate fun(trans:CS.UnityEngine.Transform[], position:CS.UnityEngine.Vector3):boolean
---@alias OperationWithScreenPosDelegate fun(trans:CS.UnityEngine.Transform[], position:CS.UnityEngine.Vector3,  screenPos:CS.UnityEngine.Vector3):boolean
---@alias OperationDelegateArray {d:OperationDelegate,p:number}[]
---@alias OperationWithScreenPosDelegateArray {d:OperationWithScreenPosDelegate,p:number}[]

---@class KingdomInteractionModule
---@field enabled boolean
local KingdomInteractionModule = class("KingdomInteractionModule", BaseModule)

local Config = {
    DragMoveCamera = {
        --屏幕边框进区域
        MinX = 0.026,
        MaxX = 0.974,
        MinY = 0.1,
        MaxY = 0.9,
        --根据高度计算当前摄像机移动速度
        MaxSpeed = 1000,
        MinSpeed = 500,
    },
}

function KingdomInteractionModule:ctor()
    self.gestureHandle = CS.LuaGestureListener(self)
    self.enabled = true
    self.worldScale = 1
    self:ResetState()
    self:ResetListeners()
end

function KingdomInteractionModule:ResetState()
    -- self._longTapPreparing = false
    -- self._longTapStart = false
    -- self._longTapTimer = 0
    self._longPressing = false
    self._dragHasStart = false
    self._dragCamTimer = 0

    self._fingerDownTrans = nil
    self._fingerDownTime = nil
    self._fingerDownPos = nil
    self._processTouch = false
end

function KingdomInteractionModule:ResetListeners()
    ---@type OperationDelegateArray
    self.onPressDown = {}
    ---@type OperationDelegateArray
    self.onRelease = {}
    ---@type OperationDelegateArray
    self.onClick = {}
    ---@type OperationDelegateArray
    self.onLongTapStart = {}
    ---@type OperationDelegateArray
    self.onLongTapEnd = {}
    ---@type OperationWithScreenPosDelegateArray
    self.onDragStart = {}
    ---@type OperationWithScreenPosDelegateArray
    self.onDragStop = {}
    ---@type OperationWithScreenPosDelegateArray
    self.onDragUpdate = {}
    ---@type fun()[]
    self.onDragCancel = {}
end

function KingdomInteractionModule:OnRegister()
end

function KingdomInteractionModule:OnRemove()
end

function KingdomInteractionModule:Setup()
    self.basicCamera = KingdomMapUtils.GetBasicCamera()
    g_Game.GestureManager:AddListener(self.gestureHandle)
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function KingdomInteractionModule:ShutDown()
    self.enabled = true
    g_Game.GestureManager:RemoveListener(self.gestureHandle);
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    self:ResetState()
    self:ResetListeners()
end

function KingdomInteractionModule:SetScale(scale)
    self.worldScale = scale
end

function KingdomInteractionModule:Tick(delta)
    if self._dragHasStart and self._dragUpdateScreenPos then
        --check and move camera
        if self.basicCamera:IsOnScreenBoard(self._dragUpdateScreenPos,Config.DragMoveCamera) then
            local offset = self.basicCamera:GetScrollingOffset(self._dragUpdateScreenPos)
            self._dragCamTimer = self._dragCamTimer + delta
            local moveSpeed = math.lerp(
                    Config.DragMoveCamera.MinSpeed,
                    Config.DragMoveCamera.MaxSpeed,
                    math.clamp01( self._dragCamTimer)
            )
            self.basicCamera:MoveCameraOffset(offset * moveSpeed * self.worldScale * delta)
            self:DoOnDragUpdate(self._dragUpdateScreenPos)
        else
            self._dragCamTimer = 0
        end
    end

     if self._longTapPreparing then
         self._longTapTimer = self._longTapTimer + delta
         if not self._longTapStart and self._longTapTimer > KingdomConstant.LongTapDelay then
             self:InvokeAction(self.onLongTapStart, self._fingerDownTrans, self._fingerDownPos)
             self._longTapStart = true
             self._longTapPreparing = false
         end
     end

     --if self._longTapStart then
     --    self._longTapTimer = self._longTapTimer + delta
     --    if self._longTapTimer > KingdomConstant.LongTapDuration then
     --        self:InvokeAction(self.onLongTapEnd, self._fingerDownTrans, self._fingerDownPos)
     --        self._longTapStart = false
     --    end
     --end
end

function KingdomInteractionModule:SetEnabled(state)
    self.enabled = state
    if not state then
        self:ResetState()
    end
end

--region Registor Input Delegate

---@param array table
---@param value any
---@param priority number
local function InsertTo(array, value, priority)
    if not value then
        return
    end
    priority = priority or 0
    local count = #array
    local addPair = {d=value, p=priority}
    if count <= 0 then
        table.insert(array, addPair)
    else
        for i = count, 1, -1 do
            if priority >= array[i].p then
                table.insert(array, i + 1, addPair)
                return
            end
        end
        table.insert(array, 1, addPair)
    end
end

---@param array table
---@param value any
---@param removeAll boolean
local function RemoveByValue(array, value, removeAll)
    if not value then
        return
    end
    local c, i, max = 0, 1, #array
    while i <= max do
        if array[i].d == value then
            table.remove(array, i)
            c = c + 1
            i = i - 1
            max = max - 1
            if not removeAll then break end
        end
        i = i + 1
    end
    return c
end

---@param callback OperationDelegate
---@param priority KingdomInteractionDefine.InteractionPriority
function KingdomInteractionModule:AddOnPressDown(callback, priority)
    InsertTo(self.onPressDown, callback, priority)
end
---@param callback OperationDelegate
function KingdomInteractionModule:RemoveOnPressDown(callback)
    RemoveByValue(self.onPressDown,callback,true)
end

---@param callback OperationDelegate
---@param priority KingdomInteractionDefine.InteractionPriority
function KingdomInteractionModule:AddOnRelease(callback, priority)
    InsertTo(self.onRelease, callback, priority)
end
---@param callback OperationDelegate
function KingdomInteractionModule:RemoveOnRelease(callback)
    RemoveByValue(self.onRelease,callback,true)
end

---@param callback OperationDelegate
---@param priority KingdomInteractionDefine.InteractionPriority
function KingdomInteractionModule:AddOnClick(callback, priority)
    InsertTo(self.onClick, callback, priority)
end
---@param callback OperationDelegate
function KingdomInteractionModule:RemoveOnClick(callback)
    RemoveByValue(self.onClick,callback,true)
end

---@param callback OperationDelegate
---@param priority KingdomInteractionDefine.InteractionPriority
function KingdomInteractionModule:AddOnLongTapStart(callback, priority)
    InsertTo(self.onLongTapStart, callback, priority)
end
---@param callback OperationDelegate
function KingdomInteractionModule:RemoveOnLongTapStart(callback)
    RemoveByValue(self.onLongTapStart, callback,true)
end

---@param callback OperationDelegate
---@param priority KingdomInteractionDefine.InteractionPriority
function KingdomInteractionModule:AddOnLongTapEnd(callback, priority)
    InsertTo(self.onLongTapEnd, callback, priority)
end
---@param callback OperationDelegate
function KingdomInteractionModule:RemoveOnLongTapEnd(callback)
    RemoveByValue(self.onLongTapEnd, callback,true)
end

---@param callback OperationWithScreenPosDelegate
---@param priority KingdomInteractionDefine.InteractionPriority
function KingdomInteractionModule:AddOnDragStart(callback, priority)
    InsertTo(self.onDragStart, callback, priority)
end
---@param callback OperationWithScreenPosDelegate
function KingdomInteractionModule:RemoveOnDragStart(callback)
    RemoveByValue(self.onDragStart, callback,true)
end

---@param callback OperationWithScreenPosDelegate
---@param priority KingdomInteractionDefine.InteractionPriority
function KingdomInteractionModule:AddOnDragEnd(callback, priority)
    InsertTo(self.onDragStop, callback, priority)
end
---@param callback OperationWithScreenPosDelegate
function KingdomInteractionModule:RemoveOnDragEnd(callback)
    RemoveByValue(self.onDragStop, callback,true)
end

---@param callback OperationWithScreenPosDelegate
---@param priority KingdomInteractionDefine.InteractionPriority
function KingdomInteractionModule:AddOnDragUpdate(callback, priority)
    InsertTo(self.onDragUpdate, callback, priority)
end
---@param callback OperationWithScreenPosDelegate
function KingdomInteractionModule:RemoveOnDragUpdate(callback)
    RemoveByValue(self.onDragUpdate, callback,true)
end

---@param callback fun()
function KingdomInteractionModule:AddDragCancel(callback)
    table.insert(self.onDragCancel, callback)
end
---@param callback fun()
function KingdomInteractionModule:RemoveDragCancel(callback)
    table.removebyvalue(self.onDragCancel,callback,true)
end

--endregion

--region Interaction Base Logic

---@param gesture CS.DragonReborn.TapGesture
function KingdomInteractionModule:OnPressDown(gesture)
    if not self.enabled then
        return
    end

    self._processTouch = true
    local trans, pos = self:RaycastTransAndPos(gesture.position)

    self._fingerDownTrans = trans
    self._fingerDownTime = g_Game.Time.realtimeSinceStartup
    self._fingerDownPos = pos

    self:InvokeAction(self.onPressDown, trans, pos,true)

     if not trans then
         self._longTapPreparing = true
         self._longTapStart = false
         self._longTapTimer = 0
     end
end

---@param gesture CS.DragonReborn.TapGesture
function KingdomInteractionModule:OnRelease(gesture)
    if not self.enabled then
        return
    end
    
    if not self._processTouch then
        return
    end

    if not self._dragHasStart then
        self:InvokeAction(self.onRelease, self._fingerDownTrans, self._fingerDownPos)
    end

    if self._longTapStart then
        self:InvokeAction(self.onLongTapEnd, self._fingerDownTrans, self._fingerDownPos)
    end

    self._longTapPreparing = false
    self._longTapStart = false
    self._longTapTimer = 0
    self._fingerDownTrans = nil
    self._fingerDownTime = nil
    self._fingerDownPos = nil
    self._processTouch = false
end

---@param gesture CS.DragonReborn.TapGesture
function KingdomInteractionModule:OnClick(gesture)
    if not self.enabled then
        return
    end
    
    local touchCount = CS.UnityEngine.Input.touchCount
    if touchCount > 1 then
        -- 防止同时点击野怪和界面按钮，同时弹出两个界面
        return
    end

    --输出地面坐标用于测试
    local trans,pos = self:RaycastTransAndPos(gesture.position)
    if pos then
        self:InvokeAction(self.onClick, trans, pos, true)
    end
end

---@param gesture CS.DragonReborn.DragGesture
function KingdomInteractionModule:OnDrag(gesture)
    if not self.enabled then
        return
    end

     self._longTapPreparing = false
     self._longTapStart = false
     self._longTapTimer = 0

    if gesture.phase == CS.DragonReborn.GesturePhase.Started then
        self:DoOnDragStart(gesture.position)
    elseif gesture.phase == CS.DragonReborn.GesturePhase.Updated then
        self:DoOnDragUpdate(gesture.position)
    elseif gesture.phase == CS.DragonReborn.GesturePhase.Ended then
        self:DoOnDragStop(gesture.position)
    end
end

function KingdomInteractionModule:OnPinch(gesture)
    if not self.enabled then
        return
    end
    
     self._longTapPreparing = false
     if self._longTapStart then
         self._longTapStart = false
         self:InvokeAction(self.onLongTapEnd, self._fingerDownTrans, self._fingerDownPos)
     end
end

function KingdomInteractionModule:SetupDragTrans(trans)
    if self._dragHasStart or Utils.IsNull(trans) then
        return
    end    
    local transArray = {}
    transArray[1] = trans
    self._fingerDownTrans = transArray
    
    self._processTouch = true    

    self._fingerDownTrans = transArray
    self._fingerDownTime = g_Game.Time.realtimeSinceStartup
    self._fingerDownPos = trans.position

    self:InvokeAction(self.onPressDown, transArray, self._fingerDownPos,true)
end

function KingdomInteractionModule:DoOnDragStart(screenPos)
    if not self._fingerDownTrans then
        return
    end

    local dragStart = self:InvokeActionWithScreenPos(self.onDragStart, self._fingerDownTrans, self._fingerDownPos,nil, screenPos, true)
    if dragStart then
        self._dragHasStart = true
        self.basicCamera:StopTween()
        self.basicCamera.enableDragging = false
    end
end


function KingdomInteractionModule:DoOnDragUpdate(screenPos)
    if not self._dragHasStart or not self._fingerDownTrans then
        return
    end

    self._dragUpdateScreenPos = screenPos
    local trans,pos,ray = self:RaycastTransAndPos(screenPos)    
    self:InvokeActionWithScreenPos(self.onDragUpdate, trans, pos,ray, screenPos,true)
end

function KingdomInteractionModule:DoOnDragStop(screenPos)
    if not self._dragHasStart then return end
    self._dragHasStart = false
    local trans,pos,ray = self:RaycastTransAndPos(screenPos)
    self.basicCamera.enableDragging = true
    self.basicCamera.enablePinch = true
    self:InvokeActionWithScreenPos(self.onDragStop, trans, pos,ray, screenPos)
end

function KingdomInteractionModule:DoCancelDrag()
    self._dragHasStart = false
    self.basicCamera.enableDragging = true
    self:InvokeActionVoid(self.onDragCancel)
end

--endregion

---@param delegates fun()[]
function KingdomInteractionModule:InvokeActionVoid(delegates)
    for _, v in ipairs(delegates) do
        local state, result = pcall(v)
        if not state then
            g_Logger.Error(result)
        end
    end
end

---@param delegates OperationDelegateArray
---@param trans CS.UnityEngine.Transform[]
---@param pos CS.UnityEngine.Vector3
---@param canBreak boolean
function KingdomInteractionModule:InvokeAction(delegates, trans, pos, canBreak)
    pos = pos or CS.UnityEngine.Vector3.zero
    for _, v in ipairs(delegates) do
        local state, result = pcall(v.d, trans, pos)
        if not state then
            if result then
                g_Logger.ErrorChannel('KingdomInteractionModule',result)
            else
                g_Logger.ErrorChannel('KingdomInteractionModule','InvokeAction Error!' )
            end
        end
        if canBreak and result then
            break
        end
    end
end

---@param delegates OperationWithScreenPosDelegateArray
---@param trans CS.UnityEngine.Transform[]
---@param pos CS.UnityEngine.Vector3
---@param ray CS.UnityEngine.Ray
---@param screenPos CS.UnityEngine.Vector3
---@param canBreak boolean
function KingdomInteractionModule:InvokeActionWithScreenPos(delegates, trans, pos, ray, screenPos, canBreak)
    local invokeResult = nil
    for _, v in ipairs(delegates) do
        local state, result = pcall(v.d, trans, pos, screenPos,ray)
        if not state then
            g_Logger.Error(result)
        end
        if canBreak and result then
            invokeResult = result
            break
        end
    end
    return invokeResult
end

---@return CS.UnityEngine.Transform[],CS.UnityEngine.Vector3,CS.UnityEngine.Ray
function KingdomInteractionModule:RaycastTransAndPos(screenPos)
    local ray = self.basicCamera:GetRayFromScreenPosition(screenPos)
    local startPos = ray.origin
    --local trans = CameraUtils.Raycast(ray, 10000, KingdomConstant.KingdomLayer)
    local number,result = CameraUtils.RaycastAll(ray,100000, LayerMask.Kingdom | LayerMask.Scene3DUI | LayerMask.MapAboveFog)
    local pos = CameraUtils.GetHitPointOnMeshCollider(ray, LayerMask.MapTerrain | LayerMask.CityStatic | LayerMask.MapAboveFog)
    if not pos then
        pos = CameraUtils.GetHitPointLinePlane(ray,CameraConst.PLANE)
    end
    if number < 1 then
        return nil,pos,ray
    else
        local trans = {}
        ---@type {distance:number, tran:CS.UnityEngine.Transform}[]
        local tmpArray = {}
        for i = 1, number do
            local distance = (result[i].transform.position - startPos).sqrMagnitude
            tmpArray[i] = {distance=distance, tran = result[i].transform}
        end
        table.sort(tmpArray, function(a, b) 
            return a.distance < b.distance
        end)
        for i = 1, #tmpArray do
            trans[i] = tmpArray[i].tran
        end
        return trans, pos,ray
    end
end

function KingdomInteractionModule:IsDraging()
    return self._dragHasStart
end

return KingdomInteractionModule