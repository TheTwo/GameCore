local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local CityUtils = require("CityUtils")
local CityWorkType = require("CityWorkType")
local CityPetUtils = require("CityPetUtils")
local BuildMasterDeployUIDataSrc = require("BuildMasterDeployUIDataSrc")
local CityFurnitureDeployUIParameter = require("CityFurnitureDeployUIParameter")
local CityCollectV2UIParameter = require("CityCollectV2UIParameter")
local UIMediatorNames = require("UIMediatorNames")
local QueuedTask = require("QueuedTask")

local CityMobileUnitUIParameter = require("CityMobileUnitUIParameter")
local I18N = require("I18N")
local CityManageCenterI18N = require("CityManageCenterI18N")
local EventConst = require("EventConst")

---@class CityManageCannotWorkWithoutPetFurniture:BaseUIComponent
local CityManageCannotWorkWithoutPetFurniture = class('CityManageCannotWorkWithoutPetFurniture', BaseUIComponent)

function CityManageCannotWorkWithoutPetFurniture:OnCreate()
    self._p_icon_furniture = self:Image("p_icon_furniture")
    self._p_text_furniture_name = self:Text("p_text_furniture_name")
    self._p_btn_goto_furniture = self:Button("p_btn_goto_furniture", Delegate.GetOrCreate(self, self.OnClickGoto))
    self._p_type_pet = self:Transform("p_type_pet")
    self._p_text_type_pet = self:Text("p_text_type_pet", CityManageCenterI18N.UIHint_Need)
    self._p_icon_type_pet = self:Image("p_icon_type_pet")
    self._pool_feature = LuaReusedComponentPool.new(self._p_icon_type_pet, self._p_type_pet)
end

---@param data CityFurniture
function CityManageCannotWorkWithoutPetFurniture:OnFeedData(data)
    self.furniture = data
    self.city = self.furniture.manager.city
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(self.furniture.furType)
    g_Game.SpriteManager:LoadSprite(typCfg:Image(), self._p_icon_furniture)
    self._p_text_furniture_name.text = self.furniture:GetName()
    self._pool_feature:HideAll()
    if self.furniture:IsBuildMaster() then
        for i = 1, typCfg:PetWorkTypeLimitLength() do
            local feature = typCfg:PetWorkTypeLimit(i)
            if feature > 0 then
                local image = self._pool_feature:GetItem()
                g_Game.SpriteManager:LoadSprite(CityPetUtils.GetFeatureIcon(feature), image)
            end
        end
    elseif self.furniture:IsHotSpring() then
        local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.furniture.singleId) or {}
        local petWorkMap = {}
        for petId, _ in pairs(petIdMap) do
            local petData = self.city.petManager.cityPetData[petId]
            for feature, _ in pairs(petData.workAbility) do
                petWorkMap[feature] = true
            end
        end

        local detailCfg = ConfigRefer.HotSpringDetail:Find(self.furniture.furnitureCell:HotSpringDetailInfo())
        for i = 1, detailCfg:AdditionProductsLength() do
            local addition = detailCfg:AdditionProducts(i)
            if not petWorkMap[addition:PetWorkType()] then
                local image = self._pool_feature:GetItem()
                g_Game.SpriteManager:LoadSprite(CityPetUtils.GetFeatureIcon(addition:PetWorkType()), image)
            end
        end
    elseif self.furniture:CanDoCityWork(CityWorkType.ResourceProduce) then
        local workCfgId = self.furniture:GetWorkCfgId(CityWorkType.ResourceProduce)
        local workCfg = ConfigRefer.CityWork:Find(workCfgId)
        local image = self._pool_feature:GetItem()
        g_Game.SpriteManager:LoadSprite(CityPetUtils.GetFeatureIcon(workCfg:RequireWorkerType()), image)
    end
end

function CityManageCannotWorkWithoutPetFurniture:OnClickGoto()
    local furniture = self.furniture
    local city = self.city
    self:OnClickGotoImp(city, furniture)

    
end

---@param furniture CityFurniture
function CityManageCannotWorkWithoutPetFurniture:OnClickGotoImp(city, furniture)
    local tile = city.gridView:GetFurnitureTile(furniture.x, furniture.y)
    if not tile then return end

    if city.showed then
        if furniture:IsBuildMaster() then
            local dataSrc = BuildMasterDeployUIDataSrc.new(tile)
            local param = CityFurnitureDeployUIParameter.new(tile, dataSrc)
            g_Game.UIManager:CloseByName(UIMediatorNames.CityManageCenterUIMediator)
            city.camera:LookAt(tile:GetWorldCenter(), 0.5, function()
                g_Game.UIManager:Open(UIMediatorNames.CityFurnitureDeployUIMediator, param)
            end)
        elseif furniture:IsHotSpring() then
            local param = CityMobileUnitUIParameter.new(tile)
            g_Game.UIManager:CloseByName(UIMediatorNames.CityManageCenterUIMediator)
            city.camera:LookAt(tile:GetWorldCenter(), 0.5, function()
                g_Game.UIManager:Open(UIMediatorNames.CityMobileUnitUIMediator, param)
            end)
        elseif furniture:CanDoCityWork(CityWorkType.ResourceProduce) then
            local param = CityCollectV2UIParameter.new(tile)
            g_Game.UIManager:CloseByName(UIMediatorNames.CityManageCenterUIMediator)
            city.camera:LookAt(tile:GetWorldCenter(), 0.5, function()
                g_Game.UIManager:Open(UIMediatorNames.CityCollectV2UIMediator, param)
            end)
        end
    else
        if self:GetParentBaseUIMediator() then
            self:GetParentBaseUIMediator():CloseSelf()
        end
        g_Game.EventManager:TriggerEvent(EventConst.HUD_RETURN_TO_MY_CITY, function()
            local queueTask = QueuedTask.new()
            queueTask:WaitTrue(function()
                return city ~= nil and city.showed
            end):DoAction(function()
                self:OnClickGotoImp(city, furniture)
            end):Start()
        end)
    end
end

return CityManageCannotWorkWithoutPetFurniture