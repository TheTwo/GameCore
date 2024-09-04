---prefab:ui3d_tips_building

local I18N = require("I18N")
local CityTrigger = require("CityTrigger")
local BasicCamera = require("BasicCamera")

---@class CityFurnitureDecorationBubble
---@field p_base_pollution CS.UnityEngine.GameObject
---@field p_group_pollution CS.UnityEngine.GameObject
---@field p_text_detail CS.U2DTextMesh
---@field p_text_name CS.U2DTextMesh
---@field p_Frame CS.DragonReborn.LuaBehaviour
---@field p_facing_camera CS.U2DFacingCamera
local CityFurnitureDecorationBubble = sealedClass('CityFurnitureDecorationBubble')

---@param furnitureTypeConfig CityFurnitureTypesConfigCell
function CityFurnitureDecorationBubble:SetupFurniture(furnitureTypeConfig)
    self.p_text_name.text = I18N.Get(furnitureTypeConfig:Name())
    self.p_text_detail.text = I18N.Get(furnitureTypeConfig:Description())
end

function CityFurnitureDecorationBubble:SetPolluted(isPolluted)
    self.p_base_pollution:SetVisible(isPolluted)
    self.p_group_pollution:SetVisible(isPolluted)
end

---@param callback fun(trigger:CityTrigger):boolean
---@param tile CityTileBase
function CityFurnitureDecorationBubble:SetOnTrigger(callback, tile)
    ---@type CityTrigger
    local v = self.p_Frame.Instance
    if v and v.is and v:is(CityTrigger) then
        v:SetOnTrigger(callback, tile, true)
    end
end

function CityFurnitureDecorationBubble:Clear()
    self.p_text_name.text = string.Empty
    self.p_text_detail.text = string.Empty
end

function CityFurnitureDecorationBubble:OnEnable()
    self.p_facing_camera.FacingCamera = BasicCamera.CurrentBasicCamera and BasicCamera.CurrentBasicCamera:GetUnityCamera() or nil
end

return CityFurnitureDecorationBubble