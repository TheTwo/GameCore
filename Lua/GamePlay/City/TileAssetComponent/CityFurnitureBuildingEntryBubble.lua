--- scene:ui3d_bubble_entrance_building

local CityTrigger = require("CityTrigger")

---@class CityFurnitureBuildingEntryBubble
---@field new fun():CityFurnitureBuildingEntryBubble
---@field p_text_num CS.U2DTextMesh
---@field p_text_name CS.U2DTextMesh
---@field p_building_click CS.DragonReborn.LuaBehaviour
---@field p_npc_click CS.DragonReborn.LuaBehaviour
---@field p_hint CS.UnityEngine.GameObject
---@field p_icon_hint CS.U2DSpriteMesh
---@field p_text_hint CS.U2DTextMesh
---@field p_status CS.StatusRecordParent
---@field p_text_goto CS.U2DTextMesh
local CityFurnitureBuildingEntryBubble = class('CityFurnitureBuildingEntryBubble')

---@return CityFurnitureBuildingEntryBubble
function CityFurnitureBuildingEntryBubble:ChangeStatusToBuilding()
    self.p_status:SetState(0)
    return self
end

---@return CityFurnitureBuildingEntryBubble
function CityFurnitureBuildingEntryBubble:ChangeStatusToNPC()
    self.p_status:SetState(1)
    return self
end

function CityFurnitureBuildingEntryBubble:ChangeStatusToMilitary()
    self.p_status:SetState(2)
    return self
end

---@return CityFurnitureBuildingEntryBubble
function CityFurnitureBuildingEntryBubble:SetLv(lv)
    self.p_text_num.text = tostring(lv)
    return self
end

---@return CityFurnitureBuildingEntryBubble
function CityFurnitureBuildingEntryBubble:SetName(name)
    self.p_text_name.text = name
    return self
end

---@return CityFurnitureBuildingEntryBubble
function CityFurnitureBuildingEntryBubble:SetBuildingBtnText(str)
    self.p_text_goto.text = str
    return self
end

---@return CityFurnitureBuildingEntryBubble
function CityFurnitureBuildingEntryBubble:Clear()
    self.p_text_num.text = string.Empty
    self.p_text_name.text = string.Empty
    return self
end

---@param callback fun(trigger:CityTrigger):boolean
---@param tile CityTileBase
---@return CityFurnitureBuildingEntryBubble
function CityFurnitureBuildingEntryBubble:SetOnTrigger(callback, tile)
    ---@type CityTrigger
    local v = self.p_building_click.Instance
    if v and v.is and v:is(CityTrigger) then
        v:SetOnTrigger(callback, tile, true)
    end
    v = self.p_npc_click.Instance
    if v and v.is and v:is(CityTrigger) then
        v:SetOnTrigger(callback, tile, true)
    end
    return self
    
end

return CityFurnitureBuildingEntryBubble