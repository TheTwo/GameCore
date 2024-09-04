local BaseUIComponent = require ('BaseUIComponent')
local LuaMultiTemplateReusedCompPool = require("LuaMultiTemplateReusedCompPool")
local UIHelper = require("UIHelper")
local CityFurnitureOverviewUIUnitType = require("CityFurnitureOverviewUIUnitType")
local CityWorkType = require("CityWorkType")
local EventConst = require('EventConst')
local Delegate = require('Delegate')

---@class CityFurnitureOverviewUIPageOverview:BaseUIComponent
local CityFurnitureOverviewUIPageOverview = class('CityFurnitureOverviewUIPageOverview', BaseUIComponent)

---@class OverviewCache
---@field container CS.UnityEngine.Transform
---@field cacheMap table<number, {data:CityFurnitureOverviewUnitDataBase, cell:CityFurnitureOverviewUIUnit}>

function CityFurnitureOverviewUIPageOverview:OnCreate()
    self._p_content_scrollview = self:Transform("p_content_scrollview")

    self._p_inner_templates = self:Transform("p_inner_templates")
    self._p_item_upgrade = self:LuaObject("p_item_upgrade")
    self._p_item_process = self:LuaObject("p_item_process")
    self._p_item_collect = self:LuaObject("p_item_collect")
    self._p_item_plant = self:LuaObject("p_item_plant")
    self._p_item_soldier = self:LuaObject("p_item_soldier")
    self._p_item_card = self:LuaObject("p_item_card")

    self._p_line_templates = self:Transform("p_line_templates")
    self._p_item_title = self:LuaObject("p_item_title")
    self._p_group = self:GameObject("p_group")
    self._p_group_upgrade_complete = self:TableViewPro("p_group_upgrade_complete")

    self._innerPool = LuaMultiTemplateReusedCompPool.new(self._p_inner_templates)
    self._upgradePool = self._innerPool:GetOrCreateLuaBaseCompPool(self._p_item_upgrade)
    self._processPool = self._innerPool:GetOrCreateLuaBaseCompPool(self._p_item_process)
    self._collectPool = self._innerPool:GetOrCreateLuaBaseCompPool(self._p_item_collect)
    self._producePool = self._innerPool:GetOrCreateLuaBaseCompPool(self._p_item_plant)
    self._soldierPool = self._innerPool:GetOrCreateLuaBaseCompPool(self._p_item_soldier)
    self._cardPool = self._innerPool:GetOrCreateLuaBaseCompPool(self._p_item_card)

    self._innerPoolMap = {
        [CityFurnitureOverviewUIUnitType.p_item_upgrade] = self._upgradePool,
        [CityFurnitureOverviewUIUnitType.p_item_process] = self._processPool,
        [CityFurnitureOverviewUIUnitType.p_item_collect] = self._collectPool,
        [CityFurnitureOverviewUIUnitType.p_item_plant] = self._producePool,
        [CityFurnitureOverviewUIUnitType.p_item_soldier] = self._soldierPool,
        [CityFurnitureOverviewUIUnitType.p_item_card] = self._cardPool,
    }

    self._containerPool = LuaMultiTemplateReusedCompPool.new(self._p_line_templates)
    self._titlePool = self._innerPool:GetOrCreateLuaBaseCompPool(self._p_item_title)
    self._groupPool = self._innerPool:GetOrCreateGameObjPool(self._p_group)
    self._upgradeCompletePool = self._innerPool:GetOrCreateCSPool(self._p_group_upgrade_complete)
end

function CityFurnitureOverviewUIPageOverview:OnClose()
    self._innerPool = nil
    self._containerPool = nil
end

function CityFurnitureOverviewUIPageOverview:OnShow()
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnOverviewPageDirty))
end

function CityFurnitureOverviewUIPageOverview:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnOverviewPageDirty))
end

---@param data {DataList:CityFurnitureOverviewDataGroupBase[], city:City}
function CityFurnitureOverviewUIPageOverview:OnFeedData(data)
    self.data = data

    self._containerPool:HideAllPool()
    self._innerPool:HideAllPool()

    local castleFurnitureMap = data.city:GetCastle().CastleFurniture
    ---@type CityFurnitureOverviewUIMiniUpgradeFinishedCellDatum[]
    local needShowUpgradeComplete = {}
    for id, castleFurniture in pairs(castleFurnitureMap) do
        if castleFurniture.LevelUpInfo.Working and castleFurniture.LevelUpInfo.CurProgress >= castleFurniture.LevelUpInfo.TargetProgress then
            table.insert(needShowUpgradeComplete, {city = data.city, furnitureId = id})
        end
    end
    
    ---@type table<number, OverviewCache>
    self._workType2Cache = {
        [CityWorkType.FurnitureLevelUp] = {},
        [CityWorkType.Process] = {},
        [CityWorkType.FurnitureResCollect] = {},
        [CityWorkType.ResourceGenerate] = {},
        [CityWorkType.MilitiaTrain] = {},
    }

    for i, v in ipairs(data.DataList) do
        local units = v:GetOneLineOverviewData()
        if #units == 0 then goto continue end

        local activeUnitCount = 0
        for i, v in ipairs(units) do
            if not string.IsNullOrEmpty(v:GetPrefabIndex()) then
                activeUnitCount = activeUnitCount + 1
            end
        end

        if activeUnitCount == 0 then
            goto continue
        end

        --- 标题
        local title = v:GetOneLineTitle()
        local titleItem = self._titlePool:Alloc()
        titleItem:FeedData(title)
        UIHelper.SetUIComponentParent(titleItem.CSComponent, self._p_content_scrollview)

        --- 升级节点需要单独处理完成列表的显示
        if v:ShowUpgradeBase() and #needShowUpgradeComplete > 0 then
            table.sort(needShowUpgradeComplete, function(a, b)
                return a.furnitureId < b.furnitureId
            end)
    
            local item = self._upgradeCompletePool:Alloc()
            UIHelper.SetUIComponentParent(item, self._p_content_scrollview)
            item:Clear()
    
            for i, v in ipairs(needShowUpgradeComplete) do
                item:AppendData(v)
            end
        end

        --- 节点外部容器
        local container = self._groupPool:Alloc()
        container.transform:SetParent(self._p_content_scrollview)
        
        for i, v in ipairs(units) do
            --- 节点
            local poolKey = v:GetPrefabIndex()
            if not string.IsNullOrEmpty(poolKey) and self._innerPoolMap[poolKey] then
                local item = self._innerPoolMap[poolKey]:Alloc()
                item:FeedData(v)
                UIHelper.SetUIComponentParent(item.CSComponent, container.transform)

                --- 缓存家具Id和节点的映射
                local furnitureId = v:GetFurnitureId()
                if v:GetWorkType() > 0 and furnitureId > 0 then
                    local map = self._workType2Cache[v:GetWorkType()]
                    map[furnitureId] = {data = v, cell = item}
                end
            end
        end
        ::continue::
    end
end

function CityFurnitureOverviewUIPageOverview:OnFurnitureUpdate(batchEvt)
    if not batchEvt.Change then return end

    if self:OnFurnitureUpdateImp(batchEvt) then
        self:OnFeedData(self.data)
    end
end

function CityFurnitureOverviewUIPageOverview:OnFurnitureUpdateImp(batchEvt)
    local furnitureManager = self.data.city.furnitureManager
    for furnitureId, _ in pairs(batchEvt.Change) do
        local furniture = furnitureManager:GetFurnitureById(furnitureId)
        if not furniture then goto continue end

        for workType, _ in pairs(furniture.functions) do
            if workType == CityWorkType.FurnitureLevelUp then
                local castleFurniture = furniture:GetCastleFurniture()
                if castleFurniture and castleFurniture.LevelUpInfo then
                    if self._workType2Cache[CityWorkType.FurnitureLevelUp]
                        and self._workType2Cache[CityWorkType.FurnitureLevelUp][furnitureId]
                        and castleFurniture.LevelUpInfo.Working
                        and castleFurniture.LevelUpInfo.CurProgress >= castleFurniture.LevelUpInfo.TargetProgress then
                            return true
                    end
                end
            else
                local cacheMap = self._workType2Cache[workType]
                if cacheMap then
                    local cache = cacheMap[furnitureId]
                    local oldHasCache = cache ~= nil
                    local newNeedCache = furniture:CanDoCityWork(workType)
                    if oldHasCache == newNeedCache then
                        if cache then
                            cache.cell:FeedData(cache.data)
                        end
                    else
                        return true
                    end
                end
            end
        end

        ::continue::
    end
    return false
end

function CityFurnitureOverviewUIPageOverview:OnOverviewPageDirty(city, batchEvt)
    if not self.data then return end

    if city ~= self.data.city then return end

    if table.nums(batchEvt.Add) > 0 or table.nums(batchEvt.Remove) > 0 then
        self:OnFeedData(self.data)
    else
        self:OnFurnitureUpdate(batchEvt)
    end
end

return CityFurnitureOverviewUIPageOverview