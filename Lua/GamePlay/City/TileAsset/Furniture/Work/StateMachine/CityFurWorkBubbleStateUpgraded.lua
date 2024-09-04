local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")
---@class CityFurWorkBubbleStateUpgraded:CityFurWorkBubbleStateBase
---@field new fun():CityFurWorkBubbleStateUpgraded
local CityFurWorkBubbleStateUpgraded = class("CityFurWorkBubbleStateUpgraded", CityFurWorkBubbleStateBase)
local Delegate = require("Delegate")

function CityFurWorkBubbleStateUpgraded:GetName()
    return CityFurWorkBubbleStateBase.Names.Upgraded
end

function CityFurWorkBubbleStateUpgraded:Enter()
    CityFurWorkBubbleStateBase.Enter(self)
    
    local bubble = self.tileAsset:GetBubble()
    if bubble and bubble:IsValid() then
        self:OnBubbleLoaded(bubble)
    else
        self:OnBubbleUnload()
    end
end

function CityFurWorkBubbleStateUpgraded:Exit()
    CityFurWorkBubbleStateBase.Exit(self)
    self._bubble = nil
end

---@param bubble City3DBubbleStandard
function CityFurWorkBubbleStateUpgraded:OnBubbleLoaded(bubble)
    self._bubble = bubble

    self._bubble:Reset()
    self._bubble:ShowBubble("sp_icon_tick_ui3d"):PlayRewardAnim()
    self._bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self:GetTile())
end

function CityFurWorkBubbleStateUpgraded:OnBubbleUnload()
    self._bubble = nil
end

function CityFurWorkBubbleStateUpgraded:OnClick()
    self.city.furnitureManager:RequestClaimFurnitureLevelUp(self.furnitureId)
    return true
end

return CityFurWorkBubbleStateUpgraded