local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local GrowthFundConst = require('GrowthFundConst')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local DBEntityPath = require('DBEntityPath')
local PlayerGetAutoRewardParameter = require('PlayerGetAutoRewardParameter')
local Utils = require('Utils')
local ColorConsts = require('ColorConsts')
local UIHelper = require('UIHelper')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local TimerUtility = require('TimerUtility')

---@class ActivityWorldEventRankComp : BaseTableViewProCell
local ActivityWorldEventRankComp = class('ActivityWorldEventRankComp', BaseTableViewProCell)

function ActivityWorldEventRankComp:OnCreate()

    self.p_base_content = self:Image('p_base_content')
    self.p_icon_rank_top_1 = self:GameObject('p_icon_rank_top_1')
    self.p_icon_rank_top_2 = self:GameObject('p_icon_rank_top_2')
    self.p_icon_rank_top_3 = self:GameObject('p_icon_rank_top_3')
    self.p_text_rank = self:Text('p_text_rank')

    self.child_ui_head_player = self:LuaObject('child_ui_head_player')
    self.p_text_player = self:Text('p_text_player')
    self.p_set_bar = self:Slider('p_set_bar')
    self.p_text_progress = self:Text('p_text_progress')
    self.p_text_contribute = self:Text('p_text_contribute')

end

function ActivityWorldEventRankComp:OnFeedData(param)
    local rank = param.index
    local percent = math.clamp(param.Progress / param.sum, 0, 1)
    self.p_text_player.text = param.Name
    self.p_set_bar.value = percent
    self.p_text_progress.text = string.format("%.2f", percent * 100) .. "%"
    self.p_text_contribute.text = param.Progress

    self.child_ui_head_player:FeedData(param.PortraitInfo)

    if rank == 1 then
        self.p_icon_rank_top_1:SetVisible(true)
        self.p_icon_rank_top_2:SetVisible(false)
        self.p_icon_rank_top_3:SetVisible(false)
        self.p_text_rank:SetVisible(false)
    elseif rank == 2 then
        self.p_icon_rank_top_1:SetVisible(false)
        self.p_icon_rank_top_2:SetVisible(true)
        self.p_icon_rank_top_3:SetVisible(false)
        self.p_text_rank:SetVisible(false)
    elseif rank == 3 then
        self.p_icon_rank_top_1:SetVisible(false)
        self.p_icon_rank_top_2:SetVisible(false)
        self.p_icon_rank_top_3:SetVisible(true)
        self.p_text_rank:SetVisible(false)
    else
        self.p_icon_rank_top_1:SetVisible(false)
        self.p_icon_rank_top_2:SetVisible(false)
        self.p_icon_rank_top_3:SetVisible(false)
        self.p_text_rank:SetVisible(true)
        self.p_text_rank.text = rank
    end
    local sprite = ModuleRefer.LeaderboardModule:GetRankItemBackgroundImagePath(rank, param.isMine)
    g_Game.SpriteManager:LoadSprite(sprite, self.p_base_content)
end

function ActivityWorldEventRankComp:OnShow()
end

function ActivityWorldEventRankComp:OnHide()
end

return ActivityWorldEventRankComp
