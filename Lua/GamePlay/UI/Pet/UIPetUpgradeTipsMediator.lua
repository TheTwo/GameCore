local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")
local KingdomMapUtils = require("KingdomMapUtils")
local QueuedTask = require("QueuedTask")
local Delegate = require("Delegate")

---@class UIPetUpgradeTipsMediator : BaseUIMediator
local UIPetUpgradeTipsMediator = class('UIPetUpgradeTipsMediator', BaseUIMediator)

function UIPetUpgradeTipsMediator:OnCreate()
    self.textTitle = self:Text('p_text_title', "gacha_select_re_tips_1")
    self.textDesc = self:Text('p_text_desc', "pet_level_up_rule_des")
    self.textLv = self:Text('p_text_lv')
	self.goName = self:GameObject("name")
    self.textName = self:Text('p_text_name')
    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
    self.textGoto = self:Text('p_text_goto', "world_qianwang")
    self.compChildReddotDefault = self:LuaObject('child_reddot_default')
end

function UIPetUpgradeTipsMediator:OnOpened(param)
	local tiles = ModuleRefer.CityModule.myCity:GetFurnitureTilesByFurnitureType(1020)
	if tiles and #tiles >= 1 then
		self.goName:SetActive(true)
		self.btnGoto.gameObject:SetActive(true)
		self.furnitureTile = tiles[1]
		self.textName.text = self.furnitureTile:GetName()
		self.textLv.text = self.furnitureTile:GetCell().level
	else
		self.btnGoto.gameObject:SetActive(false)
		self.goName:SetActive(false)
	end
end

function UIPetUpgradeTipsMediator:OnClose(param)

end

function UIPetUpgradeTipsMediator:OnBtnGotoClicked(args)
	self:CloseSelf()
	g_Game.UIManager:CloseByName(UIMediatorNames.UIPetMediator)
	local callback = function()
		local camera = ModuleRefer.CityModule.myCity:GetCamera()
		if camera then
			local tiles = ModuleRefer.CityModule.myCity:GetFurnitureTilesByFurnitureType(1020)
			if tiles and #tiles >= 1 then
				camera:LookAt(tiles[1]:GetWorldCenter(), 0.5)
			end
		end
	end
	if KingdomMapUtils.IsMapState() then
		KingdomMapUtils.GetKingdomScene():ReturnMyCity()
		local queuedTask = QueuedTask.new()
		queuedTask:WaitEvent(EventConst.CITY_SET_ACTIVE,nil,function(param)
			return true
		end):DoAction(function()
			callback()
			end
		):Start()
	else
		callback()
	end
end

return UIPetUpgradeTipsMediator