local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local Utils = require("Utils")

local CityTileAsset = require("CityTileAsset")

---@class CityTileAssetNpcBubbleInteractBehaviour:CityTileAsset
---@field new fun():CityTileAssetNpcBubbleInteractBehaviour
---@field super CityTileAsset
---@field p_icon_status CS.U2DSpriteMesh
---@field p_icon_pollution CS.UnityEngine.GameObject
---@field p_icon_danger CS.U2DSpriteMesh
---@field p_icon_creep CS.U2DSpriteMesh
---@field p_group_talk CS.UnityEngine.GameObject
---@field p_text_talk CS.U2DTextMesh
---@field p_click_trigger CS.DragonReborn.LuaBehaviour
local CityTileAssetNpcBubbleInteractBehaviour = class('CityTileAssetNpcBubbleInteractBehaviour', CityTileAsset)

function CityTileAssetNpcBubbleInteractBehaviour:ResetToNormal()
    self.p_icon_pollution:SetVisible(false)
    self.p_group_talk:SetVisible(false)
    ---@type CityTrigger
    local trigger = self.p_click_trigger.Instance
    if trigger then
        trigger:SetOnTrigger(nil, nil, false)
    end
end

function CityTileAssetNpcBubbleInteractBehaviour:SetupIcon(icon)
    if not string.IsNullOrEmpty(icon) then
        g_Game.SpriteManager:LoadSpriteAsync(icon, self.p_icon_status)
    end
end

---@param tile CityTileBase
function CityTileAssetNpcBubbleInteractBehaviour:SetupTrigger(callback, tile)
    if Utils.IsNull(self.p_click_trigger) then
        return
    end
    ---@type CityTrigger
    local trigger = self.p_click_trigger.Instance
    if trigger then
        trigger:SetOnTrigger(callback, tile, true)
    end
end

function CityTileAssetNpcBubbleInteractBehaviour:ShowCreep()
    self.p_icon_creep:SetVisible(true)
    self.p_icon_creep:SetVisible(false)
end

function CityTileAssetNpcBubbleInteractBehaviour:ShowDanger()
    self.p_icon_creep:SetVisible(false)
    self.p_icon_creep:SetVisible(true)
end

function CityTileAssetNpcBubbleInteractBehaviour:SetupTalk(str)
    if not string.IsNullOrEmpty(str) then
        self.p_group_talk:SetVisible(true)
        self.p_text_talk.text = str
    end
end

return CityTileAssetNpcBubbleInteractBehaviour