local PvPTileAssetHUDConstruction = require("PvPTileAssetHUDConstruction")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local AdornmentType = require("AdornmentType")
local KingdomMapUtils = require("KingdomMapUtils")
local PersonaliseDefine = require("PersonaliseDefine")

---@class PvPTileAssetHUDConstructionCastle : PvPTileAssetHUDConstruction
local PvPTileAssetHUDConstructionCastle = class("PvPTileAssetHUDConstructionCastle", PvPTileAssetHUDConstruction)

---@param entity wds.CastleBrief
function PvPTileAssetHUDConstructionCastle:OnRefresh(entity)
    if not entity then
        return
    end

    local durability = entity.Battle.Durability
    local maxDurability = entity.Battle.MaxDurability   
    self:RefreshDurability(durability, maxDurability)

    if ModuleRefer.PlayerModule:IsMine(entity.Owner) then
        local usingTitle = ModuleRefer.PersonaliseModule:GetUsingAdornmentDataByType(AdornmentType.Titles)
        if usingTitle then
            if usingTitle.ConfigID == PersonaliseDefine.DefaultTitleID then
                self.behavior:ShowTitle(false)
                return
            end
            local configInfo = ConfigRefer.Adornment:Find(usingTitle.ConfigID)
            if configInfo then
                self.behavior:ShowTitle(true)
                self.behavior:SetTitle(configInfo:Name(), tonumber(configInfo:Icon()))
            end
        end
    else
        local ownerAppearance = entity.Owner.OwnerAppearance
        if ownerAppearance then
            if ownerAppearance.TitleId == PersonaliseDefine.DefaultTitleID then
                self.behavior:ShowTitle(false)
                return
            end
            local configInfo = ConfigRefer.Adornment:Find(ownerAppearance.TitleId)
            if configInfo then
                self.behavior:ShowTitle(true)
                self.behavior:SetTitle(configInfo:Name(), tonumber(configInfo:Icon()))
            end
        end
    end
end

function PvPTileAssetHUDConstructionCastle:CheckLod(lod)
    return KingdomMapUtils.InMapNormalLod(lod)
end

return PvPTileAssetHUDConstructionCastle