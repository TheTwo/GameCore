local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")
---@class CityFurWorkBubbleStateAllianceRecommend:CityFurWorkBubbleStateBase
---@field new fun():CityFurWorkBubbleStateAllianceRecommend
local CityFurWorkBubbleStateRadarEnter = class("CityFurWorkBubbleStateAllianceRecommend", CityFurWorkBubbleStateBase)
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require('ModuleRefer')

function CityFurWorkBubbleStateRadarEnter:GetName()
    return CityFurWorkBubbleStateBase.Names.RadarEnter
end

function CityFurWorkBubbleStateRadarEnter:Enter()
    CityFurWorkBubbleStateBase.Enter(self)
    local bubble = self.tileAsset:GetBubble()
    if bubble and bubble:IsValid() then
        self:OnBubbleLoaded(bubble)
    else
        self:OnBubbleUnload()
    end
end

---@param bubble City3DBubbleStandard
function CityFurWorkBubbleStateRadarEnter:OnBubbleLoaded(bubble)
    self._bubble = bubble
    self._bubble:Reset()

    self._bubble:ShowBubble("sp_radar_icon_radar")
    self._bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self:GetTile())
end

function CityFurWorkBubbleStateRadarEnter:OnBubbleUnload()
    if self._bubble then
        self._bubble:ClearTrigger()
        self._bubble = nil
    end
end

function CityFurWorkBubbleStateRadarEnter:OnClick()
    local city = ModuleRefer.CityModule.myCity
    local camera = city:GetCamera()
    local param = {isInCity = true, stack = camera and camera:RecordCurrentCameraStatus()}
    g_Game.UIManager:Open(UIMediatorNames.RadarMediator,param)
    return true
end

return CityFurWorkBubbleStateRadarEnter