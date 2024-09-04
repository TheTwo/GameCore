local UIHelper = require("UIHelper")
local I18N = require("I18N")
local DBEntityType = require("DBEntityType")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")

local BattleSignalConfig={}

BattleSignalConfig.BuildingTypeHash = {
    [DBEntityType.DefenceTower] = true,
    [DBEntityType.EnergyTower] = true,
    [DBEntityType.TransferTower] = true,
    [DBEntityType.Village] = true,
    [DBEntityType.Pass] = true,
    [DBEntityType.ResourceField] = true,
    [DBEntityType.CastleBrief] = true,
    [DBEntityType.BehemothCage] = true,
}

BattleSignalConfig.FixedMapBuildingType = {
    [DBEntityType.Village] = true,
    [DBEntityType.Pass] = true,
    [DBEntityType.ResourceField] = true,
}

BattleSignalConfig.FlexibleMapBuildingType = {
    [DBEntityType.DefenceTower] = true,
    [DBEntityType.EnergyTower] = true,
    [DBEntityType.TransferTower] = true,
}

BattleSignalConfig.MobTypeHash = {
    [DBEntityType.MapMob] = true,
}

BattleSignalConfig.TroopOrMobTypeHash = {
    [DBEntityType.Troop] = true,
    [DBEntityType.MapMob] = true,
    [DBEntityType.SlgPuppet] = true,
}

---@param param wds.AllianceMapLabel
---@return BattleSignalData|nil
function BattleSignalConfig.MakeParameter(param)
    ---@type BattleSignalData
    local signalData = {}
    if BattleSignalConfig.TroopOrMobTypeHash[param.TargetTypeHash] then
        signalData.X = 0
        signalData.Y = 0
        signalData.troopId = param.TargetId
    elseif BattleSignalConfig.BuildingTypeHash[param.TargetTypeHash] then
        signalData.X = param.X
        signalData.Y = param.Y
    elseif param.X and param.Y and param.X > 0 and param.Y > 0 then
        signalData.X = param.X
        signalData.Y = param.Y
    else
        return nil
    end
    local config = ConfigRefer.AllianceMapLabel:Find(param.ConfigId)
    signalData.icon = UIHelper.IconOrMissing(config and config:Icon())
    signalData.Type = param.Type
    if string.IsNullOrEmpty(param.Content) then
        signalData.content = I18N.Get(config:DefaultDesc())
    else
        signalData.content = param.Content
    end
    if config:MapEffectVfx() ~= 0 then
        signalData.vfxEffect,signalData.vfxScale = ArtResourceUtils.GetItemAndScale(config:MapEffectVfx())
    end
    return signalData
end

---@param typeConfigCell AllianceMapLabelConfigCell
function BattleSignalConfig.GetTypeName(typeConfigCell)
    return I18N.Get(typeConfigCell:Name())
end

return BattleSignalConfig
