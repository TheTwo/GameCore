---scene: scene_guide_finger
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local GuideType = require('GuideType')
local GuideFingerType = require('GuideFingerType')
local TimerUtility = require('TimerUtility')
local GuideMaskType = require('GuideMaskType')
local Vector2 = CS.UnityEngine.Vector2
local Vector3 = CS.UnityEngine.Vector3
local UIHelper = require('UIHelper')
local Utils = require('Utils')
local GuideFingerUtil = require('GuideFingerUtil')
local GuideConst = require('GuideConst')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local EventConst = require('EventConst')
local GuideUtils = require('GuideUtils')
---@class UIGuideFingerMediator : BaseUIMediator
local UIGuideFingerMediator = class('UIGuideFingerMediator', BaseUIMediator)

---@class GuideFingerData
---@field useWorldPos boolean
---@field worldPos CS.UnityEngine.Vector3 | fun():CS.UnityEngine.Vector3
---@field fingerPosOffset CS.UnityEngine.Vector3
---@field fingerType number
---@field config GuideConfigCell
---@field targetData StepTargetData
---@field dstTargetData StepTargetData
---@field onClick fun(forceStop:boolean)

---@class GuideFingerUIData
---@field guideId number
---@field guideType number
---@field maskType number
---@field maskSize CS.UnityEngine.Vector2
---@field maskOffset CS.UnityEngine.Vector2
---@field hotZone CS.UnityEngine.Vector2
---@field fingerType number
---@field infoContain string
---@field infoImage number
---@field infoAnchorMin CS.UnityEngine.Vector2
---@field infoAnchorMax CS.UnityEngine.Vector2
---@field infoOffset CS.UnityEngine.Vector2
---@field targetData StepTargetData
---@field dstTargetData StepTargetData

UIGuideFingerMediator.InfoMinShowTime = 1

function UIGuideFingerMediator:ctor()
    self.module = ModuleRefer.GuideModule
    self.dragTime = 0
    self.isDraging = false
    self.listening = false

    self.gestureHandle = CS.LuaGestureListener(self)
end

function UIGuideFingerMediator:OnCreate()
    self.maskWithDebugMaskRoot = self:RectTransform('p_back_mask') --整体的遮罩和框体的root结点
    self:PointerClick('p_back_mask',Delegate.GetOrCreate(self,self.OnClickBack))
    self:PointerDown('p_back_mask',Delegate.GetOrCreate(self,self.OnPointerDown))
    self:PointerUp('p_back_mask',Delegate.GetOrCreate(self,self.OnPointerUp))
    self.debugMask = self:GameObject('p_debugMask')  --调试用的粉红色遮罩
    self.normalMaskAndOpenRoot = self:RectTransform('p_center') --普通的遮罩和框体的节点 控制框体的大小和位置
    self.imgCenter = self:Image('p_center',Delegate.GetOrCreate(self,self.OnClickCenter))
    self:DragEvent('p_center',
        Delegate.GetOrCreate(self,self.OnBeginDrag),
        Delegate.GetOrCreate(self,self.OnDrag) ,
        Delegate.GetOrCreate(self,self.OnEndDrag),
        false
    )
    self.normalMask = self:GameObject('p_other_masks')  --普通黑色遮罩
    self.imgRoundOpenWithMask = self:Image('round_mask')
    self.imgRectOpenWithMask = self:Image('rectangle_mask')
    self.roundOpenWithMask = self:GameObject('round_mask')      --带遮罩的圆形框体
    self.rectOpenWithMask = self:GameObject('rectangle_mask')   --带遮罩的方形框体

    self.fingerAndNoMaskRoot = self:RectTransform('p_finger_anim')  --手指和没有遮罩的框体的root结点 控制手指的位置和框体位置
    self.noMaskOpenRootRect = self:RectTransform('p_center_nomask')  --没有遮罩的框体的节点 控制框体的大小
    self.imgCenterNoMask = self:Image('p_center_nomask',Delegate.GetOrCreate(self,self.OnClickCenter))
    self.noMaskOpenRoot = self:GameObject('p_center_nomask')
    self.roundOpenWithoutMask = self:GameObject('round')               --没有遮罩的圆形框体
    self.rectOpenWithoutMask = self:GameObject('rectangle')           --没有遮罩的方形框体
    self.animationFingerAnim = self:AnimTrigger('vx_trigger')
    self.transFinger = self:Transform('p_finger')                      --点击的手指

    self.popupChatRoot = self:RectTransform('p_popup_chat')
    self.chatComp = self:LuaObject('child_chat_popup')

    self.transDragRoot = self:RectTransform('group_move')
    self.rectTransArrow = self:RectTransform('p_arrow')
    self.rectTransArrowOffset = self:RectTransform('p_arrow_offset')
    self.transFingerStart = self:Transform("p_finger_start")
    self.transFingerEnd = self:Transform('p_finger_end')
    self.transFinger.localPosition = Vector3.zero
end

---@param param GuideFingerData
function UIGuideFingerMediator:OnShow(param)
    g_Game.EventManager:TriggerEvent(EventConst.STOP_TASK_AUTO_FINGER, true)
    g_Logger.LogChannel('GuideModule', "UIGuideFingerMediator OnShow")
    self:Clear()
    if param.useWorldPos then   --用于直接使用世界坐标的手指显示
        self:UseFingerWorldPos(param)
    else
        self:FeedData(param)
    end
    self.debugMask:SetVisible(self.module.debugMode)
    g_Game.GestureManager:AddListener(self.gestureHandle)
    g_Game.EventManager:AddListener(EventConst.UI_BUTTON_CLICK_PRE, Delegate.GetOrCreate(self, self.OnBtnClick))
end

function UIGuideFingerMediator:OnHide(param)
    g_Game.EventManager:TriggerEvent(EventConst.STOP_TASK_AUTO_FINGER, false)
    self:Clear()
    self.worldPosGetter = nil
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.IgnoreInvervalTick))
    g_Logger.LogChannel('GuideModule', "UIGuideFingerMediator OnHide")
    g_Game.GestureManager:RemoveListener(self.gestureHandle)
    g_Game.EventManager:RemoveListener(EventConst.UI_BUTTON_CLICK_PRE, Delegate.GetOrCreate(self, self.OnBtnClick))
end

function UIGuideFingerMediator:OnOpened(param)
    g_Logger.LogChannel('GuideModule', "UIGuideFingerMediator OnOpened")
end

function UIGuideFingerMediator:OnClose(param)
    g_Logger.LogChannel('GuideModule', "UIGuideFingerMediator OnClose")
    self:Clear()
    if self.tickDelegate then
        g_Game:RemoveIgnoreInvervalTicker(self.tickDelegate)
        self.tickDelegate = nil
    end
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.IgnoreInvervalTick))
end

function UIGuideFingerMediator:OnPressDown()
    if not self.listening then
        return
    end
    self:CloseSelf()
    self:FinishGuide(true)
end

---@param _ BaseUIComponent
---@param go CS.UnityEngine.GameObject
function UIGuideFingerMediator:OnBtnClick(_, go)
    if self.uiData.targetData.target.transform ~= go.transform then
        self:CloseSelf()
        self:FinishGuide(true)
    end
end

function UIGuideFingerMediator:UseFingerWorldPos(param)
    local scene = g_Game.SceneManager.current
    self.worldPosGetter = nil
    local worldPos
    if type(param.worldPos) == "function" then
        self.worldPosGetter = param.worldPos
        worldPos = self.worldPosGetter()
    else
        worldPos = param.worldPos
    end

    if param.fingerPosOffset then
        self.transFinger.localPosition = self.transFinger.localPosition + param.fingerPosOffset
    end
    local pos = UIHelper.WorldPos2UIPos(scene.basicCamera.mainCamera, worldPos, self.fingerAndNoMaskRoot.transform)
    self.fingerAndNoMaskRoot.localPosition = pos
    self.fingerAndNoMaskRoot:SetVisible(true)
    self.transFinger:SetVisible(true)
    self.noMaskOpenRoot:SetVisible(false)
    self.maskWithDebugMaskRoot:SetVisible(false)
    self.popupChatRoot:SetVisible(false)
    self.transDragRoot:SetVisible(false)
    if self.tickDelegate then
        g_Game:AddIgnoreInvervalTicker(self.tickDelegate)
    end
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.IgnoreInvervalTick))
    if self.worldPosGetter then
        g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.IgnoreInvervalTick))
    end
    self:SetFingerAngleAdnScale(param.fingerType)
    self.animationFingerAnim:PlayAll(FpAnimTriggerEvent.Custom1)
end

function UIGuideFingerMediator:IgnoreInvervalTick()
    if not self.worldPosGetter then return end
    local worldPos = self.worldPosGetter()
    if not worldPos then
        self.worldPosGetter = nil
        return
    end
    local scene = g_Game.SceneManager.current
    local pos = UIHelper.WorldPos2UIPos(scene.basicCamera.mainCamera, worldPos, self.fingerAndNoMaskRoot.transform)
    self.fingerAndNoMaskRoot.localPosition = pos
end

---@param param GuideFingerData
function UIGuideFingerMediator:OnFeedData(param)
    self:ClearDelayTimer()
    if param and param.onClick then  --需要玩家点击才能进行下一步的操作
        g_Logger.LogChannel('GuideModule','OnFeedData onClick')
        if param.config then
            self.uiData = GuideFingerUtil.CreateUIDataFromConfig(param.config,param.targetData,param.dstTargetData)
            self.stepId = param.config:Id()
        end
        self.guideType = self.uiData.guideType
        self.onClickCallback = param.onClick
        self:ApplyUIData()
    else   --CamFocus或者Wait类型的时候需要打开引导的屏蔽点击遮罩
        self.uiData = nil
        self.guideType = GuideType.Wait
        local block = true
        if param and param.config then
            local strParamLength = param.config:StringParamsLength()
            if strParamLength > 1 then
                local strParam = param.config:StringParams(2)
                local intParam = tonumber(strParam)
                if intParam and intParam == 0 then
                    block = false
                end
            end
            self.stepId = param.config:Id()
            g_Logger.LogChannel('GuideModule','OnFeedData' .. self.stepId)
        end
        if block then
            self.forceHideTimer = TimerUtility.DelayExecute(function()
                self.maskWithDebugMaskRoot:SetVisible(false)
            end, 5)
        end
        self.maskWithDebugMaskRoot:SetVisible(block)
        self.normalMask:SetVisible(false)
        self.normalMaskAndOpenRoot:SetVisible(false)
        self.noMaskOpenRoot:SetVisible(false)
        self.transFinger:SetVisible(false)
        self.popupChatRoot:SetVisible(false)
        self.transDragRoot:SetVisible(false)
    end
end

function UIGuideFingerMediator:ApplyUIData()
    self:SetupMask(self.uiData)
    if self.guideType == GuideType.Drag then
        self.fingerAndNoMaskRoot:SetVisible(false)
        self.transDragRoot:SetVisible(true)
        self.transDragRoot.anchoredPosition = self.normalMaskAndOpenRoot.anchoredPosition
    else
        self.fingerAndNoMaskRoot:SetVisible(true)
        self.transDragRoot:SetVisible(false)
        self.fingerAndNoMaskRoot.anchoredPosition = self.normalMaskAndOpenRoot.anchoredPosition
        self:SetFingerAngleAdnScale(self.uiData.fingerType)
    end
    if self.uiData.maskType == GuideMaskType.Rect then
        self.animationFingerAnim:PlayAll(FpAnimTriggerEvent.Custom2)
    else
        self.animationFingerAnim:PlayAll(FpAnimTriggerEvent.Custom1)
    end
    if self.guideType == GuideType.Drag and self.uiData.dstTargetData then
        self:SetupDragTarget()
    end
    self.hasGuideInfo = not string.IsNullOrEmpty(self.uiData.infoContain)
    if self.hasGuideInfo then
        self.popupChatRoot:SetVisible(true)
        self.popupChatRoot.anchorMin = self.uiData.infoAnchorMin
        self.popupChatRoot.anchorMax = self.uiData.infoAnchorMax
        self.popupChatRoot.anchoredPosition = self.uiData.infoOffset
        self.chatComp:FeedData(self.uiData)
        self.guideInfoTime = g_Game.Time.realtimeSinceStartup
    else
        self.popupChatRoot:SetVisible(false)
    end
end

---@param param GuideFingerUIData
function UIGuideFingerMediator:SetupMask(param)
    local zonePos,zoneRect,zoneTrans = GuideFingerUtil.GetUIPosFromeUIData(param)
    self.srcAnchoredPos = nil
    self.srcRect = nil

    self.maskWithDebugMaskRoot:SetVisible(not param.hideMask)
    if zonePos == nil or zoneRect == nil then
        self.srcTrans = nil
        self.normalMask:SetVisible(false)
        self.normalMaskAndOpenRoot:SetVisible(false)
        self.transFinger:SetVisible(false)
        self.noMaskOpenRoot:SetVisible(false)
        return false
    end
    self.srcTrans = zoneTrans
    self.normalMaskAndOpenRoot:SetVisible(true)
    self.transFinger:SetVisible(true)
    local maskType = param.maskType
    if self.guideType == GuideType.Goto then
        self.maskWithDebugMaskRoot:SetVisible(false)
        self.noMaskOpenRoot:SetVisible(true)
        if param.targetData and param.targetData.type ~= GuideConst.TargetTypeEnum.UITrans then
            if not self.tickDelegate then
                self.tickDelegate = Delegate.GetOrCreate(self,self.Tick)
                g_Game:AddIgnoreInvervalTicker(self.tickDelegate)
            end
        elseif param.targetData.type == GuideConst.TargetTypeEnum.UITrans then
            self.listening = true
        end
        if maskType == GuideMaskType.Rect then
            g_Game.SoundManager:PlayAudio("sfx_se_world_guide")
            self.roundOpenWithoutMask:SetVisible(false)
            self.rectOpenWithoutMask:SetVisible(true)
            self.animationFingerAnim:PlayAll(FpAnimTriggerEvent.Custom6)
        elseif maskType == GuideMaskType.Circle then
            g_Game.SoundManager:PlayAudio("sfx_se_world_guide")
            self.roundOpenWithoutMask:SetVisible(true)
            self.rectOpenWithoutMask:SetVisible(false)
            self.animationFingerAnim:PlayAll(FpAnimTriggerEvent.Custom7)
            g_Logger.LogChannel('GuideModule',"UIGuideFingerMediator:SetupMask Circle guideID = "..param.guideId)
        else
            self.roundOpenWithoutMask:SetVisible(false)
            self.rectOpenWithoutMask:SetVisible(false)
        end
    else
        self.maskWithDebugMaskRoot:SetVisible(true)
        local showDarkMask = self.guideType == GuideType.UIClick or self.guideType == GuideType.GroundClick
        self.normalMask:SetVisible(showDarkMask)
        self.imgRectOpenWithMask.enabled = showDarkMask
        self.imgRoundOpenWithMask.enabled = showDarkMask
        self.noMaskOpenRoot:SetVisible(false)
        if maskType == GuideMaskType.Rect then
            g_Game.SoundManager:PlayAudio("sfx_se_world_guide")
            self.roundOpenWithMask:SetVisible( false )
            self.rectOpenWithMask:SetVisible( true )
            self.animationFingerAnim:PlayAll(FpAnimTriggerEvent.Custom8)
        else
            g_Game.SoundManager:PlayAudio("sfx_se_world_guide")
            self.roundOpenWithMask:SetVisible( true )
            self.rectOpenWithMask:SetVisible( false )
            self.animationFingerAnim:PlayAll(FpAnimTriggerEvent.Custom9)
        end
    end

    local posOffset = (param.targetData or {}).offset
    local sizeOffset = param.maskSize
    if posOffset then
        self.srcAnchoredPos = CS.UnityEngine.Vector2(zonePos.x + posOffset.x, zonePos.y + posOffset.y)
    else
        self.srcAnchoredPos = CS.UnityEngine.Vector2(zonePos.x , zonePos.y )
    end
    self.normalMaskAndOpenRoot.anchoredPosition = self.srcAnchoredPos
    if maskType == GuideMaskType.Rect then
        self.normalMaskAndOpenRoot.sizeDelta = CS.UnityEngine.Vector2(zoneRect.width + sizeOffset.x, zoneRect.height + sizeOffset.y)
    else
        local rectSize = math.min(zoneRect.width + sizeOffset.x, zoneRect.height + sizeOffset.y)
        self.normalMaskAndOpenRoot.sizeDelta = CS.UnityEngine.Vector2(rectSize,rectSize)
    end
    if self.guideType == GuideType.Goto then
        if maskType == GuideMaskType.Rect then
            self.noMaskOpenRootRect.sizeDelta = CS.UnityEngine.Vector2(zoneRect.width + sizeOffset.x, zoneRect.height + sizeOffset.y)
        elseif maskType == GuideMaskType.Circle then
            local rectSize = math.min(zoneRect.width + sizeOffset.x, zoneRect.height + sizeOffset.y)
            self.noMaskOpenRootRect.sizeDelta = CS.UnityEngine.Vector2(rectSize,rectSize)
        end
    end
    if param.hotZone then
        local centerRect = self.normalMaskAndOpenRoot.rect
        local minoffset = (param.hotZone - centerRect.size ) * 0.5
        self.srcRect = CS.UnityEngine.Rect(centerRect.min - minoffset,param.hotZone)
    end
    self:StartUpdateTargetPos()
    return true
end

function UIGuideFingerMediator:StartUpdateTargetPos()
    self.updatingTargetPos = true
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self,self.UpdateTargetPos))
    self:UpdateTargetPos()
end

function UIGuideFingerMediator:StopUpdateTargetPos()
    if not self.updatingTargetPos then
        return
    end
    self.updatingTargetPos = false
    if self.updateTimer then
        TimerUtility.StopAndRecycle(self.updateTimer)
        self.updateTimer = nil
    end
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self,self.UpdateTargetPos))
end

function UIGuideFingerMediator:UpdateTargetPos()

    local zonePos,zoneRect = GuideFingerUtil.GetUIPosFromeUIData(self.uiData)
    if zonePos == nil or zoneRect == nil then
        return
    end
    local posOffset = self.uiData.maskOffset
    local sizeOffset = self.uiData.maskSize

    if posOffset then
        self.srcAnchoredPos = CS.UnityEngine.Vector2(zonePos.x + posOffset.x, zonePos.y + posOffset.y)
    else
        self.srcAnchoredPos = CS.UnityEngine.Vector2(zonePos.x , zonePos.y )
    end

    self.normalMaskAndOpenRoot.anchoredPosition = self.srcAnchoredPos
    if self.uiData.maskType == GuideMaskType.Rect then
        self.normalMaskAndOpenRoot.sizeDelta = CS.UnityEngine.Vector2(zoneRect.width + sizeOffset.x, zoneRect.height + sizeOffset.y)
    else
        local rectSize = math.min(zoneRect.width + sizeOffset.x, zoneRect.height + sizeOffset.y)
        self.normalMaskAndOpenRoot.sizeDelta = CS.UnityEngine.Vector2(rectSize,rectSize)
    end
    if self.uiData.hotZone then
        local centerRect = self.normalMaskAndOpenRoot.rect
        local minoffset = (self.uiData.hotZone - centerRect.size ) * 0.5
        self.srcRect = CS.UnityEngine.Rect(centerRect.min - minoffset,self.uiData.hotZone)
    end
    self.fingerAndNoMaskRoot.anchoredPosition = self.normalMaskAndOpenRoot.anchoredPosition
end

function UIGuideFingerMediator:SetupDragTarget()
    --set drag target
    local tarZonePos,tarZoneRect, uiTrans= self.module:GetTargetUIPos(self.uiData.dstTargetData)
    if not tarZonePos then
        tarZonePos = CS.UnityEngine.Vector3(0,0,0)
    end
    if not tarZoneRect then
        tarZoneRect = CS.UnityEngine.Rect()
    end
    self.targetPos = tarZonePos
    self.targetRagne = tarZoneRect.width * tarZoneRect.width
    --setup drag anim end pos
    if self.uiData.dstTargetData.type == GuideConst.TargetTypeEnum.UITrans  then
        if uiTrans then
            self.transFingerEnd.position = uiTrans.position
        else
            return
        end
    else
        self.transFingerEnd.position = self.targetPos
    end
    --setup drag arrow
    if not self.uiData.hideDragArrow then
        self.rectTransArrow:SetVisible(true)
        local dir = self.transFingerEnd.localPosition - self.transFingerStart.localPosition
        local sizeDelta = self.rectTransArrow.sizeDelta
        sizeDelta.y = dir.magnitude
        self.rectTransArrow.sizeDelta = sizeDelta

        local dot = Vector3.Dot(dir.normalized,Vector3.up)
        local sign = Vector3.Cross(dir,Vector3.up).z < 0 and 1 or -1

        self.rectTransArrow.eulerAngles = Vector3.forward * math.radian2angle(math.acos(dot)) *  sign

        local offset = math.min(self.normalMaskAndOpenRoot.sizeDelta.x,self.normalMaskAndOpenRoot.sizeDelta.y) / 2.0
        self.rectTransArrowOffset.anchoredPosition = Vector2(0,offset)
        self.rectTransArrowOffset.sizeDelta = Vector2(self.rectTransArrowOffset.sizeDelta.x,-offset)
        self.animationFingerAnim:PlayAll(FpAnimTriggerEvent.Custom3)
    else
        self.rectTransArrow:SetVisible(false)
        self.animationFingerAnim:PlayAll(FpAnimTriggerEvent.Custom3)
    end
end

function UIGuideFingerMediator:ClearDelayTimer()
    if self.forceHideTimer then
        TimerUtility.StopAndRecycle(self.forceHideTimer)
        self.forceHideTimer = nil
    end
end

function UIGuideFingerMediator:FinishGuide(forceStop)
    g_Logger.LogChannel('GuideModule','UIGuideFingerMediator FinishGuide')
    self.waiting = true
    TimerUtility.DelayExecuteInFrame(function()
        self.waiting = false
        if self.onClickCallback then
            self.onClickCallback(forceStop)
        end
        self:CloseSelf()
    end
    , 1)
end

function UIGuideFingerMediator:OnClickCenter(param,pointerEventData)
    if self.stepId then
        g_Logger.LogChannel('GuideModule','UIGuideFingerMediator OnClickCenter' .. self.stepId)
    end
    if self.guideType == GuideType.Drag then
        g_Logger.LogChannel('GuideModule','DragTypeGuideForbidClick')
        return
    end
    if self.isDraging then
        return
    end
    if self.hasGuideInfo then
        --信息框最小显示时间
        if g_Game.Time.realtimeSinceStartup - self.guideInfoTime < UIGuideFingerMediator.InfoMinShowTime then
            return
        end
    end
    if self.guideType == GuideType.UIClick or self.guideType == GuideType.Goto or self.guideType == GuideType.GroundClick then
        if self.uiData.targetData then
            GuideUtils.AutoClickTarget(self.uiData.targetData)
        end
        self.normalMaskAndOpenRoot:SetVisible(false)
        self.transFinger:SetVisible(false)
        self:FinishGuide(false)
    end
end

function UIGuideFingerMediator:OnPointerDown(param,eventData)
    if self.stepId then
        g_Logger.LogChannel('GuideModule','UIGuideFingerMediator OnPointerDown' .. self.stepId)
    end
    if self.waiting or self.isDraging  then return end
    if Utils.IsNotNull(self.srcTrans) then
        local pointListeners = self.srcTrans.gameObject:GetComponentsInChildren(typeof(CS.UIPointerDownListener))
        if pointListeners and pointListeners.Length > 0 then
            if Utils.IsNotNull(pointListeners[0]) then
                pointListeners[0]:OnPointerDown(eventData)
            end
        end
    end
end

function UIGuideFingerMediator:OnPointerUp(param,eventData)
    if self.stepId then
        g_Logger.LogChannel('GuideModule','UIGuideFingerMediator OnPointerUp' .. self.stepId)
    end
    if self.waiting or self.isDraging then return end
    if Utils.IsNotNull(self.srcTrans) then
        local pointListeners = self.srcTrans.gameObject:GetComponentsInChildren(typeof(CS.UIPointerUpListener))
        if pointListeners and pointListeners.Length > 0 then
            if Utils.IsNotNull(pointListeners[0]) then
                pointListeners[0]:OnPointerUp(eventData)
            end
        end
    end
end

function UIGuideFingerMediator:OnClickBack(param,eventData)
    if self.stepId then
        g_Logger.LogChannel('GuideModule','UIGuideFingerMediator OnClickBack' .. self.stepId)
    end
    if self.guideType == GuideType.Drag then
        g_Logger.LogChannel('GuideModule','DragTypeGuideForbidClick')
        return
    end
    if self.waiting or self.isDraging  then return end
    --判定点击热区
    if self.srcRect and self.srcRect.width > 0 and self.srcRect.height > 0 then
        local inputPos = UIHelper.ScreenPos2UIPos(eventData.position)
        inputPos.x = inputPos.x - self.srcAnchoredPos.x
        inputPos.y = inputPos.y - self.srcAnchoredPos.y
        if self.srcRect:Contains(inputPos) then
            self:OnClickCenter(param,eventData)
            return
        end
    elseif self.hasGuideInfo and self.srcAnchoredPos == nil then
        --只有一个信息框
        if g_Game.Time.realtimeSinceStartup - self.guideInfoTime > UIGuideFingerMediator.InfoMinShowTime then
            self:OnClickCenter(param,eventData)
        end
    end
    if self.guideType == GuideType.Goto then
        self:FinishGuide(true)
    end
end

--------------------------------------------------Drag Start---------------------------------------------------------
function UIGuideFingerMediator:OnBeginDrag(go,event)
    if self.guideType ~= GuideType.Drag and self.guideType ~= GuideType.Goto then
        return
    end
    if self.stepId then
        g_Logger.LogChannel('GuideModule','UIGuideFingerMediator OnBeginDrag' .. self.stepId)
    end
    self.isDraging = true
    if Utils.IsNull(self.srcTrans) then
        g_Logger.ErrorChannel('GuideModule','GuideFinger.OnBeginDrag():Target Trans is Missing!')
        self:FinishGuide(true)
        self:CloseSelf()
        return
    end
    local dragListeners = self.srcTrans.gameObject:GetComponentsInChildren(typeof(CS.UIDragListener))
    if dragListeners and dragListeners.Length > 0 then
        self.dragListener = dragListeners[0]
    end
    if Utils.IsNotNull(self.dragListener) then
        self.dragTime = 0
        if g_Game.UIManager:GetGestureEnabled() and g_Game.UIManager:GetInputEnabled() then
            local curScene = g_Game.SceneManager.current
            local sceneCam = nil
            if curScene then
                sceneCam = curScene.basicCamera
            end
            if sceneCam  then
                self.beginDragCamPos = sceneCam:GetLookAtPosition()
            end
        else
            self.beginDragCamPos = nil
        end
        self.dragListener:OnBeginDrag(event)
    end
    self.roundOpenWithMask:SetVisible(false)
    self.rectOpenWithMask:SetVisible(false)
    self.rectTransArrow:SetVisible(false)
end

function UIGuideFingerMediator:OnDrag(go,event)
    if (self.guideType ~= GuideType.Drag and self.guideType ~= GuideType.Goto) or not self.isDraging then
        return
    end
    if Utils.IsNotNull(self.dragListener) then
        self.dragListener:OnDrag(event)
    end
    self.dragTime = self.dragTime + g_Game.RealTime.deltaTime
    if self.dragTime > 0.5 then
        self.animationFingerAnim:ResetAll(FpAnimTriggerEvent.Custom3)
        self.dragTime = 0
    end
end

function UIGuideFingerMediator:OnEndDrag(go,event)
    if self.stepId then
        g_Logger.LogChannel('GuideModule','UIGuideFingerMediator OnEndDrag' .. self.stepId)
    end
    if (self.guideType ~= GuideType.Drag and self.guideType ~= GuideType.Goto) or not self.isDraging then
        return
    end
    self.isDraging = false
    if Utils.IsNotNull(self.dragListener) then
        self.dragListener:OnEndDrag(event)
        self.dragListener = nil
    end
    self:FinishGuide(false)
end
--------------------------------------------------Drag End---------------------------------------------------------

function UIGuideFingerMediator:Clear()
    self.onClickCallback = nil
    self.waiting = false
    self.dragListener = nil
    self.guideType = nil
    self.worldPosGetter = nil
    self:ClearDelayTimer()
    self:StopUpdateTargetPos()
end

function UIGuideFingerMediator:SetFingerAngleAdnScale(fingerType)
    if fingerType == GuideFingerType.LeftBottom then
        self.transFinger.localEulerAngles = Vector3.zero
        self.transFinger.localScale = Vector3(-1,1,1)
    elseif fingerType == GuideFingerType.LeftTop then
        self.transFinger.localEulerAngles = Vector3(0,0,-60)
        self.transFinger.localScale = Vector3(-1,1,1)
    elseif fingerType == GuideFingerType.RightTop then
        self.transFinger.localEulerAngles = Vector3(0,0,60)
        self.transFinger.localScale = Vector3.one
    elseif fingerType == GuideFingerType.RightBottom then
        self.transFinger.localEulerAngles = Vector3.zero
        self.transFinger.localScale = Vector3.one
    else
        self.transFinger.localScale = Vector3.zero
    end
end

-------------------------------------------------------------------------------------------------------------------------------------
function UIGuideFingerMediator:DebugSkipGuideGroup()
    self:FinishGuide(true)
end

return UIGuideFingerMediator;
