local Delegate = require("Delegate")

local BaseUIComponent = require("BaseUIComponent")

---@class HUDSelectTroopBattleTipEscrowToggleData
---@field isOn boolean
---@field onToggleChanged fun(isOn:boolean)

---@class HUDSelectTroopBattleTipEscrowToggle:BaseUIComponent
---@field new fun():HUDSelectTroopBattleTipEscrowToggle
---@field super BaseUIComponent
local HUDSelectTroopBattleTipEscrowToggle = class('HUDSelectTroopBattleTipEscrowToggle', BaseUIComponent)

function HUDSelectTroopBattleTipEscrowToggle:ctor()
    BaseUIComponent.ctor(self)
    self._isOn = false
end

function HUDSelectTroopBattleTipEscrowToggle:OnCreate(param)
    self._selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnClickBtn))
    self._selfStatus = self:StatusRecordParent("")
end

---@param data HUDSelectTroopBattleTipEscrowToggleData
function HUDSelectTroopBattleTipEscrowToggle:OnFeedData(data)
    self._data = data
    self:SetToggle(data.isOn, false)
end

function HUDSelectTroopBattleTipEscrowToggle:SetToggle(isOn, notify)
    self._isOn = isOn
    self._selfStatus:SetState(isOn and 1 or 0)
    if not notify then
        return
    end
    if self._data.onToggleChanged then
        self._data.onToggleChanged(self._isOn)
    end
end

function HUDSelectTroopBattleTipEscrowToggle:OnClickBtn()
    self:SetToggle(not self._isOn, true)
end

return HUDSelectTroopBattleTipEscrowToggle