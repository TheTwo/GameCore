local Delegate = require("Delegate")
local BaseUIComponent = require("BaseUIComponent")

---@class AllianceCenterTransformCostCellData
---@field icon string
---@field numbStr string
---@field onClickAdd fun()

---@class AllianceCenterTransformCostCell:BaseUIComponent
---@field new fun():AllianceCenterTransformCostCell
---@field super BaseUIComponent
local AllianceCenterTransformCostCell = class('AllianceCenterTransformCostCell', BaseUIComponent)

function AllianceCenterTransformCostCell:OnCreate(param)
	self._child_common_quantity_l = self:Button("child_common_quantity_l")
	self._p_base_farme = self:Image("p_base_farme")
	self._p_icon_item = self:Image("p_icon_item")
	self._p_text_01 = self:Text("p_text_01")
	self._p_btn_add = self:Button("p_btn_add", Delegate.GetOrCreate(self, self.OnClickAdd))
end

---@param data AllianceCenterTransformCostCellData
function AllianceCenterTransformCostCell:OnFeedData(data)
	self._data = data
	g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon_item)
	self._p_text_01.text = data.numbStr
	self._p_btn_add:SetVisible(data.onClickAdd ~= nil)
end

function AllianceCenterTransformCostCell:OnClickAdd()
	if self._data and self._data.onClickAdd then
		return self._data.onClickAdd()
	end
end

return AllianceCenterTransformCostCell
