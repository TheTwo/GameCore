local BaseUIComponent = require('BaseUIComponent')
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local ColorConsts = require('ColorConsts')
local LeaderboardHeadType = require('LeaderboardHeadType')

---@class LeaderboardTopListPageData
---@field title string
---@field tip string
---@field leaderboardActivityID number @LeaderboardActivity
---@field reply wrpc.GetTopListReply
---@field req wrpc.GetTopListRequest

---@class LeaderboardTopListPage:BaseUIComponent
---@field new fun():LeaderboardTopListPage
---@field super BaseUIComponent
local LeaderboardTopListPage = class('LeaderboardTopListPage', BaseUIComponent)

function LeaderboardTopListPage:OnCreate()
    self.p_text_title = self:Text('p_text_title')
    self.p_text_hint_reward = self:Text('p_text_hint_reward')
    self.txtHeadRank = self:Text('p_text_title_rank', 'leaderboard_ElementName_0')
    self.txtHeadPet = self:Text('p_text_title_pet')
    self.txtHeadHero = self:Text('p_text_title_hero')
    self.goHeadPlayer = self:GameObject('p_group_player')
    self.txtHeadPlayer = self:Text('p_text_title_player')
    self.txtHeadLeague = self:Text('p_text_title_league')
    self.txtHeadBehemoth = self:Text('p_text_title_behemoth')
    self.txtHeadLeader = self:Text('p_text_title_leader')
    self.txtHeadPvplevel = self:Text('p_text_title_pvplevel')
    self.txtHeadSchedule = self:Text('p_text_title_schedule')
    self.txtHeadTime = self:Text('p_text_title_time')
    self.txtHeadPower = self:Text('p_text_title_power')
    self.txtHeadScore = self:Text('p_text_title_score')
    self.txtHeadDistrict = self:Text('p_text_title_province')
    self.txtHeadReward = self:Text('p_text_title_reward')
    ---@type table <number, CS.UnityEngine.UI.Text>
    self.headers = {}
    self.headers[LeaderboardHeadType.Rank] = self.txtHeadRank
    self.headers[LeaderboardHeadType.Pet] = self.txtHeadPet
    self.headers[LeaderboardHeadType.Hero] = self.txtHeadHero
    self.headers[LeaderboardHeadType.Player] = self.goHeadPlayer
    self.headers[LeaderboardHeadType.League] = self.txtHeadLeague
    self.headers[LeaderboardHeadType.Behemoth] = self.txtHeadBehemoth
    self.headers[LeaderboardHeadType.Leader] = self.txtHeadLeader
    self.headers[LeaderboardHeadType.PvpLevel] = self.txtHeadPvplevel
    self.headers[LeaderboardHeadType.Schedule] = self.txtHeadSchedule
    self.headers[LeaderboardHeadType.Time] = self.txtHeadTime
    self.headers[LeaderboardHeadType.Power] = self.txtHeadPower or self.txtHeadScore
    self.headers[LeaderboardHeadType.Score] = self.txtHeadScore or self.txtHeadPower
    self.headers[LeaderboardHeadType.District] = self.txtHeadDistrict
    self.headers[LeaderboardHeadType.Rewards] = self.txtHeadReward

    self.tableRanking = self:TableViewPro('p_table_ranking')

    ---@type LeaderboardRankingItem
    self.myRankItem = self:LuaObject('p_content_mine')

    self.goEmpty = self:GameObject('p_empty')
    self.txtEmpty = self:Text('p_text_empty', 'alliance_worldevent_rank_empty')
end

---@param data LeaderboardTopListPageData
function LeaderboardTopListPage:OnFeedData(data)
    self.reply = data.reply
    self.req = data.req
    self.title = data.title
    self.tip = data.tip
    self.leaderboardActivityID = data.leaderboardActivityID

    self:SetupHeaders()
    self:SetupRanks()
    self:SetupMyRank()

    if self.goEmpty then
        self.goEmpty:SetActive(table.isNilOrZeroNums(self.reply.TopList))
    end
end

function LeaderboardTopListPage:SetupHeaders()
    if self.p_text_title then
        self.p_text_title:SetVisible(self.title)
        if self.title then
            self.p_text_title.text = self.title
        end
    end

    if self.p_text_hint_reward then
        self.p_text_hint_reward:SetVisible(self.tip)
        if self.tip then
            self.p_text_hint_reward.text = self.tip
        end
    end

    for type, v in pairs(self.headers) do
        if type == LeaderboardHeadType.Rank or v == nil then
            goto continue
        end
        v:SetVisible(false)
        ::continue::
    end

    local leaderboardConfigCell = ConfigRefer.Leaderboard:Find(self.req.TopListTid)
    for i = 1, leaderboardConfigCell:ShowElemLength() do
        local elementId = leaderboardConfigCell:ShowElem(i)
        local elementConfigCell = ConfigRefer.LeaderElement:Find(elementId)
        local headerIndex = ModuleRefer.LeaderboardModule:GetLeaderboardHeadTypeIndex(elementConfigCell)
        if headerIndex > 0 then
            self.headers[headerIndex]:SetVisible(true)
            if headerIndex == LeaderboardHeadType.Player then
                self.txtHeadPlayer.text = I18N.Get(elementConfigCell:Title())
            else
                self.headers[headerIndex].text = I18N.Get(elementConfigCell:Title())
            end
        end
    end
end

function LeaderboardTopListPage:SetupRanks()
    self.tableRanking:Clear()

    local count = self.reply.TopList:Count()
    for i = 1, count do
        ---@type LeaderboardRankingCellData
        local cellData = {}
        cellData.rankMemData = self.reply.TopList[i]
        cellData.rank = i
        if self.reply.PlayerInfo.Rank == i then
            cellData.color = UIHelper.TryParseHtmlString(ColorConsts.quality_green)
        else
            cellData.color = UIHelper.TryParseHtmlString(ColorConsts.black)
        end
        cellData.leaderboardId = self.req.TopListTid
        cellData.leaderboardActivityID = self.leaderboardActivityID
        
        self.tableRanking:AppendData(cellData)
    end
end

function LeaderboardTopListPage:SetupMyRank()
    if self.reply.PlayerInfo.Rank < 1 then
        self.myRankItem:SetVisible(false)
        return
    end

    self.myRankItem:SetVisible(true)

    ---@type LeaderboardRankingItemData
    local itemData = {}
    itemData.leaderboardId = self.req.TopListTid
    itemData.leaderboardActivityID = self.leaderboardActivityID
    itemData.rank = self.reply.PlayerInfo.Rank
    itemData.color = nil
    itemData.rankMemData = self.reply.PlayerInfo.Data
    itemData.isBottom = true
    self.myRankItem:FeedData(itemData)
end

return LeaderboardTopListPage