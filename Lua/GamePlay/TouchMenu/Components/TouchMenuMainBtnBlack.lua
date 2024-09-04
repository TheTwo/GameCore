local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class TouchMenuMainBtnBlack:BaseUIComponent
local TouchMenuMainBtnBlack = class('TouchMenuMainBtnBlack', BaseUIComponent)

function TouchMenuMainBtnBlack:OnCreate()
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._p_text = self:Text("p_text")
end

---@param data TouchMenuMainBtnDatum
function TouchMenuMainBtnBlack:OnFeedData(data)
    self.data = data
    self._p_text.text = data.label
end

function TouchMenuMainBtnBlack:OnClick()
    if self.data.enable then
        if self.data.onClick then
            if not self.data.onClick(self.data.onClickDatum, self._transform) then
                local mediator = self:GetParentBaseUIMediator()
                if mediator then
                    mediator:CloseSelf()
                end
                self.data.onClick = nil
            end
        else
            if UNITY_EDITOR or UNITY_DEBUG then
                g_Logger.Error("空回调from:%s", tostring(self.data.where))
            end
        end
    else
        if self.data.onClickDisable then
            self.data.onClickDisable(self.data.onClickDatum, self._transform)
        end
    end
end

return TouchMenuMainBtnBlack