local CityCitizenManageUITypeCellDataDefine = require("CityCitizenManageUITypeCellDataDefine")
local Delegate = require("Delegate")
local CityCitizenDefine = require("CityCitizenDefine")

---@class CityCitizenManageUIState
---@field new fun(host:CityCitizenManageUIMediator):CityCitizenManageUIState
local CityCitizenManageUIState = class('CityCitizenManageUIState')

---@param host CityCitizenManageUIMediator
function CityCitizenManageUIState:ctor(host)
    self._host = host
    ---@type CityCitizenManageUITypeCellData[]
    self._citizenTypeData = {}
    ---@type table<CityCitizenManageUITypeCellDataDefine.Type, CityCitizenManageUITypeCellData>
    self._typeDataMap = {}
    self._selectedType = nil
end

function CityCitizenManageUIState:OnShow()
    self:AddEvents()
end

function CityCitizenManageUIState:OnHide()
   self:RemoveEvents() 
end

function CityCitizenManageUIState:AddEvents()
    
end

function CityCitizenManageUIState:RemoveEvents()
    
end

function CityCitizenManageUIState:OnClickClose()
    self._host:CloseSelf()
end

function CityCitizenManageUIState:OnClickTitleResident()
    self._host._p_group_table:SetVisible(true)
    self._host._p_table_vagrant:SetVisible(false)
end

function CityCitizenManageUIState:OnClickTitleVagrant()
    self._host._p_group_table:SetVisible(false)
    self._host._p_table_vagrant:SetVisible(true)
end

function CityCitizenManageUIState:OnClickCheckIn(btnTrans)
    
end

function CityCitizenManageUIState:GenerateTypeTable()
    local onSelected = Delegate.GetOrCreate(self, self.OnSelectType)
    table.clear(self._citizenTypeData)
    table.clear(self._typeDataMap)
    local index = 1
    ---@type CityCitizenManageUITypeCellData
    local dFree = {}
    dFree.id = index
    index = index + 1
    dFree.type = CityCitizenManageUITypeCellDataDefine.Type.Free
    dFree.icon = CityCitizenDefine.WorkTargetToIconNone
    dFree.count = 0
    dFree.onSelected = onSelected
    self._typeDataMap[dFree.type] = dFree
    table.insert(self._citizenTypeData, dFree)

    ---@type CityCitizenManageUITypeCellData
    local d = {}
    d.id = index
    index = index + 1
    d.type = CityCitizenManageUITypeCellDataDefine.Type.Work
    d.icon = CityCitizenDefine.WorkTargetToIconWorking
    d.count = 0
    d.onSelected = onSelected
    self._typeDataMap[d.type] = d
    table.insert(self._citizenTypeData, d)

    self._host._p_table_btn:Clear()
    for _, v in ipairs(self._citizenTypeData) do
        self._host._p_table_btn:AppendData(v)
    end
end

---@param city City
function CityCitizenManageUIState:RefreshTypeTable(city)
    if self._host._city.uid ~= city.uid then
        return
    end
    local mgr = self._host._city.cityCitizenManager
    for _, v in ipairs(self._citizenTypeData) do
        v.count = 0
    end
    for _, citizenData, citizenWork in mgr:pairsCitizenData() do
        local cellType
        if citizenData._workId == 0 then
            cellType = CityCitizenManageUITypeCellDataDefine.Type.Free
        elseif citizenWork then
            cellType = CityCitizenManageUITypeCellDataDefine.Type.Work
        end
        local v = self._typeDataMap[cellType]
        if v then
            v.count = v.count + 1
        end
    end
    self._host._p_table_btn:UnSelectAll()
    self._host._p_table_btn:UpdateOnlyAllDataImmediately()
    if self._selectedType then
        self:OnSelectType(self._selectedType)
    end
end

function CityCitizenManageUIState:OnSelectType(index)
    --- override me!
end

return CityCitizenManageUIState

