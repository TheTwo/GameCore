
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceCenterTransformAdditionCell:BaseTableViewProCell
---@field new fun():AllianceCenterTransformAdditionCell
---@field super BaseTableViewProCell
local AllianceCenterTransformAdditionCell = class('AllianceCenterTransformAdditionCell', BaseTableViewProCell)

function AllianceCenterTransformAdditionCell:OnCreate(param)
    self._p_icon_addtion = self:Image("p_icon_addtion")
    self._p_text_addtion = self:Text("p_text_addtion")
    self._p_text_addtion_number_old = self:Text("p_text_addtion_number_old")
    self._p_icon_arrow = self:GameObject("p_icon_arrow")
    self._p_text_addtion_number_new = self:Text("p_text_addtion_number_new")
end

---@param data {prefabIdx:number, cellData:{strLeft:string,strRight:string,icon:string,strRightOrigin:string}}
function AllianceCenterTransformAdditionCell:OnFeedData(data)
	g_Game.SpriteManager:LoadSprite(data.cellData.icon, self._p_icon_addtion)
	self._p_text_addtion.text = data.cellData.strLeft
	self._p_text_addtion_number_old.text = data.cellData.strRightOrigin
	self._p_text_addtion_number_new.text = data.cellData.strRight
end

return AllianceCenterTransformAdditionCell
