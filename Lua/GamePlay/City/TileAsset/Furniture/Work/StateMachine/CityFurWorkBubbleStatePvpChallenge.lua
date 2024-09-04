local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
---@class CityFurWorkBubbleStatePvpChallenge : CityFurWorkBubbleStateBase
local CityFurWorkBubbleStatePvpChallenge = class("CityFurWorkBubbleStatePvpChallenge", CityFurWorkBubbleStateBase)

function CityFurWorkBubbleStatePvpChallenge:GetName()
    return CityFurWorkBubbleStateBase.Names.PvpChallenge
end

function CityFurWorkBubbleStatePvpChallenge:Enter()
    CityFurWorkBubbleStateBase.Enter(self)
    local bubble = self.tileAsset:GetBubble()
    if bubble and bubble:IsValid() then
        self:OnBubbleLoaded(bubble)
    else
        self:OnBubbleUnload()
    end
end

---@param bubble City3DBubbleStandard
function CityFurWorkBubbleStatePvpChallenge:OnBubbleLoaded(bubble)
    self._bubble = bubble
    self._bubble:Reset()

    self._bubble:ShowBubble("sp_item_icon_pvp")
    self._bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self:GetTile())
end

function CityFurWorkBubbleStatePvpChallenge:OnBubbleUnload()
    if self._bubble then
        self._bubble:ClearTrigger()
        self._bubble = nil
    end
end

function CityFurWorkBubbleStatePvpChallenge:OnClick()
    g_Game.UIManager:Open(UIMediatorNames.ReplicaPVPMainMediator)
    return true
end

return CityFurWorkBubbleStatePvpChallenge