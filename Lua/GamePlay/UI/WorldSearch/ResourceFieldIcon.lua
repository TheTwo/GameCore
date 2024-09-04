local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')

---@class ResourceFieldIconData
---@field config FixedMapBuildingConfigCell
---@field selected boolean
---@field locked boolean
---@field onClick fun()

---@class ResourceFieldIcon : BaseTableViewProCell
---@field data ResourceFieldIconData
local ResourceFieldIcon = class("ResourceFieldIcon", BaseTableViewProCell)

function ResourceFieldIcon:OnCreate(param)
    self.p_img = self:Image("p_img")
    self:PointerClick("p_btn_resources", Delegate.GetOrCreate(self, self.OnClick))
    self.p_img_select = self:GameObject("p_img_select")
    self.p_lock = self:GameObject("p_lock")

end

---@param data ResourceFieldIconData
function ResourceFieldIcon:OnFeedData(data)
    self.data = data
    
    g_Game.SpriteManager:LoadSprite(data.config:BubbleImage(), self.p_img)
    self.p_img_select:SetVisible(data.selected)
    self.p_lock:SetVisible(data.locked)
end

function ResourceFieldIcon:OnClick()
    if self.data.onClick then
        self.data.onClick(self.data.config)
    end
end

return ResourceFieldIcon