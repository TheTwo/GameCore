local Utils = require("Utils")


---@class PvPTileAssetHUDTroopHeadBehavior
---@field root CS.UnityEngine.Transform
---@field p_img_base CS.U2DSpriteMesh
---@field p_image_monster CS.U2DSpriteMesh
---@field p_health CS.UnityEngine.GameObject
---@field p_progress CS.U2DSlider
---@field p_trigger CS.DragonReborn.LuaBehaviour
---@field p_group_village_monsters CS.UnityEngine.GameObject
---@field p_text_monsters_num CS.U2DTextMesh
---@field p_image_dange CS.U2DSpriteMesh
local PvPTileAssetHUDTroopHeadBehavior = class("PvPTileAssetHUDTroopHeadBehavior")

function PvPTileAssetHUDTroopHeadBehavior:SetFrame(spriteName)
    g_Game.SpriteManager:LoadSprite(spriteName, self.p_img_base)
    self.p_img_base:UpdateImmediate()
end

function PvPTileAssetHUDTroopHeadBehavior:SetHead(spriteName)
    g_Game.SpriteManager:LoadSprite(spriteName, self.p_image_monster)
    self.p_img_base:UpdateImmediate()
end

function PvPTileAssetHUDTroopHeadBehavior:SetInfected(isInfected)
    self.p_image_dange:SetVisible(isInfected)
end

function PvPTileAssetHUDTroopHeadBehavior:SetMonsterTroopCount(countOrNil)
    if not countOrNil or countOrNil <=0 then
        self.p_group_village_monsters:SetActive(false)
    else
        self.p_group_village_monsters:SetActive(true)
        self.p_text_monsters_num.text = tostring(countOrNil)
    end
end

function PvPTileAssetHUDTroopHeadBehavior:SetProgress(value)
    self.p_progress.progress = value
    self.p_progress.spriteMesh:UpdateImmediate()
end

---@param enable boolean
function PvPTileAssetHUDTroopHeadBehavior:EnableTrigger(enable)
    if Utils.IsNull(self.p_trigger) then return end
    ---@type MapUITrigger
    local trigger = self.p_trigger.Instance
    trigger:SetEnable(enable)
end

function PvPTileAssetHUDTroopHeadBehavior:SetTrigger(callback)
    if Utils.IsNull(self.p_trigger) then return end
    self.p_trigger.Instance:SetTrigger(callback)
end

return PvPTileAssetHUDTroopHeadBehavior