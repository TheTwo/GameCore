---scene: scene_kingdom_construction_mode
local BaseUIMediator = require("BaseUIMediator")
local Delegate = require('Delegate')
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local FlexibleMapBuildingFilterType = require("FlexibleMapBuildingFilterType")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")

---@class KingdomConstructionModeUIMediatorParameter
---@field chooseTab number
---@field chooseType number
---@field chooseCell number

---@class KingdomConstructionModeUIMediator : BaseUIMediator
local KingdomConstructionModeUIMediator = class("KingdomConstructionModeUIMediator", BaseUIMediator)

function KingdomConstructionModeUIMediator:ctor()
    BaseUIMediator.ctor(self)
    self._chooseTab = nil
    self._flexMapBuildingType = nil
    self._firstChooseTab = nil
    self._firstChooseType = nil
    self._firstChooseCell = nil
end

function KingdomConstructionModeUIMediator:OnCreate()
    self._p_hide_root = self:BindComponent("p_hide_root", typeof(CS.UnityEngine.CanvasGroup))
    self._p_group_toggle = self:GameObject("p_group_toggle")
    self._p_group_table = self:GameObject("p_group_table")
    self._p_title = self:GameObject("p_title")

    self._p_table_toggle = self:TableViewPro("p_table_toggle")
    self._p_table_view = self:TableViewPro("p_table_view");

    --self._p_txt_title = self:Text("p_txt_free_2", "world_build_fangzhi");
    
    self._p_table_tab = self:TableViewPro("p_table_tab")
    self._p_hint = self:GameObject("p_hint")
    self._p_txt_hint = self:Text("p_txt_hint", "alliance_bj_r4quanxian")
end

---@param param KingdomConstructionModeUIMediatorParameter
function KingdomConstructionModeUIMediator:OnOpened(param)
    self._firstChooseTab = nil
    self._firstChooseType = nil
    self._firstChooseCell = nil
    self._firstChooseTab = param and param.chooseTab
    self._firstChooseType = param and param.chooseType
    self._firstChooseCell = param and param.chooseCell
    self:InitToggleButton()
end

function KingdomConstructionModeUIMediator:OnClose(param)
    ModuleRefer.KingdomPlacingModule:EndPlacing()
end

function KingdomConstructionModeUIMediator:InitToggleButton()
    self._p_table_toggle:SetSelectedDataChanged(nil)
    self._p_table_toggle:UnSelectAll()
    self._p_table_toggle:Clear()
    ---@type KingdomConstructionToggleData
    local toggleDataAlliance = {}
    toggleDataAlliance.image = "sp_construction_icon_function"
    toggleDataAlliance.context = FlexibleMapBuildingFilterType.Alliance
    self._p_table_toggle:AppendData(toggleDataAlliance)

    toggleDataAlliance = {}
    toggleDataAlliance.image = "sp_comp_icon_soldier_quantity"
    toggleDataAlliance.context = FlexibleMapBuildingFilterType.Personal
    self._p_table_toggle:AppendData(toggleDataAlliance)
    self._p_table_toggle:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnToggleSelected))
    local chooseTab = self._firstChooseTab or 0
    self._firstChooseTab = nil
    self._p_table_toggle:SetToggleSelectIndex(chooseTab)
end

function KingdomConstructionModeUIMediator:RefreshTabTable()
    self._p_table_tab:SetSelectedDataChanged(nil)
    self._p_table_tab:UnSelectAll()
    self._p_table_tab:Clear()
    self._flexMapBuildingType = nil
    if self._chooseTab == FlexibleMapBuildingFilterType.Alliance then
        ---@type KingdomConstructionModeUITabCellData
        local tabCellData = {}
        tabCellData.buildingType = FlexibleMapBuildingType.EnergyTower
        self._p_table_tab:AppendData(tabCellData)
        tabCellData = {}
        tabCellData.buildingType = FlexibleMapBuildingType.DefenseTower
        self._p_table_tab:AppendData(tabCellData)
        tabCellData = {}
        tabCellData.buildingType = FlexibleMapBuildingType.BehemothDevice
        self._p_table_tab:AppendData(tabCellData)
        tabCellData = {}
        tabCellData.buildingType = FlexibleMapBuildingType.BehemothSummoner
        self._p_table_tab:AppendData(tabCellData)
        self._p_table_tab:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnChooseTabChanged))
        local chooseIndex = 0
        if self._firstChooseType == FlexibleMapBuildingType.DefenseTower then
            chooseIndex = 1
        elseif self._firstChooseType == FlexibleMapBuildingType.BehemothDevice then
            chooseIndex = 2
        elseif self._firstChooseType == FlexibleMapBuildingType.BehemothSummoner then
            chooseIndex = 3
        end
        self._firstChooseType = nil
        self._p_table_tab:SetToggleSelectIndex(chooseIndex)
    elseif self._chooseTab == FlexibleMapBuildingFilterType.Personal then
        --todo 预留给个人的
    end
end

---@param formData KingdomConstructionToggleData
---@param toData KingdomConstructionToggleData
function KingdomConstructionModeUIMediator:OnToggleSelected(formData, toData)
    if self._chooseTab == toData.context then
        return
    end
    self._chooseTab = toData.context
    self:RefreshTabTable()
end

---@param newData KingdomConstructionModeUITabCellData
function KingdomConstructionModeUIMediator:OnChooseTabChanged(oldData, newData)
    if self._flexMapBuildingType == newData then
        return
    end
    self._flexMapBuildingType = newData.buildingType
    self._p_table_view:UnSelectAll()
    self._p_table_view:Clear()
    self._p_table_view:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnSelectCell))
    local buildingList = ModuleRefer.KingdomConstructionModule:GetSortedBuildingList(self._chooseTab, self._flexMapBuildingType)
    local isFirstIsUnlocked = false
    local chooseCellIndex = nil
    if #buildingList > 0 then
        isFirstIsUnlocked = ModuleRefer.AllianceTechModule:IsBuildingTechSatisfy(buildingList[1].Config)
        if isFirstIsUnlocked then
            chooseCellIndex = 0 
        end
        if self._firstChooseCell then
            local c = self._firstChooseCell
            self._firstChooseCell = nil
            for i, v in ipairs(buildingList) do
                if v.Config:Id() == c then
                    chooseCellIndex = i - 1
                    break
                end
            end
        end
    end
    for _, v in ipairs(buildingList) do
        self._p_table_view:AppendData(v)
    end
    if chooseCellIndex then
        self._p_table_view:SetToggleSelectIndex(chooseCellIndex)
    end
end

---@param formData FlexibleMapBuildingUIData
---@param toData FlexibleMapBuildingUIData
function KingdomConstructionModeUIMediator:OnSelectCell(formData, toData)
    if not formData and toData then
        ModuleRefer.KingdomPlacingModule:StartPlacing(toData.Config:Id(), ModuleRefer.KingdomConstructionModule.CanPlace, true)
    elseif formData and not toData then
        ModuleRefer.KingdomPlacingModule:EndPlacing(true)
    elseif formData ~= toData then
        ModuleRefer.KingdomPlacingModule:StartPlacing(toData.Config:Id(), ModuleRefer.KingdomConstructionModule.CanPlace, true)
    end
end

return KingdomConstructionModeUIMediator