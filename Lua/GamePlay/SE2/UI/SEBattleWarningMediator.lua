local BaseUIMediator = require ('BaseUIMediator')

---@class SEBattleWarningMediator : BaseUIMediator
local SEBattleWarningMediator = class('SEBattleWarningMediator', BaseUIMediator)

function SEBattleWarningMediator:ctor()

end

function SEBattleWarningMediator:OnCreate()
	self.base = self:Image("p_base")
	self.nodes = {}
	self.nodes[1] = self:GameObject("p_icon_task")
	self.nodes[2] = self:GameObject("p_card_monster")
	self.nodes[3] = self:GameObject("p_icon_pet")
	self.nodes[4] = self:GameObject("p_icon_defense")
    self.textToast = self:Text('p_text_toast')
	self.icon = self:Image("p_img_monster")
end


function SEBattleWarningMediator:OnShow(param)
	if (param and param.text) then
		self.textToast.text = require("I18N").Get(param.text)
	end

	for i = 1, #self.nodes do
		if (param and param.battleType + 1 == i) then
			self.nodes[i]:SetActive(true)
		else
			self.nodes[i]:SetActive(false)
		end
	end

	if (param and param.icon and param.icon > 0) then
		self:LoadSprite(param.icon, self.icon)
	end

	g_Game.SoundManager:Play('sfx_se_fight_began_pve')
end

function SEBattleWarningMediator:OnHide(param)
end

function SEBattleWarningMediator:OnOpened(param)
end

function SEBattleWarningMediator:OnClose(param)
end


return SEBattleWarningMediator;
