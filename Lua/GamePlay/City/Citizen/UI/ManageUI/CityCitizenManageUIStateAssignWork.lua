local CityCitizenManageUIState = require("CityCitizenManageUIState")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local CityCitizenDefine = require("CityCitizenDefine")
local CityConst = require("CityConst")
local CityCitizenManageUITypeCellDataDefine = require("CityCitizenManageUITypeCellDataDefine")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")

---@class CityCitizenManageUIStateAssignWork:CityCitizenManageUIState
---@field new fun(host:CityCitizenManageUIMediator):CityCitizenManageUIStateAssignWork
---@field super CityCitizenManageUIState
local CityCitizenManageUIStateAssignWork = class('CityCitizenManageUIStateAssignWork', CityCitizenManageUIState)

function CityCitizenManageUIStateAssignWork:ctor(host)
    CityCitizenManageUIState.ctor(self, host)

    ---@type CityCitizenManageUITypeCellData[]
    self._citizenTypeData = {}
    ---@type table<CityCitizenManageUITypeCellDataDefine.Type, CityCitizenManageUITypeCellData>
    self._typeDataMap = {}
    self._selectedType = nil

    ---@type CityCitizenManageUIDraggableCellData[]
    self._citizenData = {}
end

function CityCitizenManageUIStateAssignWork:OnShow()
    CityCitizenManageUIState.OnShow(self)

    self._host:PushCameraStatus()

    self._host._p_line_root:SetVisible(false)
    
    self:GenerateTypeTable()
    self:OnClickTitleResident()
    self:RefreshTypeTable(self._host._city)
    self:OnSelectType(self:FindFirstHasMemberType())
    ---@type CS.DragonReborn.UI.UIMediatorType
    local t = CS.DragonReborn.UI.UIMediatorType
    g_Game.UIManager:SetBlockUIRootType(t.SceneUI, false)
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allRight, false)
end


function CityCitizenManageUIStateAssignWork:FindFirstHasMemberType()
    for i,v in ipairs(self._citizenTypeData) do
        if v.count > 0 then
            return i
        end
    end
    return 1
end

function CityCitizenManageUIStateAssignWork:OnHide()
    ---@type CS.DragonReborn.UI.UIMediatorType
    local t = CS.DragonReborn.UI.UIMediatorType
    g_Game.UIManager:SetBlockUIRootType(t.SceneUI, true)
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allRight, true)
    self._host:PopCameraStatus()
    CityCitizenManageUIState.OnHide(self)
end

function CityCitizenManageUIStateAssignWork:AddEvents()
    CityCitizenManageUIState.AddEvents(self)
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.RefreshTypeTable))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_REFRESH, Delegate.GetOrCreate(self, self.RefreshTypeTable))
end

function CityCitizenManageUIStateAssignWork:RemoveEvents()
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_REFRESH, Delegate.GetOrCreate(self, self.RefreshTypeTable))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.RefreshTypeTable))
    CityCitizenManageUIState.RemoveEvents(self)
end

function CityCitizenManageUIStateAssignWork:OnSelectType(index)
    self._selectedType = index
    self._host._p_table_btn:SetToggleSelectIndex(index - 1)
    self:RefreshTypeCitizenTable()
end

function CityCitizenManageUIStateAssignWork:RefreshTypeCitizenTable()
    if not self._selectedType then
        return
    end
    self._host._p_table_detail:UnSelectAll()
    
    local onSelected = Delegate.GetOrCreate(self, self.OnCellSelected)
    local onRecall = Delegate.GetOrCreate(self, self.OnCellReCall)
    local onClickRecover = Delegate.GetOrCreate(self, self.OnClickRecover)
    
    local mgr = self._host._city.cityCitizenManager
    local typ = self._citizenTypeData[self._selectedType].type
    self._selectedCitizenIndex = nil
    table.clear(self._citizenData)
    
    self._host._p_table_detail:Clear()
    for _, citizenData, citizenWork in mgr:pairsCitizenData() do
        if citizenWork and typ == CityCitizenManageUITypeCellDataDefine.Type.Work then
            ---@type CityCitizenManageUIDraggableCellData
            local data = {}
            data.citizenData = citizenData
            data.citizenWork = citizenWork
            data.OnSelected = onSelected
            data.OnRecall = onRecall
            data.OnClickRecover = onClickRecover
            table.insert(self._citizenData, data)
            self._host._p_table_detail:AppendData(data)
        elseif not citizenWork and not citizenData:HasWork() then
            if typ ~= CityCitizenManageUITypeCellDataDefine.Type.Free then
                goto continue
            end
            ---@type CityCitizenManageUIDraggableCellData
            local data = {}
            data.citizenData = citizenData
            data.OnSelected = onSelected
            data.OnRecall = onRecall
            data.OnClickRecover = onClickRecover
            table.insert(self._citizenData, data)
            self._host._p_table_detail:AppendData(data)
        end
        ::continue::
    end
    self._host:SetTableShowNoCitizens(#self._citizenData <= 0)
end

---@param data CityCitizenManageUIDraggableCellData
function CityCitizenManageUIStateAssignWork:OnCellSelected(data)
    if not data then
        return
    end
    local index = table.indexof(self._citizenData, data, 1)
    if index == -1 then
        return
    end
    if data.citizenData:IsFainting() then
        local healthStatus = data.citizenData:GetHealthStatusLocal()
        if healthStatus == CityCitizenDefine.HealthStatus.FaintingReadyWakeUp then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("citizen_coma_tips_1"))
        else
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("citizen_coma_tips_2"))
        end
        return
    end
    self._host._p_table_detail:UnSelectAll()
    self._host._p_table_detail:SetToggleSelectIndex(index - 1)
    if data.citizenData._workId ~= 0 then
        --self._host._city.cityCitizenManager:StopWork(data.citizenData._id)
        self._host:FocusOnCitizen(data.citizenData._id, false)
        return
    end
    self._host._city.cityCitizenManager:StartWork(data.citizenData._id, self._host._param.targetId, self._host._param.targetType)
    self._host:CloseSelf()
end

---@param data CityCitizenManageUIDraggableCellData
function CityCitizenManageUIStateAssignWork:OnCellReCall(data)
    if data then
        local index = table.indexof(self._citizenData, data, 1)
        if index == -1 then
            return
        end
        if data.citizenData._workId ~= 0 then
            self._host._city.cityCitizenManager:StopWork(data.citizenData._id)
        end
    end
end

---@param data CityCitizenManageUIDraggableCellData
function CityCitizenManageUIStateAssignWork:OnClickRecover(data)
    if data then
        local index = table.indexof(self._citizenData, data, 1)
        if index == -1 then
            return
        end
        if data.citizenData:IsReadyForWeakUp() then
            self._host._city.cityCitizenManager:SendRecoverCitizen(data.citizenData._id)
        end
    end
end

return CityCitizenManageUIStateAssignWork

