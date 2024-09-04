local BaseModule = require ('BaseModule')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class CityWorkSpeedUpModule:BaseModule
local CityWorkSpeedUpModule = class('CityWorkSpeedUpModule', BaseModule)

function CityWorkSpeedUpModule:OnRegister()
    ---@type table<number, CitySpeedUpConfigCell>
    self.itemId2Cfg = {}
    for _, cfg in ConfigRefer.CitySpeedUp:pairs() do
        self.itemId2Cfg[cfg:CostItem()] = cfg
    end
end

function CityWorkSpeedUpModule:OnRemove()
    self.itemId2Cfg = nil
end

function CityWorkSpeedUpModule:GetCitySpeedUpCfgByItem(itemId)
    return self.itemId2Cfg[itemId]
end

function CityWorkSpeedUpModule:GetItemList(workCfgId)
    local itemList = {}
    for itemId, cfg in pairs(self.itemId2Cfg) do
        for i = 1, cfg:SpeedWorkLength() do
            if cfg:SpeedWork(i) == workCfgId then
                table.insert(itemList, itemId)
                break
            end
        end
    end
    return itemList
end

return CityWorkSpeedUpModule