---@class City3DBubbleNeedItem
---@field behaviour CS.DragonReborn.LuaBehaviour
---@field new fun():City3DBubbleNeedItem
---@field p_icon_resource CS.U2DSpriteMesh
---@field trigger CityTrigger
---@field p_text_quantity CS.U2DTextMesh
---@field p_icon_check CS.UnityEngine.GameObject
local City3DBubbleNeedItem = class("City3DBubbleNeedItem")

---@private
function City3DBubbleNeedItem:Awake()
    self.trigger = self.behaviour.gameObject:GetLuaBehaviour("CityTrigger").Instance
end

---@param icon string
---@param text string|nil
---@param showCheck boolean|nil
---@param userdata any
function City3DBubbleNeedItem:UpdateUI(icon, text, showCheck, userdata)
    g_Game.SpriteManager:LoadSpriteAsync(icon, self.p_icon_resource)
    local showText = type(text) == "string"
    self.p_text_quantity:SetVisible(showText)
    if showText then
        self.p_text_quantity.text = text
    end
    self.p_icon_check:SetActive(showCheck == true)
    self.userdata = userdata
end

---@param callback fun(trigger:CityTrigger):boolean
---@param tile CityTileBase
function City3DBubbleNeedItem:SetOnTrigger(callback, tile)
    self.trigger:SetOnTrigger(callback, tile, true)
end

function City3DBubbleNeedItem:ClearTrigger()
    self.trigger:SetOnTrigger(nil, nil, false)
end

return City3DBubbleNeedItem