local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
local LackItemIconCell = class('LackItemIconCell',BaseTableViewProCell)

function LackItemIconCell:OnCreate(param)
    self.btnItemResources = self:Button('', Delegate.GetOrCreate(self, self.OnBtnItemResourcesClicked))
    self.goGroupUnselected = self:GameObject('p_group_unselected')
    self.textResourceNumUnselected = self:Text('p_text_resource_num_unselected')
    self.imgImgResourceUnselected = self:Image('p_img_resource_unselected')
    self.goGroupSelected = self:GameObject('p_group_selected')
    self.textResourceNumSelected = self:Text('p_text_resource_num_selected')
    self.imgImgResourceSelected = self:Image('p_img_resource_selected')
end

---@param data ExchangeResourceMediatorItemInfo
function LackItemIconCell:OnFeedData(data)
    self.data = data
    local itemCfg = ConfigRefer.Item:Find(data.id)
    local icon = itemCfg:Icon()
    g_Game.SpriteManager:LoadSprite(icon, self.imgImgResourceUnselected)
    g_Game.SpriteManager:LoadSprite(icon, self.imgImgResourceSelected)
end

function LackItemIconCell:OnBtnItemResourcesClicked()
    self:SelectSelf()
end

function LackItemIconCell:Select(param)
    self.goGroupUnselected:SetVisible(false)
    self.goGroupSelected:SetVisible(true)
    g_Game.EventManager:TriggerEvent(EventConst.EXCHANGE_RESOURCE_SELECT_ITEM, self.data)
end

function LackItemIconCell:UnSelect(param)
    self.goGroupUnselected:SetVisible(true)
    self.goGroupSelected:SetVisible(false)
end

return LackItemIconCell
