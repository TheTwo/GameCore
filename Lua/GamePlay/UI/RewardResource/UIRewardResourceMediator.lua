---Scene Name : scene_toast_resources
local BaseUIMediator = require ('BaseUIMediator')
local LuaReusedComponentPool = require('LuaReusedComponentPool')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local UIRewardResourceItemData = require("UIRewardResourceItemData")
local KingdomScene = require("KingdomScene")
local ResourcePopDatum = require("ResourcePopDatum")
local RoomScorePopDatum = require("RoomScorePopDatum")

---@class UIRewardResourceMediator:BaseUIMediator
---@field city City
local UIRewardResourceMediator = class('UIRewardResourceMediator', BaseUIMediator)
local delay = 0.45

function UIRewardResourceMediator:OnCreate()
    self.transform = self:Transform("")
    self._p_node = self:LuaBaseComponent("p_node")
    self._pool = LuaReusedComponentPool.new(self._p_node, self.transform)
end

---@param param {city:City, datum:ResourcePopDatum|RoomScorePopDatum}
function UIRewardResourceMediator:OnOpened(param)
    self.param = param
    self.city = param.city
    self._pool:HideAll()
    ---@type table<UIRewardResourceItemData, UIRewardResourceItemData>
    self.toShowMap = {}

    if self.param.datum then
        self:OnItemPopup(self.param.datum)
    end

    g_Game.EventManager:AddListener(EventConst.UI_REWARD_RESOURCE_POPUP, Delegate.GetOrCreate(self, self.OnItemPopup))
end

function UIRewardResourceMediator:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.UI_REWARD_RESOURCE_POPUP, Delegate.GetOrCreate(self, self.OnItemPopup))
    self:TryRemoveTicker()
end

---@param datum ResourcePopDatum|RoomScorePopDatum
function UIRewardResourceMediator:OnItemPopup(datum)
    if not g_Game.SceneManager.current then return end
    if g_Game.SceneManager.current:GetName() ~= KingdomScene.Name then return end

    local maxDelay = self:GetMaxDelay()
    if datum:is(ResourcePopDatum) then
        local info = UIRewardResourceItemData.new(datum, self, maxDelay)
        self:DefaultPositionGetter(info, datum.x, datum.y)
        self.toShowMap[info] = info
    elseif datum:is(RoomScorePopDatum) then
        local info = UIRewardResourceItemData.new(datum, self, maxDelay)
        self:DefaultPositionGetter(info, datum.x, datum.y)
        self.toShowMap[info] = info
    else
        g_Logger.ErrorChannel("UIRewardResourceMediator", "OnItemPopup datum is not ResourcePopDatum or RoomScorePopDatum")
    end

    self:TryAddTicker()
    self:OnTick(0)
end

function UIRewardResourceMediator:GetMaxDelay()
    if next(self.toShowMap) then return 0 end

    local maxDelay = 0
    for info, _ in pairs(self.toShowMap) do
        if info.delay > maxDelay then
            maxDelay = info.delay
        end
    end
    return maxDelay + delay
end

function UIRewardResourceMediator:TryAddTicker()
    if self.added then return end
    self.added = true
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function UIRewardResourceMediator:TryRemoveTicker()
    if not self.added then return end
    self.added = nil
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function UIRewardResourceMediator:OnTick(delta)
    for info, _ in pairs(self.toShowMap) do
        info.delay = info.delay - delta
        if info.delay <= 0 then
            self.toShowMap[info] = nil
            
            if self:CanShowItem() then
                local item = self._pool:GetItem()
                item:FeedData(info)
            end
        end
    end

    if next(self.toShowMap) == nil then
        self:TryRemoveTicker()
    end
end

---@param info UIRewardResourceItemData
function UIRewardResourceMediator:DefaultPositionGetter(info, x, y)
    local scene = g_Game.SceneManager.current
    if scene and scene.IsInCity and scene:IsInCity() then
        local worldPos = self.city:GetWorldPositionFromCoord(x, y)
        info:SetFixedWorldPos(worldPos)
    else
        info:SetFixedViewportPos(0.5, 0.5)
    end
end

function UIRewardResourceMediator:CanShowItem()
    return self.city and self.city.showed and not g_Game.UIManager:HaveCullSceneUIMediator()
end

return UIRewardResourceMediator