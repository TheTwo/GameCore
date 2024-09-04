local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local Utils = require('Utils')
local ItemAdditionCell = class('ItemAdditionCell',BaseTableViewProCell)

function ItemAdditionCell:OnCreate(param)
    self.goBase = self:GameObject("p_base")
    self.imgIconAddtion = self:Image('p_icon_addtion')
    self.textAddtion = self:Text('p_text_addtion')
    self.textAddtionNumber = self:Text('p_text_addtion_number')
    if Utils.IsNotNull(self.goBase) then
        self.goBase:SetActive(false)
    end
end


function ItemAdditionCell:OnFeedData(data)
    if not data then
        return
    end
    if Utils.IsNotNull(self.goBase) then
        self.goBase:SetActive(data.showBase)
    end
    local cfg = ConfigRefer.AttrElement:Find(data.type)
    g_Game.SpriteManager:LoadSprite(cfg:Icon(), self.imgIconAddtion)
    self.textAddtion.text = I18N.Get(cfg:Name())
    self.textAddtionNumber.text = data.value
end

return ItemAdditionCell
