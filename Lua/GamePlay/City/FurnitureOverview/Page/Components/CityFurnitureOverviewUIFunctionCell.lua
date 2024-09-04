local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class CityFurnitureOverviewUIFunctionCell:BaseTableViewProCell
local CityFurnitureOverviewUIFunctionCell = class('CityFurnitureOverviewUIFunctionCell', BaseTableViewProCell)
local CityFurnitureOverviewUIUnitType = require("CityFurnitureOverviewUIUnitType")
local CityFurnitureOverviewDataGroup_LevelUp = require("CityFurnitureOverviewDataGroup_LevelUp")
local CityFurnitureOverviewUnitData_LevelUp = require("CityFurnitureOverviewUnitData_LevelUp")
local UIHelper = require("UIHelper")
local Utils = require("Utils")

function CityFurnitureOverviewUIFunctionCell:OnCreate()
    self._p_base_upgrade = self:GameObject("p_base_upgrade")

    self._p_text_title = self:Text("p_text_title")
    self._p_group = self:Transform("p_group")

    --- 组件列表
    ---@type table<number, BaseUIComponent>
    self._components = {}
    ---@type CityFurnitureOverviewUIUnitUpgrade
    self._p_item_upgrade = self:LuaObject("p_item_upgrade")
    self._p_item_upgrade:SetVisible(false)
    ---@type CityFurnitureOverviewUIUnitProcess
    self._p_item_process = self:LuaObject("p_item_process")
    self._p_item_process:SetVisible(false)
    ---@type CityFurnitureOverviewUIUnitCollect
    self._p_item_collect = self:LuaObject("p_item_collect")
    self._p_item_collect:SetVisible(false)
    ---@type CityFurnitureOverviewUIUnitProduce
    self._p_item_plant = self:LuaObject("p_item_plant")
    self._p_item_plant:SetVisible(false)
    ---@type CityFurnitureOverviewUIUnitMilitaryTrain
    self._p_item_soldier = self:LuaObject("p_item_soldier")
    self._p_item_soldier:SetVisible(false)
    ---@type CityFurnitureOverviewUIUnitCard
    self._p_item_card = self:LuaObject("p_item_card")
    self._p_item_card:SetVisible(false)

    self._components[CityFurnitureOverviewUIUnitType.p_item_upgrade] = self._p_item_upgrade
    self._components[CityFurnitureOverviewUIUnitType.p_item_process] = self._p_item_process
    self._components[CityFurnitureOverviewUIUnitType.p_item_collect] = self._p_item_collect
    self._components[CityFurnitureOverviewUIUnitType.p_item_plant] = self._p_item_plant
    self._components[CityFurnitureOverviewUIUnitType.p_item_soldier] = self._p_item_soldier
    self._components[CityFurnitureOverviewUIUnitType.p_item_card] = self._p_item_card

    ---@see CityFurnitureOverviewUIUnitUpgrade
    self._p_group_upgrade_complete = self:TableViewPro("p_group_upgrade_complete")

    ---@type BaseUIComponent[]
    self._instances = {}
end

---@param data CityFurnitureOverviewDataGroupBase
function CityFurnitureOverviewUIFunctionCell:OnFeedData(data)
    self.data = data
    self._p_base_upgrade:SetActive(data:ShowUpgradeBase())
    self._p_text_title.text = data:GetOneLineTitle()

    for _, v in ipairs(self._instances) do
        UIHelper.DeleteUIComponent(v.CSComponent)
    end
    self._p_group_upgrade_complete:Clear()
    self._instances = {}
    
    local isUpgrade = self.data:is(CityFurnitureOverviewDataGroup_LevelUp)
    if isUpgrade then
        self:OnFeedDataUpgrade()
    else
        self:OnFeedDataNormal()
    end
end

function CityFurnitureOverviewUIFunctionCell:OnFeedDataUpgrade()
    local units = self.data:GetOneLineOverviewData()
    local smallCells, normalCells = {}, {}
    for i, v in ipairs(units) do
        if v:is(CityFurnitureOverviewUnitData_LevelUp) and v:IsFinished() then
            table.insert(smallCells, v)
        else
            table.insert(normalCells, v)
        end
    end

    self._p_group_upgrade_complete:SetVisible(#smallCells > 0)
    if #smallCells > 0 then
        self._p_group_upgrade_complete:Clear()
        for _, v in ipairs(smallCells) do
            self._p_group_upgrade_complete:AppendData(v)
        end
    end

    self._p_group:SetVisible(#normalCells > 0)
    if #normalCells > 0 then
        for _, v in ipairs(normalCells) do
            local prefabIndex = v:GetPrefabIndex()
            if not string.IsNullOrEmpty(prefabIndex) and self._components[prefabIndex] ~= nil then
                local inst = UIHelper.DuplicateUIComponent(self._components[prefabIndex].CSComponent)
                if Utils.IsNotNull(inst) then
                    inst:SetVisible(true)
                    inst:FeedData(v)
                    table.insert(self._instances, inst.LogicObject)
                end
            end
        end
    end
end

function CityFurnitureOverviewUIFunctionCell:OnFeedDataNormal()
    self._p_group:SetVisible(true)
    self._p_group_upgrade_complete:SetVisible(false)
    local units = self.data:GetOneLineOverviewData()
    for i, v in ipairs(units) do
        local prefabIndex = v:GetPrefabIndex()
        if not string.IsNullOrEmpty(prefabIndex) and self._components[prefabIndex] ~= nil then
            local inst = UIHelper.DuplicateUIComponent(self._components[prefabIndex].CSComponent)
            if Utils.IsNotNull(inst) then
                inst:SetVisible(true)
                inst:FeedData(v)
                table.insert(self._instances, inst.LogicObject)
            end
        end
    end
end

return CityFurnitureOverviewUIFunctionCell