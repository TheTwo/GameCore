---@class CityTileAssetFurnitureEggBubbleBehaviour
---@field new fun():CityTileAssetFurnitureEggBubbleBehaviour
---@field p_rotation CS.DragonReborn.LuaBehaviour
---@field p_egg_1 CS.UnityEngine.GameObject
---@field p_egg_2 CS.UnityEngine.GameObject
---@field p_egg_3 CS.UnityEngine.GameObject
---@field p_text_1 CS.U2DTextMesh
---@field p_text_2 CS.U2DTextMesh
---@field p_text_3 CS.U2DTextMesh
local CityTileAssetFurnitureEggBubbleBehaviour = class("CityTileAssetFurnitureEggBubbleBehaviour")
local NumberFormatter = require("NumberFormatter")
local Delegate = require("Delegate")

function CityTileAssetFurnitureEggBubbleBehaviour:Awake()
    ---@type CityTrigger
    self.trigger1 = self.p_egg_1:GetLuaBehaviour("CityTrigger").Instance
    ---@type CityTrigger
    self.trigger2 = self.p_egg_2:GetLuaBehaviour("CityTrigger").Instance
    ---@type CityTrigger
    self.trigger3 = self.p_egg_3:GetLuaBehaviour("CityTrigger").Instance
end

function CityTileAssetFurnitureEggBubbleBehaviour:ClearTrigger()
    self.trigger1:SetOnTrigger(nil, nil, nil)
    self.trigger2:SetOnTrigger(nil, nil, nil)
    self.trigger3:SetOnTrigger(nil, nil, nil)
end

function CityTileAssetFurnitureEggBubbleBehaviour:ActiveTrigger(callback1, callback2, callback3)
    self.trigger1:SetOnTrigger(callback1, nil, true)
    self.trigger2:SetOnTrigger(callback2, nil, true)
    self.trigger3:SetOnTrigger(callback3, nil, true)
end

function CityTileAssetFurnitureEggBubbleBehaviour:ApplyEggNumber(count1, count2, count3)
    self.p_egg_1:SetActive(count1 > 0)
    self.p_egg_2:SetActive(count2 > 0)
    self.p_egg_3:SetActive(count3 > 0)

    self.p_text_1.text = NumberFormatter.NumberAbbr(count1)
    self.p_text_2.text = NumberFormatter.NumberAbbr(count2)
    self.p_text_3.text = NumberFormatter.NumberAbbr(count3)
end

return CityTileAssetFurnitureEggBubbleBehaviour