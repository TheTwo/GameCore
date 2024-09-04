local Delegate = require("Delegate")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceCenterTransformConditionCellData
---@field conditionText string
---@field gotoFunc fun()
---@field isFinished boolean

---@class AllianceCenterTransformConditionCell:BaseUIComponent
---@field new fun():AllianceCenterTransformConditionCell
---@field super BaseTableViewProCell
local AllianceCenterTransformConditionCell = class('AllianceCenterTransformConditionCell', BaseUIComponent)

function AllianceCenterTransformConditionCell:OnCreate(param)
	self._p_text_conditions = self:Text("p_text_conditions")
	self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickGo))
	self._p_icon_finish = self:GameObject("p_icon_finish")
end

---@param data AllianceCenterTransformConditionCellData
function AllianceCenterTransformConditionCell:OnFeedData(data)
	self._data = data
	self._p_text_conditions.text = data.conditionText
	self._p_btn_goto:SetVisible(not data.isFinished)
	self._p_icon_finish:SetVisible(data.isFinished)
end

function AllianceCenterTransformConditionCell:OnClickGo()
	if self._data and self._data.gotoFunc then
		self._data.gotoFunc()
	end
end

return AllianceCenterTransformConditionCell
