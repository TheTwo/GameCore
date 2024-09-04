local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")
---@class CityFurWorkBubbleStateNeedPet:CityFurWorkBubbleStateBase
local CityFurWorkBubbleStateNeedPet = class("CityFurWorkBubbleStateNeedPet", CityFurWorkBubbleStateBase)
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local CityWorkType = require("CityWorkType")
local CityCollectV2UIParameter = require("CityCollectV2UIParameter")
local UIMediatorNames = require("UIMediatorNames")
local BuildMasterDeployUIDataSrc = require("BuildMasterDeployUIDataSrc")
local CityFurnitureDeployUIParameter = require("CityFurnitureDeployUIParameter")
local CityMobileUnitUIParameter = require("CityMobileUnitUIParameter")
local HeaterPetDeployUIDataSrc = require("HeaterPetDeployUIDataSrc")
local CityUtils = require("CityUtils")

function CityFurWorkBubbleStateNeedPet:GetName()
    return CityFurWorkBubbleStateBase.Names.NeedPet
end

function CityFurWorkBubbleStateNeedPet:Enter()
    CityFurWorkBubbleStateBase.Enter(self)
    local bubble = self.tileAsset:GetBubble()
    if bubble and bubble:IsValid() then
        self:OnBubbleLoaded(bubble)
    else
        self:OnBubbleUnload()
    end
end

function CityFurWorkBubbleStateNeedPet:Exit()
    CityFurWorkBubbleStateBase.Exit(self)
    self._bubble = nil
end

---@param bubble City3DBubbleStandard
function CityFurWorkBubbleStateNeedPet:OnBubbleLoaded(bubble)
    self._bubble = bubble
    self._bubble:Reset()

    self._bubble:ShowBubble("sp_city_bubble_add_pet")
    self._bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self:GetTile())
end

function CityFurWorkBubbleStateNeedPet:OnBubbleUnload()
    self._bubble = nil
end

function CityFurWorkBubbleStateNeedPet:OnClick()
    local tile = self.city.gridView:GetFurnitureTile(self.furniture.x, self.furniture.y)
    if not tile then return false end

    local lvCfg = self.furniture.furnitureCell
    for i = 1, lvCfg:WorkListLength() do
        local workCfg = ConfigRefer.CityWork:Find(lvCfg:WorkList(i))
        if workCfg:Type() == CityWorkType.ResourceProduce then
            local param = CityCollectV2UIParameter.new(tile)
            g_Game.UIManager:Open(UIMediatorNames.CityCollectV2UIMediator, param)
            self.city.petManager:BITraceBubbleClick(self.furnitureId, "need_pet_resource_produce")
            return true
        end
    end

    if self.furniture:IsBuildMaster() then
        local dataSrc = BuildMasterDeployUIDataSrc.new(tile)
        local param = CityFurnitureDeployUIParameter.new(tile, dataSrc)
        g_Game.UIManager:Open(UIMediatorNames.CityFurnitureDeployUIMediator, param)
        self.city.petManager:BITraceBubbleClick(self.furnitureId, "need_pet_build_master")
        return true
    elseif self.furniture:IsHotSpring() then
        local param = CityMobileUnitUIParameter.new(tile)
        g_Game.UIManager:Open(UIMediatorNames.CityMobileUnitUIMediator, param)
        self.city.petManager:BITraceBubbleClick(self.furnitureId, "need_pet_mobile_unit")
        return true
    elseif self.furniture:IsTemperatureBooster() then
        local dataSrc = HeaterPetDeployUIDataSrc.new(tile)
        local param = CityFurnitureDeployUIParameter.new(tile, dataSrc)
        g_Game.UIManager:Open(UIMediatorNames.CityFurnitureDeployUIMediator, param)
        self.city.petManager:BITraceBubbleClick(self.furnitureId, "need_pet_temperature_booster")
        return true
    end

    return false
end

return CityFurWorkBubbleStateNeedPet