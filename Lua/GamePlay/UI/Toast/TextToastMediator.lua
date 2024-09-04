---scene:scene_toast_text

local BaseUIMediator = require ('BaseUIMediator')
local TimerUtility = require("TimerUtility")
local UIHelper = require('UIHelper')
local TimeFormatter = require('TimeFormatter')
local LayoutRebuilder = CS.UnityEngine.UI.LayoutRebuilder
local Vector3 = CS.UnityEngine.Vector3
local I18N = require('I18N')
local Utils = require("Utils")
local Delegate = require("Delegate")

---@class TextToastMediatorParameter
---@field clickTransform CS.UnityEngine.RectTransform
---@field title string
---@field content string


---@class TextToastMediator : BaseUIMediator
local TextToastMediator = class('TextToastMediator', BaseUIMediator)

function TextToastMediator:ctor()
    BaseUIMediator.ctor(self)
    self._inLateTickLimitInScreen = false
end

function TextToastMediator:OnCreate()
    self.goRoot = self:GameObject("")
    self.goToast = self:GameObject("p_toast_text")
    self.textSubtitle = self:Text('p_text_subtitle')
    self.textDetail = self:Text('p_text_detail')
    self.goArrow = self:GameObject('p_arrow')
    ---@type CS.FpAnimation.FpAnimationCommonTrigger
    self.trigger = self.goRoot.transform:Find("vx_trigger"):GetComponent(typeof(CS.FpAnimation.FpAnimationCommonTrigger))
end

---@param param TextToastMediatorParameter
function TextToastMediator:OnOpened(param)
    self._inLateTickLimitInScreen = false
    if not param then
        return
    end

    self.clickTransform = param.clickTransform
    if string.IsNullOrEmpty(param.title) then
        self.textSubtitle:SetVisible(false)
    else
        self.textSubtitle:SetVisible(true)
        self.textSubtitle.text = param.title
    end
    if param.tailContent then
        self.tailContent = param.tailContent
        self.textDetail.text = param.content .. "\n" .. self.tailContent
    else
        self.textDetail.text = param.content
    end
    if param.timeStamp then
        self:ClearTimer()
        self.content = param.content
        self.timeStamp = param.timeStamp
        self.timeText = param.timeText

        self:RefreshTimeText()
        self.timer = TimerUtility.IntervalRepeat(function() self:RefreshTimeText() end, 0.5, -1)
    end

    if self.clickTransform then
        self.trigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
        LayoutRebuilder.ForceRebuildLayoutImmediate(self.goToast.transform)
        self:LimitInScene()
        self._inLateTickLimitInScreen = true
    end
    self.trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

function TextToastMediator:OnShow()
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.LateTick))
end

function TextToastMediator:OnHide(param)
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateTick))
end

function TextToastMediator:ClearTimer()
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

function TextToastMediator:RefreshTimeText()
    local remainTime = self.timeStamp - g_Game.ServerTime:GetServerTimestampInSeconds()
    if remainTime > 0 then
        self.textDetail.text = self.content .. "\n" .. I18N.GetWithParams(self.timeText, TimeFormatter.SimpleFormatTime(remainTime)) .. "\n" .. self.tailContent
    else
        self:ClearTimer()
    end
end

function TextToastMediator:LimitInScene()
    if Utils.IsNull(self.clickTransform) then
        self._inLateTickLimitInScreen = false
        return
    end
    local anchorPos = self.clickTransform.position
    local csType = self.clickTransform:GetType()
    if csType == typeof(CS.UnityEngine.RectTransform) then
        ---@type CS.UnityEngine.RectTransform
        local rectTrans = self.clickTransform
        local center = rectTrans.rect.center
        anchorPos = rectTrans:TransformPoint(center.x, center.y, 0)
    end
    anchorPos = Vector3(anchorPos.x, anchorPos.y, 0)
    local halfHeight = self.clickTransform.rect.height / 2
    self.goArrow.transform.position = anchorPos

    local uiCamera = g_Game.UIManager:GetUICamera()
    local lb = uiCamera:ViewportToWorldPoint(CS.UnityEngine.Vector3(0,0,0))
    local rt = uiCamera:ViewportToWorldPoint(CS.UnityEngine.Vector3(1,1,0))
    local localLb = self.goRoot.transform:InverseTransformPoint(lb)
    local localRt = self.goRoot.transform:InverseTransformPoint(rt)
    local arrowPos = UIHelper.WorldPos2UIPos(uiCamera, anchorPos, self.goRoot.transform)
    local arrowSize = self.goArrow.transform.rect
    local toastWidth = self.textDetail.transform.rect.width + 30
    local toastHeight = self.textDetail.transform.rect.height + 30
    local tragetArrowY
    local targetToastY
    local yPosFix = 0
    if arrowPos.y < 0 then
        self.goArrow.transform.eulerAngles = Vector3(0, 0, 90)
        tragetArrowY = arrowPos.y + halfHeight
        targetToastY = tragetArrowY + arrowSize.height * 2 + toastHeight / 2 - 30
        yPosFix = math.min(0, localRt.y - (targetToastY + toastHeight / 2))
    else
        self.goArrow.transform.eulerAngles = Vector3(0, 0, 270)
        tragetArrowY = arrowPos.y - halfHeight
        targetToastY = tragetArrowY - arrowSize.height * 2 - toastHeight / 2 + 30
        yPosFix = math.max(0, localLb.y - (targetToastY - toastHeight / 2))
    end

    local halfScreenWidth = g_Game.UIManager:GetUIRoot():GetComponent(typeof(CS.UIRoot)).referenceWidth / 2
    local targetToastX = arrowPos.x
   -- local targetArrowX = arrowPos.x
    if targetToastX > 0 and targetToastX + toastWidth / 2 > halfScreenWidth then
        targetToastX = halfScreenWidth - toastWidth / 2 - 40
        --targetArrowX = targetToastX + toastWidth / 2
    end
    if targetToastX < 0 and targetToastX - toastWidth / 2 < - halfScreenWidth then
        targetToastX = - halfScreenWidth + toastWidth / 2 + 40
        --targetArrowX = targetToastX - toastWidth / 2
    end
    self.goToast.transform.localPosition = Vector3(targetToastX, targetToastY + yPosFix, 0)
    self.goArrow.transform.localPosition = Vector3(arrowPos.x, tragetArrowY + yPosFix, 0)
end

function TextToastMediator:OnClose(param)
    self:ClearTimer()
end

function TextToastMediator:LateTick()
    if not self._inLateTickLimitInScreen then
        return
    end
    self:LimitInScene()
end

return TextToastMediator
