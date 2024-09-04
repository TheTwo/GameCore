local BaseUIComponent = require('BaseUIComponent')
local DBEntityPath = require("DBEntityPath")
local Delegate = require('Delegate')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local ColorConsts = require('ColorConsts')
local UIHelper = require('UIHelper')
local TimeFormatter = require("TimeFormatter")

---@class LeaderboardHonorListPageData
---@field reply wrpc.GetHonorTopListReply

---@class LeaderboardHonorListPage:BaseUIComponent
---@field new fun():LeaderboardHonorListPage
---@field super BaseUIComponent
local LeaderboardHonorListPage = class('LeaderboardHonorListPage', BaseUIComponent)

function LeaderboardHonorListPage:OnCreate()
    self.txtPlayerTitle = self:Text('p_text_famous', 'leaderboard_showTitle_1')
    -- self.txtAllianceTitle = self:Text('p_text_alliance', 'leaderboard_showTitle_2')
    self.txtMyRankTitle = self:Text('p_text_mine_title', 'leaderboard_showTitle_3')
    self.txtSelfPlayerTitle = self:Text('p_text_mine_ranking_title', 'leaderboard_ElementName_1')
    self.txtSelfAllianceTitle = self:Text('p_text_mine_ranking_title_league', 'leaderboard_ElementName_2')

    self.btnTips = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnTipsClick))
    self.txtMyPlayerRank = self:Text('p_text_mine_ranking_recent')
    self.txtMyPlayerRankChange = self:Text('p_text_mine_ranking_change')
    self.txtMyPlayerRankChange1 = self:Text('p_text_mine_ranking_change_1', '(')
    self.txtMyPlayerRankChange2 = self:Text('p_text_mine_ranking_change_2', ')')
    self.imgMyPlayerRankChange = self:Image('p_icon_arrow')

    self.goMyAllianceRank = self:GameObject('p_group_mine_ranking_league')
    self.txtMyAllianceRank = self:Text('p_text_mine_ranking_recent_league')
    self.txtMyAllianceRankChange = self:Text('p_text_mine_ranking_change_league')
    self.txtMyAllianceRankChange1 = self:Text('p_text_mine_ranking_change_1_league', '(')
    self.txtMyAllianceRankChange2 = self:Text('p_text_mine_ranking_change_2_league', ')')
    self.imgMyAllianceRankChange = self:Image('p_icon_arrow_league')

    ---@type CommonDailyGift
    self.child_gift_daily = self:LuaObject('child_gift_daily')
    self.txtDailyRewardRefresh = self:Text('p_text_refresh_mine', 'leaderboard_showTime')
    self.txtDailyRewardRefreshTimestamp = self:Text('p_text_time_refresh_mine')

    self.txtRankRefresh = self:Text('p_text_refresh', 'leaderboard_showTime')
    self.txtRankRefreshTimestamp = self:Text('p_text_time_refresh')

    ---@type LeaderboardHonorPlayerItem
    self.playerTop1 = self:LuaObject('p_group_top_1')
    ---@type LeaderboardHonorPlayerItem
    self.playerTop2 = self:LuaObject('p_group_top_2')
    ---@type LeaderboardHonorPlayerItem
    self.playerTop3 = self:LuaObject('p_group_top_3')
    ---@type table <number, LeaderboardHonorPlayerItem>
    self.playerTops = {}
    table.insert(self.playerTops, self.playerTop1)
    table.insert(self.playerTops, self.playerTop2)
    table.insert(self.playerTops, self.playerTop3)

    -- ---@type LeaderboardHonorAllianceItem
    -- self.allianceTop1 = self:LuaObject('p_group_top_alliance_1')
    -- ---@type LeaderboardHonorAllianceItem
    -- self.allianceTop2 = self:LuaObject('p_group_top_alliance_2')
    -- ---@type LeaderboardHonorAllianceItem
    -- self.allianceTop3 = self:LuaObject('p_group_top_alliance_3')
    -- ---@type table <number, LeaderboardHonorAllianceItem>
    -- self.allianceTops = {}
    -- table.insert(self.allianceTops, self.allianceTop1)
    -- table.insert(self.allianceTops, self.allianceTop2)
    -- table.insert(self.allianceTops, self.allianceTop3)
end

function LeaderboardHonorListPage:OnShow(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper3.PlayerTopList.DailyReward.MsgPath, Delegate.GetOrCreate(self, self.OnDailyRewardChanged))
end

function LeaderboardHonorListPage:OnHide(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper3.PlayerTopList.DailyReward.MsgPath, Delegate.GetOrCreate(self, self.OnDailyRewardChanged))
end

---@param data LeaderboardHonorListPageData
function LeaderboardHonorListPage:OnFeedData(data)
    self.playerTopData = data.reply.PlayerInfo
    self.allianceTopData = data.reply.AllianceInfo

    self:RefreshHonorTopList()
    self:RefreshMyRank()
    self:RefreshDailyReward()
end

function LeaderboardHonorListPage:RefreshMyRank()
    local hasAlliance = self.allianceTopData.CurRank > 0
    self.goMyAllianceRank:SetVisible(hasAlliance)
    self.txtSelfAllianceTitle:SetVisible(hasAlliance)
    if hasAlliance then
        self.txtMyAllianceRank.text = tostring(self.allianceTopData.CurRank)
        self:RefreshChanges(self.allianceTopData.CurRank, self.allianceTopData.OldRank, self.imgMyAllianceRankChange, self.txtMyAllianceRankChange, self.txtMyAllianceRankChange1, self.txtMyAllianceRankChange2)
    end

    self.txtMyPlayerRank.text = tostring(self.playerTopData.CurRank)
    self:RefreshChanges(self.playerTopData.CurRank, self.playerTopData.OldRank, self.imgMyPlayerRankChange, self.txtMyPlayerRankChange, self.txtMyPlayerRankChange1, self.txtMyPlayerRankChange2)
end

---@param rank number
---@param oldRank number
---@param imgArrow UnityEngine.UI.Image
---@param txtChange UnityEngine.UI.Text
---@param colorStaff1 UnityEngine.UI.Graphic
---@param colorStaff2 UnityEngine.UI.Graphic
function LeaderboardHonorListPage:RefreshChanges(rank, oldRank, imgArrow, txtChange, colorStaff1, colorStaff2)
    local delta = 0
    if oldRank < 0 then oldRank = 9999 end
    if rank < oldRank then
        -- 升
        delta = oldRank - rank
        imgArrow.color = UIHelper.TryParseHtmlString(ColorConsts.army_green)
        imgArrow.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, -90)
        imgArrow:SetVisible(true)
        txtChange.text = tostring(delta)
        txtChange.color = UIHelper.TryParseHtmlString(ColorConsts.army_green)
        colorStaff1.color = UIHelper.TryParseHtmlString(ColorConsts.army_green)
        colorStaff2.color = UIHelper.TryParseHtmlString(ColorConsts.army_green)
    elseif rank > oldRank then
        -- 降
        delta = rank - oldRank
        imgArrow:SetVisible(true)
        imgArrow.color = UIHelper.TryParseHtmlString(ColorConsts.army_red)
        imgArrow.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, 90)
        txtChange.text = tostring(delta)
        txtChange.color = UIHelper.TryParseHtmlString(ColorConsts.army_red)
        colorStaff1.color = UIHelper.TryParseHtmlString(ColorConsts.army_red)
        colorStaff2.color = UIHelper.TryParseHtmlString(ColorConsts.army_red)
    else
        -- 平
        imgArrow:SetVisible(false)
        txtChange.text = '-'
        txtChange.color = UIHelper.TryParseHtmlString(ColorConsts.dark_gray)
        colorStaff1.color = UIHelper.TryParseHtmlString(ColorConsts.dark_gray)
        colorStaff2.color = UIHelper.TryParseHtmlString(ColorConsts.dark_gray)
    end
end

function LeaderboardHonorListPage:RefreshHonorTopList()
    local playerTopListCount = self.playerTopData.List:Count()
    for index, item in ipairs(self.playerTops) do
        local hasPlayerData = playerTopListCount >= index
        item:SetVisible(hasPlayerData)
        if hasPlayerData then
            ---@type LeaderboardHonorPlayerItemData
            local data = {}
            data.rankData = self.playerTopData.List[index]
            item:FeedData(data)
        end
    end
    
    -- local allianceTopListCount = self.allianceTopData.List:Count()
    -- for index, item in ipairs(self.allianceTops) do
    --     local hasAllianceData = allianceTopListCount >= index
    --     item:SetVisible(hasAllianceData)
    --     if hasAllianceData then
    --         ---@type LeaderboardHonorAllianceItemData
    --         local data = {}
    --         data.rankData = self.allianceTopData.List[index]
    --         item:FeedData(data)
    --     end
    -- end

    local timestamp = self.playerTopData.HonorRefreshTime
    self.txtRankRefreshTimestamp.text = TimeFormatter.GetFormatCompleteTime(timestamp * 1000)
end

function LeaderboardHonorListPage:OnTipsClick()
    ---@type TextToastMediatorParameter
    local toastParameter = {}
    toastParameter.clickTransform =  self.btnTips.transform
    toastParameter.content = I18N.Get('leaderboard_desc')
    ModuleRefer.ToastModule:ShowTextToast(toastParameter)
end

function LeaderboardHonorListPage:RefreshDailyReward()
    ---@type CommonDailyGiftData
    local data = {}
    data.itemGroupId = ModuleRefer.LeaderboardModule:GetDailyRewardItemGroupId()
    data.state = ModuleRefer.LeaderboardModule:GetDailyRewardState()
    data.customCloseIcon = ModuleRefer.LeaderboardModule:GetDailyRewardBoxIcon(false)
    data.customOpenIcon = ModuleRefer.LeaderboardModule:GetDailyRewardBoxIcon(true)
    data.onClickWhenClosed = Delegate.GetOrCreate(self, self.OnDailyRewardClick)
    self.child_gift_daily:FeedData(data)

    -- 设置红点
    ModuleRefer.LeaderboardModule:AttachHonorDailyRewardRedDot(self.child_gift_daily:GetReddotNode())
    ModuleRefer.LeaderboardModule:UpdateDailyRewardState()

    local refreshTimestamp = ModuleRefer.LeaderboardModule:GetDailyRewardRefreshTimestamp()
    self.txtDailyRewardRefreshTimestamp.text = TimeFormatter.GetFormatCompleteTime(refreshTimestamp * 1000)
end

function LeaderboardHonorListPage:OnDailyRewardClick()
    local req = require('GetTopListDailyRewardParameter').new()
    req:Send()
end

function LeaderboardHonorListPage:OnDailyRewardChanged()
    self:RefreshDailyReward()
end

return LeaderboardHonorListPage