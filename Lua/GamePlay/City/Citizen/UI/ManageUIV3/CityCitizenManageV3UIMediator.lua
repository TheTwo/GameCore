---Scene Name : scene_city_popup_citizen
local BaseUIMediator = require ('BaseUIMediator')
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local CityWorkI18N = require('CityWorkI18N')
local I18N = require("I18N")
local Delegate = require('Delegate')
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local EventConst = require("EventConst")
local UIMediatorNames = require("UIMediatorNames")

---@class CityCitizenManageV3UIMediator:BaseUIMediator
---@field allCitizens CityCitizenData[]
---@field pageCitizens CityCitizenData[]
local CityCitizenManageV3UIMediator = class('CityCitizenManageV3UIMediator', BaseUIMediator)

function CityCitizenManageV3UIMediator:OnCreate()
    self._p_text_title = self:Text("p_text_title", "citizen_information")
    self._p_table_detail = self:TableViewPro("p_table_detail")

    self._p_empty = self:GameObject("p_empty")
    self._p_text_no = self:Text("p_text_no", "citizen_blank")

    self._group_tab = self:Transform("group_tab")
    self._p_btn = self:LuaBaseComponent("p_btn")
    self._tab_pool = LuaReusedComponentPool.new(self._p_btn, self._group_tab)

    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.BackToPrevious))
end

---@param param CityCitizenManageV3UIParameter
function CityCitizenManageV3UIMediator:OnOpened(param)
    self.param = param
    self:UpdateUI()

    g_Game.EventManager:AddListener(EventConst.UI_CITIZEN_MANAGE_V3_REFRESH, Delegate.GetOrCreate(self, self.UpdateUI))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
end

function CityCitizenManageV3UIMediator:UpdateUI()
    self.allCitizens = {}

    local originCitizenMap = self.param.city.cityCitizenManager._citizenData
    if self.param.globalFilter == nil then
        for id, citizenData in pairs(originCitizenMap) do
            table.insert(self.allCitizens, citizenData)
        end
    else
        for id, citizenData in pairs(originCitizenMap) do
            if self.param.globalFilter(citizenData) then
                table.insert(self.allCitizens, citizenData)
            end
        end
    end

    if self.param.pages == nil then
        self._group_tab:SetVisible(false)
        self.pageCitizens = {}
        for i, v in ipairs(self.allCitizens) do
            table.insert(self.pageCitizens, v)
        end
        self.currentPage = nil
        self:UpdateCitizenTableView()
    else
        self._group_tab:SetVisible(true)
        self.pages = {}
        for i, v in ipairs(self.param.pages) do
            table.insert(self.pages, v)
        end
        table.sort(self.pages, function(a, b)
            return a.priority > b.priority
        end)

        self._tab_pool:HideAll()
        for i, v in ipairs(self.pages) do
            local item = self._tab_pool:GetItem()
            item:FeedData(v)
        end

        self:SelectPage(self.pages[1])
    end

    self.dirtyRefreshCellBuffer = {}
    self.dirtyCitizenCellData = {}
end

---@param page CityCitizenManageV3PageData
function CityCitizenManageV3UIMediator:SelectPage(page)
    self.pageCitizens = {}
    if page.filter == nil then
        for i, v in ipairs(self.allCitizens) do
            table.insert(self.pageCitizens, v)
        end
    else
        for i, v in ipairs(self.allCitizens) do
            if page.filter(v) then
                table.insert(self.pageCitizens, v)
            end
        end
    end

    self.currentPage = page
    self:UpdateToggleSelectStatus()
    self:UpdateCitizenTableView()
end

function CityCitizenManageV3UIMediator:OnClose(param)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    g_Game.EventManager:RemoveListener(EventConst.UI_CITIZEN_MANAGE_V3_REFRESH, Delegate.GetOrCreate(self, self.UpdateUI))
end

function CityCitizenManageV3UIMediator:UpdateToggleSelectStatus()
    g_Game.EventManager:TriggerEvent(EventConst.UI_CITIZEN_MANAGE_V3_SELECT_PAGE)
end

function CityCitizenManageV3UIMediator:UpdateCitizenTableView()
    local isEmpty = #self.pageCitizens == 0
    self._p_empty:SetActive(isEmpty)
    self._p_table_detail:SetVisible(not isEmpty)
    
    if isEmpty then return end
    self._p_table_detail:Clear()

    self.citizenIdToCellData = {}
    for i, v in ipairs(self.pageCitizens) do
        ---@type CityCitizenNewManageUICitizenCellData
        local data = {
            city = self.param.city,
            citizenData = v,
            citizenWorkData = self.param.city.cityWorkManager:GetCitizenWorkDataByCitizenId(v._id),
            showPower = self.param.showWorkPower,
            showProperty = self.param.showWorkProperty,
            workCfg = self.param.workCfg,
            isRecommand = false,
            onClick = Delegate.GetOrCreate(self, self.OnClickCitizen),
            onCanCelWork = self.param.allowCancelCitizenWork and Delegate.GetOrCreate(self, self.OnClickCancelWork) or nil,
            onTimeUp = Delegate.GetOrCreate(self, self.OnTimeUp),
        }
        self.citizenIdToCellData[v._id] = data
        self._p_table_detail:AppendData(data)
    end
end

---@param data CityCitizenNewManageUICitizenCellData
function CityCitizenManageV3UIMediator:OnClickCitizen(data)
    if self.param.onCitizenSelect then
        if self.param.onCitizenSelect(data.citizenData) then
            self:BackToPrevious()
        end
    end
end

---@param data CityCitizenNewManageUICitizenCellData
function CityCitizenManageV3UIMediator:OnClickCancelWork(data)
    local param = {}
    param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
    param.title = I18N.Get(CityWorkI18N.RemoveOtherCitizen_Title)
    param.content = I18N.Get(CityWorkI18N.RemoveOtherCitizen_Content)
    param.onConfirm = function()
        self.city.cityWorkManager:DetachCitizenFromWork(data.citizenWorkData._id)
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
end

---@param data CityCitizenNewManageUICitizenCellData
function CityCitizenManageV3UIMediator:OnTimeUp(data)
    self.dirtyCitizenCellData[data] = true
end

function CityCitizenManageV3UIMediator:OnSecondTick()
    self.dirtyRefreshCellBuffer, self.dirtyCitizenCellData = self.dirtyCitizenCellData, self.dirtyRefreshCellBuffer
    for data, _ in pairs(self.dirtyRefreshCellBuffer) do
        data.citizenWorkData = self.param.city.cityWorkManager:GetCitizenWorkDataByCitizenId(data.citizenData._id)
        self._p_table_detail:UpdateChild(data)
    end
    table.clear(self.dirtyRefreshCellBuffer)
end

return CityCitizenManageV3UIMediator