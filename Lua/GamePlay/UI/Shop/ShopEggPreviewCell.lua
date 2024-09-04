local BaseTableViewProCell = require ('BaseTableViewProCell')
---@class ShopEggPreviewCell : BaseTableViewProCell
local ShopEggPreviewCell = class('ShopEggPreviewCell', BaseTableViewProCell)

function ShopEggPreviewCell:ctor()
    self.duplicatedComps = {}
end

function ShopEggPreviewCell:OnCreate()
    self.textTip = self:Text('p_text_tip', 'pet_drone_available_pets_name')
    self.tablePets = self:TableViewPro('p_layout_pets')
end

---@param data UIPossiblePetCompData[]
function ShopEggPreviewCell:OnFeedData(data)
    if not data or #data == 0 then
        return
    end
    for _, petData in ipairs(data) do
        self.tablePets:AppendData(petData)
    end
end

return ShopEggPreviewCell