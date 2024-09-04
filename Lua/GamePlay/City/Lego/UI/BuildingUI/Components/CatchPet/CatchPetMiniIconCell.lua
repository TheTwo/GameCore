local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class CatchPetMiniIconCell:BaseTableViewProCell
---@field new fun():CatchPetMiniIconCell
---@field super BaseTableViewProCell
local CatchPetMiniIconCell = class('CatchPetMiniIconCell', BaseTableViewProCell)

function CatchPetMiniIconCell:OnCreate()
    self.img = self:Image('p_img')
end

---@param data number @ArtResourceUI Id
function CatchPetMiniIconCell:OnFeedData(data)
    local imageId = data
    if imageId and imageId > 0 then
        self:LoadSprite(imageId, self.img)
    end
end

return CatchPetMiniIconCell