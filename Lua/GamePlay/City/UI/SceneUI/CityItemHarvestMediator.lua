-- scene:scene_item_harvest

local EventConst = require("EventConst")
local Delegate = require("Delegate")
local UIHelper = require("UIHelper")
local ConfigRefer = require("ConfigRefer")
local AudioConsts = require("AudioConsts")

local BaseUIMediator = require("BaseUIMediator")

---@class CityItemHarvestItemCellData
---@field itemIcon string
---@field addCount number
---@field viewPortPos CS.UnityEngine.Vector3
---@field arriveSoundEffect number|nil

---@class CityItemHarvestMediator:BaseUIMediator
---@field new fun():CityItemHarvestMediator
---@field super BaseUIMediator
local CityItemHarvestMediator = class('CommonItemHarvestMediator', BaseUIMediator)
CityItemHarvestMediator.MaxFrameShowCount = 100
CityItemHarvestMediator.RandomDirBurstLength = 70

function CityItemHarvestMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type CityItemHarvestItemCellData[]
    self._itemQueue = {}
    ---@type CityItemHarvestItemCell[]
    self._flyingItem = {}
    self._pool = {}
    ---@type CS.UnityEngine.Camera
    self._uiCamera = nil
end

function CityItemHarvestMediator:OnCreate(param)
    self._p_pool = self:Transform("p_pool")
    self._p_template = self:LuaBaseComponent("p_template")
    self._p_flyRoot = self:Transform("p_flyRoot")
    self._p_flyTarget = self:RectTransform("p_flyTarget")
end

function CityItemHarvestMediator:OnShow(param)
    self._uiCamera = g_Game.UIManager:GetUICamera()
    g_Game.EventManager:AddListener(EventConst.CITY_SCENE_UI_ITEM_HARVEST, Delegate.GetOrCreate(self, self.OnItemHarvest))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CityItemHarvestMediator:OnHide(param)
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SCENE_UI_ITEM_HARVEST, Delegate.GetOrCreate(self, self.OnItemHarvest))
end

function CityItemHarvestMediator:OnClose()
    for i = #self._flyingItem, 1,-1 do
        local flyingItem = self._flyingItem[i]
        flyingItem:Recycle(self._p_pool)
    end
    self._flyingItem = {}
end

function CityItemHarvestMediator:OnItemHarvest(itemId, count, viewPortPos)
    if viewPortPos.x <= 0 or viewPortPos.x >= 1 or viewPortPos.y <= 0 or viewPortPos.y >= 1 then return end
    local itemConfig = ConfigRefer.Item:Find(itemId)
    if not itemConfig then
        return
    end
    ---@type CityItemHarvestItemCellData
    local item = {}
    item.itemIcon = itemConfig:Icon()
    item.addCount = count
    item.viewPortPos = viewPortPos
    item.arriveSoundEffect = AudioConsts.sfx_ui_crop_inbag
    table.insert(self._itemQueue, item)
end

function CityItemHarvestMediator:Tick(dt)
    for i = #self._flyingItem, 1,-1 do
        local flyingItem = self._flyingItem[i]
        if flyingItem:TickEnd(dt) then
            table.remove(self._flyingItem, i)
            flyingItem:Recycle(self._p_pool)
            table.insert(self._pool, flyingItem)
        end
    end
    if #self._itemQueue <= 0 then
        return
    end
    local targetPos = self._p_flyRoot:InverseTransformPoint(self._p_flyTarget.position)
    local anchoredPos = CS.UnityEngine.Vector2(targetPos.x, targetPos.y)
    local delay = 0.05
    while #self._flyingItem < CityItemHarvestMediator.MaxFrameShowCount and #self._itemQueue > 0 do
        local itemData = table.remove(self._itemQueue, 1)
        local flyingItem = self:GetOrCreate(itemData)
        table.insert(self._flyingItem, 1, flyingItem)
        flyingItem:Start(anchoredPos, CityItemHarvestMediator.RandomDirBurstLength)
        delay = delay + 0.05
    end
end

---@param itemData CityItemHarvestItemCellData
---@return CityItemHarvestItemCell
function CityItemHarvestMediator:GetOrCreate(itemData)
    ---@type CityItemHarvestItemCell
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

return CityItemHarvestMediator