---@class City3DBubbleHeroRescue
---@field behaviour CS.DragonReborn.LuaBehaviour
---@field new fun():City3DBubbleHeroRescue
---@field transform CS.UnityEngine.Transform
---@field p_base_lock CS.UnityEngine.GameObject
---@field p_base_unlock CS.UnityEngine.GameObject
---@field p_icon_check CS.UnityEngine.GameObject
---@field p_bubble CS.UnityEngine.Collider
---@field trigger CS.DragonReborn.LuaBehaviour
---@field cityTrigger CityTrigger
---@field p_icon_item CS.U2DSpriteMesh
---@field p_icon_item_unlock CS.U2DSpriteMesh
local City3DBubbleHeroRescue = class("City3DBubbleHeroRescue")

function City3DBubbleHeroRescue:Awake()
    self.enableTrigger = self.p_bubble.enabled
    self.cityTrigger = self.trigger.Instance
    self.unlock = nil
end

function City3DBubbleHeroRescue:Reset()
    self:ClearTrigger()
    self:EnableTrigger(true)
    self:ShowBubbleCheckImg(false)
end

function City3DBubbleHeroRescue:ShowBubble(icon)
    g_Game.SpriteManager:LoadSpriteAsync(icon, self.p_icon_item)
    g_Game.SpriteManager:LoadSpriteAsync(icon, self.p_icon_item_unlock)
end

function City3DBubbleHeroRescue:ShowBubbleCheckImg(flag)
    if self.unlock ~= flag then
        self.unlock = flag
        self.p_base_lock:SetActive(not self.unlock)
        self.p_base_unlock:SetActive(self.unlock)
        self.p_icon_check:SetActive(self.unlock)
    end
    return self
end

function City3DBubbleHeroRescue:EnableTrigger(flag)
    if self.enableTrigger ~= flag then
        self.enableTrigger = flag
        self.p_bubble.enabled = flag
    end
    return self
end

function City3DBubbleHeroRescue:PlayLoopAni()
    --- wait vx
end

function City3DBubbleHeroRescue:SetOnTrigger(callback, tile)
    self.callback = callback
    self.cityTrigger:SetOnTrigger(callback, tile, true)
    return self
end

function City3DBubbleHeroRescue:ClearTrigger()
    if self.callback ~= nil then
        self.cityTrigger:SetOnTrigger(nil, nil, false)
        self.callback = nil
    end
    return self
end

return City3DBubbleHeroRescue