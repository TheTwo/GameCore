local CommonTileAssetSlgBubble = require("CommonTileAssetSlgBubble")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local ConfigRefer = require("ConfigRefer")
local ObjectType = require("ObjectType")
local ManualResourceConst = require("ManualResourceConst")

---@class PlayerTileAssetPetRadarBubble : CommonTileAssetSlgBubble
local PlayerTileAssetPetRadarBubble = class("PlayerTileAssetPetRadarBubble", CommonTileAssetSlgBubble)

function PlayerTileAssetPetRadarBubble:GetLodPrefabName(lod)
    if self:CheckLod(lod) then
        return ManualResourceConst.ui3d_bubble_radar
    end
    return string.Empty
end

function PlayerTileAssetPetRadarBubble:CanShow()
    local pData = self:GetData()
    if not pData then
        return false
    end
    self.IsRadarTaskEntity = ModuleRefer.RadarModule:IsRadarTaskEntity(pData.data.ID, ObjectType.SlgCatchPet)
    return self.IsRadarTaskEntity
end

---@return CS.UnityEngine.Vector3
function PlayerTileAssetPetRadarBubble:CalculatePosition()
    local pData = self:GetData()
    -- + CS.UnityEngine.Vector3(0, -60, 0)
    return pData.worldPos
end

function PlayerTileAssetPetRadarBubble:GetIcon()
    local pData = self:GetData()
    if not pData then
        return string.Empty
    end
    local radarTaskId = ModuleRefer.RadarModule:GetRadarTaskId(pData.data.ID)
    local configInfo = ConfigRefer.RadarTask:Find(radarTaskId)
    if configInfo then
        return configInfo:RadarTaskIcon()
    end
    return string.Empty
end

function PlayerTileAssetPetRadarBubble:GetQuality()
    local pData = self:GetData()
    if not pData then
        return 0
    end
    return ModuleRefer.RadarModule:GetRadarTaskQuality(pData.data.ID)
end

function PlayerTileAssetPetRadarBubble:OnIconClick()
    local pData = self:GetData()
    if pData then
        ModuleRefer.PetModule:TryOpenCatchMenu(pData)
    end
end

function PlayerTileAssetPetRadarBubble:GetCustomData()
    local pData = self:GetData()
    local ObjectType = require("ObjectType")
    local param = {isRadarTaskBubble = true, type = ObjectType.SlgCatchPet, objectData = pData}
    return param
end

function PlayerTileAssetPetRadarBubble:GetYOffset()
    return 100
end

function PlayerTileAssetPetRadarBubble:CustomBubbleLogic()
    if self.IsRadarTaskEntity then
        local pData = self:GetData()
        if not pData then
            return
        end
        local radarTaskId = ModuleRefer.RadarModule:GetRadarTaskId(pData.data.ID)
        local configInfo = ConfigRefer.RadarTask:Find(radarTaskId)
        if configInfo then
            local behavior = self:GetAsset():GetLuaBehaviour("PvETileAsseRadarBubbleBehavior").Instance
            if not behavior then
                return
            end
            if not string.IsNullOrEmpty(configInfo:RadarTaskRewardIcon()) then
                behavior:SetPetRewardActive(true)
                behavior:SetPetRewardIcon(configInfo:RadarTaskRewardIcon())
            else
                behavior:SetPetRewardActive(false)
            end
            if not string.IsNullOrEmpty(configInfo:RadarTaskCitizenIcon()) then
                behavior:SetCitizenTaskActive(true)
                behavior:SetCitizenTaskIcon(configInfo:RadarTaskCitizenIcon())
            else
                behavior:SetCitizenTaskActive(false)
            end
        end
    end
end

return PlayerTileAssetPetRadarBubble