local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local BattlePassConst = require('BattlePassConst')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local DBEntityPath = require('DBEntityPath')
local UIMediatorNames = require('UIMediatorNames')
local ActivityRewardType = require('ActivityRewardType')
---@class BattlePassReward : BaseUIComponent
local BattlePassReward = class('BattlePassReward', BaseUIComponent)

local I18N_KEYS = BattlePassConst.I18N_KEYS

function BattlePassReward:OnCreate()
    -- left
    --- basic
    self.textBasic = self:Text('p_text_basic', I18N_KEYS.BASIC_NAME)

    --- advanced
    self.textAdvanced = self:Text('p_text_better', I18N_KEYS.SENIOR_NAME)
    self.btnUnlock = self:Button('p_btn_unlock')
    self.goBtnUnlock = self:GameObject('p_btn_unlock')

    -- reward table
    self.tableReward = self:TableViewPro('p_table_reward')

    -- reward show
    self.luaFixedRewardCell = self:LuaObject('p_reward_show')

    self.progressLeft = self:Slider('p_progress_reward_left')

    self.btnUnlock = self:Button('p_btn_unlock', Delegate.GetOrCreate(self, self.OnBtnUnlockClicked))
end

function BattlePassReward:OnShow()
    self.cfgId = ModuleRefer.BattlePassModule:GetCurOpeningBattlePassId()
    self:UpdateData(true)
    g_Game.EventManager:AddListener(EventConst.BATTLEPASS_REWARD_CELL_SHOW_HIDE, Delegate.GetOrCreate(self, self.OnRewardCellShowHide))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerAutoReward.Rewards.MsgPath, Delegate.GetOrCreate(self, self.OnDataChanged))
end

function BattlePassReward:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.BATTLEPASS_REWARD_CELL_SHOW_HIDE, Delegate.GetOrCreate(self, self.OnRewardCellShowHide))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerAutoReward.Rewards.MsgPath, Delegate.GetOrCreate(self, self.OnDataChanged))
end

function BattlePassReward:OnDataChanged(_, changedTable)
    local actId = ModuleRefer.ActivityCenterModule:GetCurOpeningAutoRewardId(ActivityRewardType.BattlePass)
    local oldData = (changedTable.Remove or {})[actId].BattlePassParam
    local currentData = (changedTable.Add or {})[actId].BattlePassParam
    if not currentData then return end
    local shouldRefreshTable = (currentData.Level ~= oldData.Level or currentData.Exp ~= oldData.Exp)
    self:UpdateData(shouldRefreshTable)
end

function BattlePassReward:UpdateData(shouldRefreshTable)
    local rewardNodes = ModuleRefer.BattlePassModule:GetRewardInfosByCfgId(self.cfgId)
    if shouldRefreshTable then
        self.levelsShownRightBound = 0
        self.tableReward:Clear()
        for i, v in ipairs(rewardNodes) do
            self.tableReward:AppendData({
                isFixed = false,
                level = i,
                curAchievedLevel = ModuleRefer.BattlePassModule:GetLevelByCfgId(self.cfgId),
            })
        end
        self.tableReward:SetDataFocus(ModuleRefer.BattlePassModule:GetLevelByCfgId(self.cfgId) - 1, 0, CS.TableViewPro.MoveSpeed.None)
    end
    self.progressLeft.gameObject:SetActive(ModuleRefer.BattlePassModule:GetLevelByCfgId(self.cfgId) > 0)
    self.progressLeft.value = 1
    self.btnUnlock.gameObject:SetActive(not ModuleRefer.BattlePassModule:IsVIP(self.cfgId))
end

function BattlePassReward:OnRewardCellShowHide(level, isShow)
    if isShow then
        if level > self.levelsShownRightBound then
            self.levelsShownRightBound = level
        else
            return
        end
    else
        if level == self.levelsShownRightBound then
            self.levelsShownRightBound = self.levelsShownRightBound - 1
        else
            return
        end
    end
    local maxLvl = self.levelsShownRightBound
    if maxLvl > 0 then
        local maxSpLvl = ModuleRefer.BattlePassModule:GetNextSpRewardIndex(self.cfgId, maxLvl)
        if self.maxSpLvl == maxSpLvl then return end
        if maxSpLvl == 0 then maxSpLvl = self.maxSpLvl end
        self.luaFixedRewardCell:SetVisible(true)
        self.luaFixedRewardCell:FeedData({
            isFixed = true,
            level = maxSpLvl,
            curAchievedLevel = ModuleRefer.BattlePassModule:GetLevelByCfgId(self.cfgId),
        })
        self.maxSpLvl = maxSpLvl
    end
end

function BattlePassReward:OnBtnUnlockClicked()
    g_Game.UIManager:Open(UIMediatorNames.BattlePassUnlockAdvanceMediator)
end

function BattlePassReward:Log(...)
    g_Logger.LogChannel('BattlePassReward', ...)
end


return BattlePassReward