local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local ProgressType = require('ProgressType')
local UIHelper = require('UIHelper')
local UIMediatorNames = require('UIMediatorNames')
local LayoutRebuilder = CS.UnityEngine.UI.LayoutRebuilder
local Vector3 = CS.UnityEngine.Vector3

---@class WorldEventDetailMediatorParameter
---@field clickTransform CS.UnityEngine.Transform
---@field touchMenuBasicInfoDatum TouchMenuBasicInfoDatum
---@field touchMenuCellTextDatum TouchMenuCellTextDatum
---@field tid number
---@field x number
---@field y number
---@field progress number
---@field personalProgress number
---@field quality number
---@field openType number    1=从世界地图打开  2=从世界事件记录打开
--- WorldToastRewardItemDatum  WorldToastRewardItemParameter[]

---@class WorldEventDetailMediator : BaseUIMediator
local WorldEventDetailMediator = class('WorldEventDetailMediator', BaseUIMediator)

local QUALITY_COLOR = {"sp_world_base_1", "sp_world_base_2", "sp_world_base_3", "sp_world_base_4"}

function WorldEventDetailMediator:OnCreate()
    self.imgFrame = self:Image('p_img_frame')
    self.imgEventIcon = self:Image('p_event_icon')

    self.luagoMenuName = self:LuaObject('child_touch_menu_name')
    self.luagoTextContent = self:LuaObject('p_text')
    -- self.luagoGroupReward = self:LuaObject('group_reward')
    -- self.luagoGroupLeagueReward = self:LuaObject('group_reward_league')

    self.transGroupReward = self:RectTransform('p_group_reward')
    self.transItemProgress = self:RectTransform('p_item_progress')
    self.transScroll = self:RectTransform('scroll_text')
    self.transGroupLeagueReward = self:RectTransform('group_reward_league')

    self.textPersonalReward = self:Text('p_text_monsters', I18N.Get("Worldexpedition_personal_reward"))
    self.textTips = self:Text('p_text_tips', I18N.Get("Worldexpedition_reward_tips"))
    self.tableviewproTableRewards = self:TableViewPro('p_table_reward')

    self.goRoot = self:GameObject("")
    self.goContent = self:GameObject('content')

    self.textCoupleReward = self:Text('p_text_reward', I18N.Get("WorldExpedition_info_Cooperation_reward"))
    self.textCoupleRewardDes = self:Text('p_text_discriptions', I18N.Get("WorldExpedition_tips_Cooperation_reward"))
    self.luaGoCoupleReward = self:LuaObject('p_item_reward')
    self.goCoupleReward = self:GameObject('p_item_reward')

    self.p_text_reward_league = self:Text('p_text_reward_league', I18N.Get("alliance_worldevent_pop_progressrewards"))
    self.p_table_reward_league = self:TableViewPro('p_table_reward_league')

    self.btnShare = self:Button('p_btn_share', Delegate.GetOrCreate(self, self.OnBtnShareClick))
    self.p_btn_goto_activity = self:Button('p_btn_goto_activity', Delegate.GetOrCreate(self, self.OnBtnClickGotoEvent))
end

---@param param WorldEventDetailMediatorParameter
function WorldEventDetailMediator:OnOpened(param)
    if not param then
        return
    end
    self.textPersonalReward:SetVisible(true)

    self.clickTransform = param.clickTransform
    self.itemHeight = self.transItemProgress.rect.height
    if param.touchMenuBasicInfoDatum then
        self.luagoMenuName:OnFeedData(param.touchMenuBasicInfoDatum)
    end

    if param.touchMenuCellTextDatum then
        self.luagoTextContent:OnFeedData(param.touchMenuCellTextDatum)
    end

    self.posX = param.x
    self.posY = param.y
    self.openType = param.openType or 1
    if param.tid then

        self.tid = param.tid
        self.progress = param.progress or 0
        self.personalProgress = param.personalProgress or 0
        self.quality = param.quality or 0
        self.eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(self.tid)

        g_Game.SpriteManager:LoadSprite(QUALITY_COLOR[self.quality + 1], self.imgFrame)
        if self.eventCfg:WorldTaskIcon() then
            g_Game.SpriteManager:LoadSprite(self.eventCfg:WorldTaskIcon(), self.imgEventIcon)
        end
        self.p_btn_goto_activity:SetVisible(self.eventCfg:ProgressType() == ProgressType.Alliance)

        self.tableviewproTableRewards:Clear()
        self.p_table_reward_league:Clear()
        if self.eventCfg:ProgressType() == ProgressType.Personal then
            self.textCoupleReward.gameObject:SetActive(false)
            self.textCoupleRewardDes.gameObject:SetActive(false)
            self.goCoupleReward:SetActive(false)
            self.btnShare.gameObject:SetActive(false)
            self.transGroupLeagueReward:SetVisible(false)
            self.transGroupReward.sizeDelta = {x = self.transGroupReward.sizeDelta.x, y = self.itemHeight * 2}
            self.tableviewproTableRewards:AppendData({stage = 1, progress = self.eventCfg:MaxProgress(), rewardID = self.eventCfg:FullProgressReward(), type = 1, Id = self.tid})
        elseif self.eventCfg:ProgressType() == ProgressType.Whole then
            self.textCoupleReward.gameObject:SetActive(true)
            self.textCoupleRewardDes.gameObject:SetActive(true)
            self.btnShare.gameObject:SetActive(true)
            self.goCoupleReward:SetActive(true)
            self.transGroupLeagueReward:SetVisible(false)
            self.transGroupReward.sizeDelta = {x = self.transGroupReward.sizeDelta.x, y = self.itemHeight * (self.eventCfg:PartProgressRewardLength() + 1)}
            for i = 1, self.eventCfg:PartProgressRewardLength() do
                local reward = self.eventCfg:PartProgressReward(i)
                ---@type WorldToastRewardItemParameter
                self.tableviewproTableRewards:AppendData({
                    stage = i,
                    progress = reward:Progress(),
                    rewardID = reward:Reward(),
                    type = 1,
                    Id = self.tid,
                    isShowFinish = self.personalProgress >= reward:Progress(),
                })
            end

            -- 合作奖励
            if self.openType == 2 then
                self.transScroll.sizeDelta = {x = self.transScroll.sizeDelta.x, y = 960}
                self.transScroll.transform.localPosition = Vector3(self.transScroll.transform.localPosition.x, -CS.UnityEngine.Screen.height / 2 - 150, 0)
            end
            if self.eventCfg:CooReward() then
                -- local isShowFinish = self.progress == 1 and self.openType == 2
                self.luaGoCoupleReward:OnFeedData({progress = "100%", rewardID = self.eventCfg:CooReward(), type = 2, Id = self.tid, isShowFinish = false})
            end
            local curTimes = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerExpeditions.ReceiveCooRewardTimes
            self.textCoupleRewardDes.text = I18N.GetWithParams("WorldExpedition_info_Cooperation_reward_times", curTimes, ConfigRefer.ConstMain:ExpeditionCooRewardTimesPerDay())
        elseif self.eventCfg:ProgressType() == ProgressType.Alliance then
            local personalRewardsLength = self.eventCfg:PartProgressRewardLength()
            local allianceRewardsLength = self.eventCfg:AlliancePartProgressRewardLength()
            self.textCoupleReward:SetVisible(false)
            self.textCoupleRewardDes:SetVisible(false)
            self.btnShare:SetVisible(true)
            self.transGroupLeagueReward:SetVisible(true)
            self.goCoupleReward:SetVisible(false)
            self.transGroupReward.sizeDelta = {x = self.transGroupReward.sizeDelta.x, y = self.itemHeight * (personalRewardsLength + 1)}

            if personalRewardsLength == 0 then
                self.textPersonalReward:SetVisible(false)
                self.transGroupReward:SetVisible(false)
            else
                self.textPersonalReward:SetVisible(true)
                self.transGroupReward:SetVisible(true)
                for i = 1, personalRewardsLength do
                    local reward = self.eventCfg:PartProgressReward(i)
                    ---@type WorldToastRewardItemParameter
                    self.tableviewproTableRewards:AppendData({
                        stage = i,
                        progress = reward:Progress(),
                        rewardID = reward:Reward(),
                        type = 1,
                        Id = self.tid,
                        isShowFinish = self.personalProgress >= reward:Progress(),
                    })
                end
            end

            local allianceProgress = ModuleRefer.WorldEventModule:GetAllianceActivityExpeditionByExpeditionID(param.tid).Progress
            self.transGroupLeagueReward.sizeDelta = {x = self.transGroupLeagueReward.sizeDelta.x, y = self.itemHeight * (allianceRewardsLength + 1)}
            for i = 1, allianceRewardsLength do
                local reward = self.eventCfg:AlliancePartProgressReward(i)
                ---@type WorldToastRewardItemParameter
                self.p_table_reward_league:AppendData({
                    stage = i,
                    progress = reward:Progress(),
                    rewardID = reward:Reward(),
                    type = 1,
                    Id = self.tid,
                    isShowFinish = allianceProgress >= reward:Progress(),
                })
            end

        end

    end
    -- if self.clickTransform then
    --     LayoutRebuilder.ForceRebuildLayoutImmediate(self.goContent.transform)
    --     self:LimitInScene()
    -- end
end

function WorldEventDetailMediator:LimitInScene()
    local anchorPos = self.clickTransform.position
    local halfHeight = self.clickTransform.rect.height / 2
    local halfWidth = self.clickTransform.rect.width / 2
    self.goContent.transform.position = anchorPos

    self.goContent.transform.localPosition = Vector3(self.clickTransform.position.x + halfWidth, self.clickTransform.position.y - halfHeight - 40, 0)
end

function WorldEventDetailMediator:OnClose(param)
    -- TODO
end

function WorldEventDetailMediator:OnBtnShareClick()
    self:CloseSelf()
    local ChatShareType = require("ChatShareType")
    ---@type ShareChannelChooseParam
    local param = {type = ChatShareType.WorldEvent, configID = self.tid, x = self.posX, y = self.posY}
    g_Game.UIManager:Open(UIMediatorNames.ShareChannelChooseMediator, param)
end

function WorldEventDetailMediator:OnBtnClickGotoEvent()
    self:CloseSelf()
    local isBigEvent = ModuleRefer.WorldEventModule:IsAllianceBigWorldEvent(self.tid)
    ModuleRefer.ActivityCenterModule:GotoActivity(isBigEvent and 8 or ModuleRefer.WorldEventModule:GetPersonalOwnAllianceExpedition())
end

return WorldEventDetailMediator
