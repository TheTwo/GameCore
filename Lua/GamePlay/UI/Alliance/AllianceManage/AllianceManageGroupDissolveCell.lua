local Delegate = require("Delegate")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceManageGroupDissolveCellData
---@field isSatisfied boolean
---@field content string
---@field gotoFunc fun()

---@class AllianceManageGroupDissolveCell:BaseTableViewProCell
---@field new fun():AllianceManageGroupDissolveCell
---@field super BaseTableViewProCell
local AllianceManageGroupDissolveCell = class('AllianceManageGroupDissolveCell', BaseTableViewProCell)

function AllianceManageGroupDissolveCell:ctor()
    AllianceManageGroupDissolveCell.super.ctor(self)
    self._clickFunc = nil
end

function AllianceManageGroupDissolveCell:OnCreate(param)
    self._p_icon_check = self:Image("p_icon_check")
    self._p_icon_fork = self:Image("p_icon_fork")
    self._p_text_require = self:Text("p_text_require")
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickGoToButton))
end

---@param data AllianceManageGroupDissolveCellData
function AllianceManageGroupDissolveCell:OnFeedData(data)
    self._p_icon_check:SetVisible(data.isSatisfied)
    self._p_icon_fork:SetVisible(not data.isSatisfied)
    self._p_text_require.text = data.content
    self._p_btn_goto:SetVisible(data.gotoFunc ~= nil)
    self._clickFunc = data.gotoFunc
end

function AllianceManageGroupDissolveCell:OnClickGoToButton()
    if self._clickFunc then
        self._clickFunc()
    end
end

return AllianceManageGroupDissolveCell