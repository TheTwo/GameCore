local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local UIHelper = require('UIHelper')
local MailRankType = require('MailRankType')

---@class MailRankCompParameter
---@field Name string
---@field Damage number
---@field Rank number
---@field PortraitInfo wds.PortraitInfo

---@class MailRankComp : BaseTableViewProCell
---@field super BaseTableViewProCell
local MailRankComp = class('MailRankComp', BaseTableViewProCell)

function MailRankComp:ctor()
    MailRankComp.super.ctor(self)
    self.id = 0
end

function MailRankComp:OnCreate(param)
    self.text = self:Text("")
    self.p_img_rank = self:Image("p_img_rank")
    self.p_title_number = self:Text("p_title_number")
    self.child_ui_head_player = self:LuaObject("child_ui_head_player")
    self.p_title_name_player = self:Text("p_title_name_player")
    self.p_title_content_player = self:Text("p_title_content_player")

end

---@param param MailRankCompParameter
function MailRankComp:OnFeedData(param)
    -- Damage = res.Damage, PortraitInfo = res.PortraitInfo, Name = res.Name, Rank = res.Rank
    self.p_title_name_player.text = param.Name
    self.p_title_content_player.text = param.Damage
    self.child_ui_head_player:FeedData(param.PortraitInfo)
    if param.Rank <= 3 then
        self.p_img_rank:SetVisible(true)
        local icon = UIHelper.GetRankIcon(param.Rank)
        g_Game.SpriteManager:LoadSprite(icon, self.p_img_rank)
    else
        self.p_img_rank:SetVisible(false)
        self.p_title_number.text = param.Rank
    end

end

return MailRankComp;
