local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local NumberFormatter = require('NumberFormatter')
---@class AllianceWorldEventSettlementMediator : BaseUIMediator
local AllianceWorldEventSettlementMediator = class('AllianceWorldEventSettlementMediator', BaseUIMediator)

function AllianceWorldEventSettlementMediator:ctor()
    self.module = ModuleRefer.GveModule
end

function AllianceWorldEventSettlementMediator:OnCreate()

    self.goWin = self:GameObject('p_win')
    self.goLose = self:GameObject('p_lose')
    self.textBattleInfo = self:Text('p_text_battle_info', 'alliance_battle_hud23')
    self.textTime = self:Text('p_text_time', 'alliance_battle_hud22')

    self.textProgress = self:Text('p_text_progress', 'alliance_battle_hud24')

    self.btnFinish = self:Button('p_finish', Delegate.GetOrCreate(self, self.OnBtnFinishClicked))
    self.goGroupContinue = self:GameObject('p_group_continue')
    self.textContinue1 = self:Text('p_text_continue_1', 'task_open_next_click')
    self.textContinue2 = self:Text('p_text_continue_2')

    self.goRanking = self:GameObject('ranking')
    self.textTitleRanking = self:Text('p_text_title_ranking', 'gverating_rank')
    self.textTitlePlayer = self:Text('p_text_title_player', 'gverating_commander')
    self.textTitleOutput = self:Text('p_text_title_output', 'alliance_worldevent_big_rank_value')
    self.damageDataTable = self:TableViewPro('table_ranking')

    self.goResultVictory = self:GameObject('p_result_victory')
    self.goResultDefeat = self:GameObject('p_result_defeat')
    -- Init Node State   
    self.goGroupContinue:SetVisible(false)
    self.goRanking:SetVisible(true)

end

function AllianceWorldEventSettlementMediator:OnShow(param)
    self.param = param
    local isWin = param.isWin
    self.goWin:SetVisible(isWin)
    self.goLose:SetVisible(not isWin)
    self.textBattleInfo:SetVisible(false)
    self.goResultVictory:SetVisible(isWin)
    self.goResultDefeat:SetVisible(not isWin)

    self:UpdateDamageInfo()
end

function AllianceWorldEventSettlementMediator:OnHide(param)

end

function AllianceWorldEventSettlementMediator:OnOpened(param)
end

function AllianceWorldEventSettlementMediator:OnClose(param)
end

function AllianceWorldEventSettlementMediator:OnBtnFinishClicked()
    g_Game.UIManager:CloseByName("AllianceWorldEventSettlementMediator")
end

function AllianceWorldEventSettlementMediator:UpdateDamageInfo()
    local selfID = ModuleRefer.PlayerModule:GetPlayer().ID
    local members = ModuleRefer.AllianceModule:GetMyAllianceData().AllianceMembers.Members
    local ProgressList = self.param.ProgressList
    local temp = {}

    local sum = 0
    for k, v in pairs(ProgressList) do
        sum = sum + v
        temp[k] = v
    end

    local index = 1
    local maxPlayerDamage
    self.damageDataTable:Clear()
    for k, v in pairs(ProgressList) do
        local max = v
        local key = k
        for k2, v2 in pairs(temp) do
            if v2 then
                if max < v2 then
                    max = v2
                    key = k2
                end
            end
        end

        -- 玩家最大值
        if maxPlayerDamage == nil then
            maxPlayerDamage = max
        end
        local isSelf = false
        local faceBookId

        -- 玩家本身数据
        if key == selfID then
            isSelf = true
            faceBookId = ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID
        end

        -- 他人数据
        for k3, v3 in pairs(members) do
            if v3.PlayerID == key then
                faceBookId = k3
                break
            end
        end

        ---@type GveBattleDamageInfoCellData
        local info = {}
        info.index = index
        info.isSelf = isSelf
        info.damageInfo = {playerName = members[faceBookId].Name, damage = max, portraitInfo = members[faceBookId].PortraitInfo}
        info.allDamage = sum
        info.maxPlayerDamage = maxPlayerDamage
        self.damageDataTable:AddData(info)
        index = index + 1

        temp[key] = -1
    end
end

return AllianceWorldEventSettlementMediator
