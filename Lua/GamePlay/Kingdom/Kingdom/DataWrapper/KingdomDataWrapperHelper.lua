local Delegate = require("Delegate")
local KingdomRefreshData = require("KingdomRefreshData")

local Vector3 = CS.UnityEngine.Vector3

---@class KingdomDataWrapperHelper
local KingdomDataWrapperHelper = class("KingdomDataWrapperHelper")

---@param staticMapData CS.Grid.StaticMapData
function KingdomDataWrapperHelper.CalculateCenterPosition(x, y, sizeX, sizeY, staticMapData)
    local posX = (x + sizeX / 2) * staticMapData.UnitsPerTileX
    local posZ = (y + sizeY / 2) * staticMapData.UnitsPerTileZ
    return Vector3(posX, posZ * 0.001, posZ) --in case of z-fighting
end

---@param refreshData KingdomRefreshData
---@param delayInvoker KingdomDelayInvoker
function KingdomDataWrapperHelper.ShowSprite(refreshData, delayInvoker, id, index, immediately)
    refreshData:SetActive(id, index, true)
    if immediately or not delayInvoker then
        refreshData:SetSpriteStay(id, index)
    else
        refreshData:SetSpriteFadeIn(id, index)
        delayInvoker:AddCallback(KingdomRefreshData.SetSpriteStay, id, index)
    end
end

---@param refreshData KingdomRefreshData
---@param delayInvoker KingdomDelayInvoker
function KingdomDataWrapperHelper.HideSprite(refreshData, delayInvoker, id, index, immediately)
    if immediately or not delayInvoker then
        refreshData:SetActive(id, index, false)
        refreshData:SetSpriteStay(id, index)
    else
        refreshData:SetSpriteFadeOut(id, index)
        delayInvoker:AddCallback(KingdomRefreshData.SetActive, id, index, false)
        delayInvoker:AddCallback(KingdomRefreshData.SetSpriteStay, id, index)
    end
end

---@param refreshData KingdomRefreshData
---@param delayInvoker KingdomDelayInvoker
function KingdomDataWrapperHelper.ShowText(refreshData, delayInvoker, id, index, immediately)
    refreshData:SetActive(id, index, true)
    if immediately or not delayInvoker then
        refreshData:SetTextStay(id, index)
    else
        refreshData:SetTextFadeIn(id, index)
        delayInvoker:AddCallback(KingdomRefreshData.SetTextStay, id, index)
    end
end

---@param refreshData KingdomRefreshData
---@param delayInvoker KingdomDelayInvoker
function KingdomDataWrapperHelper.HideText(refreshData, delayInvoker, id, index, immediately)
    if immediately or not delayInvoker then
        refreshData:SetActive(id, index, false)
        refreshData:SetTextStay(id, index)
    else
        refreshData:SetTextFadeOut(id, index)
        delayInvoker:AddCallback(KingdomRefreshData.SetActive, id, index, false)
        delayInvoker:AddCallback(KingdomRefreshData.SetTextStay, id, index)
    end
end

return KingdomDataWrapperHelper