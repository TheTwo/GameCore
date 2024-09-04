--- scene:scene_league_behemoth_list

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local AllianceBehemoth = require("AllianceBehemoth")
local SlgTouchMenuHelper = require("SlgTouchMenuHelper")
local AllianceBehemothListOperationProvider = require("AllianceBehemothListOperationProvider")
local Utils = require("Utils")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceBehemothListMediatorParameter
---@field chooseEntityId number

---@class AllianceBehemothListMediator:BaseUIMediator
---@field new fun():AllianceBehemothListMediator
---@field super BaseUIMediator
local AllianceBehemothListMediator = class('AllianceBehemothListMediator', BaseUIMediator)

function AllianceBehemothListMediator:ctor()
    AllianceBehemothListMediator.super.ctor(self)
    ---@type AllianceBehemothListCellData[]
    self._cellsData = {}
    ---@type AllianceBehemothListOperationProvider
    self._operator = nil
    self._delayMark = {}
    ---@type table<string, {name:string, go:CS.UnityEngine.GameObject, handle:CS.DragonReborn.UI.UIHelper.CallbackHolder, visible:boolean}>
    self._bgContent = {}
    self._bgContent["child_behemoth_lion"] = {name = "child_behemoth_lion"}
    self._bgContent["child_behemoth_turtle"] = {name = "child_behemoth_turtle"}
end

function AllianceBehemothListMediator:OnCreate(param)
    self._p_base_content = self:GameObject("p_base_content")
    ---@type AllianceBehemothInfoComponent
    self._child_league_behemoth_info = self:LuaObject("child_league_behemoth_info")
    self._p_table_behemoth = self:TableViewPro("p_table_behemoth")
    self._p_power = self:GameObject("p_power")
    self._p_text_power_1 = self:Text("p_text_power_1")
    self._p_now_control_1 = self:GameObject("p_now_control_1")
    self._p_text_now_control = self:Text("p_text_now_control", "alliance_behemoth_attend_tip1")

    ---@see CommonBackButtonComponent
    self._child_common_btn_back = self:LuaBaseComponent("child_common_btn_back")
end

---@param param AllianceBehemothListMediatorParameter|nil
function AllianceBehemothListMediator:OnOpened(param)
    ---@type CommonBackButtonData
    local backBtnData = {}
    backBtnData.title = I18N.Get("alliance_behemoth_button_list")
    self._child_common_btn_back:FeedData(backBtnData)
    self._operator = AllianceBehemothListOperationProvider.new()
    self:GenerateTableCells(param and param.chooseEntityId)
end

function AllianceBehemothListMediator:OnClose()
    for _, value in pairs(self._bgContent) do
        if value.handle then
            value.handle:AbortAndCleanup()
        end
    end
    table.clear(self._bgContent)
end

---@param a AllianceBehemothListCellData
---@param b AllianceBehemothListCellData
function AllianceBehemothListMediator.SortCells(a, b)
    if a.isInUsing and not b.isInUsing then
        return true
    end
    if not a.isInUsing and not b.isInUsing then
        local l = a.monsterConfig:Level() - b.monsterConfig:Level()
        if l > 0 then
            return true
        end
        if l < 0 then
            return false
        end
    end
    return a.monsterConfig:Id() < b.monsterConfig:Id()
end

function AllianceBehemothListMediator:GenerateTableCells(chooseId)
    table.clear(self._cellsData)
    self._p_table_behemoth:Clear()
    local currentLevel = ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceLevel()
    local currentBehemoth = ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth()
    local ownBehemoths = {}
    for _, v in ModuleRefer.AllianceModule.Behemoth:PairsOfBehemoths() do
        ownBehemoths[v:GetBehemothGroupId()] = true
        ---@type AllianceBehemothListCellData
        local cellData = {}
        cellData.ownedData = v
        cellData.isInUsing = currentBehemoth == v
        cellData.host = self
        if cellData.isInUsing and currentLevel then
            cellData.monsterConfig = v:GetRefKMonsterDataConfig(currentLevel)
        else
            cellData.monsterConfig = v:GetRefKMonsterDataConfig(1)
        end
        table.insert(self._cellsData, cellData)
    end
    for _, v in ipairs(ModuleRefer.AllianceModule.Behemoth.BehemothDummyAllList) do
        if not ownBehemoths[v:GetBehemothGroupId()] then
            ---@type AllianceBehemothListCellData
            local cellData = {}
            cellData.ownedData = v
            cellData.monsterConfig = v:GetRefKMonsterDataConfig(1)
            table.insert(self._cellsData, cellData)
        end
    end
    table.sort(self._cellsData, AllianceBehemothListMediator.SortCells)
    local chooseInUsing = nil
    local chooseByRequest = nil
    for i, v in ipairs(self._cellsData) do
        if chooseId then
            if chooseId == v.ownedData:GetBuildingEntityId() then
                chooseByRequest = i - 1
            end
        end
        if v.isInUsing then
            chooseInUsing = i - 1
        end
        self._p_table_behemoth:AppendData(v)
    end
    self._p_table_behemoth:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnCellSelectedChanged))
    if chooseByRequest then
        self._p_table_behemoth:SetToggleSelectIndex(chooseByRequest)
        self._p_table_behemoth:SetDataFocus(chooseByRequest, 0, CS.TableViewPro.MoveSpeed.Fast)
    elseif chooseInUsing then
        self._p_table_behemoth:SetToggleSelectIndex(chooseInUsing)
        self._p_table_behemoth:SetDataFocus(chooseInUsing, 0, CS.TableViewPro.MoveSpeed.Fast)
    elseif #self._cellsData > 0 then
        self._p_table_behemoth:SetToggleSelectIndex(0)
    end
end

function AllianceBehemothListMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_BEHEMOTH_DEVICE_UPDATE, Delegate.GetOrCreate(self, self.OnBehemothDeviceUpdate))
end

function AllianceBehemothListMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BEHEMOTH_DEVICE_UPDATE, Delegate.GetOrCreate(self, self.OnBehemothDeviceUpdate))
    for _, v in pairs(self._delayMark) do
        ModuleRefer.AllianceModule.Behemoth:MarkBehemothNotify(v)
    end
end

---@param newData AllianceBehemothListCellData
function AllianceBehemothListMediator:OnCellSelectedChanged(oldData, newData)
    if not newData then
        self._child_league_behemoth_info:SetVisible(false)
        self._p_base_content:SetVisible(false)
        self._p_power:SetVisible(false)
        self._p_now_control_1:SetVisible(false)
    elseif oldData ~= newData then
        self._child_league_behemoth_info:SetVisible(true)
        ---@type AllianceBehemothInfoComponentData
        local data = {}
        data.behemothInfo = newData.ownedData
        data.operationProvider = self._operator
        self._child_league_behemoth_info:FeedData(data)
        self._p_base_content:SetVisible(true)
        local isturtle = data.behemothInfo:GetBehemothGroupId() == 1000
        ---@type {name:string, go:CS.UnityEngine.GameObject, handle:CS.DragonReborn.UI.UIHelper.CallbackHolder, visible:boolean}
        local info
        if isturtle then
            info = self._bgContent["child_behemoth_turtle"]
        else
            info = self._bgContent["child_behemoth_lion"]
        end
        info.visible = true
        if Utils.IsNotNull(info.go) then
            info.go:SetVisible(true)
        elseif not info.handle then
            info.handle = CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, info.name,self._p_base_content.name, function(go, success) 
                info.go = go
                if Utils.IsNotNull(info.go) then
                    info.go:SetVisible(info.visible)
                end
            end)
        end
        for _, value in pairs(self._bgContent) do
            if value ~= info then
                value.visible = false
                if Utils.IsNotNull(value.go) then
                    value.go:SetVisible(false)
                end
            end
        end
        self._p_power:SetVisible(true)
        local inUsing = newData.isInUsing
        local monsterConfig = data.behemothInfo:GetRefKMonsterDataConfig(((data.behemothInfo:IsFake() or not inUsing) and 1) or  ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceLevel())
        self._p_text_power_1.text = tostring(monsterConfig:RecommendPower())
        if inUsing then
            self._p_now_control_1:SetVisible(true)
        else
            self._p_now_control_1:SetVisible(false)
        end
    end
end

function AllianceBehemothListMediator:OnLeaveAlliance()
    self:CloseSelf()
end

function AllianceBehemothListMediator:OnBehemothDeviceUpdate(buildingId)
    local currentLevel = ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceLevel()
    local currentBehemoth = ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth()
    for _, v in ipairs(self._cellsData) do
       v.isInUsing = v.ownedData == currentBehemoth
        if v.isInUsing and currentLevel then
            v.monsterConfig = v.ownedData:GetRefKMonsterDataConfig(currentLevel)
        else
            v.monsterConfig = v.ownedData:GetRefKMonsterDataConfig(1)
        end
    end
    self._p_table_behemoth:UpdateOnlyAllDataImmediately()
    self._child_league_behemoth_info:RefreshBehemoth()
    self._child_league_behemoth_info:RefreshOperation()
end

---@param behemoth AllianceBehemoth
function AllianceBehemothListMediator:DelayRemoveNotifyMarkBehemoth(behemoth)
    self._delayMark[behemoth] = behemoth
end

return AllianceBehemothListMediator