---prefabName:ui3d_bubble_need
---@class City3DBubbleNeed
---@field behaviour CS.DragonReborn.LuaBehaviour
---@field transform CS.UnityEngine.Transform
---@field p_rotation CS.UnityEngine.Transform
---@field p_position CS.UnityEngine.Transform
---@field p_danger CS.UnityEngine.GameObject
---@field p_grid CS.U2D.U2DGrid
---@field p_icon_resource_tmplate CS.UnityEngine.GameObject
---@field vx_trigger CS.FpAnimation.FpAnimationCommonTrigger
---@field activeItems City3DBubbleNeedItem[]
local City3DBubbleNeed = class("City3DBubbleNeed")
local LuaReusedComponentPool = require("LuaReusedComponentPool")

function City3DBubbleNeed:Awake()
    self.pool = LuaReusedComponentPool.new(self.p_icon_resource_tmplate, self.p_grid.transform)
    self.activeItems = {}
    self.showDanger = false
end

function City3DBubbleNeed:Reset()
    self:ResetActiveItems()
    self:ResetDangerImg()
    self:ResetAnim()
    self.pool:HideAll()
    self.p_grid.enabled = true
    return self
end

---@private
function City3DBubbleNeed:ResetActiveItems()
    for i, v in ipairs(self.activeItems) do
        v:ClearTrigger()
    end
    table.clear(self.activeItems)
end

---@param icon string
---@param text string|nil
---@param showCheck boolean|nil
---@param userdata any
function City3DBubbleNeed:AppendCustom(icon, text, showCheck, userdata)
    ---@type CS.UnityEngine.GameObject
    local item = self.pool:GetItem()
    ---@type City3DBubbleNeedItem
    local bubbleItem = item:GetLuaBehaviour("City3DBubbleNeedItem").Instance
    bubbleItem:UpdateUI(icon, text, showCheck, userdata)
    table.insert(self.activeItems, bubbleItem)
    
    if self.callback or self.tile then
        bubbleItem:SetOnTrigger(self.callback, self.tile)
    end
    self.p_grid.enabled = true
    return self
end

function City3DBubbleNeed:UpdateCustom(index, icon, text, showCheck, userdata)
    if index > #self.activeItems or index <= 0 then
        g_Logger.Error("index out of range in City3DBubbleNeed:UpdateCustom")
        return
    end
    local item = self.activeItems[index]
    item:UpdateUI(icon, text, showCheck, userdata)
    return self
end

---@param callback fun(index:number, item:City3DBubbleNeedItem, userdata:any):boolean
---@param tile CityTileBase
function City3DBubbleNeed:SetOnTrigger(callback, tile)
    local wrap = function(trigger)
        local item = trigger.behaviour.gameObject:GetLuaBehaviour("City3DBubbleNeedItem").Instance
        local index = table.indexof(self.activeItems, item, 1)
        return callback(index, item, item.userdata)
    end
    for i = 1, #self.activeItems do
        self.activeItems[i]:SetOnTrigger(wrap, tile)
    end
    self.callback = wrap
    self.tile = tile
    return self
end

function City3DBubbleNeed:ClearTrigger()
    for i = 1, #self.activeItems do
        self.activeItems[i]:ClearTrigger()
    end
    self.callback = nil
    self.tile = nil
end

---@private
function City3DBubbleNeed:ResetDangerImg()
    self:ShowDangerImg(false)
end

function City3DBubbleNeed:ShowDangerImg(flag)
    if self.showDanger ~= flag then
        self.showDanger = flag
        self.p_danger:SetActive(flag)
    end
    return self
end

function City3DBubbleNeed:PlayInAnim()
    self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

function City3DBubbleNeed:PlayOutAnim()
    self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
end

function City3DBubbleNeed:PlayLoopAnim()
    self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
end

function City3DBubbleNeed:ResetAnim()
    self.vx_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom4)
end

return City3DBubbleNeed