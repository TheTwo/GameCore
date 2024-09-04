local NoviceBaseDefenseCompInfo = require('NoviceBaseDefenseCompInfo')
local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')
---@class NoviceBaseDefenseComponent : BaseUIComponent
local NoviceBaseDefenseComponent = class('NoviceBaseDefenseComponent', BaseUIComponent)

function NoviceBaseDefenseComponent:OnCreate()
    -- body
end

function NoviceBaseDefenseComponent:OnShow()
    -- body
end

function NoviceBaseDefenseComponent:OnFeedData(param)
    if not param or not param.day then
        return
    end
    self.day = param.day
    local info = NoviceBaseDefenseCompInfo[self.day]
    self.textLock.text = I18N.Get(info.textLock)
    self:SetLock(true)
end

function NoviceBaseDefenseComponent:OnBtnGotoClicked(args)
    -- g_Logger.Log('erf:day:' .. tostring(self.day))
end

function NoviceBaseDefenseComponent:SetLock(isLocked)
    self.textLock.gameObject:SetActive(isLocked)
    self.btnGoto.gameObject:SetActive(not isLocked)
    self.compItemNeededQuantity:SetVisible(not isLocked)
end

function NoviceBaseDefenseComponent:SetFinish(isFinished)
    self.imgIconFull.gameObject:SetActive(isFinished)
    self.btnGoto.gameObject:SetActive(not isFinished)
    self.compItemNeededQuantity:SetVisible(not isFinished)
    self.textLock.gameObject:SetActive(not isFinished)
end

return NoviceBaseDefenseComponent