local Delegate = require("Delegate")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local CityCitizenDefine = require("CityCitizenDefine")
local EventConst = require("EventConst")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")

local CityCitizenManageUIState = require("CityCitizenManageUIState")

---@class CityCitizenManageUIStateAssignHouse:CityCitizenManageUIState
---@field new fun(host:CityCitizenManageUIMediator):CityCitizenManageUIStateAssignHouse
---@field super CityCitizenManageUIState
local CityCitizenManageUIStateAssignHouse = class('CityCitizenManageUIStateAssignHouse', CityCitizenManageUIState)

function CityCitizenManageUIStateAssignHouse:ctor(host)
    CityCitizenManageUIState.ctor(self, host)
    
    ---@type CityCitizenManageUIDraggableCellData[]
    self._homelessCitizen = {}
    self._selectedHomelessIds = {}
    
    self._houseUsedCount = 0
    self._houseFreeBedCount = 0
end

function CityCitizenManageUIStateAssignHouse:OnShow()
    CityCitizenManageUIState.OnShow(self)
    self._host:PushCameraStatus()
    self._houseUsedCount = 0
    self._houseFreeBedCount = 0
    local citizenMgr = self._host._city.cityCitizenManager
    local castle = self._host._city:GetCastle()
    local cityFurniture = castle.CastleFurniture
    local buildingInfo = castle.BuildingInfos[self._host._param.targetId]
    local cfg = ConfigRefer.CityFurnitureLevel
    local totalBedCount = 0
    if buildingInfo and buildingInfo.InnerFurniture then
        for _, furnitureId in pairs(buildingInfo.InnerFurniture) do
            local f = cityFurniture[furnitureId]
            if f then
                local c = cfg:Find(f.ConfigId)
                if c then
                    totalBedCount = totalBedCount + CityCitizenDefine.GetFurnitureBedCount(c)
                end
            end
        end
    end
    self._houseUsedCount = citizenMgr:GetCitizenCountByHouse(self._host._param.targetId)
    self._houseFreeBedCount = math.max(0, totalBedCount - self._houseUsedCount)
    
    self:RefreshHomelessTable(self._host._city)
    self:UpdateCheckInBtnStatus()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_MANAGE_UI_STATE, true)
end

function CityCitizenManageUIStateAssignHouse:OnHide()
    self._host:PopCameraStatus()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_MANAGE_UI_STATE, false)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_SELECT_SHOW, 0)
    CityCitizenManageUIState.OnHide(self)
end

---@param city City
function CityCitizenManageUIStateAssignHouse:RefreshHomelessTable(city)
    if self._host._city.uid ~= city.uid then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_SELECT_SHOW, 0)
    table.clear(self._selectedHomelessIds)
    table.clear(self._homelessCitizen)
    self._host._p_table_vagrant:Clear()
    local citizenMgr = self._host._city.cityCitizenManager
    local onSelected = Delegate.GetOrCreate(self, self.OnCellSelected)
    for _, data, _ in citizenMgr:pairsCitizenData() do
        if data._houseId == 0 then
            ---@type CityCitizenManageUIDraggableCellData
            local cellData = {}
            cellData.OnSelected = onSelected
            cellData.citizenData = data
            table.insert(self._homelessCitizen, cellData)
            self._host._p_table_vagrant:AppendData(cellData)
        end
    end
    self._host:SetTableShowNoCitizens(#self._homelessCitizen <= 0)
end

---@param data CityCitizenManageUIDraggableCellData
function CityCitizenManageUIStateAssignHouse:OnCellSelected(data)
    if data then
        self._host:FocusOnCitizen(data.citizenData._id, true, true)
        if table.ContainsValue(self._selectedHomelessIds, data.citizenData._id) then
            table.removebyvalue(self._selectedHomelessIds, data.citizenData._id)
            self._host._p_table_vagrant:UnSelectMulti(data)
            self:UpdateCheckInBtnStatus()
            return
        end
        if #self._selectedHomelessIds >= self._houseFreeBedCount then
            return
        end
        table.insert(self._selectedHomelessIds, data.citizenData._id)
        self._host._p_table_vagrant:SetMultiSelect(data)
        self:UpdateCheckInBtnStatus()
    end
end

function CityCitizenManageUIStateAssignHouse:UpdateCheckInBtnStatus()
    local count = #self._selectedHomelessIds
    if count <= 0 or count > self._houseFreeBedCount then
        self._host._p_comp_btn_a_l:SetVisible(false)
        self._host._p_comp_btn_d_m:SetVisible(true)
    else
        self._host._p_comp_btn_a_l:SetVisible(true)
        self._host._p_comp_btn_d_m:SetVisible(false)
    end
    local btnTxt = I18N.Get("citizen_btn_check_in") .. string.format(" %d/%d", count + self._houseUsedCount, self._houseFreeBedCount + self._houseUsedCount)
    self._host._p_text.text = btnTxt
    self._host._p_text_m.text = btnTxt
end

function CityCitizenManageUIStateAssignHouse:OnClickCheckIn(btnTrans)
    local count = #self._selectedHomelessIds
    if count <= 0 or count > self._houseFreeBedCount then
        return
    end
    if not self:CheckAssignHouseCitizenWork() then
        return
    end
    local citizenMgr = self._host._city.cityCitizenManager
    for _, citizenId in pairs(self._selectedHomelessIds) do
        citizenMgr:AssignCitizenToHouse(citizenId, self._host._param.targetId, btnTrans)
    end
    self._host:CloseSelf()
end

---@return boolean
function CityCitizenManageUIStateAssignHouse:CheckAssignHouseCitizenWork()
    local uiRuntimeId = self._host:GetRuntimeId()
    local needStopWork = {}
    local needSend = {}
    local targetId = self._host._param.targetId
    local citizenMgr = self._host._city.cityCitizenManager
    for _, citizenId in pairs(self._selectedHomelessIds) do
        table.insert(needSend, citizenId)
        if not citizenMgr:IsCitizenFree(citizenId) then
            table.insert(needStopWork, citizenId)
        end
    end
    if #needStopWork > 0 then
        ---@type CommonConfirmPopupMediatorParameter
        local data = {}
        data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        data.title = I18N.Get("citizen_check_in_hint_title")
        data.content = I18N.GetWithParams("citizen_check_in_hint_content_n", tostring(#needStopWork))
        data.onConfirm = function(context)
            for _, id in pairs(needStopWork) do
                citizenMgr:StopWork(id)
            end
            for _, citizenId in pairs(needSend) do
                citizenMgr:AssignCitizenToHouse(citizenId, targetId)
            end
            g_Game.UIManager:Close(uiRuntimeId)
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, data)
        return false
    end
    return true
end

return CityCitizenManageUIStateAssignHouse

