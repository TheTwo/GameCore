local PvPTileAssetUnit = require("PvPTileAssetUnit")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local Utils = require("Utils")
local ManualResourceConst = require("ManualResourceConst")

local Vector3 = CS.UnityEngine.Vector3

---@class PlayerTileAssetPetCatchEffect : PvPTileAssetUnit
local PlayerTileAssetPetCatchEffect = class("PlayerTileAssetPetCatchEffect", PvPTileAssetUnit)

function PlayerTileAssetPetCatchEffect:CanShow()
    if not KingdomMapUtils.InMapNormalLod() then
        return false
    end

    if not KingdomMapUtils.IsMapState() then
		return false
	end

    return true
end

function PlayerTileAssetPetCatchEffect:GetScale()
    return Vector3.one
end

---@return string
function PlayerTileAssetPetCatchEffect:GetLodPrefabName(lod)
    if KingdomMapUtils.InMapNormalLod(lod) and self.pData then
        
        if ModuleRefer.PetModule:CheckPetCatchable(self.pData) then
            -- 可捕捉特效
            return ManualResourceConst.fx_bigmap_pet_buzuo_01
        else
            -- 不可捕捉特效
            return ManualResourceConst.vfx_bigmap_pet_baohuzhao
        end
    end
    
    return string.Empty
end

function PlayerTileAssetPetCatchEffect:GetVfxHangPoint()
    if ModuleRefer.PetModule:CheckPetCatchable(self.pData) then
        return ModuleRefer.PetModule:GetPetVxRoot(self.pData.uniqueName)
    end

    return ModuleRefer.PetModule:GetPetVxCenter(self.pData.uniqueName)
end

function PlayerTileAssetPetCatchEffect:OnShow()
    PvPTileAssetUnit.OnShow(self)
    self.pData = self:GetData()
end

function PlayerTileAssetPetCatchEffect:OnConstructionSetup()
    PvPTileAssetUnit.OnConstructionSetup(self)
    if not self.pData then
        return
    end
    local uniqueName = self.pData.uniqueName
    local asset = self:GetAsset()
    if asset then
        asset.transform.name = "petEffect_".. uniqueName
    end
    self.petEffectGo = asset
    local vxHangPoint = self:GetVfxHangPoint()
    if Utils.IsNotNull(vxHangPoint) then
        self.petEffectGo.transform:SetParent(vxHangPoint.transform, false)
    end
    self:OnConstructionUpdate()
end

function PlayerTileAssetPetCatchEffect:OnHide()
    PvPTileAssetUnit.OnHide(self)
end

function PlayerTileAssetPetCatchEffect:OnConstructionShutdown()

end

function PlayerTileAssetPetCatchEffect:OnConstructionUpdate()
    PvPTileAssetUnit.OnConstructionUpdate(self)

    if self:CanShow() then
        self:Show()
    else
        self:Hide()
    end

    if not self.pData then
        return
    end

    local newData, villageList = ModuleRefer.PetModule:GetPetOriginDataAndVillage(self.pData.uniqueName)
    if not (newData and villageList) then
        return
    end

    if Utils.IsNullOrEmpty(self.petEffectGo) then
        return
    end

    if Utils.IsNotNull(self.petEffectGo) then
        local vxHangPoint = self:GetVfxHangPoint()
        if Utils.IsNotNull(vxHangPoint) then
            self.petEffectGo.transform:SetParent(vxHangPoint, false)
        end
        
        self.pData.village = villageList
    end
end

return PlayerTileAssetPetCatchEffect