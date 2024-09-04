local BaseModule = require("BaseModule")
local ConfigRefer = require("ConfigRefer")
local DBEntityType = require("DBEntityType")


---@class MapBuildingLayoutModule : BaseModule
local MapBuildingLayoutModule = class("MapBuildingLayoutModule", BaseModule)

local DefaultLayout = { SizeX = 0, SizeY = 0 } --存在没有大小的实体，例如世界事件

function MapBuildingLayoutModule:ctor()
    self.layouts = {}
end

function MapBuildingLayoutModule:GetLayout(id)
    local layout = self.layouts[id]
    if layout == nil then
        local config = ConfigRefer.MapBuildingLayout:Find(id)
        if config ~= nil then
            local row = config:Layout(1)
            local sizeX = string.len(row)
            local sizeY = config:LayoutLength()
            self.layouts[id] = { SizeX = sizeX, SizeY = sizeY }
            layout = self.layouts[id]
        end
    end

    return layout or DefaultLayout
end

function MapBuildingLayoutModule:GetLayoutByEntity(entity)
    if not entity then
        return DefaultLayout
    end
    
    local layoutId = entity.MapBasics.LayoutCfgId
    local layout = self.layouts[layoutId]
    if layout == nil then
        local config = ConfigRefer.MapBuildingLayout:Find(layoutId)
        if config == nil then
           return self:GetCustomLayout(entity)
        else
            local row = config:Layout(1)
            local sizeX = string.len(row)
            local sizeY = config:LayoutLength()
            self.layouts[layoutId] = { SizeX = sizeX, SizeY = sizeY }
            layout = self.layouts[layoutId]
        end
    end
    
    return layout or DefaultLayout
end

---@param entity wds.PlayerMapCreep
function MapBuildingLayoutModule:GetCustomLayout(entity)
    if entity.TypeHash == wds.PlayerMapCreep.TypeHash then
        local creepConfig = ConfigRefer.SlgCreepTumor:Find(entity.CfgId)
        return self:GetLayout(creepConfig:CenterBuildingLayout())
    end
    return DefaultLayout
end

return MapBuildingLayoutModule