local BaseUIComponent = require ('BaseUIComponent')
local CityCitizenNewDefine = require('CityCitizenNewDefine')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CityConst = require("CityConst")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")

local I18N = require("I18N")

---@class CityFurnitureOverviewUIPageCitizenManage:BaseUIComponent
local CityFurnitureOverviewUIPageCitizenManage = class('CityFurnitureOverviewUIPageCitizenManage', BaseUIComponent)

function CityFurnitureOverviewUIPageCitizenManage:OnCreate()
    --- 右侧分页栏，分为All/Free/Working
    ---@see CityCitizenNewManageUITypeCell
    -- self._p_table_btn = self:TableViewPro("p_table_btn")

    ---@type CityCitizenNewManageUIWorkingCitizen 点击工作家具时如果有正在工作的人则显示出来
    self._p_working = self:LuaObject("p_working")

    --- 一个黑色遮罩，用于隔离后面的UI显示
    self._p_base_black = self:GameObject("p_base_black")

    ---@see CityCitizenNewManagerUICitizenCell
    self._p_table_detail = self:TableViewPro("p_table_detail")
    self._p_empty = self:GameObject("p_empty")
    self._p_text_no = self:Text("p_text_no", "citizen_blank")
    self._p_text_title = self:Text("p_text_title", "citizen_select")
end

---@param data CityCitizenNewManageUIParameter
function CityFurnitureOverviewUIPageCitizenManage:OnFeedData(data)
    self.param = data
    
    -- self:InitToggleTableViewPro()
    self:InitCurrentWorkingCitizen()
    self:DisplayBlockImage()
    if self._p_base_black then
        self._p_base_black:SetActive(data.showMask)
    end
    -- if self.param.showWorkingCitizen then
        self:RefreshCitizenList(CityCitizenNewDefine.ManageToggleType.All)
    -- else
        -- self:RefreshCitizenList(CityCitizenNewDefine.ManageToggleType.Free)
    -- end
end

function CityFurnitureOverviewUIPageCitizenManage:OnShow()
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataChanged))
end

function CityFurnitureOverviewUIPageCitizenManage:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataChanged))
end

---@param l CityCitizenNewManageUICitizenCellData
---@param r CityCitizenNewManageUICitizenCellData
function CityFurnitureOverviewUIPageCitizenManage.FreeSortFunc(l, r)
    return l.citizenData._id < r.citizenData._id
end

function CityFurnitureOverviewUIPageCitizenManage:InitToggleTableViewPro()
    self._p_table_btn:Clear()

    local toggleData = {}
    ---@type table<number, CityCitizenNewManageUITypeCellData>
    local tableViewDataSrc = {}

    if self.param.showWorkingCitizen then
        toggleData[CityCitizenNewDefine.ManageToggleType.All] = {
            icon = "sp_city_icon_tip",
            toggleType = CityCitizenNewDefine.ManageToggleType.All,
            onClick = Delegate.GetOrCreate(self, self.OnClickToggle),
            selected = true
        }
        table.insert(tableViewDataSrc, toggleData[CityCitizenNewDefine.ManageToggleType.All])
    end

    toggleData[CityCitizenNewDefine.ManageToggleType.Free] = {
        icon = "sp_city_icon_free_resident",
        toggleType = CityCitizenNewDefine.ManageToggleType.Free,
        onClick = Delegate.GetOrCreate(self, self.OnClickToggle),
        selected = false
    }
    table.insert(tableViewDataSrc, toggleData[CityCitizenNewDefine.ManageToggleType.Free])

    if self.param.showWorkingCitizen then
        toggleData[CityCitizenNewDefine.ManageToggleType.Working] = {
            icon = "sp_city_icon_hammer",
            toggleType = CityCitizenNewDefine.ManageToggleType.Working,
            onClick = Delegate.GetOrCreate(self, self.OnClickToggle),
            selected = false
        }
        table.insert(tableViewDataSrc, toggleData[CityCitizenNewDefine.ManageToggleType.Working])
    end

    self.toggleData = toggleData

    for i, v in ipairs(tableViewDataSrc) do
        self._p_table_btn:AppendData(v)
    end
end

function CityFurnitureOverviewUIPageCitizenManage:OnClickToggle(toggleType)
    for k, v in pairs(self.toggleData) do
        v.selected = v.toggleType == toggleType
    end
    self._p_table_btn:UpdateOnlyAllDataImmediately()
    self:RefreshCitizenList(toggleType)
end
    
function CityFurnitureOverviewUIPageCitizenManage:RefreshCitizenList(toggleType)
    self.toggleType = toggleType
    ---@type table<number, CityCitizenNewManageUICitizenCellData>
    local needShowCitizen = {}
    local workCitizen = {}
    local freeCitizen = {}
    for id, citizenData, citizenWorkData in self.param.city.cityCitizenManager:pairsCitizenData() do
        if toggleType & CityCitizenNewDefine.ManageToggleType.Free ~= 0 and citizenWorkData == nil then
            local data = {
                citizenData = citizenData,
                citizenWorkData = citizenWorkData,
                city = self.param.city,
                onClick = Delegate.GetOrCreate(self, self.OnClickCitizen),
                -- onCanCelWork = Delegate.GetOrCreate(self, self.OnClickCancelWork),
                onTimeUp = Delegate.GetOrCreate(self, self.OnWorkTimeUp),
                showPower = self.param.needShowWorkingAbout,
                workCfg = self:GetWorkCfg(self.param.workCfgId)
            }
            table.insert(freeCitizen, data)
        elseif toggleType & CityCitizenNewDefine.ManageToggleType.Working ~= 0 and citizenWorkData ~= nil then
            local data = {
                citizenData = citizenData,
                citizenWorkData = citizenWorkData,
                city = self.param.city,
                onClick = Delegate.GetOrCreate(self, self.OnClickCitizen),
                -- onCanCelWork = Delegate.GetOrCreate(self, self.OnClickCancelWork),
                onTimeUp = Delegate.GetOrCreate(self, self.OnWorkTimeUp),
                showPower = self.param.needShowWorkingAbout,
                workCfg = self:GetWorkCfg(self.param.workCfgId)
            }
            table.insert(workCitizen, data)
        end
    end

    local sortFunc = self:GetSortFunc()
    table.sort(freeCitizen, sortFunc)
    table.sort(workCitizen, sortFunc)

    for i, v in ipairs(freeCitizen) do
        table.insert(needShowCitizen, v)
    end
    for i, v in ipairs(workCitizen) do
        table.insert(needShowCitizen, v)
    end

    self.showCitizen = needShowCitizen
    self.freeCitizen = freeCitizen
    self.workCitizen = workCitizen

    local show = #needShowCitizen > 0
    self._p_table_detail:SetVisible(show)
    if show then
        self._p_table_detail:Clear()
        for i, v in ipairs(needShowCitizen) do
            if self.param.needShowWorkingAbout then
                v.isRecommand = i == 1
            else
                v.isRecommand = false
            end
            if self.param.needShowWorkingAbout then
                self._p_table_detail:AppendDataEx(v, 280, 209)
            else
                self._p_table_detail:AppendDataEx(v, 280, 160)
            end
        end
    end

    self._p_empty:SetActive(not show)
end

function CityFurnitureOverviewUIPageCitizenManage:GetWorkCfg()
    if self.param.workCfgId then
        return ConfigRefer.CityWork:Find(self.param.workCfgId)
    end
end

function CityFurnitureOverviewUIPageCitizenManage:GetSortFunc()
    if self.param.needShowWorkingAbout then
        return self:GetSortFuncForWork(self.param.workCfgId)
    else
        return self.FreeSortFunc
    end
end

function CityFurnitureOverviewUIPageCitizenManage:GetSortFuncForWork(workCfgId)
    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    ---@param l CityCitizenNewManageUICitizenCellData
    ---@param r CityCitizenNewManageUICitizenCellData
    return function(l, r)
        local valuel = self.param.city.cityWorkManager:GetWorkBuffValueFromCitizen(workCfg, l.citizenData)
        local valuer = self.param.city.cityWorkManager:GetWorkBuffValueFromCitizen(workCfg, r.citizenData)
        if valuel ~= valuer then
            return valuel > valuer
        else
            return l.citizenData._id < r.citizenData._id
        end
    end
end

function CityFurnitureOverviewUIPageCitizenManage:InitCurrentWorkingCitizen()
    local show = self.param.needShowWorkingAbout and self.param.citizenWorkData ~= nil
    self._p_working:SetVisible(false)
    if show then
        ---@type CityCitizenNewManageUICitizenCellData
        local workingData = {
            citizenData = self.param.city.cityCitizenManager:GetCitizenDataById(self.param.city.cityWorkManager._work2CitizenId[self.param.citizenWorkData._id]),
            citizenWorkData = self.param.citizenWorkData,
            city = self.param.city,
            onClick = Delegate.GetOrCreate(self, self.FocusOnCitizen),
            onCanCelWork = Delegate.GetOrCreate(self, self.OnClickCancelWork),
            onTimeUp = Delegate.GetOrCreate(self, self.OnWorkTimeUp)
        }
        self.currentWorking = workingData
        self._p_working:FeedData(workingData)
    end
end

---@param data CityCitizenNewManageUICitizenCellData
function CityFurnitureOverviewUIPageCitizenManage:OnClickCitizen(data, lockable)
    if self.param.needShowWorkingAbout then
        return self:OnClickCitizenForWorking(data, lockable)
    else
        return self:FocusOnCitizen(data)
    end
end

---@param data CityCitizenNewManageUICitizenCellData
function CityFurnitureOverviewUIPageCitizenManage:OnClickCitizenForWorking(data, lockable)
    if self.param.citizenWorkData == data.citizenWorkData and data.citizenWorkData ~= nil then
        return
    end

    if self.param.onSelect(data.citizenData._id, lockable) then
        return
    end

    if data.citizenWorkData ~= nil then
        ---@type CommonConfirmPopupMediatorParameter
        local dialogParam = {}
        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        dialogParam.title = I18N.Get("CitizenChange_Title")
        dialogParam.content = I18N.Get("CitizenChange_Content")
        dialogParam.onConfirm = function(context)
            self.param.city.cityWorkManager:DetachCitizenFromWork(data.citizenWorkData._id, lockable)
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
    end
end

---@param data CityCitizenNewManageUICitizenCellData
function CityFurnitureOverviewUIPageCitizenManage:FocusOnCitizen(data)
    local pos = self.param.city.cityCitizenManager:GetCitizenPosition(data.citizenData._id)
    if pos then
        ---@type CS.UnityEngine.Vector3
        local viewPortPos = CS.UnityEngine.Vector3(0.45, 0.5, 0.0)
        self.param.city.camera:ForceGiveUpTween()
        self.param.city.camera:ZoomToWithFocusBySpeed(CityConst.CITY_RECOMMEND_CAMERA_SIZE, viewPortPos, pos)
    end
end

---@param data CityCitizenNewManageUICitizenCellData
function CityFurnitureOverviewUIPageCitizenManage:OnClickCancelWork(data, lockable)
    if data.citizenWorkData == nil then return end
    self.param.city.cityWorkManager:DetachCitizenFromWork(data.citizenWorkData._id, lockable)
end

---@param data CityCitizenNewManageUICitizenCellData
function CityFurnitureOverviewUIPageCitizenManage:OnWorkTimeUp(data)
    
end

---@param needRefreshCitizenId table<number, boolean>
function CityFurnitureOverviewUIPageCitizenManage:OnCitizenDataChanged(city, needRefreshCitizenId)
    if self.param.city ~= city then return end
    
    for id, _ in pairs(needRefreshCitizenId) do
        for _, data in ipairs(self.showCitizen) do
            if data.citizenData._id == id then
                local oldIsWorking = data.citizenWorkData ~= nil
                local newIsWorking = data.citizenData:GetWorkData() ~= nil
                if oldIsWorking ~= newIsWorking then
                    local index = table.indexof(self.showCitizen, data)
                    self._p_table_detail:RemAt(index)
                    if oldIsWorking and self.toggleType & CityCitizenNewDefine.ManageToggleType.Free ~= 0 then
                        self._p_table_detail:InsertData(#self.freeCitizen, data)
                        table.insert(self.freeCitizen, data)
                        table.removebyvalue(self.workCitizen, data)
                    elseif not oldIsWorking and self.toggleType & CityCitizenNewDefine.ManageToggleType.Working ~= 0 then
                        self._p_table_detail:AppendData(data)
                        table.insert(self.workCitizen, data)
                        table.removebyvalue(self.freeCitizen, data)
                    end
                else
                    self._p_table_detail:UpdateData(data)
                end
                break
            end
        end
    end

    if self.param.needShowWorkingAbout then
        if self.currentWorking and needRefreshCitizenId[self.currentWorking.citizenData._id] then
            self.currentWorking.citizenWorkData = self.param.city.cityWorkManager:GetCitizenWorkData()
            self._p_working:FeedData(self.currentWorking)
            self._p_working:SetVisible(self.currentWorking.citizenWorkData ~= nil)
            return
        end

        for id, _ in pairs(needRefreshCitizenId) do
            local citizenWorkData = self.param.city.cityWorkManager:GetCitizenWorkDataByCitizenId(id)
            if citizenWorkData == nil then goto continue end
            if self.param.targetId == citizenWorkData._target and self.param.targetType == citizenWorkData._targetType then
                if self.currentWorking == nil then
                    self.currentWorking = {}
                    self.currentWorking.city = self.param.city
                    self.currentWorking.onClick = Delegate.GetOrCreate(self, self.FocusOnCitizen)
                    self.currentWorking.onCanCelWork = Delegate.GetOrCreate(self, self.OnClickCancelWork)
                    self.currentWorking.onTimeUp = Delegate.GetOrCreate(self, self.OnWorkTimeUp)
                end
                self.currentWorking.citizenData = self.param.city.cityCitizenManager:GetCitizenDataById(id)
                self.currentWorking.citizenWorkData = citizenWorkData
                self._p_working:FeedData(self.currentWorking)
                self._p_working:SetVisible(true)
                return
            end
            ::continue::
        end
    end
end

function CityFurnitureOverviewUIPageCitizenManage:DisplayBlockImage()
    
end

return CityFurnitureOverviewUIPageCitizenManage