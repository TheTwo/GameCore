local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local CommonTipsInfoDefine = require('CommonTipsInfoDefine')
local Utils = require('Utils')
local UIHelper = require('UIHelper')
local LayoutRebuilder = CS.UnityEngine.UI.LayoutRebuilder
local Vector3 = CS.UnityEngine.Vector3

---@class CommonTipsInfoMediator : BaseUIMediator
local CommonTipsInfoMediator = class('CommonTipsInfoMediator', BaseUIMediator)

---@class CommonTipsInfoMediatorParameter
---@field clickTransform CS.UnityEngine.RectTransform
---@field title string
---@field contentList CommonTipsInfoContentCellParam[]

function CommonTipsInfoMediator:ctor()
    BaseUIMediator.ctor(self)
    self._inLateTickLimitInScreen = false
end


function CommonTipsInfoMediator:OnCreate()
    self.goRoot = self:GameObject("")
    self.textTitle = self:Text("p_text_title")
    self.goContent = self:GameObject("content")
    self.goArrow = self:GameObject('p_icon_arrow')
    self.tableviewproContent = self:TableViewPro('p_table')
end

function CommonTipsInfoMediator:OnShow()
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.LateTick))
end

function CommonTipsInfoMediator:OnHide(param)
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateTick))
end

function CommonTipsInfoMediator:OnOpened(param)
    self._inLateTickLimitInScreen = false
    if not param then
        return
    end
    self.clickTransform = param.clickTransform
    if param.title then
        self.textTitle.text = param.title
    end
    self.tableviewproContent:Clear()
    for i = 1, #param.contentList do
        self.tableviewproContent:AppendData(param.contentList[i])
    end

    if self.clickTransform then
        LayoutRebuilder.ForceRebuildLayoutImmediate(self.goContent.transform)
        self:LimitInScene()
        self._inLateTickLimitInScreen = true
    end
end

function CommonTipsInfoMediator:OnClose()
    --TODO
end

function CommonTipsInfoMediator:LimitInScene()
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
    local toastWidth = self.goContent.transform.rect.width + 30
    local toastHeight = self.goContent.transform.rect.height + 30
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
    self.goContent.transform.localPosition = Vector3(targetToastX, targetToastY + yPosFix, 0)
    self.goArrow.transform.localPosition = Vector3(arrowPos.x, tragetArrowY + yPosFix, 0)
end

function CommonTipsInfoMediator:LateTick()
    if not self._inLateTickLimitInScreen then
        return
    end
    self:LimitInScene()
end

return CommonTipsInfoMediator