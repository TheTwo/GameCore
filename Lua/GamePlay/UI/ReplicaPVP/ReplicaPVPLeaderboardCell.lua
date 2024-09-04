local BaseTableViewProCell = require ('BaseTableViewProCell')
local NumberFormatter = require('NumberFormatter')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class ReplicaPVPLeaderboardCellData
---@field rankNum number
---@field rankData wds.TopListMemData
---@field onHeadClick fun()

---@class ReplicaPVPLeaderboardCell:BaseTableViewProCell
---@field new fun():ReplicaPVPLeaderboardCell
---@field super BaseTableViewProCell
local ReplicaPVPLeaderboardCell = class('ReplicaPVPLeaderboardCell', BaseTableViewProCell)

function ReplicaPVPLeaderboardCell:OnCreate()
    self.imgRank1 = self:Image('p_icon_rank_top_1')
    self.imgRank2 = self:Image('p_icon_rank_top_2')
    self.imgRank3 = self:Image('p_icon_rank_top_3')
    self.txtOtherRank = self:Text('p_text_rank')

    ---@type PlayerInfoComponent
    self.headIcon = self:LuaObject('child_ui_head_player')
    self.txtPlayerName = self:Text('p_text_player')
    self.txtPower = self:Text('p_text_power')
    self.txtScore = self:Text('p_text_score')
    self.imageRankIcon = self:Image('p_icon_level')
    self.imageRankIconNum = self:Image('p_icon_lv_num')
end

---@param data ReplicaPVPLeaderboardCellData
function ReplicaPVPLeaderboardCell:OnFeedData(data)
    self.data = data

    local rankNum = data.rankNum
    self.imgRank1:SetVisible(rankNum == 1)
    self.imgRank2:SetVisible(rankNum == 2)
    self.imgRank3:SetVisible(rankNum == 3)
    self.txtOtherRank:SetVisible(rankNum > 3)
    self.txtOtherRank.text = tostring(rankNum)

    local param = data.rankData.Player.PortraitInfo
    param.PlayerId = data.rankData.PlayerId
    self.headIcon:FeedData(param)
    self.headIcon:SetClickHeadCallback(Delegate.GetOrCreate(self, self.OnHeadClicked))

    self.txtPlayerName.text = data.rankData.Player.PlayerName
    self.txtPower.text = NumberFormatter.Normal(data.rankData.PVP.PresetPower)
    self.txtScore.text = NumberFormatter.Normal(data.rankData.Score)

    local pvpTitleStageConfigCell = ConfigRefer.PvpTitleStage:Find(data.rankData.PVP.TitleStageTid)
    if pvpTitleStageConfigCell then
        self:LoadSprite(pvpTitleStageConfigCell:Icon(), self.imageRankIcon)
        if pvpTitleStageConfigCell:LevelIcon() > 0 then
            self.imageRankIconNum:SetVisible(true)
            self:LoadSprite(pvpTitleStageConfigCell:LevelIcon(), self.imageRankIconNum)
        else
            self.imageRankIconNum:SetVisible(false)
        end
    else
        g_Logger.Error('rank %s tid is %s', data.rankNum, data.rankData.PVP.TitleStageTid)
    end
end

function ReplicaPVPLeaderboardCell:OnHeadClicked()
    if self.data.onHeadClick then
        self.data.onHeadClick(self.data.rankData.PlayerId, self.headIcon.CSComponent.transform)
    end
end

return ReplicaPVPLeaderboardCell