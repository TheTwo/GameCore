local I18N = require("I18N")
---@class TroopEditTips
local TroopEditTips = class('TroopEditTips')

local TipsLevel = {
    Error = 1,
    Warning = 2,
    Info = 3
}

TroopEditTips.TipsLevel = TipsLevel

---@param checker fun():boolean, string[]
---@param yTipStr string
---@param nTipStr string
---@param level number
function TroopEditTips:ctor(checker, ytipStr, nTipStr, level)
    self.checker = checker
    self.yTipStr = ytipStr
    self.yTip = nil
    self.nTipStr = nTipStr
    self.nTip = nil
    self.level = level
end

---@param tip TroopEditTips
function TroopEditTips:SetYTip(tip)
    self.yTip = tip
end

---@param tip TroopEditTips
function TroopEditTips:SetNTip(tip)
    self.nTip = tip
end

---@return string @tip
---@return number @level
function TroopEditTips:GetTip()
    local result, params = self.checker()
    if result then
        if self.yTip then
            return self.yTip:GetTip()
        elseif self.yTipStr then
            return I18N.GetWithParams(self.yTipStr, params), self.level
        end
    else
        if self.nTip then
            return self.nTip:GetTip()
        elseif self.nTipStr then
            return I18N.GetWithParams(self.nTipStr, params), self.level
        end
    end
    return nil
end

return TroopEditTips
