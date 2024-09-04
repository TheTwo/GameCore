local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")
---@class CityFurWorkBubbleStateAllianceRecommend:CityFurWorkBubbleStateBase
---@field new fun():CityFurWorkBubbleStateAllianceRecommend
local CityFurWorkBubbleStateAllianceRecommendation = class("CityFurWorkBubbleStateAllianceRecommend", CityFurWorkBubbleStateBase)
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require('ModuleRefer')

function CityFurWorkBubbleStateAllianceRecommendation:GetName()
    return CityFurWorkBubbleStateBase.Names.AllianceRecommendation
end

function CityFurWorkBubbleStateAllianceRecommendation:Enter()
    CityFurWorkBubbleStateBase.Enter(self)
    local bubble = self.tileAsset:GetBubble()
    if bubble and bubble:IsValid() then
        self:OnBubbleLoaded(bubble)
    else
        self:OnBubbleUnload()
    end
end

---@param bubble City3DBubbleStandard
function CityFurWorkBubbleStateAllianceRecommendation:OnBubbleLoaded(bubble)
    self._bubble = bubble
    self._bubble:Reset()

    self._bubble:ShowBubble("sp_icon_item_league_recommend")
    self._bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self:GetTile())
end

function CityFurWorkBubbleStateAllianceRecommendation:OnBubbleUnload()
    if self._bubble then
        self._bubble:ClearTrigger()
        self._bubble = nil
    end
end

function CityFurWorkBubbleStateAllianceRecommendation:OnClick()
    local recommendation = ModuleRefer.AllianceModule:GetRecommendation()
    if recommendation then
        g_Game.UIManager:Open(UIMediatorNames.AllianceRecommendMediator,recommendation)
    end
    return true
end

return CityFurWorkBubbleStateAllianceRecommendation