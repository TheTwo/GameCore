local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local AllianceTechRankComp = class('AllianceTechRankComp', BaseUIComponent)

function AllianceTechRankComp:OnCreate()
    self.go = self:GameObject('')
    self.goGroupRank = self:GameObject('p_rank')
    self.goRankTop1 = self:GameObject('p_icon_rank_top_1')
    self.goRankTop2 = self:GameObject('p_icon_rank_top_2')
    self.goRankTop3 = self:GameObject('p_icon_rank_top_3')
    self.txtRankOther = self:Text('p_text_rank')
    self.imgBg = self:Image('p_base_content')
    self.playerIcon = self:LuaObject('child_ui_head_player')
    self.txtPlayerName = self:Text('p_text_player')

    self.p_text_number = self:Text('p_text_number')
    self.p_text_value = self:Text('p_text_value')
end

function AllianceTechRankComp:OnFeedData(data)
    self.data = data
    self.p_text_number.text = data.DonateTimes
    self.p_text_value.text = data.DonateValues
    local members = ModuleRefer.AllianceModule:GetMyAllianceData().AllianceMembers.Members
    self.playerIcon:FeedData(members[data.FacebookId].PortraitInfo)
    self.txtPlayerName.text = members[data.FacebookId].Name
    self:SetRank(data.rank)
end

function AllianceTechRankComp:SetRank(rank)
    self.goRankTop1:SetVisible(rank == 1)
    self.goRankTop2:SetVisible(rank == 2)
    self.goRankTop3:SetVisible(rank == 3)
    self.txtRankOther:SetVisible(rank > 3)
    if rank > 3 then
        self.txtRankOther.text = tostring(rank)
    end

    local bgImage = ModuleRefer.LeaderboardModule:GetRankItemBackgroundImagePath(rank, self.data.isMine)
    g_Game.SpriteManager:LoadSprite(bgImage, self.imgBg)
end

return AllianceTechRankComp
