---scene: scene_se_pvp_settlement
local BaseUIMediator = require("BaseUIMediator")
local PlayerModule = require("PlayerModule")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local Delegate = require("Delegate")
local TimerUtility = require("TimerUtility")

---@class ReplicaPVPSettlementMediatorParameter
---@field env SEEnvironment
---@field isWin boolean
---@field rewardInfo wrpc.LevelRewardInfo

---@class ReplicaPVPSettlementMediator:BaseUIMediator
---@field new fun():ReplicaPVPSettlementMediator
---@field super BaseUIMediator
local ReplicaPVPSettlementMediator = class('ReplicaPVPSettlementMediator', BaseUIMediator)

local ANIM_DURATION = 3

function ReplicaPVPSettlementMediator:OnCreate(param)
    self.goWin = self:GameObject('p_win')
    self.goLose = self:GameObject('p_lose')

    self.txtAttackerName = self:Text('p_text_name_attacker')
    self.txtAttackerScore = self:Text('p_text_score_attacker')
    ---@type PlayerInfoComponent
    self.attackerHeadIcon = self:LuaObject('p_head_attacker')

    self.txtDefenderName = self:Text('p_text_name_defender')
    self.txtDefenderScore = self:Text('p_text_score_defender')
    ---@type PlayerInfoComponent
    self.defenderHeadIcon = self:LuaObject('p_head_defender')

    self.txtRank = self:Text('p_text_rank', 'se_pvp_battlemessage_level2')
    ---@type UIEmojiText
    self.emojiContent = self:LuaObject('p_text_rank_num')

    self.imgRankIcon = self:Image('p_icon_level')
    self.imgRankIconNum = self:Image('p_icon_lv_num')
    self.txtRankName = self:Text('p_text_level')

    self.sliderR = self:Slider('p_progress_r')
    self.sliderG = self:Slider('p_progress_g')
    self.sliderB = self:Slider('p_progress_b')

    self.txtContinue = self:Text('p_text_continue', 'pet_se_result_memo')
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnCloseClick))

    self.textReward = self:Text('p_text_reward', 'se_pvp_levelmessage_reward2')
    self.tableReward = self:TableViewPro('p_table_reward')

    self.vxTrigger = self:AnimTrigger('vx_trigger')
end

---@param param ReplicaPVPSettlementMediatorParameter
function ReplicaPVPSettlementMediator:OnOpened(param)
    self.param = param
    self.canClose = false
    self.txtContinue:SetVisible(false)

    self:RefreshUI()
    self.timer = TimerUtility.DelayExecute(function()
        self.canClose = true
        self.txtContinue:SetVisible(true)
    end, ANIM_DURATION)

    if param.isWin then
        g_Game.SoundManager:Play("sfx_se_fight_victory")
    else
        g_Game.SoundManager:Play("sfx_se_fight_defeat")
    end
end

function ReplicaPVPSettlementMediator:OnClose(param)
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end

    local oldTitle = self.param.rewardInfo.ReplicaPvpRewardInfo.OldTitle
    local newTitle = self.param.rewardInfo.ReplicaPvpRewardInfo.NewTitle
    if ModuleRefer.ReplicaPVPModule:IsTopmostTitle(oldTitle) and ModuleRefer.ReplicaPVPModule:IsTopmostTitle(newTitle) then
        -- 两个都是最高阶，不需要升阶
        self.param.env:QuitSE()
        return
    end

    if newTitle > oldTitle then
        -- 打开升阶页面
        ---@type ReplicaPVPSettlementLevelupMediatorParameter
        local levelupParams = {}
        levelupParams.env = self.param.env
        levelupParams.rewardInfo = self.param.rewardInfo
        g_Game.UIManager:Open(UIMediatorNames.ReplicaPVPSettlementLevelupMediator, levelupParams)
    else
        self.param.env:QuitSE()
    end
end

function ReplicaPVPSettlementMediator:OnShow(param)
end

function ReplicaPVPSettlementMediator:OnHide(param)
end

function ReplicaPVPSettlementMediator:OnCloseClick()
    if self.canClose then
        self:CloseSelf()
    end
end

function ReplicaPVPSettlementMediator:RefreshUI()
    local isWin = self.param.isWin
    self.goWin:SetVisible(isWin)
    self.goLose:SetVisible(not isWin)

    local attacker = self.param.rewardInfo.ReplicaPvpRewardInfo.Mine
    self.txtAttackerName.text = PlayerModule.FullName(attacker.AllianceName, attacker.PlayerName)
    self.attackerHeadIcon:FeedData(attacker.Portrait)
    self.txtAttackerScore.text = ModuleRefer.ReplicaPVPModule:GetScoreAndScoreChangeText(attacker.NewScore, attacker.OldScore)

    local defender = self.param.rewardInfo.ReplicaPvpRewardInfo.Target
    self.txtDefenderName.text = PlayerModule.FullName(defender.AllianceName, defender.PlayerName)
    self.defenderHeadIcon:FeedData(defender.Portrait)
    self.txtDefenderScore.text = ModuleRefer.ReplicaPVPModule:GetScoreAndScoreChangeText(defender.NewScore, defender.OldScore)

    local oldRank = self.param.rewardInfo.ReplicaPvpRewardInfo.OldRank
    local newRank = self.param.rewardInfo.ReplicaPvpRewardInfo.NewRank
    ---@type UIEmojiTextData
    local emojiTextData = {}
    if oldRank <= 0 or newRank <= 0 then
        if newRank <= 0 then
            emojiTextData.text = I18N.Get('se_pvp_challengelist_notonlist')
        else
            emojiTextData.text = tostring(newRank)
        end
    else
        if oldRank == newRank then
            emojiTextData.text = tostring(newRank)
        elseif oldRank > newRank then
            -- 升
            local delta = oldRank - newRank
            emojiTextData.text = string.format('%s([a04]%s)', newRank, delta)
        else
            -- 降
            local delta = newRank - oldRank
            emojiTextData.text = string.format('%s([a03]%s)', newRank, delta)
        end
    end

    self.emojiContent:FeedData(emojiTextData)

    local oldTitle = self.param.rewardInfo.ReplicaPvpRewardInfo.OldTitle
    local newTitle = self.param.rewardInfo.ReplicaPvpRewardInfo.NewTitle
    local oldScore = attacker.OldScore
    local newScore = attacker.NewScore
    if oldTitle == newTitle then
        local cell = ConfigRefer.PvpTitleStage:Find(newTitle)
        if cell then
            self:LoadSprite(cell:Icon(), self.imgRankIcon)
            if cell:LevelIcon() > 0 then
                self.imgRankIconNum:SetVisible(true)
                self:LoadSprite(cell:LevelIcon(), self.imgRankIconNum)
            else
                self.imgRankIconNum:SetVisible(false)
            end
            self.txtRankName.text = I18N.Get(cell:Name())
        end

        -- 段内变化
        if newScore > oldScore then
            -- 涨积分
            self:ShowIncreaseScoresInStage(oldScore, newScore)
        else
            -- 降积分
            self:ShowDecreaseScoresInStage(oldScore, newScore)
        end

    elseif oldTitle < newTitle then
        -- 升阶，进度条涨到1，打开升阶UI
        local cell = ConfigRefer.PvpTitleStage:Find(oldTitle)
        if cell then
            self:LoadSprite(cell:Icon(), self.imgRankIcon)
            if cell:LevelIcon() > 0 then
                self.imgRankIconNum:SetVisible(true)
                self:LoadSprite(cell:LevelIcon(), self.imgRankIconNum)
            else
                self.imgRankIconNum:SetVisible(false)
            end
            self.txtRankName.text = I18N.Get(cell:Name())
        end

        self:ShowIncreaseScoresOverState(oldScore)
    else
        -- 降阶，进度条降到0，然后换图标接着降
        self:ShowDecreaseScoresOverState(oldScore, newScore, oldTitle, newTitle)
    end

    -- 结算奖励，先按原段位的来
    local rewardGroupId
    if isWin then
        rewardGroupId = ConfigRefer.PvpTitleStage:Find(oldTitle):WinReward()
    else
        rewardGroupId = ConfigRefer.PvpTitleStage:Find(oldTitle):LoseReward()
    end
    if rewardGroupId > 0 then
        local items = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(rewardGroupId)
        for _, item in ipairs(items) do
            self.tableReward:AppendData(item)
        end
    end
end

function ReplicaPVPSettlementMediator:ShowIncreaseScoresInStage(oldScore, newScore)
    -- 涨积分，蓝色绿色对齐，绿色涨，红色不显示
    local show1, progress1 = ModuleRefer.ReplicaPVPModule:GetStageProgress(oldScore)
    local show2, progress2 = ModuleRefer.ReplicaPVPModule:GetStageProgress(newScore)
    self.sliderR:SetVisible(false)
    self.sliderB:SetVisible(show1)
    self.sliderG:SetVisible(show2)
    if show1 and show2 then
        self.sliderB.value = progress1
        self.sliderG.value = progress1
        self.sliderG:DOValue(progress2, ANIM_DURATION):OnComplete(function()
            self.canClose = true
            self.txtContinue:SetVisible(true)
        end)
    end
end

function ReplicaPVPSettlementMediator:ShowDecreaseScoresInStage(oldScore, newScore)
    -- 降积分，红色蓝色对齐，蓝色降，绿色不显示
    local show1, progress1 = ModuleRefer.ReplicaPVPModule:GetStageProgress(oldScore)
    local show2, progress2 = ModuleRefer.ReplicaPVPModule:GetStageProgress(newScore)
    self.sliderB:SetVisible(show1)
    self.sliderR:SetVisible(show2)
    self.sliderG:SetVisible(false)
    if show1 and show2 then
        self.sliderB.value = progress1
        self.sliderR.value = progress1
        self.sliderB:DOValue(progress2, ANIM_DURATION):OnComplete(function()
            self.canClose = true
            self.txtContinue:SetVisible(true)
        end)
    end
end

function ReplicaPVPSettlementMediator:ShowIncreaseScoresOverState(oldScore)
    -- 升阶，蓝色绿色对齐，绿色涨到1，红色不显示
    local show1, progress1 = ModuleRefer.ReplicaPVPModule:GetStageProgress(oldScore)
    self.sliderR:SetVisible(false)
    self.sliderB:SetVisible(show1)
    self.sliderG:SetVisible(show1)
    if show1 then
        self.sliderB.value = progress1
        self.sliderG.value = progress1
        self.sliderG:DOValue(1, ANIM_DURATION):OnComplete(function()
            self.canClose = true
            self.txtContinue:SetVisible(true)

            -- 直接关闭UI，触发升阶UI
            self:CloseSelf()
        end)
    end
end

function ReplicaPVPSettlementMediator:ShowDecreaseScoresOverState(oldScore, newScore, oldTitle, newTitle)
    local oldCell = ConfigRefer.PvpTitleStage:Find(oldTitle)
    if oldCell then
        self:LoadSprite(oldCell:Icon(), self.imgRankIcon)
        if oldCell:LevelIcon() > 0 then
            self.imgRankIconNum:SetVisible(true)
            self:LoadSprite(oldCell:LevelIcon(), self.imgRankIconNum)
        else
            self.imgRankIconNum:SetVisible(false)
        end
        self.txtRankName.text = I18N.Get(oldCell:Name())
    end

    -- 降阶，红色蓝色对齐，蓝色降到0，换图标，红色蓝色
    local show1, progress1 = ModuleRefer.ReplicaPVPModule:GetStageProgress(oldScore)
    local show2, progress2 = ModuleRefer.ReplicaPVPModule:GetStageProgress(newScore)
    self.sliderB:SetVisible(show1)
    self.sliderR:SetVisible(show2)
    self.sliderG:SetVisible(false)
    if show1 and show2 then
        self.sliderB.value = progress1
        self.sliderR.value = progress1
        -- 第一段：蓝色降到0
        self.sliderB:DOValue(0, ANIM_DURATION):OnComplete(function()
            -- 第二段：播特效，并换新的阶位信息
            self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)

            local newCell = ConfigRefer.PvpTitleStage:Find(newTitle)
            if newCell then
                self:LoadSprite(newCell:Icon(), self.imgRankIcon)
                if newCell:LevelIcon() > 0 then
                    self.imgRankIconNum:SetVisible(true)
                    self:LoadSprite(newCell:LevelIcon(), self.imgRankIconNum)
                else
                    self.imgRankIconNum:SetVisible(false)
                end
                self.txtRankName.text = I18N.Get(newCell:Name())
            end

            -- 第三段：蓝色降到目标位置
            self.sliderB.value = 1
            self.sliderR.value = 1
            self.sliderB:DOValue(progress2, ANIM_DURATION):OnComplete(function()
                self.canClose = true
                self.txtContinue:SetVisible(true)
            end)
        end)
    end
end

return ReplicaPVPSettlementMediator