local BaseUIComponent = require ('BaseUIComponent')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class CityCitizenManageV3UIToggle:BaseUIComponent
local CityCitizenManageV3UIToggle = class('CityCitizenManageV3UIToggle', BaseUIComponent)

function CityCitizenManageV3UIToggle:OnCreate()
    self._statusRecord = self:StatusRecordParent("")
    self._btn = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._p_icon_n = self:Image("p_icon_n")
    self._p_icon_selected = self:Image("p_icon_selected")
end

function CityCitizenManageV3UIToggle:OnOpened()
    g_Game.EventManager:AddListener(EventConst.UI_CITIZEN_MANAGE_V3_SELECT_PAGE, Delegate.GetOrCreate(self, self.OnSelectPage))
end

function CityCitizenManageV3UIToggle:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.UI_CITIZEN_MANAGE_V3_SELECT_PAGE, Delegate.GetOrCreate(self, self.OnSelectPage))
end

---@param data CityCitizenManageV3PageData
function CityCitizenManageV3UIToggle:OnFeedData(data)
    self.data = data
    g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon_n)
    g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon_selected)

    self:OnSelectPage()
end

function CityCitizenManageV3UIToggle:OnClick()
    self:GetParentBaseUIMediator():SelectPage(self.data)
end

function CityCitizenManageV3UIToggle:OnSelectPage()
    local isSelected = self.data ~= nil and self.data == self:GetParentBaseUIMediator().currentPage
    self._statusRecord:ApplyStatusRecord(isSelected and 1 or 0)
end

return CityCitizenManageV3UIToggle