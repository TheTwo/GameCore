local KingdomSurface = require("KingdomSurface")
local PoolUsage = require("PoolUsage")
local ManualResourceConst = require("ManualResourceConst")
local KingdomConstant = require("KingdomConstant")
local Layers = require("Layers")
local ModuleRefer = require("ModuleRefer")
local MapHUDFadeDefine = require("MapHUDFadeDefine")

local GameObjectHandle = CS.DragonReborn.AssetTool.PooledGameObjectHandle

local EnterLod = KingdomConstant.Lod8

---@class KingdomSurfaceDistrictNames : KingdomSurface
local KingdomSurfaceDistrictNames = class("KingdomSurfaceDistrictNames", KingdomSurface)

function KingdomSurfaceDistrictNames:ctor()
    self.handle = GameObjectHandle(PoolUsage.Kingdom)
end

function KingdomSurfaceDistrictNames:OnLeaveMap()
    self:Leave()
end

---@param go CS.UnityEngine.GameObject
local function OnLoaded(go, data)
    go.transform.position = data.mapSystem.GlobalOffset
    go:SetLayerRecursive(Layers.Scene3DUI)
    
    local materialSetter = go:GetComponent(typeof(CS.Lod.U2DWidgetMaterialSetter))
    ModuleRefer.MapHUDModule:UpdateHUDFade(materialSetter, MapHUDFadeDefine.FadeIn)
end

function KingdomSurfaceDistrictNames:OnLodChanged(oldLod, newLod)
    if oldLod < EnterLod and newLod >= EnterLod then
        self:Enter()
    elseif oldLod >= EnterLod and newLod < EnterLod then
        self:Leave()
    end
end

function KingdomSurfaceDistrictNames:Enter()
    if self.handle.Loaded then
        self.handle:Delete()
    end
    self.handle:Create(ManualResourceConst.ui3d_district_names, self.root, OnLoaded, self)
end

function KingdomSurfaceDistrictNames:Leave()
    if self.handle.Loaded then
        local go = self.handle.Asset
        local materialSetter = go:GetComponent(typeof(CS.Lod.U2DWidgetMaterialSetter))
        ModuleRefer.MapHUDModule:UpdateHUDFade(materialSetter, MapHUDFadeDefine.FadeOut)

        local delay = ModuleRefer.MapHUDModule:GetFadeDuration()
        self.handle:Delete(delay)
    end
end

return KingdomSurfaceDistrictNames