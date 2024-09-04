local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local NotificationType = require("NotificationType")

---@class LanguageItemTableViewCell : BaseTableViewProCell
local LanguageItemTableViewCell = class('LanguageItemTableViewCell', BaseTableViewProCell)

function LanguageItemTableViewCell:ctor()

end

function LanguageItemTableViewCell:OnCreate(param)
    self._code = nil
    self.button = self:Button("child_toggle_dot", Delegate.GetOrCreate(self, self.OnClick))
    self.toggle = self:BindComponent("child_toggle_dot", typeof(CS.StatusRecordParent)) --self:Toggle('child_toggle_dot')
    self.text = self:Text('p_text_language')
end


function LanguageItemTableViewCell:OnShow(param)
end

function LanguageItemTableViewCell:OnOpened(param)
end

function LanguageItemTableViewCell:OnClose(param)
end

function LanguageItemTableViewCell:OnFeedData(param)
    if (param) then
        self._code = param.code
        self.text.text = param.text
        --self.toggle.enabled = true
        --self.toggle.isOn = param.selected
        --self.toggle.enabled = false
		if (param.selected) then
			self.toggle:SetState(1)
		else
			self.toggle:SetState(0)
		end
        self.onClick = param.onClick
    end
end

function LanguageItemTableViewCell:OnClick()
    if (self.onClick) then
        self.onClick(self._code)
    end
end

return LanguageItemTableViewCell;
