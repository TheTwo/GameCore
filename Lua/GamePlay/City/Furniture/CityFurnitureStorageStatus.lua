local Utils = require("Utils")

---@class CityFurnitureStorageStatus
---@field useReplaceMode boolean
---@field storageEmpty CS.UnityEngine.GameObject
---@field storageSmall CS.UnityEngine.GameObject
---@field storageMiddle CS.UnityEngine.GameObject
---@field storageHude CS.UnityEngine.GameObject
---@field storageFull CS.UnityEngine.GameObject
local CityFurnitureStorageStatus = sealedClass("CityFurnitureStorageStatus")

function CityFurnitureStorageStatus:SetStorageProgress(normalizedValue)
    if normalizedValue <= 0 then
        if Utils.IsNotNull(self.storageEmpty) then self.storageEmpty:SetVisible(true) end
        if Utils.IsNotNull(self.storageSmall) then self.storageSmall:SetVisible(false) end
        if Utils.IsNotNull(self.storageMiddle) then self.storageMiddle:SetVisible(false) end
        if Utils.IsNotNull(self.storageHude) then self.storageHude:SetVisible(false) end
        if Utils.IsNotNull(self.storageFull) then self.storageFull:SetVisible(false) end
    else
        if Utils.IsNotNull(self.storageEmpty) then self.storageEmpty:SetVisible(false) end
        if Utils.IsNotNull(self.storageSmall) then self.storageSmall:SetVisible((not self.useReplaceMode and normalizedValue > 0) or (normalizedValue > 0 and normalizedValue < 0.3)) end
        if Utils.IsNotNull(self.storageMiddle) then self.storageMiddle:SetVisible((not self.useReplaceMode and normalizedValue >= 0.3) or (normalizedValue >= 0.3 and normalizedValue < 0.6)) end
        if Utils.IsNotNull(self.storageHude) then self.storageHude:SetVisible((not self.useReplaceMode and normalizedValue >= 0.6) or (normalizedValue >= 0.6 and normalizedValue < 0.9)) end
        if Utils.IsNotNull(self.storageFull) then self.storageFull:SetVisible(normalizedValue >= 0.9) end
    end
end

return CityFurnitureStorageStatus