-- scene:scene_common_popup_tip

local Delegate = require("Delegate")
local CommonTipPopupDefine = require("CommonTipPopupDefine")
local Utils = require("Utils")

local BaseUIMediator = require("BaseUIMediator")

---@class CommonTipPopupMediatorParameter
---@field text string
---@field targetViewportPos CS.UnityEngine.Vector3|nil
---@field targetTrans CS.UnityEngine.RectTransform|CS.UnityEngine.Transform
---@field arrowMode CommonTipPopupDefine.ArrowMode @default CommonTipPopupDefine.ArrowMode.Auto
---@field arrowHide boolean
---@field context any|nil
---@field onClickTip fun(context:any):boolean
---@field onClickBackground fun(context:any):boolean

---@class CommonTipPopupMediator:BaseUIMediator
---@field new fun():CommonTipPopupMediator
---@field super BaseUIMediator
local CommonTipPopupMediator = class('CommonTipPopupMediator', BaseUIMediator)

function CommonTipPopupMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type fun(context:any):boolean
    self._onClickTip = nil
    ---@type fun(context:any):boolean
    self._onClickBackground = nil
    self._context = nil
    self._fixPos = false
end

function CommonTipPopupMediator:OnCreate(param)
    self._selfRect = self:RectTransform("")
    self._p_click_background = self:Button("p_click_background", Delegate.GetOrCreate(self, self.OnClickBtnBackground))
    self._p_anchors_pos = self:RectTransform("p_anchors_pos")
    self._p_text_root = self:RectTransform("p_text_root")
    ---@type CS.UnityEngine.UI.VerticalLayoutGroup
    self._p_text_layoutGroup = self._p_text_root:GetComponent(typeof(CS.UnityEngine.UI.VerticalLayoutGroup))
    self:Button("p_text_root", Delegate.GetOrCreate(self, self.OnClickBtnTip))
    self._p_text = self:Text("p_text")
    self._p_arrow_down = self:GameObject("p_arrow_down")
    self._p_arrow_up = self:GameObject("p_arrow_up")
    self._p_arrow_left = self:GameObject("p_arrow_left")
    self._p_arrow_right = self:GameObject("p_arrow_right")
end

function CommonTipPopupMediator:OnShow(param)
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.TickFixInScreenPos))
end

function CommonTipPopupMediator:OnHide(param)
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.TickFixInScreenPos))
end

---@param param CommonTipPopupMediatorParameter
function CommonTipPopupMediator:OnOpened(param)
    self._p_text.text = param.text
    self._onClickTip = param.onClickTip
    self._onClickBackground = param.onClickBackground
    self._context = param.context

    self._p_text_layoutGroup:CalculateLayoutInputVertical()
    
    local arrowMode,pos = self:SuggestArrowMode(param)
    self:SetUpArrowAndTipPivot(arrowMode, not param.arrowHide)
    self._p_anchors_pos.anchoredPosition = pos
    self._fixPos = true
end

function CommonTipPopupMediator:OnClose(data)
    self._onClickTip = nil
    self._onClickBackground = nil
    self._context = nil
    BaseUIMediator.OnClose(self, data)
end

---@private
---@param param CommonTipPopupMediatorParameter
---@param arrowMode CommonTipPopupDefine.ArrowMode
---@param param CS.UnityEngine.Transform
---@param camera CS.UnityEngine.Camera
function CommonTipPopupMediator.CalculateTargetPos(param, arrowMode, parent, camera)
    if param.targetViewportPos then
        local p = camera:ViewportToWorldPoint(param.targetViewportPos)
        local localPos = parent:InverseTransformPoint(p)
        return CS.UnityEngine.Vector2(localPos.x, localPos.y)
    elseif Utils.IsNotNull(param.targetTrans) then
        if param.targetTrans:GetType() == typeof(CS.UnityEngine.RectTransform) then
            local rect = param.targetTrans.rect
            local position = CS.UnityEngine.Vector3(rect.position.x, rect.position.y, 0)
            local center= rect.center
            if arrowMode == CommonTipPopupDefine.ArrowMode.Up then
                position.x = center.x
                position.y = rect.yMin
            elseif arrowMode == CommonTipPopupDefine.ArrowMode.Down then
                position.x = center.x
                position.y = rect.yMax
            elseif arrowMode == CommonTipPopupDefine.ArrowMode.Left then
                position.x = rect.xMax
                position.y = center.y
            elseif arrowMode == CommonTipPopupDefine.ArrowMode.Right then
                position.x = rect.xMin
                position.y = center.y
            end
            local p = param.targetTrans:TransformPoint(position)
            local localPos = parent.parent:InverseTransformPoint(p)
            return CS.UnityEngine.Vector2(localPos.x, localPos.y)
        else
            local localPos = parent.parent:InverseTransformPoint(param.targetTrans.position)
            return CS.UnityEngine.Vector2(localPos.x, localPos.y)
        end
    else
        local p = camera:ViewportToWorldPoint(CS.UnityEngine.Vector3(0.5, 0.5, 0))
        local localPos = parent.parent:InverseTransformPoint(p)
        return CS.UnityEngine.Vector2(localPos.x, localPos.y)
    end
end

function CommonTipPopupMediator.CalculateEdgeFix(tipWidth, tipHeight,targetLocalPos, lbLocalPos, rtLocalPos)
    local xFix = 0
    local yFix = 0
    local arrowMode
    local lOffset = targetLocalPos.x - lbLocalPos.x
    local rOffset = rtLocalPos.x - targetLocalPos.x
    local dOffset = targetLocalPos.y - lbLocalPos.y
    local tOffset = rtLocalPos.y - targetLocalPos.y
    local tipHalfWidth = 0.5 * tipWidth
    local tipHalfHeight = 0.5 * tipHeight
    if lOffset < tipWidth then
        arrowMode = CommonTipPopupDefine.ArrowMode.Left
    elseif rOffset < tipWidth then
        arrowMode = CommonTipPopupDefine.ArrowMode.Right
    elseif dOffset < tipHeight then
        arrowMode = CommonTipPopupDefine.ArrowMode.Down
    else
        arrowMode = CommonTipPopupDefine.ArrowMode.Up
    end

    if dOffset < tipHalfHeight then
        yFix = tipHalfHeight - dOffset
    end
    if tOffset < tipHalfHeight then
        yFix = tOffset - tipHalfHeight
    end
    if lOffset < tipHalfWidth then
        xFix = tipHalfWidth - lOffset
    end
    if rOffset < tipHalfWidth then
        xFix = rOffset - tipHalfWidth
    end
    return arrowMode,xFix,yFix
end

---@private
---@param param CommonTipPopupMediatorParameter
---@return CommonTipPopupDefine.ArrowMode,CS.UnityEngine.Vector2
function CommonTipPopupMediator:SuggestArrowMode(param)
    ---@type CS.UnityEngine.Vector2
    local retPos
    ---@type CS.UnityEngine.Vector2
    local targetViewportPos
    local camera = g_Game.UIManager:GetUICamera()
    local arrowMode = param.arrowMode

    local parent = self._p_anchors_pos.parent

    if arrowMode and arrowMode ~= CommonTipPopupDefine.ArrowMode.Auto then
        retPos = CommonTipPopupMediator.CalculateTargetPos(param, arrowMode, parent, camera)
        return arrowMode,retPos
    end

    if param.targetViewportPos then
        targetViewportPos = param.targetViewportPos
    elseif Utils.IsNotNull(param.targetTrans) then
        targetViewportPos = camera:WorldToViewportPoint(param.targetTrans.position)
    else
        targetViewportPos = CS.UnityEngine.Vector3(0.5,0.5, 0)
    end
    local screenLBWorldPos = camera:ViewportToWorldPoint(CS.UnityEngine.Vector3(0,0,0))
    local screenRTWorldPos = camera:ViewportToWorldPoint(CS.UnityEngine.Vector3(1,1,0))
    local targetPos = camera:ViewportToWorldPoint(targetViewportPos)

    local lbLocalPos = parent:InverseTransformPoint(screenLBWorldPos)
    local rtLocalPos = parent:InverseTransformPoint(screenRTWorldPos)
    local targetLocalPos = parent:InverseTransformPoint(targetPos)

    local tipWidth = self._p_text_layoutGroup.preferredWidth
    local tipHeight = self._p_text_layoutGroup.preferredHeight
    
    local xFix,yFix
    arrowMode,xFix,yFix = self.CalculateEdgeFix(tipWidth,tipHeight,targetLocalPos,lbLocalPos,rtLocalPos)
    retPos = CommonTipPopupMediator.CalculateTargetPos(param, arrowMode, parent, camera)
    retPos.x = retPos.x + xFix
    retPos.y = retPos.y + yFix
    return arrowMode,retPos
end

---@private
---@param mode CommonTipPopupDefine.ArrowMode
---@param showArrow boolean
function CommonTipPopupMediator:SetUpArrowAndTipPivot(mode, showArrow)
    self._p_arrow_down:SetVisible(mode == CommonTipPopupDefine.ArrowMode.Down)
    self._p_arrow_up:SetVisible(mode == CommonTipPopupDefine.ArrowMode.Up)
    self._p_arrow_left:SetVisible(mode == CommonTipPopupDefine.ArrowMode.Left)
    self._p_arrow_right:SetVisible(mode == CommonTipPopupDefine.ArrowMode.Right)
    local p = self._p_text_root.localPosition
    if mode == CommonTipPopupDefine.ArrowMode.Down then
        self._p_text_root.pivot = CS.UnityEngine.Vector2(0.5, 0)
        p.x = 0
        p.y = showArrow and 20 or 0
    elseif mode == CommonTipPopupDefine.ArrowMode.Up then
        self._p_text_root.pivot = CS.UnityEngine.Vector2(0.5, 1)
        p.x = 0
        p.y = showArrow and -20 or 0
    elseif mode == CommonTipPopupDefine.ArrowMode.Left then
        self._p_text_root.pivot = CCS.UnityEngine.Vector2(0, 0.5)
        p.x = showArrow and 20 or 0
        p.y = 0
    elseif mode == CommonTipPopupDefine.ArrowMode.Right then
        self._p_text_root.pivot = CS.UnityEngine.Vector2(1, 0.5)
        p.x = showArrow and -20 or 0
        p.y = 0
    end
    self._p_text_root.localPosition = p
end

function CommonTipPopupMediator:OnClickBtnTip()
    if self._onClickTip then
        if self._onClickTip(self._context) then
            return
        end
        self:CloseSelf()
    end
end

function CommonTipPopupMediator:OnClickBtnBackground()
    if self._onClickBackground then
        if self._onClickBackground(self._context) then
            return  
        end
    end
    self:CloseSelf()
end

function CommonTipPopupMediator:TickFixInScreenPos()
    if not self._fixPos then
        return
    end
    local uiCamera = g_Game.UIManager:GetUICamera()
    local rect = self._p_text_root:GetScreenRect(uiCamera)
    local screenRect = self._selfRect:GetScreenRect(uiCamera)
    local xMove = 0
    if rect.xMax > screenRect.xMax then
        xMove = screenRect.xMax - rect.xMax
    elseif rect.xMin < screenRect.xMin then
        xMove = screenRect.min - rect.min
    end
    if xMove ~= 0 then
        self._fixPos = false
    else
        return
    end
    rect.x = rect.x + xMove
    local center = rect.center
    local worldPos = uiCamera:ScreenToWorldPoint(CS.UnityEngine.Vector3(center.x, center.y, 0))
    local localPos = self._p_text_root.transform.parent:InverseTransformPoint(worldPos)
    local originPos = self._p_text_root.transform.localPosition
    local p = self._p_anchors_pos.anchoredPosition
    p.x = p.x + localPos.x - originPos.x
    self._p_anchors_pos.anchoredPosition = p
end

return CommonTipPopupMediator