-- scene:scene_item_resume

local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local UIHelper = require("UIHelper")

local BaseUIMediator = require("BaseUIMediator")

---@class CityItemResumeMediatorQueueItem
---@field itemIcon string
---@field count number
---@field viewPortPos CS.UnityEngine.Vector3

---@class CityItemResumeMediator:BaseUIMediator
---@field new fun():CityItemResumeMediator
---@field super BaseUIMediator
local CityItemResumeMediator = class('CityItemResumeMediator', BaseUIMediator)
CityItemResumeMediator.MaxFrameShowCount = 100

function CityItemResumeMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type CityItemResumeMediatorQueueItem[]
    self._itemQueue = {}
    ---@type CityItemResumeItemCell[]
    self._flyingItem = {}
    self._pool = {}
    ---@type CS.UnityEngine.Camera
    self._uiCamera = nil
end

function CityItemResumeMediator:OnCreate(param)
    self._p_pool = self:Transform("p_pool")
    self._p_template = self:LuaBaseComponent("p_template")
    self._p_flyRoot = self:Transform("p_flyRoot")
    self._p_template:SetVisible(false)
end

function CityItemResumeMediator:OnShow(param)
    self._uiCamera = g_Game.UIManager:GetUICamera()
    g_Game.EventManager:AddListener(EventConst.CITY_SCENE_UI_ITEM_RESUME, Delegate.GetOrCreate(self, self.OnItemResume))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CityItemResumeMediator:OnHide(param)
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SCENE_UI_ITEM_RESUME, Delegate.GetOrCreate(self, self.OnItemResume))
end

---@param itemId number
---@param count number
---@param viewPortPos CS.UnityEngine.Vector3
function CityItemResumeMediator:OnItemResume(itemId, count, viewPortPos)
    if viewPortPos.x <= 0 or viewPortPos.x >= 1 or viewPortPos.y <= 0 or viewPortPos.y >= 1 then return end
    local itemConfig = ConfigRefer.Item:Find(itemId)
    if not itemConfig then
        return
    end
    ---@type CityItemResumeMediatorQueueItem
    local item = {}
    item.itemIcon = itemConfig:Icon()
    item.count = count
    item.viewPortPos = viewPortPos
    table.insert(self._itemQueue, item)
end

function CityItemResumeMediator:Tick(dt)
    for i = #self._flyingItem, 1,-1 do
        local flyingItem = self._flyingItem[i]
        if flyingItem:TickEnd(dt) then
            table.remove(self._flyingItem, i)
            flyingItem:Recycle(self._p_pool)
            table.insert(self._pool, flyingItem)
        end
    end
    local delay = 0.1
    while #self._flyingItem < CityItemResumeMediator.MaxFrameShowCount and #self._itemQueue > 0 do
        local itemData = table.remove(self._itemQueue, 1)
        local flyingItem = self:GetOrCreate(itemData)
        table.insert(self._flyingItem, 1, flyingItem)
        flyingItem:Start(delay)
        delay = delay + 0.1
    end
end

---@param itemData CityItemResumeMediatorQueueItem
---@return CityItemResumeItemCell
function CityItemResumeMediator:GetOrCreate(itemData)
    ---@type CityItemResumeItemCell
    local cell
    if #self._pool <= 0 then
        ---@type CS.DragonReborn.UI.LuaBaseComponent
        local cellComponent = UIHelper.DuplicateUIComponent(self._p_template, self._p_flyRoot)
        cell = cellComponent.Lua
    else
        cell = table.remove(self._pool, 1)
        cell._selfTrans.parent = self._p_flyRoot
    end
    local pos = self._uiCamera:ViewportToWorldPoint(itemData.viewPortPos)
    local localPos = self._p_flyRoot:InverseTransformPoint(pos)
    cell._selfTrans.anchoredPosition = CS.UnityEngine.Vector2(localPos.x, localPos.y)
    cell:FeedData(itemData)
    return cell
end

return CityItemResumeMediator