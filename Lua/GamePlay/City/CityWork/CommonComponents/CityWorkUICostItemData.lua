---@class CityWorkUICostItemData
---@field new fun():CityWorkUICostItemData
local CityWorkUICostItemData = class("CityWorkUICostItemData")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local QualityColorHelper = require("QualityColorHelper")

function CityWorkUICostItemData:ctor(id, onceNeed, times)
    self.id = id
    self.onceNeed = onceNeed
    self.times = times or 1
end

function CityWorkUICostItemData:GetIcon()
    return ConfigRefer.Item:Find(self.id):Icon()
end

function CityWorkUICostItemData:GetQualityBackground()
    local quality = ConfigRefer.Item:Find(self.id):Quality()
    return QualityColorHelper.GetSpHeroFrameCircleImg(quality)
end

function CityWorkUICostItemData:GetCountNeed()
    return self.onceNeed * math.max(1, self.times)
end

function CityWorkUICostItemData:GetCountOwn()
    return ModuleRefer.InventoryModule:GetAmountByConfigId(self.id)
end

function CityWorkUICostItemData:GetMaxTimes()
    return math.floor(ModuleRefer.InventoryModule:GetAmountByConfigId(self.id) / self.onceNeed)
end

function CityWorkUICostItemData:ReleaseCountListener()
    if self.listenerUnbindFunc then
        self.listenerUnbindFunc()
        self.listenerUnbindFunc = nil
    end
end

function CityWorkUICostItemData:AddCountListener(delegate)
    if self.listenerUnbindFunc then
        self.listenerUnbindFunc()
    end
    self.listenerUnbindFunc = ModuleRefer.InventoryModule:AddCountChangeListener(self.id, delegate)
end

function CityWorkUICostItemData:UpdateTimes(times)
    self.times = times
end

return CityWorkUICostItemData