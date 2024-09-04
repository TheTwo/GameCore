--- scene:scene_league_behemoth_award_tip

local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local Utils = require("Utils")
local TipsRectTransformUtils = require("TipsRectTransformUtils")
local ItemGroupType = require("ItemGroupType")
local RewardShowType = require("RewardShowType")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceBehemothAwardTipMediatorParameter
---@field kMonsterConfig KmonsterDataConfigCell
---@field clickTrans CS.UnityEngine.Transform

---@class AllianceBehemothAwardTipMediator:BaseUIMediator
---@field new fun():AllianceBehemothAwardTipMediator
---@field super BaseUIMediator
local AllianceBehemothAwardTipMediator = class('AllianceBehemothAwardTipMediator', BaseUIMediator)

function AllianceBehemothAwardTipMediator:ctor()
    AllianceBehemothAwardTipMediator.super.ctor(self)
    ---@type CS.UnityEngine.RectTransform
    self._clickTrans = nil
end

function AllianceBehemothAwardTipMediator:OnCreate(param)
    self._p_table_award = self:TableViewPro("p_table_award")
    self._p_rect_range = self:RectTransform("p_rect_range")
end

---@param data AllianceBehemothAwardTipMediatorParameter
function AllianceBehemothAwardTipMediator:OnOpened(data) 
    self._clickTrans = data.clickTrans
    self._p_table_award:Clear()
    local defeatReward = data.kMonsterConfig:DropShow()
    local itemGroup = ConfigRefer.ItemGroup:Find(defeatReward)
    if itemGroup then
        -- 击败奖励
        self._p_table_award:AppendData(I18N.Get("alliance_behemoth_challenge_gift2"))
        ---@type ItemIconData[]
        local rewards = {}
        for i = 1, itemGroup:ItemGroupInfoListLength() do
            local itemInfo = itemGroup:ItemGroupInfoList(i)
            ---@type ItemIconData
            local iconData = {}
            iconData.configCell = ConfigRefer.Item:Find(itemInfo:Items())
            iconData.count = itemInfo:Nums()
            iconData.useNoneMask = false
            table.insert(rewards, iconData)
        end
        self._p_table_award:AppendData(rewards, 1)
    end
    
    local config = ConfigRefer.MapInstanceReward:Find(data.kMonsterConfig:InstanceRankReward())
    if config then
        local rankStageCount = config:RewardsLength()
        if rankStageCount > 0 then
            -- 伤害排名奖励
            self._p_table_award:AppendData(I18N.Get("alliance_behemoth_challenge_gift3"))
            for i = 1, rankStageCount - 1 do
                local rewardRankInfo = config:Rewards(i)
                ---@type AllianceBehemothAwardTipCellLevelRewardData
                local cellData = {}
                cellData.lv = rewardRankInfo:UnitRewardParam1()
                cellData.lvEnd = rewardRankInfo:UnitRewardParam2()
                cellData.cells = {}
                if rewardRankInfo:UnitRewardShowType() == RewardShowType.ShowWithNum then
                    local groupItem = ConfigRefer.ItemGroup:Find(rewardRankInfo:UnitRewardConf2())
                    for j = 1, groupItem:ItemGroupInfoListLength()do
                        local itemI = groupItem:ItemGroupInfoList(j)
                        ---@type ItemIconData
                        local iconData = {}
                        iconData.configCell = ConfigRefer.Item:Find(itemI:Items())
                        iconData.count = itemI:Nums()
                        iconData.useNoneMask = false
                        table.insert(cellData.cells, iconData)
                    end
                else
                    for j = 1, rewardRankInfo:UnitRewardConfLength() do
                        ---@type ItemIconData
                        local iconData = {}
                        iconData.configCell = ConfigRefer.Item:Find(rewardRankInfo:UnitRewardConf(j))
                        iconData.count = 0
                        iconData.showCount = false
                        iconData.useNoneMask = false
                        table.insert(cellData.cells, iconData)
                    end
                end
                self._p_table_award:AppendData(cellData, 2)
            end
            if rankStageCount > 1 then
                -- 参与奖励
                self._p_table_award:AppendData(I18N.Get("alliance_behemoth_challenge_gift4"))
                local rewardRankInfo = config:Rewards(rankStageCount)
                ---@type ItemIconData[]
                local cells = {}
                if rewardRankInfo:UnitRewardShowType() == RewardShowType.ShowWithNum then
                    local groupItem = ConfigRefer.ItemGroup:Find(rewardRankInfo:UnitRewardConf2())
                    for j = 1, groupItem:ItemGroupInfoListLength()do
                        local itemI = groupItem:ItemGroupInfoList(j)
                        ---@type ItemIconData
                        local iconData = {}
                        iconData.configCell = ConfigRefer.Item:Find(itemI:Items())
                        iconData.count = itemI:Nums()
                        iconData.useNoneMask = false
                        table.insert(cells, iconData)
                    end
                else
                    for j = 1, rewardRankInfo:UnitRewardConfLength() do
                        ---@type ItemIconData
                        local iconData = {}
                        iconData.configCell = ConfigRefer.Item:Find(rewardRankInfo:UnitRewardConf(j))
                        iconData.count = 0
                        iconData.showCount = false
                        iconData.useNoneMask = false
                        table.insert(cells, iconData)
                    end
                end
                self._p_table_award:AppendData(cells, 1)
            end
        end
    end
    
    --- ID1168218【【巨兽巢穴】隐藏观战奖励，挑战巨兽只有击败奖励、排名奖励、升级奖励和这个版本不做需要隐藏的观战奖励】
    local watchReward = nil--ConfigRefer.RandomBox:Find(data.kMonsterConfig:InstanceWatchBox())
    if watchReward then
        -- 观战奖励
        self._p_table_award:AppendData(I18N.Get("alliance_behemoth_challenge_gift5"))
        ---@type table<number, ItemIconData>
        local mergeCells = {}
        ---@type ItemIconData[]
        local cells = {}
        for i = 1, watchReward:GroupInfoLength() do
            local groupInfo = watchReward:GroupInfo(i)
            local group = ConfigRefer.ItemGroup:Find(groupInfo:Groups())
            for j = 1, group:ItemGroupInfoListLength() do
                local info = group:ItemGroupInfoList(j)
                if not mergeCells[info:Items()] then
                    ---@type ItemIconData
                    local iconData = {}
                    iconData.configCell = ConfigRefer.Item:Find(info:Items())
                    iconData.count = info:Nums()
                    iconData.useNoneMask = false
                    table.insert(cells, iconData)
                else
                    local count = math.max(mergeCells[info:Items()].count, info:Nums())
                    mergeCells[info:Items()].count = count
                end
            end
        end
        self._p_table_award:AppendData(cells, 1)
    end
    
    local behemothInfo = ConfigRefer.BehemothData:Find(data.kMonsterConfig:BehemothInfo())
    
    if behemothInfo then
        local mail = ConfigRefer.Mail:Find(behemothInfo:LevelUpRewardMail())
        local upReward = mail and ConfigRefer.ItemGroup:Find(mail:Attachment())
        if upReward and upReward:Type() == ItemGroupType.OneByOne or upReward:ItemGroupInfoListLength() > 0 then
            -- 伤害排名奖励
            self._p_table_award:AppendData(I18N.Get("alliance_behemoth_challenge_gift6"))
            ---@type ItemIconData[]
            local cells = {}
            for j = 1, upReward:ItemGroupInfoListLength() do
                local itmeInfo = upReward:ItemGroupInfoList(j)
                ---@type ItemIconData
                local iconData = {}
                iconData.configCell = ConfigRefer.Item:Find(itmeInfo:Items())
                iconData.count = itmeInfo:Nums()
                iconData.useNoneMask = false
                table.insert(cells, iconData)
            end
            self._p_table_award:AppendData(cells, 1)
        end
    end
end

function AllianceBehemothAwardTipMediator:OnShow(param)
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdate))
end

function AllianceBehemothAwardTipMediator:OnHide(param)
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdate))
end

function AllianceBehemothAwardTipMediator:LateUpdate()
    if Utils.IsNull(self._clickTrans) then
        return
    end
    TipsRectTransformUtils.TryAnchorTipsNearTargetRectTransform(self._clickTrans, self._p_rect_range)
end

return AllianceBehemothAwardTipMediator