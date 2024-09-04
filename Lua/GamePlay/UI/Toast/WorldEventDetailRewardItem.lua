local BaseUIMediator = require ('BaseUIMediator')
local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local DBEntityPath = require("DBEntityPath")

---@class WorldToastRewardItemParameter
---@field stage number     奖励阶段
---@field progress number   阶段需要的参与度
---@field rewardID number     奖励GroupID
---@field type number       类型(1 = 阶段奖励， 2 = 合作奖励)
---@field Id number       Tid
---@field isShowFinish boolean       是否显示完成

---@class WorldEventDetailRewardItem : BaseTableViewProCell
local WorldEventDetailRewardItem = class('WorldEventDetailRewardItem', BaseTableViewProCell)

function WorldEventDetailRewardItem:OnCreate()
    self.textProgress = self:Text('p_text_progress')
    -- self.tableviewproTableRewards = self:TableViewPro('')
    self.goReward1 = self:GameObject('p_reward_1')
    self.goReward2 = self:GameObject('p_reward_2')
    self.goReward3 = self:GameObject('p_reward_3')
    self.goReward4 = self:GameObject('p_reward_4')
    self.goReward5 = self:GameObject('p_reward_5')
    self.luagoRewardItem1 = self:LuaObject('child_item_standard_s_1')
    self.luagoRewardItem2 = self:LuaObject('child_item_standard_s_2')
    self.luagoRewardItem3 = self:LuaObject('child_item_standard_s_3')
    self.luagoRewardItem4 = self:LuaObject('child_item_standard_s_4')
    self.luagoRewardItem5 = self:LuaObject('child_item_standard_s_5')
    
    self.goGetReward = self:GameObject('p_img_finish')
    self.compAlphaCanvasGroup = self:BindComponent('p_alpha', typeof(CS.UnityEngine.CanvasGroup))

    self.goRewardArr = {self.goReward1, self.goReward2, self.goReward3, self.goReward4, self.goReward5}
    self.luagoRewardItemArr = {self.luagoRewardItem1, self.luagoRewardItem2, self.luagoRewardItem3, self.luagoRewardItem4, self.luagoRewardItem5}
end

function WorldEventDetailRewardItem:OnShow(param)
    self:OnRegisterEvents()
end

function WorldEventDetailRewardItem:OnHide()
    self:OnRemoveEvents()
end

function WorldEventDetailRewardItem:OnRegisterEvents(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerExpeditions.JoinExpeditions.MsgPath, Delegate.GetOrCreate(self, self.OnJoinDataChanged))
end

function WorldEventDetailRewardItem:OnRemoveEvents(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerExpeditions.JoinExpeditions.MsgPath, Delegate.GetOrCreate(self, self.OnJoinDataChanged))
end

---@param param WorldToastRewardItemParameter
function WorldEventDetailRewardItem:OnFeedData(param)
    if not param then
        return
    end
    self.stage = param.stage
    self.progress = param.progress
    self.rewardID = param.rewardID
    self.type = param.type or 1
    self.Id = param.Id
    local isShowFinish = param.isShowFinish or false
    self:SetShowFinish(isShowFinish)
    self:InitRewardItem()
end

function WorldEventDetailRewardItem:InitRewardItem()
    self.textProgress.text = self.progress
    local itemGroupConfig = ConfigRefer.ItemGroup:Find(self.rewardID)
    local maxItemNum = 5
    local itemNum = itemGroupConfig:ItemGroupInfoListLength()

    if itemNum <= maxItemNum then
        for i = itemNum, maxItemNum do
            self.goRewardArr[i]:SetActive(false)
        end
        
        for i = 1, itemNum do
            local itemGroup = itemGroupConfig:ItemGroupInfoList(i)
            self.luagoRewardItemArr[i]:OnFeedData({configCell = ConfigRefer.Item:Find(itemGroup:Items()), count = itemGroup:Nums(), showTips = true})
            self.goRewardArr[i]:SetActive(true)
        end
    end
end

function WorldEventDetailRewardItem:OnJoinDataChanged(entity, changedTable)
    if not changedTable.Add then return end
    if self.type == 2 then
        return
    end

    for id, expeditionInfo in pairs(changedTable.Add) do
        if expeditionInfo.ExpeditionInstanceTid == self.Id then
            if expeditionInfo.progress >= self.progress then
                self:SetShowFinish(true)
                return
            end
        end
    end
end

function WorldEventDetailRewardItem:SetShowFinish(isShow)
    if isShow then
        self.goGetReward:SetActive(true)
    else
        self.goGetReward:SetActive(false)
    end
end

return WorldEventDetailRewardItem