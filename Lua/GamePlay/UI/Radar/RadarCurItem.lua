local BaseTableViewProCell = require('BaseTableViewProCell')

---@class RadarCurItem : BaseTableViewProCell
---@field baseIcon BaseItemIcon
local RadarCurItem = class('RadarCurItem',BaseTableViewProCell)

function RadarCurItem:OnCreate(param)
    self.imgIcon = self:Image('p_icon')
    self.textLv = self:Text('p_text_lv')
    self.goBase = self:GameObject('p_base')
    self.goAdditionNext = self:GameObject('p_addition_next')
    self.textNum = self:Text('p_text_num')
    self.textAdd = self:Text('p_text_add')
end

function RadarCurItem:OnFeedData(data)
    self.goBase:SetActive(data.index % 2 ~= 0)
    if data.icon then
        g_Game.SpriteManager:LoadSprite(data.icon, self.imgIcon)
    end
    self.textLv.text = data.des
    self.textNum.text = data.value
    self.goAdditionNext:SetActive(data.nextValue ~= nil)
    if data.nextValue then
        self.textAdd.text = data.nextValue
    end
end

return RadarCurItem
