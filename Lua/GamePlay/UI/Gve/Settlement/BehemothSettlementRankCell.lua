local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require("ModuleRefer")
local ColorConsts = require('ColorConsts')
local UIHelper = require('UIHelper')
local NumberFormatter = require('NumberFormatter')
---@class BehemothSettlementRankCell : BaseTableViewProCell
local BehemothSettlementRankCell = class('BehemothSettlementRankCell', BaseTableViewProCell)

---@class BehemothSettlementRankCellData : GveBattleDamageInfoCellData
---@field damageInfo PlayerDamageInfo | wrpc.DamagePlayerInfo
---@field allTakeDamage number
---@field maxPlayerTakeDamage number
---@field allHeadling number
---@field maxPlayerHeadling number

local RankBaseColor = {
    [1] = ColorUtil.FromHexNoAlphaString('f9991c'),
    [2] = ColorUtil.FromHexNoAlphaString('6a739b'),
    [3] = ColorUtil.FromHexNoAlphaString('7d4141'),
    [4] = ColorUtil.FromHexNoAlphaString('17181c'),
}

function BehemothSettlementRankCell:OnCreate()
    self.goBase = self:GameObject('p_base')
    self.imgBase = self:Image('p_base')
    self.imgIconRanking = self:Image('p_icon_ranking')
    self.textRanking = self:Text('p_text_ranking_other')

    self.luaHeadPlayer = self:LuaObject('child_ui_head_player')
    self.textPlayerName = self:Text('p_text_name')

    self.textDamage = self:Text('p_text_output')
    self.sliderPercentDamage = self:Slider('p_progress')

    self.textDamageTaken = self:Text('p_text_damage')
    self.sliderPercentDamageTaken = self:Slider('p_progress_1')

    self.textHealing = self:Text('p_text_healing')
    self.sliderPercentHealing = self:Slider('p_progress_2')
end

---@param param BehemothSettlementRankCellData
function BehemothSettlementRankCell:OnFeedData(param)
    self.isSelf = param.isSelf
    self.allDamage = param.allDamage or 1
    self.damageInfo = param.damageInfo
    self.maxPlayerDamage = param.maxPlayerDamage or 1
    self.allTakeDamage = param.allTakeDamage or 1
    self.maxPlayerTakeDamage = param.maxPlayerTakeDamage or 1
    self.rank = param.index

    if self.allDamage == 0 then
        self.allDamage = 1
    end
    if self.allTakeDamage == 0 then
        self.allTakeDamage = 1
    end
    self:UpdateInfo()
end

function BehemothSettlementRankCell:UpdateInfo()
    if self.rank > 3 then
        self.imgIconRanking:SetVisible(false)
        self.textRanking:SetVisible(true)
        self.textRanking.text = self.rank
        g_Game.SpriteManager:LoadSprite("sp_league_war_base_mine", self.imgBase)
        self.imgBase.color = RankBaseColor[4]
    else
        self.imgIconRanking:SetVisible(true)
        self.textRanking:SetVisible(false)
        local icon = ModuleRefer.LeaderboardModule:GetRankIcon(self.rank)
        g_Game.SpriteManager:LoadSprite(icon, self.imgIconRanking)
        g_Game.SpriteManager:LoadSprite("sp_league_war_base_top_" .. self.rank, self.imgBase)
        self.imgBase.color = RankBaseColor[self.rank]
    end
    self.textPlayerName.text = self.damageInfo.playerName or self.damageInfo.Name
    self.textDamage.text = NumberFormatter.Percent(self.damageInfo.damage / self.allDamage)
    self.sliderPercentDamage.value = self.damageInfo.damage / self.allDamage

    self.textDamageTaken.text = NumberFormatter.Percent((self.damageInfo.takeDamage or self.damageInfo.TakeDamage or 0) / self.allTakeDamage)
    self.sliderPercentDamageTaken.value = (self.damageInfo.takeDamage or self.damageInfo.TakeDamage or 0) / self.allTakeDamage
    if self.isSelf then
        self.textPlayerName.color = UIHelper.TryParseHtmlString(ColorConsts['army_green'])
    end
    -- todo: 头像 & 其他数据
    self.luaHeadPlayer:FeedData(self.damageInfo.portraitInfo or self.damageInfo.PortraitInfo)
end

return BehemothSettlementRankCell