local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local MailRankType = require('MailRankType')

---@class MailRankTitleCompParameter
---@field RankType number

---@class MailRankTitleComp : BaseTableViewProCell
---@field super BaseTableViewProCell
local MailRankTitleComp = class('MailRankTitleComp', BaseTableViewProCell)

function MailRankTitleComp:ctor()
    MailRankTitleComp.super.ctor(self)
    self.id = 0
end

function MailRankTitleComp:OnCreate(param)
    self.text = self:Text("")
    self.p_title_rank = self:Text('p_title_rank', "gverating_rank")
    self.p_title_name = self:Text('p_title_name', "village_info_First_conquest_3")
    self.p_title_content = self:Text('p_title_content')
end

function MailRankTitleComp:OnFeedData(param)
    if param.RankType == MailRankType.Guard then
        self.p_title_content.text = I18N.Get('village_info_First_conquest_4')
    elseif param.RankType == MailRankType.Wall then
        self.p_title_content.text = I18N.Get('village_info_First_conquest_6')
    elseif param.RankType == MailRankType.BehemothCage then
        self.p_title_content.text = I18N.Get('battlemessage_output')
    elseif param.RankType == MailRankType.Rebuild then
        self.p_title_name.text = I18N.Get('village_outpost_info_players')
        self.p_title_content.text = I18N.Get('@@@贡献建设量')
    end
end

return MailRankTitleComp;
