local PvPTileAssetUnit = require("PvPTileAssetUnit")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local Utils = require("Utils")
local KingdomConstant = require("KingdomConstant")
local ObjectType = require("ObjectType")
local ManualResourceConst = require("ManualResourceConst")

local Ease = CS.DG.Tweening.Ease
local Vector3 = CS.UnityEngine.Vector3
local WORLD_PET_ICON_OFFSET = CS.UnityEngine.Vector3.zero
local VECTOR3_ONE = CS.UnityEngine.Vector3.one
local PET_ICON_SCALE = 0.006
local PET_ICON_INNER_SCALE = 0.1
local WORLD_PET_ICON_FACING_OFFSET = 200
local WORLD_PET_MOVING_SPEED = 50
local WORLD_PET_INT_DATA = 110
local SP_PET_ICON = "sp_icon_lod_pet"

---@class PlayerTileAssetPetIcon : PvPTileAssetUnit
local PlayerTileAssetPetIcon = class("PlayerTileAssetPetIcon", PvPTileAssetUnit)

function PlayerTileAssetPetIcon:CanShow()
    if not KingdomMapUtils.IsMapState() then
		return false
	end
    if self.pData and not ModuleRefer.PetModule:CheckPetCatchable(self.pData) then
        return false
    end
    if ModuleRefer.RadarModule:IsRadarTaskEntity(self.pData.data.ID, ObjectType.SlgCatchPet) then
        return false
    end

    local lod = KingdomMapUtils.GetLOD()
	return lod > KingdomConstant.NormalLod and lod < KingdomConstant.MediumLod
end

function PlayerTileAssetPetIcon:GetScale()
    return Vector3.one
end

---@return string
function PlayerTileAssetPetIcon:GetLodPrefabName(lod)
    return ManualResourceConst.ui3d_bubble_world_ecs
end

function PlayerTileAssetPetIcon:OnShow()
    PvPTileAssetUnit.OnShow(self)
    self.pData = self:GetData()
end

function PlayerTileAssetPetIcon:OnConstructionSetup()
    PvPTileAssetUnit.OnConstructionSetup(self)
    if not self.pData then
        return
    end
    local asset = self:GetAsset()
    self.petIconGo = asset
    asset.transform.name = "ui3d_bubble_world_ecs_pet_" .. self.pData.uniqueName
    asset.transform.position = self.pData.worldPos + WORLD_PET_ICON_OFFSET
    asset.transform.localScale = VECTOR3_ONE * PET_ICON_SCALE
    self.rotation = asset.transform:Find("p_rotation")
    self.bubble = asset:GetComponentInChildren(typeof(CS.UI3DBubbleWorldECS))
    -- self.bubble.FacingCamera.FacingCamera = KingdomMapUtils.GetBasicCamera().mainCamera
    self.bubble.FacingCamera.OrthographicScale = PET_ICON_INNER_SCALE
    self.bubble.FacingCamera.facingOffset = WORLD_PET_ICON_FACING_OFFSET
    self.bubble:SetIcon(SP_PET_ICON)
    self.bubble:SetFrameActive(false)
    -- if not self.pData.village and  ModuleRefer.RadarModule:IsRadarTaskEntity(self.pData.data.ID, ObjectType.SlgCatchPet) then
    --     self.bubble:SetIcon("sp_comp_icon_radar_pet")
    --     self.bubble:SetFrameActive(false)
    --     self.bubble:SetFrame(ModuleRefer.RadarModule:GetRadarTaskLodBase(self.pData.data.ID))
    -- else
    --     self.bubble:SetFrameActive(false)
    -- end
    local cdata = self.bubble.gameObject:GetComponent(typeof(CS.CustomData))
    if (not cdata) then
        cdata = self.bubble.gameObject:AddComponent(typeof(CS.CustomData))
    end
    if (cdata) then
        cdata.intData = WORLD_PET_INT_DATA
        cdata.objectData = self.pData
    end
    self:OnConstructionUpdate()
end

function PlayerTileAssetPetIcon:OnHide()
    PvPTileAssetUnit.OnHide(self)
end

function PlayerTileAssetPetIcon:OnConstructionShutdown()
    if Utils.IsNotNull(self.petIconGo) then
        self.petIconGo.transform:DOKill()
    end
end


function PlayerTileAssetPetIcon:OnConstructionUpdate()
    PvPTileAssetUnit.OnConstructionUpdate(self)
    if not self.pData then
        return
    end
    if self:CanShow() then
        self:Show()
    else
        self:Hide()
    end
    local newData, villageList = ModuleRefer.PetModule:GetPetOriginDataAndVillage(self.pData.uniqueName)
    if not (newData and villageList) then
        return
    end
    if Utils.IsNullOrEmpty(self.petIconGo) then
        return
    end
    if Utils.IsNullOrEmpty(self.rotation) then
        return
    end
    self.rotation.gameObject:SetActive(false)
    self.rotation.gameObject:SetActive(true)
    self.pData.village = villageList[self.pData.uniqueName]
    local x = math.floor(newData.CurPos.X)
	local z = math.floor(newData.CurPos.Y)
	local wpos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(x, z, KingdomMapUtils.GetMapSystem())
    if self.pData.worldPos ~= wpos then
        local fpos = wpos + WORLD_PET_ICON_OFFSET
        local delta = fpos - self.pData.worldPos
        local movingTime = delta.magnitude / WORLD_PET_MOVING_SPEED
        if self.petIconGo.activeSelf then
            self.petIconGo.transform:DOKill()
            self.petIconGo.transform:DOMove(fpos, movingTime):SetEase(Ease.Linear)
        else
            self.petIconGo.transform.position = fpos
        end
    end
    self.pData.worldPos = wpos
end

return PlayerTileAssetPetIcon