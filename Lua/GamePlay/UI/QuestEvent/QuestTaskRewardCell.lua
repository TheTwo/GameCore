local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local Utils = require('Utils')
local EventConst = require('EventConst')
local I18N = require('I18N')
local GuideFingerUtil = require('GuideFingerUtil')
local NpcServiceObjectType = require("NpcServiceObjectType")

local QuestTaskRewardCell = class('QuestTaskRewardCell',BaseTableViewProCell)

function QuestTaskRewardCell:OnCreate(param)
    self.textReward = self:Text("p_text_reward")
    self.animationTrigger = self:AnimTrigger("p_root")
    self.goGroupHead = self:GameObject('p_group_head')
    self.imgImgHeroHead = self:Image('p_img_hero_head')
    self.goFinish = self:GameObject('p_finish')
    self.btnNpcGoto = self:Button('p_btn_npc_goto', Delegate.GetOrCreate(self, self.OnBtnNpcGotoClicked))
    self.tableviewproItemTableSlotRewards = self:TableViewPro('p_item_table_slot_rewards')
    self.goClaimed = self:GameObject('p_claimed')
end

function QuestTaskRewardCell:OnFeedData(data)
    self.data = data
    self.textReward.text = I18N.Get(data.title)
    local allNpcIds = ModuleRefer.QuestModule.Chapter:GetAllNpcsInCurChapter() or {}
    local isShowFinish = allNpcIds[data.chatNpcId] == nil and data.allFinished
    self.goFinish:SetActive(isShowFinish)
    self.goGroupHead:SetActive(data.showHead)
    if data.showHead then
        g_Game.SpriteManager:LoadSprite(ConfigRefer.ChatNPC:Find(data.chatNpcId):Icon(), self.imgImgHeroHead)
    end
    self.btnNpcGoto.gameObject:SetActive(not isShowFinish)
    self.goClaimed:SetActive(isShowFinish)
    self.isNew = data.isNew
    if self.isNew then
        self.isNew = false
        self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
    local rewards = data.rewards
    self.tableviewproItemTableSlotRewards:Clear()
    if rewards then
        local items = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(rewards)
        if items then
            for _, item in ipairs(items) do
                local itemData = {}
                itemData.Items = function() return item.configCell:Id() end
                itemData.Nums = function() return item.count end
                self.tableviewproItemTableSlotRewards:AppendData(itemData)
            end
        end
    end
end

function QuestTaskRewardCell:OnBtnNpcGotoClicked(args)
    self:GetParentBaseUIMediator():BackToPrevious()
    local city = ModuleRefer.CityModule:GetMyCity()
    if not city or not city.cityExplorerManager or not city.cityCitizenManager then
        return
    end
    ---@type KingdomScene
    local currentScene = g_Game.SceneManager.current
    if not currentScene or currentScene:GetName() ~= "KingdomScene" then
        return
    end
    if not currentScene:IsInMyCity() then
        g_Game.EventManager:TriggerEvent(EventConst.HUD_RETURN_TO_MY_CITY)
        return
    end

    if self.data.isNpc and self.data.cityElementNpcId then
        local autoClick = ModuleRefer.QuestModule.Chapter:CheckIsShowCityElementNpcHeadIcon(self.data.cityElementNpcId)
        ModuleRefer.PlayerServiceModule:FocusOnObjectBubble(NpcServiceObjectType.CityElement, self.data.cityElementNpcId, function(isSuccess, bubbleTrans)
            if isSuccess and not autoClick and Utils.IsNotNull(bubbleTrans) then
                GuideFingerUtil.ShowGuideFingerOnBubbleTransform(bubbleTrans)
            end
        end, autoClick)
    elseif self.data.citizenId then
        local autoClick = ModuleRefer.QuestModule.Chapter:CheckIsShowCitizenHeadIcon(self.data.citizenId)
        ModuleRefer.PlayerServiceModule:FocusOnObjectBubble(NpcServiceObjectType.Citizen, self.data.citizenId, function(isSuccess, bubbleTrans)
            if isSuccess and not autoClick and Utils.IsNotNull(bubbleTrans) then
                GuideFingerUtil.ShowGuideFingerOnBubbleTransform(bubbleTrans)
            end
        end, autoClick)
    end
end


return QuestTaskRewardCell
