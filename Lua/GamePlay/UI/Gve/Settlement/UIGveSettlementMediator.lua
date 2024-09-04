---Deprecated
---scene: scene_league_gve_settlement
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local NumberFormatter = require('NumberFormatter')
---@class UIGveSettlementMediator : BaseUIMediator
local UIGveSettlementMediator = class('UIGveSettlementMediator', BaseUIMediator)

function UIGveSettlementMediator:ctor()
    self.module = ModuleRefer.GveModule
end

function UIGveSettlementMediator:OnCreate()
    self.goWin = self:GameObject('p_win')
    self.goLose = self:GameObject('p_lose')
    self.textBattleInfo = self:Text('p_text_battle_info', 'alliance_battle_hud23')
    self.textTime = self:Text('p_text_time', 'alliance_battle_hud22')
    self.compChildTime = self:LuaBaseComponent('child_time')
    self.textProgress = self:Text('p_text_progress', 'alliance_battle_hud24')
    self.sliderProgressFillB = self:Slider('p_progress_fill_b')
    self.imgImgMonster = self:Image('p_img_monster')
    self.textBossLv = self:Text('p_text_boss_lv')
    self.textBloodNum = self:Text('p_text_blood_num')
    self.btnFinish = self:Button('p_finish', Delegate.GetOrCreate(self, self.OnBtnFinishClicked))
    self.goGroupContinue = self:GameObject('p_group_continue')
    self.textContinue1 = self:Text('p_text_continue_1', 'task_open_next_click')
    self.textContinue2 = self:Text('p_text_continue_2')

    self.goRanking = self:GameObject('ranking')
    self.textTitleRanking = self:Text('p_text_title_ranking','gverating_rank')
    self.textTitlePlayer = self:Text('p_text_title_player','gverating_commander')
    self.textTitleOutput = self:Text('p_text_title_output','gverating_totaloutput')
    self.damageDataTable = self:TableViewPro('table_ranking')

    self.goResultVictory = self:GameObject('p_result_victory')
    self.goResultDefeat = self:GameObject('p_result_defeat')
    --Init Node State
    self.goGroupContinue:SetVisible(false)
    self.goRanking:SetVisible(true)

    local isWin = self.module:IsWin()
    self.goWin:SetVisible(isWin)
    self.goLose:SetVisible(not isWin)
    self.textBattleInfo:SetVisible(not isWin)


    self.goResultVictory:SetVisible(isWin)
    self.goResultDefeat:SetVisible(not isWin)
end


function UIGveSettlementMediator:OnShow(param)
    self:UpdateBossInfo()
    self:UpdateDamageInfo()
    self.timer = ConfigRefer.ConstMain:GvEFinishWaitTime() - self.module.FinishDelay
    self.showCountdownTime = self.timer - 3
    self.textContinue2.text = I18N.GetWithParams('se_end_countdown', tostring(math.floor(self.timer)))
    self.canContinue = false
    self.isExiting = false
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self,self.Tick))
end

function UIGveSettlementMediator:OnHide(param)
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self,self.Tick))
end

function UIGveSettlementMediator:OnOpened(param)
end

function UIGveSettlementMediator:OnClose(param)
end

function UIGveSettlementMediator:Tick(delta)    
    self.timer = math.max(0, self.timer - delta)
    if self.timer < self.showCountdownTime then
        if not self.canContinue then
            self.goGroupContinue:SetVisible(true)
            self.canContinue = true
        end
        self.textContinue2.text = I18N.GetWithParams('se_end_countdown', tostring(math.floor(self.timer)))
    end
end

function UIGveSettlementMediator:UpdateBossInfo()
    local bossData = self.module:GetBossData()
    if not bossData
        or not bossData.Battle
        or not bossData.Battle.Group
        or not bossData.Battle.Group.Heros
        or not bossData.Battle.Group.Heros[0]
    then
        return
    end
    local hpPct = bossData.Battle.Hp / bossData.Battle.MaxHp
    self.sliderProgressFillB.value = hpPct
    self.textBloodNum.text = NumberFormatter.PercentKeep2(hpPct)
    local heroId = bossData.Battle.Group.Heros[0].HeroID
    local heroCfg = ConfigRefer.Heroes:Find(heroId)

    -- self.textTarget.text = I18N.Get(heroCfg:Name())
    ---@type CommonTimerData
    local timerParam = {
        fixTime = self.module:GetUseTime()
    }
    self.compChildTime:FeedData(timerParam)

    local heroClientRes = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
    self:LoadSprite( heroClientRes:HeadMini(), self.imgImgMonster )
    self.textBossLv.text = tostring(bossData.Battle.Group.Heros[0].HeroLevel)
end


function UIGveSettlementMediator:OnBtnFinishClicked(args)
   if not self.canContinue or self.isExiting then
        return
    end
    self.isExiting = true    
    ModuleRefer.GveModule:Exit()
end


function UIGveSettlementMediator:UpdateDamageInfo()
    local damageList,allDamage,maxPlayerDamage = self.module:GetBossDamageDatas()
    if damageList == nil then
        return
    end
    self.damageDataTable:Clear()
    local findedSelf = false
    for index, value in ipairs(damageList) do
        if index < 4 then
            ---@type GveBattleDamageInfoCellData
            local info = {}
            info.index = index
            info.isSelf = ModuleRefer.PlayerModule:IsMineById(value.playerId)
            info.damageInfo = value
            info.allDamage = allDamage
            info.maxPlayerDamage = maxPlayerDamage
            self.damageDataTable:AddData(info)
            if info.isSelf then
                findedSelf = true
            end
        elseif not findedSelf then
            findedSelf = ModuleRefer.PlayerModule:IsMineById(value.playerId)
            if findedSelf then
                ---@type GveBattleDamageInfoCellData
                local info = {}
                info.index = index
                info.isSelf = true
                info.damageInfo = value
                info.allDamage = allDamage
                info.maxPlayerDamage = maxPlayerDamage
                self.damageDataTable:AddData(info)
                break
            end
        end
    end
end

return UIGveSettlementMediator
