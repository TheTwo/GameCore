local PvPTileAssetUnit = require("PvPTileAssetUnit")
local KingdomMapUtils = require("KingdomMapUtils")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local ModuleRefer = require("ModuleRefer")
local DBEntityType = require("DBEntityType")
local MoveCityParameter = require("MoveCityParameter")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ManualResourceConst = require("ManualResourceConst")

local One = CS.UnityEngine.Vector3.one

---@class PvPTileAssetRelocateEffect : PvPTileAssetUnit
local PvPTileAssetRelocateEffect = class("PvPTileAssetRelocateEffect", PvPTileAssetUnit)

function PvPTileAssetRelocateEffect:CanShow()
    if self.canShow then
        return true
    end
    return false
end

function PvPTileAssetRelocateEffect:GetLodPrefabName(lod)
    if KingdomMapUtils.InMapNormalLod(lod) then
        return ManualResourceConst.vfx_S_slg_city_bron
    end
    return string.Empty
end

function PvPTileAssetRelocateEffect:GetScale()
    return CS.UnityEngine.Vector3(0.75, 0.75, 0.75)
end

function PvPTileAssetRelocateEffect:OnShow()
    -- g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushMoveCity, Delegate.GetOrCreate(self, self.OnRelocated))
    g_Game.EventManager:AddListener(EventConst.RELOCATE_CITY_DONE, Delegate.GetOrCreate(self, self.OnRelocated))
end

function PvPTileAssetRelocateEffect:OnHide()
    self.canShow = false
    -- g_Game.ServiceManager:RemoveResponseCallback(MoveCityParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnRelocated))
    g_Game.EventManager:RemoveListener(EventConst.RELOCATE_CITY_DONE, Delegate.GetOrCreate(self, self.OnRelocated))
end

function PvPTileAssetRelocateEffect:OnRelocated(entityID)
    if not entityID then
        return
    end
    local entity = self:GetData()
    if not entity then
        return
    end
    if entity.ID ~= entityID then
        return
    end
    self.canShow = true
    self:Refresh()
    self.canShow = false
end


return PvPTileAssetRelocateEffect