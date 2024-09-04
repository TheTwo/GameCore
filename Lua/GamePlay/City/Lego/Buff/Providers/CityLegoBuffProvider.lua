---@class CityLegoBuffProvider
---@field new fun():CityLegoBuffProvider
---@field tagMap table<number, number>
local CityLegoBuffProvider = class("CityLegoBuffProvider")
local CityLegoBuffProviderType = require("CityLegoBuffProviderType")

function CityLegoBuffProvider:ctor()
    self.tagMap = {}
end

function CityLegoBuffProvider:UpdateTagMap()
    ---DO NOTHING
end

function CityLegoBuffProvider:GetTagCount(tagId)
    return 0
end

function CityLegoBuffProvider:GetType()
    return CityLegoBuffProviderType.None
end

function CityLegoBuffProvider:GetImage()
    return string.Empty
end

function CityLegoBuffProvider:HasTag(tagId, count)
    count = count or 1
    return self.tagMap[tagId] and self.tagMap[tagId] >= count
end

---@param buffCfg RoomTagBuffConfigCell
function CityLegoBuffProvider:IsRelative(buffCfg)
    for i = 1, buffCfg:RoomTagListLength() do
        local tagCfgId = buffCfg:RoomTagList(i)
        if self.tagMap[tagCfgId] and self.tagMap[tagCfgId] > 0 then
            return true
        end
    end
end

return CityLegoBuffProvider