local BaseGetMoreDataProvider = require("BaseGetMoreDataProvider")
local EnergyGetMoreItemCellDataProvider = require("EnergyGetMoreItemCellDataProvider")
local GetMoreAcquisitionWayCellDataProvider = require("GetMoreAcquisitionWayCellDataProvider")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
---@class EnergyGetMoreDataProvider : BaseGetMoreDataProvider
local EnergyGetMoreDataProvider = class("EnergyGetMoreDataProvider", BaseGetMoreDataProvider)

function EnergyGetMoreDataProvider:GetCellDatas()
    local ret = {}

    local items = self:GetItemList()
    for _, itemId in ipairs(items) do
        local data = {}
        data.provider = EnergyGetMoreItemCellDataProvider.new(itemId)
        data.cellType = 0
        table.insert(ret, data)
    end

    local titleCellData = {}
    titleCellData.title = I18N.Get("energy_info_Access")
    titleCellData.cellType = 2

    table.insert(ret, titleCellData)

    local hasGetMore = false
    local sysMap = {}
    for _, itemId in ipairs(items) do
        local itemConfig = ConfigRefer.Item:Find(itemId)
        local getMoreCfg = ConfigRefer.GetMore:Find(itemConfig:GetMoreConfig())
        if not getMoreCfg then
            goto continue
        end
        hasGetMore = true
        local gotoCount = getMoreCfg:GotoLength()
        for i = 1, gotoCount do
            local data = {}
            data.provider = GetMoreAcquisitionWayCellDataProvider.new(itemId, i)
            data.cellType = 1
            local sysId = getMoreCfg:Goto(i):UnlockSystem()
            if not sysMap[sysId] then
                sysMap[sysId] = true
                table.insert(ret, data)
            end
        end
        ::continue::
    end

    if not hasGetMore then
        table.remove(ret, #ret)
    end

    return ret
end

function EnergyGetMoreDataProvider:GetProgress()
    local radarInfo = ModuleRefer.RadarModule:GetRadarInfo()
    local curEnery = radarInfo.PPPCur
    local maxEnergy = radarInfo.PPPMax
    return curEnery / maxEnergy
end

function EnergyGetMoreDataProvider:GetProgressStr()
    local radarInfo = ModuleRefer.RadarModule:GetRadarInfo()
    local curEnery = radarInfo.PPPCur
    local maxEnergy = radarInfo.PPPMax
    return string.format("%d/%d", curEnery, maxEnergy)
end

return EnergyGetMoreDataProvider