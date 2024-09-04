local CommonTileAssetSlgBubble = require("CommonTileAssetSlgBubble")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local ConfigRefer = require("ConfigRefer")
local ManualResourceConst = require("ManualResourceConst")
local MapUtils = CS.Grid.MapUtils
local PlayerTileAssetWorldRewardHUD = class("PlayerTileAssetWorldRewardHUD", CommonTileAssetSlgBubble)

function PlayerTileAssetWorldRewardHUD:GetLodPrefabName(lod)
    if self:CheckLod(lod) then
        return ManualResourceConst.ui3d_bubble_radar
    end
    return string.Empty
end

-- ---@return CS.UnityEngine.Vector3
function PlayerTileAssetWorldRewardHUD:CalculatePosition()
    local data = self:GetData()
    local pos = MapUtils.CalculateCoordToTerrainPosition(math.floor(data.Pos.X), math.floor(data.Pos.Y), KingdomMapUtils.GetMapSystem())
    return pos
end

function PlayerTileAssetWorldRewardHUD:GetIcon()
    local data = self:GetData()
    local radarTaskId = ModuleRefer.RadarModule:GetRadarTaskId(data.ID)
    local configInfo = ConfigRefer.RadarTask:Find(radarTaskId)
    if configInfo then
        return configInfo:RadarTaskIcon()
    else
        return data.isMistBox and "sp_icon_lod_mark" or "sp_icon_reward"
    end
end

function PlayerTileAssetWorldRewardHUD:GetQuality()
    ---@type wds.RtBoxInfo 
    local data = self:GetData()
    -- local res = ModuleRefer.RadarModule:GetRadarTaskQuality(data.ID)
    return data.Quality
end

function PlayerTileAssetWorldRewardHUD:GetCustomData()
    local data = self:GetData()
    local ObjectType = require("ObjectType")
    local param = {isRadarTaskBubble = true, type = ObjectType.SlgRtBox, data = data, X = math.floor(data.Pos.X), Y = math.floor(data.Pos.Y)}
    return param
end

function PlayerTileAssetWorldRewardHUD:OnIconClick()
    local data = self:GetData()
    ModuleRefer.WorldRewardInteractorModule:ShowMenu(data)
end

function PlayerTileAssetWorldRewardHUD:CustomBubbleLogic()
    local data = self:GetData()
    if not data then
        return
    end
    local behavior = self:GetAsset():GetLuaBehaviour("PvETileAsseRadarBubbleBehavior").Instance
    if not behavior then
        return
    end
    local isMistBox = false
    local radarCfg = ConfigRefer.RadarTask:Find(data.AssignRadarTaskId)
    if radarCfg == nil then
        return
    end

    if radarCfg:IsSkipReward() then
        isMistBox = true
    end
    
    behavior:SetFrameActive(not isMistBox)
    behavior:SetLodFrameActive(not isMistBox)

    if not string.IsNullOrEmpty(radarCfg:RadarTaskRewardIcon()) then
        behavior:SetPetRewardActive(true)
        behavior:SetPetRewardIcon(radarCfg:RadarTaskRewardIcon())
    else
        behavior:SetPetRewardActive(false)
    end
    if not string.IsNullOrEmpty(radarCfg:RadarTaskCitizenIcon()) then
        behavior:SetCitizenTaskActive(true)
        behavior:SetCitizenTaskIcon(radarCfg:RadarTaskCitizenIcon())
    else
        behavior:SetCitizenTaskActive(false)
    end

end

function PlayerTileAssetWorldRewardHUD:GetYOffset()
    return 100
end

return PlayerTileAssetWorldRewardHUD
