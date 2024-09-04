local CityTileAssetBubble = require("CityTileAssetBubble")
---@class CityTileAssetLegoBuildingLockedServiceBubble:CityTileAssetBubble
---@field new fun():CityTileAssetLegoBuildingLockedServiceBubble
local CityTileAssetLegoBuildingLockedServiceBubble = class("CityTileAssetLegoBuildingLockedServiceBubble", CityTileAssetBubble)
local Utils = require("Utils")
local I18N = require("I18N")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local LegoBuildingNpcServiceGotoProvider = require("LegoBuildingNpcServiceGotoProvider")
local ManualResourceConst = require("ManualResourceConst")

---@param legoBuliding CityLegoBuilding
---@param npcServiceCfg NpcServiceConfigCell
function CityTileAssetLegoBuildingLockedServiceBubble:ctor(legoBuliding, npcServiceCfg)
    self.legoBuilding = legoBuliding
    self.npcServiceCfg = npcServiceCfg
end

function CityTileAssetLegoBuildingLockedServiceBubble:GetPrefabName()
    if not self:CheckCanShow() then return string.Empty end
    
    return ManualResourceConst.ui3d_bubble_entrance_building
end

function CityTileAssetLegoBuildingLockedServiceBubble:OnAssetLoaded(go, userdata, handle)
    CityTileAssetBubble.OnAssetLoaded(self, go, userdata, handle)
    if Utils.IsNull(go) then return end

    self.go = go
    local pos = self.legoBuilding:GetWorldCenter()
    local offset = self.legoBuilding.legoBluePrintCfg:BubbleHeightOffset() * self:GetCity().scale
    self.go.transform.position = pos + (CS.UnityEngine.Vector3.up * offset)

    ---@type CityFurnitureBuildingEntryBubble
    local bubble = self.go:GetLuaBehaviour("CityFurnitureBuildingEntryBubble").Instance
    bubble:ChangeStatusToNPC()
        :SetName(I18N.Get(self.legoBuilding:GetNameI18N()))
        :SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self.tileView.tile)
end

function CityTileAssetLegoBuildingLockedServiceBubble:OnAssetUnload(go, fadeOut)
    self.go = nil
end

function CityTileAssetLegoBuildingLockedServiceBubble:OnClick()
    g_Game.UIManager:Open(UIMediatorNames.UIRaisePowerPopupMediator, self:GetContentProviderParam())
    return true
end

function CityTileAssetLegoBuildingLockedServiceBubble:GetContentProviderParam()
    ---@type RaisePowerPopupParam
    local ret = {
        overrideDefaultProvider = LegoBuildingNpcServiceGotoProvider.new(self.legoBuilding)
    }
    return ret
end

return CityTileAssetLegoBuildingLockedServiceBubble