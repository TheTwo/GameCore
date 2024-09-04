local CityTileAssetBubble = require("CityTileAssetBubble")
---@class CityTileAssetBubbleFurnitureRepair:CityTileAssetBubble
---@field new fun():CityTileAssetBubbleFurnitureRepair
local CityTileAssetBubbleFurnitureRepair = class("CityTileAssetBubbleFurnitureRepair", CityTileAssetBubble)
local ModuleRefer = require("ModuleRefer")
local NpcServiceObjectType = require("NpcServiceObjectType")
local NpcServiceType = require("NpcServiceType")
local Utils = require("Utils")
local ColorUtil = require("ColorUtil")
local ColorConsts = require("ColorConsts")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local ManualResourceConst = require("ManualResourceConst")
local NumberFormatter = require("NumberFormatter")

function CityTileAssetBubbleFurnitureRepair:ctor()
    CityTileAssetBubble.ctor(self)
    self.itemCountListeners = {}
end

function CityTileAssetBubbleFurnitureRepair:GetPrefabName()
    if not self:CheckCanShow() then return string.Empty end

    return ManualResourceConst.ui3d_bubble_need
end

function CityTileAssetBubbleFurnitureRepair:OnTileViewInit()
    CityTileAssetBubble.OnTileViewInit(self)
    ModuleRefer.PlayerServiceModule:AddServicesChanged(NpcServiceObjectType.Furniture, Delegate.GetOrCreate(self, self.ForceRefresh))
end

function CityTileAssetBubbleFurnitureRepair:OnTileViewRelease()
    CityTileAssetBubble.OnTileViewRelease(self)
    ModuleRefer.PlayerServiceModule:RemoveServicesChanged(NpcServiceObjectType.Furniture, Delegate.GetOrCreate(self, self.ForceRefresh))
end

function CityTileAssetBubbleFurnitureRepair:CheckCanShow()
    self.serviceId = nil
    if not CityTileAssetBubble.CheckCanShow(self) then return false end

    ---@type CityFurniture
    local furniture = self.tileView.tile:GetCell()
    if not furniture:GetCastleFurniture().Locked then return false end

    local serviceMap = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.Furniture)
    local serviceGroup = serviceMap[self.tileView.tile:GetCell().singleId]
    if not serviceGroup then return false end

    local isOnlyCommit, serviceId, _, _  = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(serviceGroup, NpcServiceType.CommitItem)
    self.serviceId = serviceId
    return isOnlyCommit
end

function CityTileAssetBubbleFurnitureRepair:OnAssetLoaded(go, userdata, handle)
    CityTileAssetBubble.OnAssetLoaded(self, go, userdata, handle)
    if Utils.IsNull(go) then return end

    self.go = go
    local city = self:GetCity()
    local tile = self.tileView.tile
    local pos = city:GetCenterWorldPositionFromCoord(tile.x, tile.y, tile:SizeX(), tile:SizeY())
    self.go.transform.position = pos

    ---@type City3DBubbleNeed
    self.bubble = go:GetLuaBehaviour("City3DBubbleNeed").Instance
    self:UpdateBubble()
end

function CityTileAssetBubbleFurnitureRepair:OnAssetUnload(go, fadeout)
    self:ReleaseAllItemCountListeners()
    self.bubble = nil
    self.go = nil
end

function CityTileAssetBubbleFurnitureRepair:UpdateBubble()
    self.bubble:Reset()
    self.bubble:ClearTrigger()

    if not self.serviceId then return end
    local commitItemMap = ModuleRefer.StoryPopupTradeModule:GetServicesInfo(NpcServiceObjectType.Furniture, self.tileView.tile:GetCell().singleId, self.serviceId)
    local needItemMap = ModuleRefer.StoryPopupTradeModule:GetNeedItems(self.serviceId)

    self:ReleaseAllItemCountListeners()
    local index = 0
    for _, v in ipairs(needItemMap) do
        local commitCount = commitItemMap[v.id] or 0
        local lackCount =  v.count - commitCount
        if lackCount > 0 then
            index = index + 1

            local ownCount = ModuleRefer.InventoryModule:GetAmountByConfigId(v.id)
            local colorText = ownCount >= lackCount and ColorUtil.FromGammaStrToLinearStr(ColorConsts.quality_green) or ColorUtil.FromGammaStrToLinearStr(ColorConsts.warning)
            local text = string.format("<color=%s>%s</color>/%s", colorText, NumberFormatter.NumberAbbr(ownCount, true, false), NumberFormatter.NumberAbbr(lackCount, true, false))
            local itemCfg = ConfigRefer.Item:Find(v.id)
            self.bubble:AppendCustom(itemCfg:Icon(), text, false)
            
            local releaseCall = ModuleRefer.InventoryModule:AddCountChangeListener(v.id, function()
                local ownCount = ModuleRefer.InventoryModule:GetAmountByConfigId(v.id)
                local colorText = ownCount >= lackCount and ColorUtil.FromGammaStrToLinearStr(ColorConsts.quality_green) or ColorUtil.FromGammaStrToLinearStr(ColorConsts.warning)
                local text = string.format("<color=%s>%s</color>/%s", colorText, NumberFormatter.NumberAbbr(ownCount, true, false), NumberFormatter.NumberAbbr(lackCount, true, false))
                local itemCfg = ConfigRefer.Item:Find(v.id)
                self.bubble:UpdateCustom(index, itemCfg:Icon(), text, false)
            end)
            if self.itemCountListeners[v.id] then
                self.itemCountListeners[v.id]()
            end
            self.itemCountListeners[v.id] = releaseCall
        end
    end

    self.bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickBubble), self.tileView.tile)
end

function CityTileAssetBubbleFurnitureRepair:ReleaseAllItemCountListeners()
    for id, releaseCall in pairs(self.itemCountListeners) do
        releaseCall()
    end
    table.clear(self.itemCountListeners)
end

function CityTileAssetBubbleFurnitureRepair:OnClickBubble()
    return self.tileView.tile:GetCell():RequestToRepair()
end

return CityTileAssetBubbleFurnitureRepair