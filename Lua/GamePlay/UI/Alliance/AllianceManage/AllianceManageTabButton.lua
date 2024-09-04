local Delegate = require("Delegate")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceManageTabButtonParameter
---@field index number
---@field onClick fun(index:number)
---@field onClickLocked fun(index:number)
---@field btnName string
---@field isLocked boolean
---@field titleText string

---@class AllianceManageTabButton:BaseUIComponent
---@field new fun():AllianceManageTabButton
---@field super BaseUIComponent
local AllianceManageTabButton = class('AllianceManageTabButton', BaseUIComponent)

function AllianceManageTabButton:ctor()
    BaseUIComponent.ctor(self)
    self._index = nil
    self._onClick = nil
    self._onClickLocked = nil
    self._status = 0
    self._titleString = string.Empty
end

function AllianceManageTabButton:OnCreate(param)
    self._selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnClickBtn))
    self._selfStatus = self:BindComponent("", typeof(CS.StatusRecordParent))
    self._p_text_b = self:Text("p_text_b")
    self._p_text_a = self:Text("p_text_a")
    self._p_text_c = self:Text("p_text_c")
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
    self._child_reddot_default:SetVisible(false)
end

---@param data AllianceManageTabButtonParameter
function AllianceManageTabButton:OnFeedData(data)
    self._index = data.index
    self._onClick = data.onClick
    self._onClickLocked = data.onClickLocked
    self._p_text_a.text = data.btnName
    self._p_text_b.text = data.btnName
    self._p_text_c.text = data.btnName
    self._titleString = data.titleText
    if data.isLocked then
        self._status = 2
        self._selfStatus:SetState(2)
    else
        self._status = 0
        self._selfStatus:SetState(0)
    end
end

function AllianceManageTabButton:OnClickBtn()
    if self._status == 2 then
        if self._onClickLocked then
            self._onClickLocked(self._index)
        end
        return
    end
    if self._onClick then
        self._onClick(self._index)
    end
end

---@param status number @0-selected,1-normal,2-locked
function AllianceManageTabButton:SetStatus(status)
    if self._status == 2 then
        return
    end
    self._status = status
    self._selfStatus:SetState(status)
end

function AllianceManageTabButton:GetTitleString()
    return self._titleString
end

return AllianceManageTabButton