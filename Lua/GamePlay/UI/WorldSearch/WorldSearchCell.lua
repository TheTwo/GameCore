local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local I18N = require('I18N')
local EventConst = require('EventConst')

---@class WorldSearchCellData
---@field icon string
---@field category number
---@field type number
---@field name string

---@class WorldSearchCell : BaseTableViewProCell
local WorldSearchCell = class('WorldSearchCell',BaseTableViewProCell)

function WorldSearchCell:OnCreate(param)
    self.btnItemTpye = self:Button('', Delegate.GetOrCreate(self, self.OnBtnItemTpyeClicked))
    self.goImgSelect = self:GameObject('p_img_select')
    self.imgTypeIcon = self:Image('p_type_icon')
    self.textName = self:Text('p_txt_type_name')
end

---@param data WorldSearchCellData
function WorldSearchCell:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.icon, self.imgTypeIcon)
    self.category = data.category
    self.type = data.type
    self.textName.text = I18N.Get(data.name)
end

function WorldSearchCell:OnBtnItemTpyeClicked(args)
    g_Game.EventManager:TriggerEvent(EventConst.WORLD_SEARCH_TYPE, self.category, self.type)
end

function WorldSearchCell:Select(param)
    self.goImgSelect:SetActive(true)
end

function WorldSearchCell:UnSelect(param)
    self.goImgSelect:SetActive(false)
end

return WorldSearchCell
