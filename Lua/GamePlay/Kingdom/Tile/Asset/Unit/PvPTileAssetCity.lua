local PvPTileAssetUnit = require("PvPTileAssetUnit")
local KingdomMapUtils = require('KingdomMapUtils')
local ConfigRefer = require('ConfigRefer')
local ArtResourceUtils = require('ArtResourceUtils')
local ModuleRefer = require('ModuleRefer')
local AdornmentType = require('AdornmentType')

---@class PvPTileAssetCity : PvPTileAssetUnit
local PvPTileAssetCity = class("PvPTileAssetCity", PvPTileAssetUnit)

---@return string
function PvPTileAssetCity:GetLodPrefabName(lod)
    ---@type wds.CastleBrief
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
       return string.Empty
    end
    
    if KingdomMapUtils.InMapNormalLod(lod) then
        --local config = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)
        local config = ConfigRefer.FixedMapBuilding:Find(104)
        if ModuleRefer.PlayerModule:IsMine(entity.Owner) then
            local usingCastleSkin = ModuleRefer.PersonaliseModule:GetUsingAdornmentDataByType(AdornmentType.CastleSkin)
            if usingCastleSkin then
                local configInfo = ConfigRefer.Adornment:Find(usingCastleSkin.ConfigID)
                if configInfo then
                    if configInfo:BigWOrldRealModel() > 0 then
                        return ArtResourceUtils.GetItem(configInfo:BigWOrldRealModel())
                    end
                end
            end
        else
            local ownerAppearance = entity.Owner.OwnerAppearance
            if ownerAppearance then
                local configInfo = ConfigRefer.Adornment:Find(ownerAppearance.CastleSkinId)
                if configInfo then
                    if configInfo:BigWOrldRealModel() > 0 then
                        return ArtResourceUtils.GetItem(configInfo:BigWOrldRealModel())
                    end
                end
            end
        end
        return ArtResourceUtils.GetItem(config:Model())
    end
    return string.Empty
end

return PvPTileAssetCity