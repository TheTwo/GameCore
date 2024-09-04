local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")

---@class ReplicaPVPBattleRecordMediatorParameter

---@class ReplicaPVPBattleRecordMediator:BaseUIMediator
---@field new fun():ReplicaPVPBattleRecordMediator
---@field super BaseUIMediator
local ReplicaPVPBattleRecordMediator = class('ReplicaPVPBattleRecordMediator', BaseUIMediator)

function ReplicaPVPBattleRecordMediator:OnCreate(param)
    ---@type CommonPopupBackComponent
    self._child_popup_base_l = self:LuaObject("child_popup_base_l")

    self.goBottom = self:GameObject('p_bottom')
    self.txtChallenge = self:Text('p_text_challenge')
    self.btnAddChallenge = self:Button('p_btn_add', Delegate.GetOrCreate(self, self.OnAddChallengeClicked))

    self.tableChallengeList = self:TableViewPro('p_table_player')
    self.goEmpty = self:GameObject('p_empty')
    self.txtEmpty = self:Text('p_text_empty', 'se_pvp_history_nolist')

    ---@see CommonResourceBtn
    self.luaResource = self:LuaObject('child_resource')
end

---@param data ReplicaPVPSettlementRewardsMediatorParameter
function ReplicaPVPBattleRecordMediator:OnOpened(param)
    ---@type CommonBackButtonData
    local backButtonData = {}
    backButtonData.title = I18N.Get('se_pvp_history_name')
    backButtonData.hideClose = false
    self._child_popup_base_l:FeedData(backButtonData)
    local ticketId = ModuleRefer.ReplicaPVPModule:GetTicketItemId()
    ---@type CommonResourceBtnSimplifiedData
    local data = {}
    data.itemId = ticketId
    data.isShowPlus = true
    data.onClick = Delegate.GetOrCreate(self, self.OnAddChallengeClicked)
    self.luaResource:FeedData(data)
    self:RefreshUI()
end

function ReplicaPVPBattleRecordMediator:OnClose(param)

end

function ReplicaPVPBattleRecordMediator:OnShow(param)

end

function ReplicaPVPBattleRecordMediator:OnHide(param)

end

function ReplicaPVPBattleRecordMediator:RefreshUI()
    local freeMax = ConfigRefer.ReplicaPvpConst:FreeChallengeNum()
    local canChallengeTimes = ModuleRefer.ReplicaPVPModule:CanChallengeTimes()
    self.txtChallenge.text = I18N.GetWithParams('se_pvp_challengelist_chance', canChallengeTimes, freeMax)

    local battleRecords = ModuleRefer.ReplicaPVPModule:GetBattleRecords()
    local count = battleRecords:Count()
    self.goEmpty:SetVisible(count == 0)
    self.goBottom:SetVisible(count > 0)
    self.tableChallengeList:SetVisible(count > 0)
    if count > 0 then
        local battleStats = self:GenOpponentBattleStats(battleRecords)
        self.tableChallengeList:Clear()
        for i = count, 1, -1 do
            local battleRecord = battleRecords[i]
            local battleStats = battleStats[battleRecord.BasicInfo.PlayerId]

            ---@type ReplicaPVPBattleRecordCellData
            local data = {}
            data.recordInfo = battleRecord
            data.onChallengeClick = Delegate.GetOrCreate(self, self.OnChallengeClicked)
            data.showAttack = self:IsShowAttack(battleRecord, battleStats)
            self.tableChallengeList:AppendData(data)
        end
    end

    ModuleRefer.ReplicaPVPModule:UpdateLastChallengeTime()
end

---@class BattleStats
---@field targetPlayerId number @对手PlayerId
---@field isLastBattleWin boolean @最近一场战斗是否胜利
---@field lastBattleTime google.protobuf.Timestamp @最近一场战斗的时间戳，毫秒

---统计和同一个对手的战斗情况，用于判断是否显示反击按钮
---对于同一个对手，只在最近的一场战斗为失败的时候，才显示反击按钮
---@param battleRecords wds.ReplicaPvpBattleRecordInfo[] | RepeatedField
---@return table<number, BattleStats>
function ReplicaPVPBattleRecordMediator:GenOpponentBattleStats(battleRecords)
    if battleRecords == nil or battleRecords:Count() == 0 then
        return {}
    end

    ---@type table<number, BattleStats>
    local allStats = {}
    for i = 1, battleRecords:Count() do
        local battleRecord = battleRecords[i]
        local targetPlayerId = battleRecord.BasicInfo.PlayerId
        local stats = allStats[targetPlayerId]
        if stats == nil then
            ---@type BattleStats
            stats = {}
            stats.targetPlayerId = targetPlayerId
            allStats[targetPlayerId] = stats
        end

        stats.isLastBattleWin = battleRecord.IsSuccess
        stats.lastBattleTime = battleRecord.BattleTime
    end

    return allStats
end

---@param battleRecord wds.ReplicaPvpBattleRecordInfo
---@param battleStats BattleStats
function ReplicaPVPBattleRecordMediator:IsShowAttack(battleRecord, battleStats)
    if battleRecord.BasicInfo.PlayerId ~= battleStats.targetPlayerId then
        g_Logger.Error('查询关系错乱 %s %s', battleRecord.BasicInfo.PlayerId, battleStats.targetPlayerId)
        return false
    end

    -- 只有最近一场战斗是失败，才显示反击按钮
    if not battleStats.isLastBattleWin and battleRecord.BattleTime.Millisecond == battleStats.lastBattleTime.Millisecond then
        return true
    end

    return false
end

---@param basicInfo wds.ReplicaPvpPlayerBasicInfo
function ReplicaPVPBattleRecordMediator:OnChallengeClicked(basicInfo)
    local canChallengeTimes = ModuleRefer.ReplicaPVPModule:CanChallengeTimes()
    if canChallengeTimes == 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('se_pvp_challengelist_insufficient'))
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.REPLICA_PVP_CHALLENGE_CLICK)
    ModuleRefer.ReplicaPVPModule:OpenAttackTroopEditUI(basicInfo.PlayerId)
end

function ReplicaPVPBattleRecordMediator:OnAddChallengeClicked()
    ModuleRefer.ReplicaPVPModule:OpenPVPShop()
end

return ReplicaPVPBattleRecordMediator