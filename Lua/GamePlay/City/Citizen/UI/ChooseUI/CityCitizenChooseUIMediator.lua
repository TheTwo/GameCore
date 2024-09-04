---@sceneName:scene_construction_popup_resident
local Delegate = require("Delegate")
local CityCitizenDefine = require("CityCitizenDefine")
local CityCitizenManageUITypeCellDataDefine = require("CityCitizenManageUITypeCellDataDefine")
local EventConst = require("EventConst")

local BaseUIMediator = require("BaseUIMediator")

---@class CityCitizenChooseUIMediatorParam
---@field citizenMgr CityCitizenManager
---@field onSelected fun(citizenId)
---@field onClosed fun()

---@class CityCitizenChooseUIMediator:BaseUIMediator
---@field new fun():CityCitizenChooseUIMediator
---@field super BaseUIMediator
local CityCitizenChooseUIMediator = class('CityCitizenChooseUIMediator', BaseUIMediator)

function CityCitizenChooseUIMediator:ctor()
    BaseUIMediator.ctor(self)

    ---@type CityCitizenManageUITypeCellData[]
    self._citizenTypeData = {}
    ---@type table<CityCitizenManageUITypeCellDataDefine.Type, CityCitizenManageUITypeCellData>
    self._typeDataMap = {}
    self._selectedType = nil
    
    ---@type CityCitizenChooseTypeCellData[]
    self._typesData = {}

    ---@type CityCitizenManager
    self._citizenMgr = nil
    
    ---@type CityCitizenManageUIDraggableCellData[]
    self._citizens = {}
    
    self._onSelected = nil
    ---@type ZoomToWithFocusStackStatus
    self._cameraStack = nil
end

function CityCitizenChooseUIMediator:OnCreate(_)
    self._p_base_black = self:Image("p_base_black", Delegate.GetOrCreate(self, self.OnClickBlank))
    self._p_text_title = self:Text("p_text_title", "citizen_select")
    self._p_text_number = self:Text("p_text_number")
    self._p_table_btn = self:TableViewPro("p_table_btn")
    self._p_table_detail = self:TableViewPro("p_table_detail")
    self._p_empty = self:GameObject("p_empty")
    self._p_text_no = self:Text("p_text_no", "citizen_blank")
    self._p_empty:SetVisible(false)
end

---@param param CityCitizenChooseUIMediatorParam
function CityCitizenChooseUIMediator:OnOpened(param)
    self._cameraStack = param.citizenMgr.city:GetCamera():RecordCurrentCameraStatus(0.1)
    self._citizenMgr = param.citizenMgr
    self._onSelected = param.onSelected
    self._onClosed = param.onClosed
    self._city = self._citizenMgr.city
    self:GenerateTypeTable()
    self:RefreshTypeTable(self._city)
    self:OnSelectType(self:FindFirstHasMemberType())
end

function CityCitizenChooseUIMediator:OnShow(param)
    BaseUIMediator.OnShow(self, param)
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.RefreshTypeTable))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_REFRESH, Delegate.GetOrCreate(self, self.RefreshTypeTable))
end

function CityCitizenChooseUIMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.RefreshTypeTable))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_REFRESH, Delegate.GetOrCreate(self, self.RefreshTypeTable))
    BaseUIMediator.OnHide(self, param)
end

function CityCitizenChooseUIMediator:OnClose(_)
    if self._cameraStack then
        self._cameraStack:back()
    end
    if self._onClosed then
        self._onClosed()
    end
    self._cameraStack = nil
    self._citizenMgr = nil
    self._onSelected = nil
    self._onClosed = nil
end

function CityCitizenChooseUIMediator:GenerateTypeTable()
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
    local dWork = {}
    dWork.id = index
    index = index + 1
    dWork.type = CityCitizenManageUITypeCellDataDefine.Type.Work
    dWork.icon = CityCitizenDefine.WorkTargetToIconWorking
    dWork.count = 0
    dWork.onSelected = onSelected
    self._typeDataMap[dWork.type] = dWork
    table.insert(self._citizenTypeData, dWork)

    self._p_table_btn:Clear()
    for _, v in ipairs(self._citizenTypeData) do
        self._p_table_btn:AppendData(v)
    end
end

---@param city City
function CityCitizenChooseUIMediator:RefreshTypeTable(city)
    if self._city.uid ~= city.uid then
        return
    end
    self._p_table_btn:UnSelectAll()
    local freeCount = 0
    local totalCount = 0
    local mgr = self._citizenMgr
    for _, v in ipairs(self._citizenTypeData) do
        v.count = 0
    end
    for _,citizenData,citizenWork in mgr:pairsCitizenData() do
        totalCount = totalCount + 1
        local cellType
        if citizenData._workId == 0 then
            freeCount = freeCount + 1
            cellType = CityCitizenManageUITypeCellDataDefine.Type.Free
        elseif citizenWork then
            local _, workTargetType = citizenWork:GetTarget()
            cellType = CityCitizenManageUITypeCellDataDefine.Type.Work
        end
        local v = self._typeDataMap[cellType]
        if v then
            v.count = v.count + 1
        end
    end
    self._p_table_btn:UpdateOnlyAllDataImmediately()
    if self._selectedType then
        self:OnSelectType(self._selectedType)
    end
    self._p_text_number.text = tostring(freeCount) .. '/' .. tostring(totalCount)
end

function CityCitizenChooseUIMediator:FindFirstHasMemberType()
    for i,v in ipairs(self._citizenTypeData) do
        if v.count > 0 then
            return i
        end
    end
    return 1
end

function CityCitizenChooseUIMediator:OnSelectType(index)
    self._selectedType = index
    self._p_table_btn:SetToggleSelectIndex(index - 1)
    self:RefreshTypeCitizenTable()
end

function CityCitizenChooseUIMediator:RefreshTypeCitizenTable()
    if not self._selectedType then
        return
    end
    local onSelected = Delegate.GetOrCreate(self, self.OnChooseCitizen)
    local onReCall = Delegate.GetOrCreate(self, self.OnCellReCall)
    local onRecover = Delegate.GetOrCreate(self, self.OnCellRecover)

    local mgr = self._citizenMgr
    local typ = self._citizenTypeData[self._selectedType].type
    
    table.clear(self._citizens)
    self._p_table_detail:UnSelectAll()
    self._p_table_detail:Clear()
    for _, citizenData, citizenWork in mgr:pairsCitizenData() do
        if citizenWork and typ == CityCitizenManageUITypeCellDataDefine.Type.Work then
            ---@type CityCitizenManageUIDraggableCellData
            local data = {}
            data.citizenData = citizenData
            data.citizenWork = citizenWork
            data.OnSelected = onSelected
            data.OnRecall = onReCall
            table.insert(self._citizens, data)
            self._p_table_detail:AppendData(data)
        elseif not citizenWork and not citizenData:HasWork() then
            if typ ~= CityCitizenManageUITypeCellDataDefine.Type.Free then
                goto continue
            end
            ---@type CityCitizenManageUIDraggableCellData
            local data = {}
            data.citizenData = citizenData
            data.OnSelected = onSelected
            data.OnClickRecover = onRecover
            table.insert(self._citizens, data)
            self._p_table_detail:AppendData(data)
        end
        ::continue::
    end
    if #self._citizens > 0 then
        self._p_empty:SetVisible(false)
    else
        self._p_empty:SetVisible(true)
    end
end

---@param data CityCitizenManageUIDraggableCellData
function CityCitizenChooseUIMediator:OnChooseCitizen(data)
    if data then
        local index = table.indexof(self._citizens, data, 1)
        if index == -1 then
            return
        end
        self._p_table_detail:SetToggleSelectIndex(index - 1)
        if self._onSelected then
            self._onSelected(data.citizenData._id)
        end
    end
end

function CityCitizenChooseUIMediator:OnClickBlank()
    self:CloseSelf()
end

---@param data CityCitizenManageUIDraggableCellData
function CityCitizenChooseUIMediator:OnCellReCall(data)
    if data then
        local index = table.indexof(self._citizens, data, 1)
        if index == -1 then
            return
        end
        if data.citizenData._workId ~= 0 then
            self._citizenMgr:StopWork(data.citizenData._id, self._p_table_detail.transform)
        end
    end
end

---@param data CityCitizenManageUIDraggableCellData
function CityCitizenChooseUIMediator:OnCellRecover(data)
    if data then
        local index = table.indexof(self._citizens, data, 1)
        if index == -1 then
            return
        end
        if data.citizenData:IsReadyForWeakUp() then
            self._citizenMgr:SendRecoverCitizen(data.citizenData._id, self._p_table_detail.transform)
        end
    end
end

return CityCitizenChooseUIMediator