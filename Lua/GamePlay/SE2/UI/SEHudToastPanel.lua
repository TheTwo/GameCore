local BaseUIComponent = require('BaseUIComponent')

---@class SEHudToastPanel:BaseUIComponent
---@field super BaseUIComponent
local SEHudToastPanel = class('SEHudToastPanel',BaseUIComponent)

function SEHudToastPanel:ctor()
    BaseUIComponent.ctor(self)
end

function SEHudToastPanel:OnCreate(param)
    self._env = require("SEEnvironment").Instance()
    self:InitObjects()
end

function SEHudToastPanel:OnShow(param)

end

function SEHudToastPanel:OnOpened(param)

end

function SEHudToastPanel:OnHide(param)

end

function SEHudToastPanel:OnClose(param)
    BaseUIComponent.OnClose(self,param)
end

---@param self SEHudToastPanel
function SEHudToastPanel:InitObjects()
    self._canvasGroup = self:BindComponent("",typeof(CS.UnityEngine.CanvasGroup))
    self._animation = self:BindComponent("",typeof(CS.UnityEngine.Animation))
    self._text = self:Text("p_text_toast")
	---@type CommonHeroHeadIcon
	self._head = self:LuaObject("child_card_hero_s_toast")
    self:HideToast()
end

function SEHudToastPanel:ShowToast(text, heroId)
    self._text.text = text
	if (heroId and heroId > 0) then
		self._head:FeedData(heroId)
		self._head:SetVisible(true)
	else
		self._head:SetVisible(false)
	end
    self._animation:Rewind()
    self._animation:Play()
end

function SEHudToastPanel:HideToast()
    self._animation:Stop()
	self._animation:Rewind()
    self._canvasGroup.alpha = 0
end

return SEHudToastPanel
