--- scene:scene_league_storehouse

local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local DBEntityPath = require("DBEntityPath")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceStoreHouseMediatorParameter
---@field backNoAni boolean

---@class AllianceStoreHouseMediator:BaseUIMediator
---@field new fun():AllianceStoreHouseMediator
---@field super BaseUIMediator
local AllianceStoreHouseMediator = class('AllianceStoreHouseMediator', BaseUIMediator)

function AllianceStoreHouseMediator:ctor()
    BaseUIMediator.ctor(self)
    self._eventAdd = false
    self._uiReady = false
    ---@type AllianceStoreHouseResCellParameter[]
    self._resCellData = {}
    ---@type AllianceStoreHouseResLogCellParameter[]
    self._logCellData = {}
    self._backNoAni = false
end

function AllianceStoreHouseMediator:OnCreate(param)
    ---@type CommonBackButtonComponent
    self.child_popup_base_l = self:LuaObject("child_popup_base_l")
    
    self._p_subtitle_resource = self:Text("p_subtitle_resource", "alliance_resource_ziyuan")
    self._p_btn_info = self:Image("p_btn_info", Delegate.GetOrCreate(self, self.OnClickBtnDetailInfo))
    self._p_text_resource_desc = self:Text("p_text_resource_desc", "alliance_resource_tips1")
    self._p_res_table = self:TableViewPro("p_res_table")
    self._p_subtitle_detail = self:Text("p_subtitle_detail", "alliance_resource_jilu")
    self._p_table_detail = self:TableViewPro("p_table_detail")
    self._p_empty = self:GameObject("p_empty")
    self._p_text_empty = self:Text("p_text_empty", "alliance_resource_tips03")
end

function AllianceStoreHouseMediator:OnShow(param)
    self:SetupEvents(true)
end

function AllianceStoreHouseMediator:OnHide(param)
    self:SetupEvents(false)
end

---@param param AllianceStoreHouseMediatorParameter
function AllianceStoreHouseMediator:OnOpened(param)
    self._backNoAni = param and param.backNoAni or false
    ---@type CommonBackButtonData
    local backBtnData = {}
    backBtnData.title = I18N.Get("alliance_resource_cangku")
    backBtnData.onClose = Delegate.GetOrCreate(self, self.OnClickBackBtn)
    self.child_popup_base_l:FeedData(backBtnData)
    self:GenerateResCellsData()
    for i, v in ipairs(self._resCellData) do
        self._p_res_table:AppendData(v)
    end
    self:GenerateLogCellsData()
    if #self._logCellData > 0 then
        self._p_table_detail:SetVisible(true)
        self._p_empty:SetVisible(false)
    else
        self._p_table_detail:SetVisible(false)
        self._p_empty:SetVisible(true)
    end
    for i, v in ipairs(self._logCellData) do
        self._p_table_detail:AppendData(v)
    end
end

function AllianceStoreHouseMediator:GenerateResCellsData()
    table.clear(self._resCellData)
    for i, v in ConfigRefer.AllianceCurrency:ipairs() do
        ---@type AllianceStoreHouseResCellParameter
        local cellData = {}
        cellData.config = v
        table.insert(self._resCellData, cellData)
    end
end

function AllianceStoreHouseMediator:GenerateLogCellsData()
    table.clear(self._logCellData)
    ---@type wds.AllianceCurrencyLog[]
    local logsData = {}
    table.addrange(logsData, ModuleRefer.AllianceModule:GetMyAllianceCurrencyLogs())
    table.sort(logsData, function(a, b)
        return a.Time.Seconds > b.Time.Seconds
    end)
    for i = 1, #logsData do
        ---@type AllianceStoreHouseResLogCellParameter
        local logCell = {}
        logCell.serverData = logsData[i]
        table.insert(self._logCellData, logCell)
    end
end

function AllianceStoreHouseMediator:SetupEvents(add)
    if self._eventAdd and not add then
        self._eventAdd = false
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceCurrency.Logs.MsgPath, Delegate.GetOrCreate(self, self.OnCurrencyLogChanged))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    elseif not self._eventAdd and add then
        self._eventAdd = true
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceCurrency.Logs.MsgPath, Delegate.GetOrCreate(self, self.OnCurrencyLogChanged))
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    end
end

---@param entity wds.Alliance
function AllianceStoreHouseMediator:OnCurrencyLogChanged(entity, changeData)
    if not self._uiReady then
        return
    end
    if entity.ID ~= ModuleRefer.AllianceModule:GetAllianceId() then
        return
    end
    ---@type wds.AllianceCurrencyLog[]
    local logsData = {}
    table.addrange(logsData, ModuleRefer.AllianceModule:GetMyAllianceCurrencyLogs())
    table.sort(logsData, function(a, b) 
        return a.Time.Seconds > b.Time.Seconds
    end)
    local nowCount = #self._logCellData
    local newCount = #logsData
    if newCount > 0 then
        self._p_table_detail:SetVisible(true)
        self._p_empty:SetVisible(false)
    else
        self._p_table_detail:SetVisible(false)
        self._p_empty:SetVisible(true)
    end
    for i = nowCount, newCount + 1, -1 do
        table.remove(self._logCellData, i)
        self._p_table_detail:RemAt(i - 1)
    end
    local updateCount = math.min(newCount, nowCount)
    for i = 1, updateCount do
        local logCell = self._logCellData[i]
        logCell.serverData = logsData[i]
        self._p_table_detail:UpdateData(logCell)
    end
    for i = nowCount + 1, newCount do
        ---@type AllianceStoreHouseResLogCellParameter
        local logCell = {}
        logCell.serverData = logsData[i]
        self._p_table_detail:AppendData(logCell)
    end
end

function AllianceStoreHouseMediator:OnClickBtnDetailInfo()
    ---@type TextToastMediatorParameter
    local param = {}
    param.clickTransform = self._p_btn_info:GetComponent(typeof(CS.UnityEngine.RectTransform))
    param.content = I18N.Get(ConfigRefer.AllianceConsts:AllianceStoreHouseTip())
    ModuleRefer.ToastModule:ShowTextToast(param)
end

function AllianceStoreHouseMediator:OnLeaveAlliance(allianceId)
    self:CloseSelf()
end

function AllianceStoreHouseMediator:OnClickBackBtn()
    self:BackToPrevious(nil, self._backNoAni, self._backNoAni)
end

return AllianceStoreHouseMediator