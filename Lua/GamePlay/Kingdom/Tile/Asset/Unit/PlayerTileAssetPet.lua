local PvPTileAssetUnit = require("PvPTileAssetUnit")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local ConfigRefer = require("ConfigRefer")
local TimerUtility = require('TimerUtility')
local Utils = require("Utils")

local Vector3 = CS.UnityEngine.Vector3
local Vector2Short = CS.DragonReborn.Vector2Short
local Ease = CS.DG.Tweening.Ease
local LAYER_KINGDOM = 13
local WORLD_PET_SCALE = 0.016
local WORLD_PET_INT_DATA = 110
local VECTOR3_ONE = CS.UnityEngine.Vector3.one
local WORLD_PET_ANIM_IDLE = "idle"
local WORLD_PET_ANIM_MOVING = "run"
local WORLD_PET_MOVING_SPEED = 50

---@class PlayerTileAssetPet : PvPTileAssetUnit
local PlayerTileAssetPet = class("PlayerTileAssetPet", PvPTileAssetUnit)

function PlayerTileAssetPet:CanShow()
    if not KingdomMapUtils.InMapNormalLod() then
        return false
    end
    if not KingdomMapUtils.IsMapState() then
		return false
	end
    return true
end

function PlayerTileAssetPet:GetScale()
    return Vector3.one
end

---@return string
function PlayerTileAssetPet:GetLodPrefabName(lod)
    if KingdomMapUtils.InMapNormalLod(lod) then
        if self.pData then
            local cfg = ConfigRefer.PetWild:Find(self.pData.data.ConfigId)
            local artResConf = ConfigRefer.ArtResource:Find(cfg:Model())
            return artResConf:Path()
        end
    end
    return string.Empty
end

function PlayerTileAssetPet:OnShow()
    PvPTileAssetUnit.OnShow(self)
    self.pData = self:GetData()
end

function PlayerTileAssetPet:OnConstructionSetup()
    PvPTileAssetUnit.OnConstructionSetup(self)

    if not self.pData then
        return
    end

    local asset = self:GetAsset()
    if Utils.IsNull(asset) then
        return
    end

    if asset then
        asset.transform.name = "pet_".. self.pData.uniqueName
    end

    self.petGo = asset
    self.bubbleGo = nil
    self.bubble = nil
    local uniqueName = self.pData.uniqueName
    ModuleRefer.PetModule:SetPetUnitRoot(uniqueName, self.petGo.transform)
    local pdata = self.pData
    local cfg = ConfigRefer.PetWild:Find(pdata.data.ConfigId)
    local petCfg = ModuleRefer.PetModule:GetPetCfg(cfg:PetId())
    local typeCfg = ModuleRefer.PetModule:GetTypeCfg(petCfg:Type())
    local artResConf = ConfigRefer.ArtResource:Find(cfg:Model())
    local modelScale = artResConf:ModelScale()
    if (not modelScale or modelScale == 0) then modelScale = 1 end
    local scale = WORLD_PET_SCALE
    if (typeCfg and typeCfg.ColliderScale and typeCfg:ColliderScale() > 0) then
        scale = typeCfg:ColliderScale()
    end
    local hasCollider = typeCfg and typeCfg.Collider and typeCfg:Collider() and typeCfg:ColliderPosLength() > 4
    local trans = asset.transform
    trans.position = self.pData.worldPos
    trans.localScale = VECTOR3_ONE * scale
    -- 宠物朝向随机
    trans.localRotation = CS.UnityEngine.Quaternion.Euler(CS.UnityEngine.Vector3(0, math.random(-90, 90), 0))
    asset:SetLayerRecursive(LAYER_KINGDOM)
    local fbxTrans = nil
    if (trans.childCount > 0) then
        fbxTrans = trans:GetChild(0)
    end
    if (Utils.IsNotNull(fbxTrans)) then
        fbxTrans.localScale = VECTOR3_ONE * modelScale
    end
    -- Collider
    if (hasCollider) then
        local collider = asset:GetComponent(typeof(CS.UnityEngine.CapsuleCollider))
        if (not collider) then
            collider = asset:AddComponent(typeof(CS.UnityEngine.CapsuleCollider))
        end
        if (collider) then
            collider.center = CS.UnityEngine.Vector3(typeCfg:ColliderPos(1), typeCfg:ColliderPos(2), typeCfg:ColliderPos(3))
            collider.radius = typeCfg:ColliderPos(4)
            collider.height = typeCfg:ColliderPos(5)
        end
    end

    ---@type CS.CustomData
    local cdata = asset:GetComponent(typeof(CS.CustomData))
    if (not cdata) then
        cdata = asset:AddComponent(typeof(CS.CustomData))
    end
    if (cdata) then
        cdata.intData = WORLD_PET_INT_DATA
        cdata.objectData = pdata
    end

    ---@type CS.UnityEngine.Animator
    local animator = asset:GetComponentInChildren(typeof(CS.UnityEngine.Animator))
    if Utils.IsNotNull(animator) then
        animator:Play(WORLD_PET_ANIM_IDLE)
    else
        g_Logger.Error('pet %s没有Animator组件, 请修改!', artResConf:Path())
    end

    self:OnConstructionUpdate()
end

function PlayerTileAssetPet:OnHide()
    PvPTileAssetUnit.OnHide(self)
end

function PlayerTileAssetPet:OnConstructionShutdown()
    if Utils.IsNotNull(self.petGo) then
        self.petGo.transform:DOKill()
    end
    
    if self.remainTimer then
        TimerUtility.StopAndRecycle(self.remainTimer)
        self.remainTimer = nil
    end
end

function PlayerTileAssetPet:OnConstructionUpdate()
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
    if Utils.IsNullOrEmpty(self.petGo) then
        return
    end
    local x = math.floor(newData.CurPos.X)
	local z = math.floor(newData.CurPos.Y)
	local wpos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(x, z, KingdomMapUtils.GetMapSystem())
    local gpos = Vector2Short(x, z)
    -- 移动到下一处
    if self.pData.worldPos ~= wpos then
        if Utils.IsNotNull(self.petGo) then
            local animator = self.petGo:GetComponentInChildren(typeof(CS.UnityEngine.Animator))
            if Utils.IsNotNull(animator) then
                animator:Play(WORLD_PET_ANIM_MOVING)
            end
            local delta = wpos - self.pData.worldPos
            local forward = delta.normalized
            local movingTime = delta.magnitude / WORLD_PET_MOVING_SPEED
            forward.y = 0
            self.petGo.transform.forward = forward
            self.petGo.transform:DOKill()
            self.petGo.transform:DOMove(wpos, movingTime):SetEase(Ease.Linear):OnComplete(function()
                if Utils.IsNotNull(animator) then
                    animator:Play(WORLD_PET_ANIM_IDLE)
                end
            end)
        end
        self.pData.worldPos = wpos
    end
end

return PlayerTileAssetPet