--- scene:scene_league_popup_help

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ProtocolId = require("ProtocolId")
local timestamp = require("timestamp")
local DBEntityPath = require("DBEntityPath")
local ConfigRefer = require("ConfigRefer")
local AllianceAttr = require("AllianceAttr")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceHelpMediator:BaseUIMediator
---@field new fun():AllianceHelpMediator
---@field super BaseUIMediator
local AllianceHelpMediator = class('AllianceHelpMediator', BaseUIMediator)

function AllianceHelpMediator:ctor()
    AllianceHelpMediator.super.ctor(self)
    self._eventAdd = false
    ---@type wds.AllianceHelpInfo[]
    self._listDataTmp = {}
    ---@type AllianceHelpCellData[]
    self._listData = {}
    ---@type CommonTimerData
    self._timerData = {}
    self._timerData.needTimer = true
    self._dailyCurrencyMax = 0
    ---@type RefreshConfigCell
    self._refreshConfig = nil
end

function AllianceHelpMediator:OnCreate(param)
    ---@see CommonPopupBackComponent
    self._child_popup_base_l = self:LuaBaseComponent("child_popup_base_l")
    self._p_text_coin = self:Text("p_text_coin")
    self._p_text_refuse = self:Text("p_text_refuse", I18N.GetWithParams("alliance_help_refreshremainder", ""))
    ---@type CommonTimer
    self._child_time = self:LuaObject("child_time")
    self._p_table = self:TableViewPro("p_table")
    self._p_empty = self:GameObject("p_empty")
    self._p_text_empty = self:Text("p_text_empty", "alliance_help_nonehelp")
    self._p_text_hint = self:Text("p_text_hint")
    ---@type BistateButton
    self._child_comp_btn_b = self:LuaObject("child_comp_btn_b")
end

function AllianceHelpMediator:OnOpened(param)
    ---@type CommonBackButtonData
    local backBtnData = {}
    backBtnData.title = I18N.Get("alliance_help_entrybtn")
    self._child_popup_base_l:FeedData(backBtnData)
    local t = ModuleRefer.CastleAttrModule:SimpleGetValue(AllianceAttr.Help_SpeedUp_Time)
    if t <= 0 then
        t = 30
    end
    self._p_text_hint.text = I18N.GetWithParams("alliance_help_tips", t) 
    
    ---@type BistateButtonParameter
    local btnData = {}
    btnData.buttonText = I18N.Get("alliance_help_helpall")
    btnData.onClick = Delegate.GetOrCreate(self, self.OnClickHelpAll)
    btnData.disableClick = Delegate.GetOrCreate(self, self.OnClickHelpAllDisabled)
    self._child_comp_btn_b:FeedData(btnData)
    self._child_comp_btn_b:SetVisible(false)
    self._child_time:FeedData(self._timerData)
    self._p_table:SetVisible(false)
    self._p_empty:SetVisible(true)
    self._dailyCurrencyMax = ConfigRefer.AllianceConsts:HelpCurrencyLimit()
    self._refreshConfig = ConfigRefer.Refresh:Find(ConfigRefer.AllianceConsts:HelpCurrencyLimitRefresh())
    self:FetchData()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    self:RefreshTime(player, nil, true)
    self:RefreshHelpCurrency(player)
end

function AllianceHelpMediator:OnShow(param)
    self:SetupEvents(true)
end

function AllianceHelpMediator:OnHide(param)
    self:SetupEvents(false)
end

function AllianceHelpMediator:SetupEvents(add)
    if not self._eventAdd and add then
        self._eventAdd = true
        g_Game.ServiceManager:AddResponseCallback(ProtocolId.GetAllianceHelps, Delegate.GetOrCreate(self, self.OnReceiveServerData))
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerAlliance.HelpCurrencyDaily.MsgPath, Delegate.GetOrCreate(self, self.RefreshHelpCurrency))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerAlliance.HelpCurrencyNextRefreshTime.MsgPath, Delegate.GetOrCreate(self, self.RefreshTime))
    elseif self._eventAdd and not add then
        self._eventAdd = false
        g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.GetAllianceHelps, Delegate.GetOrCreate(self, self.OnReceiveServerData))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerAlliance.HelpCurrencyDaily.MsgPath, Delegate.GetOrCreate(self, self.RefreshHelpCurrency))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerAlliance.HelpCurrencyNextRefreshTime.MsgPath, Delegate.GetOrCreate(self, self.RefreshTime))
    end
end

function AllianceHelpMediator:FetchData()
    ModuleRefer.AllianceModule:GetAllianceHelps()
end

---@param a wds.AllianceHelpInfo
---@param b wds.AllianceHelpInfo
function AllianceHelpMediator.IsChanged(a, b)
    for fieldKey, valueA in pairs(a) do
        local valueB = b[fieldKey]
        if valueA ~= valueB then
            local typeA = type(valueA)
            local typeB = type(valueB)
            if typeA ~= typeB then
                return true
            end
            if valueA and valueA.TypeName and valueA.TypeName == timestamp.TypeName then
                if valueA.timeSeconds ~= valueB.timeSeconds or valueA.nanos ~= valueB.nanos then
                    return true
                end
            end
        end
    end
    return false
end

---@param a AllianceHelpCellData[]
---@param b wds.AllianceHelpInfo[]
---@return table<number, AllianceHelpCellData>,table<number, AllianceHelpCellData>,table<number, AllianceHelpCellData>
function AllianceHelpMediator.DiffAndUpdate(a, b, skipPlayerId)
    ---@type table<number, AllianceHelpCellData>
    local add = {}
    ---@type table<number, AllianceHelpCellData>
    local remove = {}
    ---@type table<number, AllianceHelpCellData>
    local change = {}
    
    for _, v in ipairs(a) do
        remove[v.serverData.HelpID] = v
    end
    for _, v in ipairs(b) do
        if v.PlayerID == skipPlayerId then
            goto continue
        end
        local helpId = v.HelpID
        local oldData = remove[helpId]
        ---@type AllianceHelpCellData
        local cellData = {}
        cellData.serverData = v
        if oldData then
            remove[helpId] = nil
            if AllianceHelpMediator.IsChanged(v, oldData.serverData) then
                oldData.serverData = v
                change[helpId] = oldData
            end
        else
            add[helpId] = cellData
        end
        ::continue::
    end
    
    return add, remove, change
end

---@param a AllianceHelpCellData
---@param b AllianceHelpCellData
---@return boolean
function AllianceHelpMediator.Sorter(a, b)
    return a.serverData.Time.ServerSecond < b.serverData.Time.ServerSecond
end

---@param isSuccess boolean
---@param rsp wrpc.GetAllianceHelpsReply
function AllianceHelpMediator:OnReceiveServerData(isSuccess, rsp)
    if not isSuccess then
        return
    end
    self._p_table:SetVisible(true)
    table.addrange(self._listDataTmp, rsp.Helps)
    local add,remove,change = AllianceHelpMediator.DiffAndUpdate(self._listData, self._listDataTmp, 0)
    local canHelpItemCount = 0
    for i = #self._listData, 1, -1 do
        local d = self._listData[i]
        if remove[d.serverData.HelpID] then
            table.remove(self._listData, i)
            self._p_table:RemData(d)
        end
    end
    if not table.isNilOrZeroNums(add) then
        self._p_table:Clear()
        for i, v in pairs(add) do
            table.insert(self._listData, v)
        end
        table.sort(self._listData, AllianceHelpMediator.Sorter)
        for i, v in ipairs(self._listData) do
            self._p_table:AppendData(v)
        end
    else
        for _, v in pairs(change) do
            self._p_table:UpdateChild(v)
        end
    end
    local myId = ModuleRefer.PlayerModule:GetPlayerId()
    for _, value in ipairs(self._listData) do
        if value.serverData.PlayerID ~= myId then
            canHelpItemCount = canHelpItemCount + 1
        end
    end
    table.clear(self._listDataTmp)
    self._p_table:SetVisible(#self._listData > 0)
    self._p_empty:SetVisible(#self._listData <= 0)
    self._child_comp_btn_b:SetVisible(canHelpItemCount > 0)
end

function AllianceHelpMediator:OnClickHelpAll()
    ModuleRefer.AllianceModule:SendAllianceHelps(self._child_comp_btn_b.button.transform, Delegate.GetOrCreate(self, self.OnSendAllHelpeRet))
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_help_helpall_toast"))
end

function AllianceHelpMediator:OnSendAllHelpeRet(_, _)
    self:FetchData()
end

function AllianceHelpMediator:OnClickHelpAllDisabled()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_help_nonehelp"))
end

---@param entity wds.Player
function AllianceHelpMediator:RefreshTime(entity, _, nofetch)
    if entity.ID ~= ModuleRefer.PlayerModule.playerId then
        return
    end
    self._timerData.endTime = entity.PlayerAlliance.HelpCurrencyNextRefreshTime.ServerSecond
    if nofetch then
        return
    end
    self:FetchData()
end

---@param entity wds.Player
function AllianceHelpMediator:RefreshHelpCurrency(entity, _)
    if entity.ID ~= ModuleRefer.PlayerModule.playerId then
        return
    end
    self._p_text_coin.text = I18N.GetWithParams("alliance_help_dailylimit", entity.PlayerAlliance.HelpCurrencyDaily, self._dailyCurrencyMax)
end

function AllianceHelpMediator:OnLeaveAlliance()
    self:CloseSelf()
end

return AllianceHelpMediator