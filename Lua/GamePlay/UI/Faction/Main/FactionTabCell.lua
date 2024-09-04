local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local FactionTabCell = class('FactionTabCell',BaseTableViewProCell)

function FactionTabCell:OnCreate(param)
    self.btnPower = self:Button('p_btn_power', Delegate.GetOrCreate(self, self.OnBtnPowerClicked))
    self.imgIconPowerTab = self:Image('p_icon_power_tab')
    self.goImgSelect = self:GameObject('p_img_select')
    self.imgIconPowerTabSelect = self:Image('p_icon_power_tab_select')

end

function FactionTabCell:OnFeedData(data)
    self.factionId = data.factionId
    g_Game.SpriteManager:LoadSprite(ConfigRefer.Sovereign:Find(self.factionId):Icon(), self.imgIconPowerTab)
    g_Game.SpriteManager:LoadSprite(ConfigRefer.Sovereign:Find(self.factionId):SelectIcon(), self.imgIconPowerTabSelect)
end

function FactionTabCell:OnBtnPowerClicked(args)
    g_Game.EventManager:TriggerEvent(EventConst.FACTION_SELECT_TAB, self.factionId)
    self:SelectSelf()
end

function FactionTabCell:Select(param)
    g_Game.SpriteManager:LoadSprite(ConfigRefer.Sovereign:Find(self.factionId):SelectIcon(), self.imgIconPowerTabSelect)
    self.goImgSelect:SetVisible(true)
end

function FactionTabCell:UnSelect(param)
    g_Game.SpriteManager:LoadSprite(ConfigRefer.Sovereign:Find(self.factionId):Icon(), self.imgIconPowerTab)
    self.goImgSelect:SetVisible(false)
end

return FactionTabCell
