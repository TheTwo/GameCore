local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetZzz:CityTileAsset
---@field new fun():CityTileAssetZzz
---@field animation CS.UnityEngine.Animation
local CityTileAssetZzz = class("CityTileAssetZzz", CityTileAsset)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")

function CityTileAssetZzz:ctor()
    CityTileAsset:ctor(self)
    self.isUI = true
end

function CityTileAssetZzz:ShouldShow()
    return ModuleRefer.ScienceModule:CheckIsHasCanResearchTech()
end

function CityTileAssetZzz:OnTileViewInit()
    g_Game.EventManager:AddListener(EventConst.ON_REFRESH_TECH, Delegate.GetOrCreate(self, self.OnChangeTechState))
    g_Game.EventManager:AddListener(EventConst.CITY_EDIT_MODE_CHANGE, Delegate.GetOrCreate(self, self.OnEditModeChanged))
end

function CityTileAssetZzz:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.ON_REFRESH_TECH, Delegate.GetOrCreate(self, self.OnChangeTechState))
    g_Game.EventManager:RemoveListener(EventConst.CITY_EDIT_MODE_CHANGE, Delegate.GetOrCreate(self, self.OnEditModeChanged))
end

function CityTileAssetZzz:OnChangeTechState()
    self:Refresh()
end

function CityTileAssetZzz:Refresh()
    self:Hide()
    self:Show()
end

function CityTileAssetZzz:GetPrefabName()
    if self:ShouldShow() then
        return ArtResourceUtils.GetItem(ArtResourceConsts.ui3d_science_zzz)
    end
    return string.Empty
end

function CityTileAssetZzz:OnAssetLoaded(go, userdata)

end

function CityTileAssetZzz:OnAssetUnload(go, fade)

end
function CityTileAssetZzz:OnEditModeChanged(flag)
    if flag then
        self:Hide()
    else
        self:Show()
    end
end

return CityTileAssetZzz