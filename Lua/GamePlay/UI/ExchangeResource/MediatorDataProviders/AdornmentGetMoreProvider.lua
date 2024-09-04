local BaseGetMoreDataProvider = require("BaseGetMoreDataProvider")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local GetMoreAcquisitionWayCellDataProvider = require("GetMoreAcquisitionWayCellDataProvider")
local AdornmentGetMoreItemCellDataProvider = require("AdornmentGetMoreItemCellDataProvider")
---@class AdornmentGetMoreProvider : BaseGetMoreDataProvider
local AdornmentGetMoreProvider = class("AdornmentGetMoreProvider", BaseGetMoreDataProvider)

function AdornmentGetMoreProvider:GetTitle()
    return I18N.Get("skincollection_access")
end

function AdornmentGetMoreProvider:GetCellDatas()
    local ret = {}

    local items = self:GetItemList()
    for _, itemId in ipairs(items) do
        local data = {}
        data.provider = AdornmentGetMoreItemCellDataProvider.new(itemId)
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

function AdornmentGetMoreProvider:ShowProgress()
    return false
end

return AdornmentGetMoreProvider