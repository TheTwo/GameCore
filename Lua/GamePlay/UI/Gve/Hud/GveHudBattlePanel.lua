local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local DBEntityType = require('DBEntityType')
local DBEntityPath = require('DBEntityPath')
local NumberFormatter = require('NumberFormatter')
---@class GveHudBattlePanel : BaseUIComponent
---@field compGroupPrepare GveTroopPreparePanel
---@field compChildCardHeroS HeroInfoItemComponent
---@field troopData wds.Troop
---@field damageRankingList GveHudDamageList
local GveHudBattlePanel = class('GveHudBattlePanel', BaseUIComponent)

function GveHudBattlePanel:ctor()
    self.module = ModuleRefer.GveModule
    self.slgModule = ModuleRefer.SlgModule
end

function GveHudBattlePanel:OnCreate()    
   
    
    self.goToast = self:GameObject('p_toast')
    self.textToast = self:Text('p_text_toast')
    self.textCountdown = self:Text('p_text_countdown')

    self.goGroupRight = self:GameObject('p_group_right')
    --- group_prepare
    self.compGroupPrepare = self:LuaObject('p_group_prepare')
    --- group_battle
    self.btnTroop = self:Button('p_btn_troop', Delegate.GetOrCreate(self, self.OnBtnTroopClicked))
    self.compChildCardHeroS = self:LuaObject('child_card_hero_s')
    self.sliderTroopHp = self:Slider('p_troop_hp')
    --- group_watching
    self.goWatching = self:GameObject('p_watching')
    self.textWatching = self:Text('p_text_watching', 'alliance_battle_hud21')
    self:DragEvent('p_btn_troop',
    Delegate.GetOrCreate(self,self.OnTroopBeginDrag),
    Delegate.GetOrCreate(self,self.OnTroopDrag) ,
    Delegate.GetOrCreate(self,self.OnEndTroopDrag),
    true)
    self:DragCancelEvent('p_btn_troop',Delegate.GetOrCreate(self,self.OnTroopDragCancel))

    --- group chat
    self.goGroupChat = self:GameObject('p_group_chat')    
    self.damageRankingList = self:LuaObject('p_rank')
    self.kingdomInteraction = ModuleRefer.KingdomInteractionModule
    
    ---@type GvEBossInfo
    self.compBossInfo = self:LuaObject('child_league_behemoth_top_info')
    
    --Move to ChildComponent
    -- self.goGroupBossBar = self:GameObject('p_group_boss_bar')    
    -- self.imgImgMonster = self:Image('p_img_monster')
    -- self.textBossLv = self:Text('p_text_boss_lv')
    -- self.textBloodNum = self:Text('p_text_blood_num')
    -- self.compChildTime = self:LuaObject('child_time')
    -- self.textName = self:Text('p_text_target')

    self.p_text_hint = self:Text('p_text_hint',"alliance_behemoth_copy_die1")
    self.p_text_hint_detail = self:Text('p_text_hint_detail','alliance_behemoth_copy_die2')
    self.vx_trigger_troop = self:BindComponent("vx_trigger_troop", typeof(CS.FpAnimation.FpAnimationCommonTrigger))
end


function GveHudBattlePanel:OnShow(param)
    self.goToast:SetVisible(false)
    self.textCountdown:SetVisible(false)
    self.goGroupChat:SetVisible(true)
    self.damageRankingList:SetVisible(true)
    self.isSetIconGray = nil
    g_Game.EventManager:AddListener(EventConst.GVE_TROOP_MODIFIED,Delegate.GetOrCreate(self,self.TroopModified))
    g_Game.EventManager:AddListener(EventConst.GVE_MONSTER_MODIFIED,Delegate.GetOrCreate(self,self.MobModified))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Troop.Battle.MsgPath,Delegate.GetOrCreate(self,self.OnCtrlTroopChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.MapMob.Battle.MsgPath,Delegate.GetOrCreate(self,self.OnBossChanged))
    g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.MapMob,Delegate.GetOrCreate(self,self.UpdateBossInfo))
    g_Game.EventManager:AddListener(EventConst.SLGTROOP_WARNING_PUPPET,Delegate.GetOrCreate(self,self.OnWarningEvent))
    g_Game.EventManager:AddListener(EventConst.GVE_CHAT_PANEL_STATE_CHANGED,Delegate.GetOrCreate(self,self.OnChatPanelStateChanged))
    g_Game.EventManager:AddListener(EventConst.GVE_RANK_POP_SHOW_HIDE, Delegate.GetOrCreate(self,self.OnRankPopShowHide))
end

function GveHudBattlePanel:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.GVE_TROOP_MODIFIED,Delegate.GetOrCreate(self,self.TroopModified))
    g_Game.EventManager:RemoveListener(EventConst.GVE_MONSTER_MODIFIED,Delegate.GetOrCreate(self,self.MobModified))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Troop.Battle.MsgPath,Delegate.GetOrCreate(self,self.OnCtrlTroopChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.MapMob.Battle.MsgPath,Delegate.GetOrCreate(self,self.OnBossChanged))
    g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.MapMob,Delegate.GetOrCreate(self,self.UpdateBossInfo))
    g_Game.EventManager:RemoveListener(EventConst.SLGTROOP_WARNING_PUPPET,Delegate.GetOrCreate(self,self.OnWarningEvent))
    g_Game.EventManager:RemoveListener(EventConst.GVE_CHAT_PANEL_STATE_CHANGED,Delegate.GetOrCreate(self,self.OnChatPanelStateChanged))
    g_Game.EventManager:RemoveListener(EventConst.GVE_RANK_POP_SHOW_HIDE, Delegate.GetOrCreate(self,self.OnRankPopShowHide))
end

function GveHudBattlePanel:OnOpened(param)
end

function GveHudBattlePanel:OnClose(param)
end

function GveHudBattlePanel:OnFeedData(param)
end

function GveHudBattlePanel:OnBtnTroopClicked(args)
    self:SelectAllMyTroops()
end

function GveHudBattlePanel:SelectAllMyTroops()
    self.slgModule.selectManager:ClearAllSelect()

    local count = 0;
    local ctrls = self.slgModule:GetMyTroopCtrls()
    for _, ctrl in ipairs(ctrls) do
        if ctrl:CanSelect() then
            self.slgModule.selectManager:AddSelect(ctrl)
            count = count + 1
        end
    end
    return count
end

---@param go CS.UnityEngine.GameObject
---@param pointData CS.UnityEngine.EventSystems.PointerEventData
function GveHudBattlePanel:OnTroopBeginDrag(go, pointData)
    local count = self:SelectAllMyTroops()
    if count > 0 then
        
        local ctrl = self.slgModule.selectManager:GetSelectTroopCtrl()
        self.kingdomInteraction:SetupDragTrans(ctrl.troopView.transform)
        self.slgModule.touchManager:SetPressOnCtrl(ctrl)
        self.kingdomInteraction:DoOnDragStart(pointData.position)
    end
end

function GveHudBattlePanel:OnTroopDrag(go,event)
    if not self.kingdomInteraction or not self.kingdomInteraction:IsDraging() then        
        return
    end         
    self.kingdomInteraction:DoOnDragUpdate(event.position)
end

function GveHudBattlePanel:OnEndTroopDrag(go,event)
    if  not self.kingdomInteraction or not self.kingdomInteraction:IsDraging()  then
        return
    end
   
    self.kingdomInteraction:DoOnDragStop(event.position)
    self.kingdomInteraction:SetupDragTrans(nil)
end

function GveHudBattlePanel:OnTroopDragCancel(go)
    local ctrls = self.slgModule:GetMyTroopCtrls()
    for _, ctrl in ipairs(ctrls) do
        if ctrl then
            ctrl:ReleaseTroopLine()
        end
    end

    self.kingdomInteraction:DoCancelDrag()
end

function GveHudBattlePanel:SetState(state)
    ---@type GveModule.BattleFieldState
    self.state = state or 0
end

function GveHudBattlePanel:PanelState_Prepare(args)    
    -- self.goGroupBossBar:SetVisible(true)
    
    self.compGroupPrepare:SetVisible(true)
    self.btnTroop:SetVisible(false)
    self.goWatching:SetVisible(false)
    self.compGroupPrepare:SetState_Ready(args)
    self:UpdateBossInfo()
end

function GveHudBattlePanel:PanelState_TroopSelection(args)
    -- self.goGroupBossBar:SetVisible(true)
    self.compGroupPrepare:SetVisible(true)
    self.btnTroop:SetVisible(false)
    self.goWatching:SetVisible(false)
    self.compGroupPrepare:SetState_TroopSelction(args)
    self:UpdateBossInfo()
end

function GveHudBattlePanel:PanelState_Battling(args)
    -- self.goGroupBossBar:SetVisible(true)
    self.compGroupPrepare:SetVisible(false)
    self.btnTroop:SetVisible(true)
    self.goWatching:SetVisible(false)
    self:UpdateTroopInfo()
    self:UpdateBossInfo()
end
function GveHudBattlePanel:PanelState_DeadWait(args)
    -- self.goGroupBossBar:SetVisible(true)
    self.compGroupPrepare:SetVisible(true)
    self.btnTroop:SetVisible(false)
    self.goWatching:SetVisible(false)
    self.compGroupPrepare:SetState_DeadWait(args)    
    self:UpdateBossInfo()
end
function GveHudBattlePanel:PanelState_OB(args)    
    -- self.goGroupBossBar:SetVisible(true)
    self.compGroupPrepare:SetVisible(true)
    self.btnTroop:SetVisible(true)
    self.goWatching:SetVisible(false)   
    self.compGroupPrepare:SetState_OB()
    self:UpdateBossInfo()
    self:UpdateTroopIcon()
end

function GveHudBattlePanel:PanelState_Watching(args)
    -- self.goGroupBossBar:SetVisible(false)
    self.compGroupPrepare:SetVisible(false)
    self.btnTroop:SetVisible(true)
    self.goWatching:SetVisible(false)
    self:UpdateBossInfo()
    self:UpdateTroopIcon()
end

function GveHudBattlePanel:UpdateTroopIcon()
    if not self.isSetIconGray then
        local entity = ModuleRefer.GveModule:GetTroopCandidateDBData()
        if entity then
            local heroId = entity.Candidates[1].Heros[1].ConfigId
            ---@type HeroInfoData
            local heroInfoData = {
                heroData = ModuleRefer.HeroModule:GetHeroByCfgId(heroId),
                hideJobIcon = true,
                hideStrengthen = true,
                hideStyle = true,
                onClick = nil
            }
            self.compChildCardHeroS:FeedData(heroInfoData)
            self.isSetIconGray = true
            self:UpdateTroopInfo()
            self.sliderTroopHp.value = 0
            self.compChildCardHeroS:SetGray(true)
            self.vx_trigger_troop:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        end
    end
end

function GveHudBattlePanel:UpdateTroopInfo()
    local troopData = self.module:GetSelectTroopData()
    if not troopData then
        self.troopId = nil
        return
    end
    local heroId = troopData.Battle.Group.Heros[0].HeroID
    ---@type HeroInfoData
    local heroInfoData = {
        heroData = ModuleRefer.HeroModule:GetHeroByCfgId(heroId),
        hideExtraInfo = true,       
        onClick = nil
    }
    self.compChildCardHeroS:FeedData(heroInfoData)
    self.sliderTroopHp.value = troopData.Battle.Hp / troopData.Battle.MaxHp
    self.troopId = troopData.ID
end



function GveHudBattlePanel:TroopModified()
    self:UpdateTroopInfo()
end

---@param data wds.Troop
function GveHudBattlePanel:OnCtrlTroopChanged(data,changed)
    if not self.troopId or self.troopId ~= data.ID then
        return
    end

    self.sliderTroopHp.value = data.Battle.Hp / data.Battle.MaxHp    
end

function GveHudBattlePanel:UpdateBossInfo()
    local bossData = self.module:GetBossData()
    local bossInfoParam = {
        bossData = bossData,
    }
    -- if not bossData 
    --     or not bossData.Battle 
    --     or not bossData.Battle.Group 
    --     or not bossData.Battle.Group.Heros 
    --     or not bossData.Battle.Group.Heros[0]
    -- then
    --     return
    -- end
    -- self.imgProgressFillA.fillAmount = 1
    -- local hpPct = bossData.Battle.Hp / bossData.Battle.MaxHp
    -- self.sliderProgressFillB.value = hpPct
    -- self.textBloodNum.text = NumberFormatter.PercentKeep2(hpPct)
    -- local heroId = bossData.Battle.Group.Heros[0].HeroID
    -- local heroCfg = ConfigRefer.Heroes:Find(heroId)
    
    -- self.textName.text = I18N.Get(heroCfg:Name())
    
    -- ---@type CommonTimerData
    -- local timerParam = {}
    if self.state ~= nil and self.state >= self.module.BattleFieldState.Select then
        -- timerParam.needTimer = true
        -- timerParam.endTime = self.module:GetEndTime()
        bossInfoParam.endTime = self.module:GetEndTime()
    else
        -- timerParam.fixTime = self.module:GetSceneDisplayDuration()
        bossInfoParam.fixTime = self.module:GetSceneDisplayDuration()
    end
    -- self.compChildTime:FeedData(timerParam)    


    self.compBossInfo:FeedData(bossInfoParam)
    -- local heroClientRes = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
    -- self:LoadSprite( heroClientRes:HeadMini(), self.imgImgMonster )
    -- self.textBossLv.text = tostring(bossData.Battle.Group.Heros[0].HeroLevel)
end

function GveHudBattlePanel:MobModified()
    self:UpdateBossInfo()
    if self.damageRankingList then
        self.damageRankingList:UpdateDamageInfo()
    end
end

---@param data wds.MapMob
---@param changed wds.Battle
function GveHudBattlePanel:OnBossChanged(data,changed)
    if not self.module.curBoss or self.module.curBoss.ID ~= data.ID then
        return
    end

    -- self.imgProgressFillA.fillAmount = 1
    if changed.Hp or (changed.Group and changed.Group.Heros and changed.Group.Heros[0] ) then
        -- local hpPct = data.Battle.Hp / data.Battle.MaxHp
        -- self.sliderProgressFillB.value = hpPct
        -- self.textBloodNum.text = NumberFormatter.PercentKeep2(hpPct)
        self.compBossInfo:OnBossChanged(data)
    end
end

function GveHudBattlePanel:OnWarningEvent(event)
    local troopId = event.troopId
    local show = event.show
    if not self.warningTroop then
        self.warningTroop = {}
    end
    if show then
        self.warningTroop[troopId] = true
        self.goToast:SetVisible(true)
        self.textToast.text = I18N.Get('alliance_battle_toast7')
    else
        self.warningTroop[troopId] = nil
        if table.isNilOrZeroNums(self.warningTroop) then
            self.goToast:SetVisible(false)
        end
    end
    
end

function GveHudBattlePanel:OnChatPanelStateChanged(extended)
    self.damageRankingList:SetVisible(not extended)
end

function GveHudBattlePanel:OnRankPopShowHide(show)
    self.damageRankingList:SetVisible(not show)
    self.goGroupChat:SetActive(not show)
end

return GveHudBattlePanel
