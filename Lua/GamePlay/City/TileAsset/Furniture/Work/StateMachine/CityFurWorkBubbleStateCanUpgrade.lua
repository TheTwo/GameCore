local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")
---@class CityFurWorkBubbleStateCanUpgrade:CityFurWorkBubbleStateBase
---@field new fun():CityFurWorkBubbleStateCanUpgrade
local CityFurWorkBubbleStateCanUpgrade = class("CityFurWorkBubbleStateCanUpgrade", CityFurWorkBubbleStateBase)
local Delegate = require("Delegate")
local CityWorkType = require("CityWorkType")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local CityLegoBuildingUIParameter = require("CityLegoBuildingUIParameter")

function CityFurWorkBubbleStateCanUpgrade:GetName()
    return CityFurWorkBubbleStateBase.Names.CanUpgrade
end

function CityFurWorkBubbleStateCanUpgrade:Enter()
    CityFurWorkBubbleStateBase.Enter(self)
    local bubble = self.tileAsset:GetBubble()
    if bubble and bubble:IsValid() then
        self:OnBubbleLoaded(bubble)
    else
        self:OnBubbleUnload()
    end
end

---@param bubble City3DBubbleStandard
function CityFurWorkBubbleStateCanUpgrade:OnBubbleLoaded(bubble)
    self._bubble = bubble
    self._bubble:Reset()

    self._bubble:ShowBubble("sp_common_icon_arrow_08")
    self._bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self:GetTile())
end

function CityFurWorkBubbleStateCanUpgrade:OnBubbleUnload()
    if self._bubble then
        self._bubble:ClearTrigger()
        self._bubble = nil
    end
end

function CityFurWorkBubbleStateCanUpgrade:OnClick()
    local workId = self.furniture:GetWorkCfgId(CityWorkType.FurnitureLevelUp)
    if workId == 0 then return true end

    local tile = self:GetTile()
    if tile == nil then return true end

    local castleFurniture = self.furniture:GetCastleFurniture()
    local legoBuilding = nil
    if castleFurniture.BuildingId > 0 then
        legoBuilding = self.city.legoManager:GetLegoBuilding(castleFurniture.BuildingId)
    end

    -- local param = CityLegoBuildingUIParameter.new(self.city, legoBuilding, self.furnitureId)
    -- g_Game.UIManager:Open(UIMediatorNames.CityLegoBuildingUIMediator, param)
    return true
end

return CityFurWorkBubbleStateCanUpgrade