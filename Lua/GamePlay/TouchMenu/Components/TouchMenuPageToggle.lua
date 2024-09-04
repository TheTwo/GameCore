local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class TouchMenuPageToggle:BaseUIComponent
local TouchMenuPageToggle = class('TouchMenuPageToggle', BaseUIComponent)

function TouchMenuPageToggle:OnCreate()
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))

    self._p_base = self:GameObject("p_base")
    self._p_icon_base = self:Image("p_icon_base")

    self._p_selected = self:GameObject("p_selected")
    self._p_icon_selected = self:Image("p_icon_selected")
end

---@param data TouchMenuPageToggleDatum
function TouchMenuPageToggle:OnFeedData(data)
    self.data = data
    g_Game.SpriteManager:LoadSprite(self.data.pageData.toggleImage, self._p_icon_base)
    g_Game.SpriteManager:LoadSprite(self.data.pageData.toggleImage, self._p_icon_selected)
end

function TouchMenuPageToggle:OnSelected(flag)
    self._p_base:SetActive(not flag)
    self._p_selected:SetActive(not flag)
end

function TouchMenuPageToggle:OnClick()
    ---@type TouchMenuUIMediator
    local uiMediator = self:GetParentBaseUIMediator()
    uiMediator:ClickToggle(self.data)
end

return TouchMenuPageToggle