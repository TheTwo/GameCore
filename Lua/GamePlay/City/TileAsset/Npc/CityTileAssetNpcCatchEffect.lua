local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")

local CityTileAsset = require("CityTileAsset")

---@class CityTileAssetNpcCatchEffect:CityTileAsset
---@field super CityTileAsset
local CityTileAssetNpcCatchEffect = class("CityTileAssetNpcCatchEffect", CityTileAsset)

function CityTileAssetNpcCatchEffect:ctor()
    CityTileAssetNpcCatchEffect.super.ctor(self)
    self._needAddEvent = false
    ---@type CS.UnityEngine.Material[]
    self._needTickMat = {}
    self._tickLeft = nil
    self._tickTotal = nil
end

function CityTileAssetNpcCatchEffect:OnTileViewInit()
    local cell = self.tileView.tile:GetCell()
    self._elementId = cell:UniqueId()
    self._cityUid = self.tileView.tile:GetCity().uid
    local config = ConfigRefer.CityElementData:Find(self._elementId)
    self._needAddEvent = false
    self._vfxPrefab = string.Empty
    if config then
        local npcConfig = ConfigRefer.CityElementNpc:Find(config:ElementId())
        self._needAddEvent = npcConfig:InteractSeSkill() ~= 0
    end
    if self._needAddEvent then
        g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_NPC_TRIGGER_CATCH_EFFECT, Delegate.GetOrCreate(self, self.OnCatchEffectFire))
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.TickMat))
    end
end

function CityTileAssetNpcCatchEffect:OnTileViewRelease()
    if self._needAddEvent then
        g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_NPC_TRIGGER_CATCH_EFFECT, Delegate.GetOrCreate(self, self.OnCatchEffectFire))
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.TickMat))
    end
end

function CityTileAssetNpcCatchEffect:Refresh()
    self:Hide()
    self:Show()
end

function CityTileAssetNpcCatchEffect:GetPrefabName()
    return self._vfxPrefab
end

function CityTileAssetNpcCatchEffect:TickMat(dt)
    if not self._tickLeft then return end
    self._tickLeft = self._tickLeft - dt
    local alpha = 1 - math.inverseLerp(0, self._tickTotal, self._tickLeft)
    for _, value in pairs(self._needTickMat) do
        value:SetFloat("Alpha", alpha)
    end
    if self._tickLeft <= 0 then
        self._tickLeft = nil
    end
end

function CityTileAssetNpcCatchEffect:OnCatchEffectFire(cityUid, elementId, vfx, matVfx, fadeTime, triggerAudio)
    if self._cityUid ~= cityUid or self._elementId ~= elementId then return end
    self._vfxPrefab = vfx
    self._tickLeft = fadeTime
    self._tickTotal = fadeTime
    ---@type table<CityTileAssetNpc|CityTileAssetNpcSLG, CityTileAssetNpc|CityTileAssetNpcSLG>
    local mainAsset = self.tileView:GetMainAssets()
    if not mainAsset then return end
    if triggerAudio then
        for _, value in pairs(mainAsset) do
            if value.PlayAudioOnGo and value:PlayAudioOnGo(triggerAudio) then
                break
            end
        end
    end
    table.clear(self._needTickMat)
    for _, assetLogic in pairs(mainAsset) do
        if GetClassName(assetLogic) == "CityTileAssetNpc" then
            ---@type CityTileAssetNpc
            local npcAsset = assetLogic
            local mat = npcAsset:AttachRenderMat(matVfx)
            if mat then
                table.insert(self._needTickMat, mat)
            end
        end
    end
    self:Refresh()
end

return CityTileAssetNpcCatchEffect