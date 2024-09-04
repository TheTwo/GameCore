local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local ModuleRefer = require("ModuleRefer")
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
local UIMediatorNames = require('UIMediatorNames')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local UIFactionPrestigeMediator = class('UIFactionPrestigeMediator',BaseUIMediator)

function UIFactionPrestigeMediator:OnCreate()
    self.compChildCommonBack = self:LuaObject('child_common_btn_back')
    self.textPower = self:Text('p_text_power', I18N.Get("prestige_present"))
    self.textPowerNum = self:Text('p_text_power_num')
    self.imgIconReward = self:Image('p_icon_reward')
    self.sliderProgressPrestige = self:Slider('p_progress_prestige')
    self.tableviewproTablePrestige = self:TableViewPro('p_table_prestige')
    self.imgIconLogo = self:Image('p_icon_logo')
    self.textPrestigeLv = self:Text('p_text_prestige_lv')
    self.textTask = self:Text('p_text_task')
    self.textSe = self:Text('p_text_se')
    self.textStop = self:Text('p_text_stop')
    self.goReward = self:GameObject('reward')
    self.textStop1 = self:Text('p_text_stop_1', I18N.Get("sov_prestige_unlock_04"))
    self.tableviewproTableReward = self:TableViewPro('p_table_reward')
    self.btnLeft = self:Button('p_btn_left', Delegate.GetOrCreate(self, self.OnBtnLeftClicked))
    self.btnRight = self:Button('p_btn_right', Delegate.GetOrCreate(self, self.OnBtnRightClicked))
    self.imgReward = self:Image('p_icon_item_reward')
    self.goBasePrestige = self:GameObject('p_base_prestige')
    self.textNum = self:Text('p_text_prestige_num')
    self.textReward = self:Text('p_text_prestige_reward')
    self.goSelectReward = self:GameObject('p_select_prestige_reward')
    self.btnReward = self:Button('p_btn_prestige_reward', Delegate.GetOrCreate(self, self.OnBtnRewardClicked))
    self.textStop.gameObject:SetActive(false)
end

function UIFactionPrestigeMediator:OnOpened(param)
    self.factionId = param.factionId
    self.index = param.index
    self.compChildCommonBack:OnFeedData({title = I18N.Get("sov_general_des2")})
    local curNumber = ModuleRefer.FactionModule:GetFactionPrestigeValue(self.factionId)
    local maxNumber = ModuleRefer.FactionModule:GetMaxPrestigeValue(self.factionId)
    self.textPowerNum.text = curNumber
    self.sliderProgressPrestige.value = curNumber / maxNumber
    self.tableviewproTablePrestige:Clear()
    local factionCfg = ConfigRefer.Sovereign:Find(self.factionId)
    local rewards = factionCfg:ReputationReward()
    self.rewardCfg = ConfigRefer.SovereignReputation:Find(rewards)
    local width = self.sliderProgressPrestige.transform.rect.width
    for i = 1, self.rewardCfg:StageRewardLength() do
        if i == self.rewardCfg:StageRewardLength() then
            local isEnough = curNumber >= maxNumber
            self.goBasePrestige:SetActive(isEnough)
            self.textNum.text = maxNumber
            local stageReward = self.rewardCfg:StageReward(i)
            self.itemId = ConfigRefer.SovereignConst:FinalReward()
            self.textReward.text = I18N.Get(stageReward:Relation())
            g_Game.SpriteManager:LoadSprite(ConfigRefer.Item:Find(self.itemId):Icon(), self.imgReward)
        else
            local offset = 0
            self.tableviewproTablePrestige:AppendData({factionId = self.factionId, index = i, width = width, forbidClick = true, offset = offset})
        end

    end
    self.factionId = param.factionId
    g_Game.SpriteManager:LoadSprite(factionCfg:Icon(), self.imgIconLogo)
    self:RefreshDetails()
end

function UIFactionPrestigeMediator:OnBtnRewardClicked()
    local param = {
        itemId = self.itemId,
        itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM,
        clickTransform = self.btnReward.transform
    }
    g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
end

function UIFactionPrestigeMediator:OnClose()

end

function UIFactionPrestigeMediator:RefreshDetails()
    local stageReward = self.rewardCfg:StageReward(self.index)
    self.textPrestigeLv.text = I18N.Get(stageReward:Relation())
    if stageReward:InstancesLength() >= 1 then
        self.textSe.gameObject:SetActive(true)
        self.textSe.text = I18N.Get(ConfigRefer.MapInstance:Find(stageReward:Instances(1)):Name())
    else
        self.textSe.gameObject:SetActive(false)
    end
    if stageReward:TasksLength() >= 1 then
        self.textTask.gameObject:SetActive(true)
        local taskId = stageReward:Tasks(1)
        local taskCfg = ConfigRefer.Task:Find(taskId)
        local taskNameKey,taskNameParam = ModuleRefer.QuestModule:GetTaskName(taskCfg)
        local taskName = I18N.GetWithParamList(taskNameKey,taskNameParam)
        self.textTask.text = taskName
    else
        self.textTask.gameObject:SetActive(false)
    end
    if stageReward:RewardLength() >= 1 then
        self.goReward:SetActive(true)
        local itemGroup = stageReward:Reward(1)
        local items = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(itemGroup)
        self.tableviewproTableReward:Clear()
        for _, item in ipairs(items) do
            self.tableviewproTableReward:AppendData(item)
        end
    else
        self.goReward:SetActive(false)
    end
    if self.index < self.rewardCfg:StageRewardLength() then
        self.tableviewproTablePrestige:SetToggleSelectIndex(self.index - 1)
        self.goSelectReward:SetActive(false)
        self.imgIconReward.gameObject:SetActive(false)
        self.imgIconLogo.gameObject:SetActive(true)
        self.textPrestigeLv.gameObject:SetActive(true)
    else
        self.tableviewproTablePrestige:UnSelectAll()
        self.goSelectReward:SetActive(true)
        self.imgIconReward.gameObject:SetActive(true)
        self.imgIconLogo.gameObject:SetActive(false)
        self.textPrestigeLv.gameObject:SetActive(false)
    end
end

function UIFactionPrestigeMediator:OnBtnLeftClicked(args)
    self.index = self.index - 1
    if self.index < 1 then
        self.index = self.rewardCfg:StageRewardLength()
    end
    self:RefreshDetails()
end

function UIFactionPrestigeMediator:OnBtnRightClicked(args)
    self.index = self.index + 1
    if self.index > self.rewardCfg:StageRewardLength() then
        self.index = 1
    end
    self:RefreshDetails()
end


return UIFactionPrestigeMediator