local PvPTileAssetUnit = require("PvPTileAssetUnit")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")

local Vector3 = CS.UnityEngine.Vector3

---@class PlayerTileAssetSlgInteractor : PvPTileAssetUnit
---@field seEnterData wds.SeEnter
---@field config MineConfigCell
local PlayerTileAssetSlgInteractor = class("PlayerTileAssetSlgInteractor", PvPTileAssetUnit)

function PlayerTileAssetSlgInteractor:CanShow()
    if not self.seEnterData then
        return false
    end

    return true
end

-- function PlayerTileAssetSlgInteractor:GetPosition()
--     return self:CalculateCenterPosition()
-- end

function PlayerTileAssetSlgInteractor:GetScale()
    if self.config then
        return ArtResourceUtils.GetScale(self.config:InteractModel()) * Vector3.one
    end
    return Vector3.one
end

---@return string
function PlayerTileAssetSlgInteractor:GetLodPrefabName(lod)
    if KingdomMapUtils.InMapNormalLod(lod) then
        if self.config then
            return ArtResourceUtils.GetItem(self.config:InteractModel())
        end
    end
    return string.Empty
end

function PlayerTileAssetSlgInteractor:OnShow()
    PvPTileAssetUnit.OnShow(self)
    
    self.seEnterData = self:GetData()
    if not self.seEnterData then
        return
    end
    self.config = ConfigRefer.Mine:Find(self.seEnterData.MineCfgId)
end

function PlayerTileAssetSlgInteractor:OnConstructionSetup()
    PvPTileAssetUnit.OnConstructionSetup(self)
    local asset = self:GetAsset()
    if asset then
        asset.transform.name = "PlayerTileAssetSlgInteractor"..self.seEnterData.ID
    end
    self:OnConstructionUpdate()
end

function PlayerTileAssetSlgInteractor:OnHide()
    PvPTileAssetUnit.OnHide(self)
    
    self.config = nil
end

function PlayerTileAssetSlgInteractor:OnConstructionUpdate()
    PvPTileAssetUnit.OnConstructionUpdate(self)
    
    if not self.seEnterData then
        return
    end
end

return PlayerTileAssetSlgInteractor