---@class CityResidentMark
---@field new fun():CityResidentMark
---@field root CS.UnityEngine.Transform
---@field rootFull CS.UnityEngine.GameObject
---@field rootAvailable CS.UnityEngine.GameObject
---@field textFull CS.U2DTextMesh
---@field textAvailable CS.U2DTextMesh
local CityResidentMark = sealedClass("CityResidentMark")

---@param cellTile CityCellTile
function CityResidentMark:FeedData(cellTile)
    self.cellTile = cellTile
    self:UpdateUI()
end

function CityResidentMark:UpdateUI()
    local cellTile = self.cellTile
    local city = cellTile:GetCity()
    local houseId = cellTile:GetCell().tileId
    local cur = city.cityCitizenManager:GetCitizenCountByHouse(houseId)
    local max = city.cityCitizenManager:GetCitizenSlotByHouse(houseId)

    local up = self.root.up
    self.root.localPosition = up

    self.rootFull:SetActive(cur >= max)
    self.rootAvailable:SetActive(cur < max)

    if cur >= max then
        self.textFull.text = ("%d/%d"):format(cur, max)
    else
        self.textAvailable.text = ("%d/%d"):format(cur, max)
    end
end

return CityResidentMark