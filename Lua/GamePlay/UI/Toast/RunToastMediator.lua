local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local Utils = require('Utils')
local Ease = CS.DG.Tweening.Ease

---@class RunToastMediator : BaseUIMediator
local RunToastMediator = class('RunToastMediator', BaseUIMediator)

local MASK_LENGTH = 300
local RUN_SPEED = 5

function RunToastMediator:ctor()
    ---@type number
    self.openTime = 0
end

function RunToastMediator:OnCreate()
    self.textText = self:Text('p_text')
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
    self.toastList = {}
    self.originPosition = self.textText.transform.localPosition
end

function RunToastMediator:OnBtnCloseClicked(args)
    g_Game.UIManager:Close(self.runtimeId)
end

---@param param TopToastParameter
function RunToastMediator:OnOpened(param)
    if not param then
        return
    end
    self:PushToast(param)
    self:PopToast()
    g_Game.EventManager:AddListener(EventConst.UI_EVENT_RUN_TOAST_NEW, Delegate.GetOrCreate(self, self.OnNewToast))
end

function RunToastMediator:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.UI_EVENT_RUN_TOAST_NEW, Delegate.GetOrCreate(self, self.OnNewToast))
    self.textText.transform:DOKill()
end

---@field delta number
function RunToastMediator:Move(delta)
    self.textText.transform:DOLocalMove(self.targetPos, 10):OnComplete(function()
        self:PopToast()
    end)
end

function RunToastMediator:PushToast(param)
    local toastCfg = ConfigRefer.Toast:Find(param.configId)
    local single = {configId = param.configId, content = param.content, times = toastCfg:Times() > 0 and toastCfg:Times() or 1}
    self.toastList[#self.toastList + 1] = single
end

function RunToastMediator:PopToast()
    if #self.toastList == 0 then
        g_Game.UIManager:Close(self.runtimeId)
        return
    end
    local toastInfo = self.toastList[1]
    if toastInfo.times == 0 then
        table.remove(self.toastList, 1)
        self:PopToast()
        return
    end
    toastInfo.times = toastInfo.times - 1
    local settings = self.textText:GetGenerationSettings(CS.UnityEngine.Vector2(0, self.textText:GetPixelAdjustedRect().size.y))
    local width = self.textText.cachedTextGeneratorForLayout:GetPreferredWidth(toastInfo.content, settings) / self.textText.pixelsPerUnit
    self.textText.transform.localPosition = CS.UnityEngine.Vector3(MASK_LENGTH, 0, 0)
    self.textText.text = toastInfo.content
    self.targetPos = CS.UnityEngine.Vector3(self.originPosition.x - width, self.originPosition.y, 0)
    self:Move()
end

function RunToastMediator:OnNewToast(param)
    self:PushToast(param)
end

return RunToastMediator
