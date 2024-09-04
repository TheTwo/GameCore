local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class TouchMenuCellSeMonster:BaseUIComponent
local TouchMenuCellSeMonster = class('TouchMenuCellSeMonster', BaseUIComponent)

function TouchMenuCellSeMonster:OnCreate()
    self._p_text_monsters = self:Text("p_text_monsters")
    self._p_table_monsters = self:TableViewPro("p_table_monsters")
    self._p_btn_view = self:Button("p_btn_view", Delegate.GetOrCreate(self, self.OnClickView))
	self._p_creep_buff = self:GameObject("p_creep_buff")
	self._p_icon_buff = self:Image("p_icon_buff")
	self._p_icon_buff_btn = self:Button("p_icon_buff", Delegate.GetOrCreate(self, self.OnClickBuffIcon))
	self._p_text_buff_num = self:Text("p_text_buff_num")
end

---@param data TouchMenuCellSeMonsterDatum
function TouchMenuCellSeMonster:OnFeedData(data)
	self.__data = data
    self._p_text_monsters.text = data.title
	self.onInfoClick = data.infoClick
	self.onBuffIconClick = data.onClickCreepBuffIcon
	if (not self.onInfoClick) then
		self._p_btn_view.gameObject:SetActive(false)
	else
		self._p_btn_view.gameObject:SetActive(true)
	end
	self._p_table_monsters:Clear()
	if (data.monstersData) then
		for _, v in ipairs(data.monstersData) do
			self._p_table_monsters:AppendData(v)
		end
	end
	if data.creepBuff and data.creepBuff > 0 then
		self._p_creep_buff:SetVisible(true)
		g_Game.SpriteManager:LoadSpriteAsync(data.creepBuffIcon, self._p_icon_buff)
		if data.creepBuff > 1 then
			self._p_text_buff_num:SetVisible(true)
			self._p_text_buff_num.txt = ("x%d"):format(data.creepBuff)
		else
			self._p_text_buff_num:SetVisible(false)
		end
	else
		self._p_creep_buff:SetVisible(false)
	end
end

function TouchMenuCellSeMonster:OnClickView()
	if (self.onInfoClick) then
		self.onInfoClick()
	end
end

function TouchMenuCellSeMonster:OnClickBuffIcon()
	if (self.onBuffIconClick) then
		self.onBuffIconClick(self._p_icon_buff_btn.transform:GetComponent(typeof(CS.UnityEngine.RectTransform)), self.__data)
	end
end

return TouchMenuCellSeMonster
