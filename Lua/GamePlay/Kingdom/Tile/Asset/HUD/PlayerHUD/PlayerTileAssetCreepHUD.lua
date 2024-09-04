local CommonTileAssetSlgBubble = require("CommonTileAssetSlgBubble")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local ManualResourceConst = require("ManualResourceConst")

---@class PlayerTileAssetCreepHUD : CommonTileAssetSlgBubble
local PlayerTileAssetCreepHUD = class("PlayerTileAssetCreepHUD", CommonTileAssetSlgBubble)

function PlayerTileAssetCreepHUD:GetLodPrefabName(lod)
    if KingdomMapUtils.InMapNormalLod(lod) or KingdomMapUtils.InMapLowLod(lod) then
        if ModuleRefer.MapCreepModule:IsTumorAlive(self:GetData()) then
            return ManualResourceConst.ui3d_bubble_radar
        end
    end
    return string.Empty
end

function PlayerTileAssetCreepHUD:GetIcon()
    return "sp_comp_icon_radar_cyst"
end

function PlayerTileAssetCreepHUD:GetQuality()
    ---@type wds.PlayerMapCreep
    local creepData = self:GetData()
    return ModuleRefer.RadarModule:GetRadarTaskQuality(creepData.ID)
end

function PlayerTileAssetCreepHUD:OnIconClick()
    ---@type wds.PlayerMapCreep
    local creepData = self:GetData()
    ModuleRefer.MapCreepModule:StartSweepClean(creepData)
end

function PlayerTileAssetCreepHUD:GetCustomData()
    ---@type wds.PlayerMapCreep
    local creepData = self:GetData()
    local ObjectType = require("ObjectType")
    local param = {isRadarTaskBubble = true, type = ObjectType.SlgCreepTumor, data = creepData}
    return param
end

return PlayerTileAssetCreepHUD