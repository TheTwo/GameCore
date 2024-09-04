local CityLegoBuffProvider = require("CityLegoBuffProvider")
---@class CityLegoBuffProvider_FurnitureCfg:CityLegoBuffProvider
---@field new fun():CityLegoBuffProvider_FurnitureCfg
local CityLegoBuffProvider_FurnitureCfg = class("CityLegoBuffProvider_FurnitureCfg", CityLegoBuffProvider)
local CityLegoBuffProviderType = require("CityLegoBuffProviderType")

---@param lvCfg CityFurnitureLevelConfigCell
function CityLegoBuffProvider_FurnitureCfg:ctor(lvCfg, locked)
    CityLegoBuffProvider.ctor(self)
    self.lvCfg = lvCfg
    self:UpdateTagMap(locked)
end

function CityLegoBuffProvider_FurnitureCfg:UpdateTagMap(locked)
    self:ClearTagMap()
    if locked then return end
    
    for i = 1, self.lvCfg:RoomTagsLength() do
        local tagId = self.lvCfg:RoomTags(i)
        self.tagMap[tagId] = (self.tagMap[tagId] or 0) + 1
    end
end

function CityLegoBuffProvider_FurnitureCfg:ClearTagMap()
    table.clear(self.tagMap)
end

function CityLegoBuffProvider_FurnitureCfg:GetType()
    return CityLegoBuffProviderType.Furniture
end

return CityLegoBuffProvider_FurnitureCfg