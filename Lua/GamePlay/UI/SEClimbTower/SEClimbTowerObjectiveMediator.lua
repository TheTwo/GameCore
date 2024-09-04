local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local I18N = require('I18N')
local UIMediatorNames = require("UIMediatorNames")
local ConfigRefer = require("ConfigRefer")

---@class SEClimbTowerObjectiveMediator : BaseUIMediator
local SEClimbTowerObjectiveMediator = class('SEClimbTowerObjectiveMediator', BaseUIMediator)

---@class SEClimbTowerTroopMediatorParam
---@field sectionId number

function SEClimbTowerObjectiveMediator:ctor()

end

function SEClimbTowerObjectiveMediator:OnCreate()
	self:InitObjects()
end

function SEClimbTowerObjectiveMediator:InitObjects()
	self.titleText = self:Text("p_text_title")
	self.stars = {}
	self.stars[1] = self:GameObject("p_icon_star_1")
	self.stars[2] = self:GameObject("p_icon_star_2")
	self.stars[3] = self:GameObject("p_icon_star_3")

	self.objText = {}
	self.objText[1] = self:Text("p_text_objective_1")
	self.objText[2] = self:Text("p_text_objective_2")
	self.objText[3] = self:Text("p_text_objective_3")
end

function SEClimbTowerObjectiveMediator:OnShow(param)
	self:InitData(param)
    self:InitUI()
    self:RefreshUI()
end

function SEClimbTowerObjectiveMediator:OnHide(param)
end

function SEClimbTowerObjectiveMediator:OnOpened(param)
end

function SEClimbTowerObjectiveMediator:OnClose(param)

end

--- 初始化数据
---@param self SEClimbTowerObjectiveMediator
---@param param SEClimbTowerObjectiveMediatorParam
function SEClimbTowerObjectiveMediator:InitData(param)
	self.sectionId = param and param.sectionId or 0
end

--- 初始化UI
---@param self SEClimbTowerObjectiveMediator
function SEClimbTowerObjectiveMediator:InitUI()

end

--- 刷新UI
---@param self SEClimbTowerObjectiveMediator
function SEClimbTowerObjectiveMediator:RefreshUI()
	local gotStars = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.ClimbTower.SectionId2StarMask[self.sectionId]
	local sectionCfg = ConfigRefer.ClimbTowerSection:Find(self.sectionId)
	if (sectionCfg) then
		self.titleText.text = I18N.Get(sectionCfg:Name())
		for i = 1, sectionCfg:StarEventLength() do
			local event = sectionCfg:StarEvent(i)
			if (self.objText[i]) then
				self.objText[i].text = I18N.GetWithParams(event:Des(), event:DesPrm())
			end
		end
		for i = 1, 3 do
			if (self.stars[i]) then
				self.stars[i]:SetActive(gotStars and gotStars.GetStar and gotStars.GetStar[i - 1])
			end
		end
	end
end

return SEClimbTowerObjectiveMediator
