local BaseTableViewProCell = require('BaseTableViewProCell')
local I18N = require('I18N')
local TitleItemCell = class('TitleItemCell',BaseTableViewProCell)

---@class TitleItemCellData
---@field itemName string
---@field itemNum number
---@field hideNum boolean

function TitleItemCell:OnCreate(param)
    self.textName = self:Text('p_text_name')
    self.textResourceNum = self:Text('p_text_resource_num')
    self.textTitle = self:Text('p_text_title')

    self.textResourceNum.gameObject:SetVisible(false)
end

---@param data TitleItemCellData
function TitleItemCell:OnFeedData(data)
    self.textName.text = data.itemName
    -- if data.itemNum and data.itemNum > 0 and not data.hideNum then
    --     self.textResourceNum.gameObject:SetActive(true)
    --     self.textResourceNum.text = "X" .. math.floor(data.itemNum)
    -- else
    --     self.textResourceNum.gameObject:SetActive(false)
    -- end
    -- self.textTitle.text = I18N.Get("getmore_goto")
    self.textTitle.text = ""
end

return TitleItemCell