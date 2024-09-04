local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local ModuleRefer = require("ModuleRefer")
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
local UIMediatorNames = require('UIMediatorNames')
local DBEntityPath = require('DBEntityPath')
local UIFactionMainMediator = class('UIFactionMainMediator',BaseUIMediator)

function UIFactionMainMediator:OnCreate()
    self.tableviewproTableTabPower = self:TableViewPro('p_table_tab_power')
    self.imgIconLogo = self:Image('p_icon_logo')
    self.textNamePower = self:Text('p_text_name_power')
    self.btnAuthority = self:Button('p_btn_authority', Delegate.GetOrCreate(self, self.OnBtnAuthorityClicked))
    self.btnTerritory = self:Button('p_btn_territory', Delegate.GetOrCreate(self, self.OnBtnTerritoryClicked))
    self.btnShop = self:Button('p_btn_shop', Delegate.GetOrCreate(self, self.OnBtnShopClicked))
    self.compChildReddotDefault = self:LuaObject('child_reddot_default')
    self.textDetail = self:Text('p_text_detail')
    self.goStatusLock = self:GameObject('p_status_lock')
    self.textTask = self:Text('p_text_task', I18N.Get("relation_task_title"))
    self.tableviewproTableTask = self:TableViewPro('p_table_task')
    self.goStatusUnlock = self:GameObject('p_status_unlock')
    self.textPower = self:Text('p_text_power', I18N.Get("prestige_present"))
    self.textPowerNum = self:Text('p_text_power_num')
    self.sliderProgressPrestige = self:Slider('p_progress_prestige')
    self.tableviewproTablePrestige = self:TableViewPro('p_table_prestige')
    self.textWay = self:Text('p_text_way', I18N.Get("prestige_channel"))
    self.btnPowerTask = self:Button('p_btn_power_task', Delegate.GetOrCreate(self, self.OnBtnPowerTaskClicked))
    self.textPowerTask = self:Text('p_text_power_task', I18N.Get("sov_task_title"))
    self.btnSeTask = self:Button('p_btn_se_task', Delegate.GetOrCreate(self, self.OnBtnSeTaskClicked))
    self.textSeTask = self:Text('p_text_se_task', I18N.Get("sov_raid_title"))
    self.compChildCommonBack = self:LuaObject('child_common_btn_back')
    self.imgReward = self:Image('p_icon_item_reward')
    self.goBasePrestige = self:GameObject('p_base_prestige')
    self.textNum = self:Text('p_text_prestige_num')
    self.btnReward = self:Button('p_btn_prestige_reward', Delegate.GetOrCreate(self, self.OnBtnRewardClicked))
end

function UIFactionMainMediator:OnOpened(param)
    self.compChildCommonBack:OnFeedData({title = I18N.Get("sovereign_name")})
    self:InitPanel()
    g_Game.EventManager:AddListener(EventConst.FACTION_SELECT_TAB, Delegate.GetOrCreate(self, self.RefreshById))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.MisCell.Cells.MsgPath,Delegate.GetOrCreate(self,self.RefreshByQuest))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Task.MsgPath, Delegate.GetOrCreate(self,self.RefreshByQuest))
    g_Game.EventManager:TriggerEvent(EventConst.FACTION_OPENED)
end

function UIFactionMainMediator:InitPanel()
    local factionList = {}
    for _, v in ConfigRefer.Sovereign:ipairs() do
        factionList[#factionList + 1] = v:Id()
    end

    self.tableviewproTableTabPower:Clear()
    for _, factionId in ipairs(factionList) do
        self.tableviewproTableTabPower:AppendData({factionId = factionId})
    end
    self.tableviewproTableTabPower:SetToggleSelectIndex(0)
    self:RefreshById(factionList[1])
end

function UIFactionMainMediator:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.FACTION_SELECT_TAB, Delegate.GetOrCreate(self, self.RefreshById))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.MisCell.Cells.MsgPath,Delegate.GetOrCreate(self,self.RefreshByQuest))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Task.MsgPath, Delegate.GetOrCreate(self,self.RefreshByQuest))
end

function UIFactionMainMediator:RefreshByQuest()
    self:RefreshById(self.factionId)
end

function UIFactionMainMediator:RefreshById(factionId)
    self.factionId = factionId
    local factionCfg = ConfigRefer.Sovereign:Find(factionId)
    g_Game.SpriteManager:LoadSprite(factionCfg:Icon(), self.imgIconLogo)
    self.textNamePower.text = I18N.Get(factionCfg:Name())
    self.textDetail.text = I18N.Get(factionCfg:Desc())
    local isFactionUnlock = ModuleRefer.FactionModule:CheckFactionIsUnlock(factionId)
    self.goStatusLock:SetActive(not isFactionUnlock)
    self.goStatusUnlock:SetActive(isFactionUnlock)
    if isFactionUnlock then
        local curNumber = ModuleRefer.FactionModule:GetFactionPrestigeValue(self.factionId)
        local maxNumber = ModuleRefer.FactionModule:GetMaxPrestigeValue(self.factionId)
        self.textPowerNum.text = curNumber
        self.sliderProgressPrestige.value = curNumber / maxNumber
        self.tableviewproTablePrestige:Clear()
        local rewards = factionCfg:ReputationReward()
        local rewardCfg = ConfigRefer.SovereignReputation:Find(rewards)
        local width = self.sliderProgressPrestige.transform.rect.width
        for i = 1, rewardCfg:StageRewardLength() do
            if i == rewardCfg:StageRewardLength() then
                local isEnough = curNumber >= maxNumber
                self.goBasePrestige:SetActive(isEnough)
                self.textNum.text = maxNumber
                local itemId = ConfigRefer.SovereignConst:FinalReward()
                self.index = rewardCfg:StageRewardLength()
                g_Game.SpriteManager:LoadSprite(ConfigRefer.Item:Find(itemId):Icon(), self.imgReward)
            else
                local offset = 0
                self.tableviewproTablePrestige:AppendData({factionId = factionId, index = i, width = width, offset = offset})
            end
        end
    else
        self.tableviewproTableTask:Clear()
        for i = 1, factionCfg:DiplomaticTasksLength() do
            self.tableviewproTableTask:AppendData(factionCfg:DiplomaticTasks(i))
        end
    end
end

function UIFactionMainMediator:OnBtnRewardClicked()
    g_Game.UIManager:Open(UIMediatorNames.UIFactionPrestigeMediator, {factionId = self.factionId, index = self.index})
end

function UIFactionMainMediator:OnBtnAuthorityClicked(args)
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("see_you_next_time"))
    --g_Game.UIManager:Open(UIMediatorNames.UIFactionArchitectureMediator, {factionId = self.factionId})
end

function UIFactionMainMediator:OnBtnTerritoryClicked(args)
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("see_you_next_time"))
end

function UIFactionMainMediator:OnBtnShopClicked(args)
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("see_you_next_time"))
end

function UIFactionMainMediator:OnBtnPowerTaskClicked(args)
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("see_you_next_time"))
end

function UIFactionMainMediator:OnBtnSeTaskClicked(args)
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("see_you_next_time"))
end

return UIFactionMainMediator