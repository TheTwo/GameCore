---@class CityLegoBuildingName
---@field new fun():CityLegoBuildingName
---@field p_rotation CS.UnityEngine.Transform
---@field p_info CS.Lod.U2DWidgetMaterialSetter
---@field p_text_name CS.U2DTextMesh
---@field p_base_lv CS.U2DSpriteMesh
---@field p_text_lv CS.U2DTextMesh
local CityLegoBuildingName = class("CityLegoBuildingName")

function CityLegoBuildingName:SetName(name)
    self.p_text_name.text = name
end

return CityLegoBuildingName