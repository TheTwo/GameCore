local State = require("State")
---@class CityFurWorkBubbleStateBase:State
---@field new fun():CityFurWorkBubbleStateBase
local CityFurWorkBubbleStateBase = class("CityFurWorkBubbleStateBase", State)
CityFurWorkBubbleStateBase.Names = {
    Idle = "Idle",
    Upgraded = "Upgraded",
    Process = "Process",
    Produce = "Produce",
    Collect = "Collect",
    CanUpgrade = "CanUpgrade",
    AllianceHelp = "AllianceHelp",
    AutoPetCatch = "AutoPetCatch",
    AllianceRecommendation = "AllianceRecommendation",
    RadarEnter = "RadarEnter",
    NeedPet = "NeedPet",
    Storeroom = "Storeroom",
    CanHatchPet = "CanHatchPet",
    CanProcess = "CanProcess",
    PvpChallenge = "PvpChallenge",
    Hunting = "Hunting",
}
local ManualResourceConst = require("ManualResourceConst")

---@param tileAsset CityTileAssetBubbleFurnitureWork
function CityFurWorkBubbleStateBase:ctor(furnitureId, tileAsset)
    self.furnitureId = furnitureId
    self.tileAsset = tileAsset
    self.city = self.tileAsset:GetCity()
    self.furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
end

function CityFurWorkBubbleStateBase:Enter()
    self.tileAsset:ForceRefresh()
end

function CityFurWorkBubbleStateBase:Exit()
    
end

---@param bubble City3DBubbleStandard
function CityFurWorkBubbleStateBase:OnBubbleLoaded(bubble)
    bubble:Reset()
end

function CityFurWorkBubbleStateBase:OnBubbleUnload()
    ---override this
end

function CityFurWorkBubbleStateBase:GetPrefabName()
    return ManualResourceConst.ui3d_bubble_group
end

function CityFurWorkBubbleStateBase:GetTile()
    if self.tileAsset and self.tileAsset.tileView and self.tileAsset.tileView.tile then
        return self.tileAsset.tileView.tile
    end
end

return CityFurWorkBubbleStateBase