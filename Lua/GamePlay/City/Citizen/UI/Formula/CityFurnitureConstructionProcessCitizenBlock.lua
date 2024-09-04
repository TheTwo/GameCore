local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local UIHelper = require("UIHelper")
local Utils = require("Utils")
local CityCitizenNewManageUIParameter = require("CityCitizenNewManageUIParameter")
local BaseUIComponent = require("BaseUIComponent")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CityFurnitureOverviewUIParameter = require("CityFurnitureOverviewUIParameter")
local HeroUIUtilities = require("HeroUIUtilities")

---@class CityFurnitureConstructionProcessCitizenBlockData
---@field citizenId number
---@field citizenMgr CityCitizenManager
---@field workCfgId number
---@field onSelectedChanged fun(citizenId:number):boolean
---@field hideDeleteBtn boolean|nil
---@field canAddOrChange fun():boolean

---@class CityFurnitureConstructionProcessCitizenBlock:BaseUIComponent
---@field new fun():CityFurnitureConstructionProcessCitizenBlock
---@field super BaseUIComponent
local CityFurnitureConstructionProcessCitizenBlock = class('CityFurnitureConstructionProcessCitizenBlock', BaseUIComponent)

function CityFurnitureConstructionProcessCitizenBlock:ctor()
    BaseUIComponent.ctor(self)
    self._currentOpenSelectedUi = nil
    self._waitUpdateData = false
end

function CityFurnitureConstructionProcessCitizenBlock:OnCreate(param)
    self._p_base_resident_0 = self:GameObject("p_base_resident_0")
    self._p_base_pet_0 = self:GameObject("p_base_pet_0")

    self._p_btn_resident_add = self:Button("p_btn_resident_add", Delegate.GetOrCreate(self, self.OnClickAddOrChangeCitizen))
    self._p_text_add = self:Text("p_text_add", "citizen_select")

    ---- 居民部分 ----
    self._p_resident = self:GameObject("p_resident")
    self._p_base_resident = self:Image("p_base_resident")
    ---@type CommonCitizenCellComponent
    self._p_item_resident = self:LuaObject("p_item_resident")

    ---- 居民连携宠物部分 ----
    self._p_pet = self:GameObject("p_pet")
    ---- 宠物品质色框 ----
    self._p_base_pet = self:Image("p_base_pet")
    ---@type CommonPetIconBase
    self._child_card_pet_s = self:LuaObject("child_card_pet_s")

    self._p_btn_delete = self:Button("p_btn_delete", Delegate.GetOrCreate(self, self.OnClickRemoveCitizen))
end

---@param data CityFurnitureConstructionProcessCitizenBlockData
function CityFurnitureConstructionProcessCitizenBlock:OnFeedData(data)
    if self._currentOpenSelectedUi then
        local runtimeId = self._currentOpenSelectedUi
        self._currentOpenSelectedUi = nil
        g_Game.UIManager:Close(runtimeId)
    end
    self._param = data
    self._p_btn_resident_add:SetVisible(data.citizenId == nil)
    self._p_resident:SetVisible(data.citizenId ~= nil)
    self._p_btn_delete:SetVisible(data.citizenId ~= nil and not self._param.hideDeleteBtn)

    local hasCitizen, hasPet = false, false
    if data.citizenId then
        hasCitizen = true
        ---@type CommonCitizenCellComponentParameter
        local citizenData = {}
        citizenData.citizenData = self._param.citizenMgr:GetCitizenDataById(data.citizenId)
        citizenData.citizenWork = nil
        citizenData.onClickSelf = Delegate.GetOrCreate(self, self.OnClickAddOrChangeCitizen)
        self._p_item_resident:FeedData(citizenData)

        local quality = citizenData.citizenData:GetCitizenQuality()
        local path = HeroUIUtilities.GetQualitySpriteID(quality)
        self:LoadSprite(path, self._p_base_resident)

        if citizenData.citizenData then
            local petUid = ModuleRefer.HeroModule:GetHeroLinkPet(citizenData.citizenData._config:HeroId())
            if petUid then
                hasPet = true
                local petInfo = ModuleRefer.PetModule:GetPetByID(petUid)
                if self._child_card_pet_s ~= nil then
                    ---@type UIPetIconData
                    local UIPetIconData = {
                        id = petUid, --- number @宠物ID
                        cfgId = petInfo.ConfigId, --- number @宠物配置ID
                        selected = false, --- boolean
                        level = petInfo.Level, --- number
                    }
                    self._child_card_pet_s:FeedData(UIPetIconData)
                end
                local petCfg = ConfigRefer.Pet:Find(petInfo.ConfigId)
                g_Game.SpriteManager:LoadSprite(("sp_hero_frame_circle_%d"):format(math.clamp(petCfg:Quality(), 1, 5)), self._p_base_pet)
            end
        end
    end

    if Utils.IsNotNull(self._p_base_resident_0) then
        self._p_base_resident_0:SetActive(hasCitizen and not hasPet)
    end
    if Utils.IsNotNull(self._p_base_pet_0) then
        self._p_base_pet_0:SetActive(hasCitizen and hasPet)
    end
    if Utils.IsNotNull(self._p_pet) then
        self._p_pet:SetActive(hasPet)
    end
    self:ClearMarkWaitUpdateData()
end

function CityFurnitureConstructionProcessCitizenBlock:MarkWaitUpdateData()
    if self._waitUpdateData then
        return
    end
    self._waitUpdateData = true
    if Utils.IsNotNull(self._p_btn_resident_add) then
        self._p_btn_resident_add.interactable = false
    end
end

function CityFurnitureConstructionProcessCitizenBlock:ClearMarkWaitUpdateData()
    if not self._waitUpdateData then
        return
    end
    self._waitUpdateData = false
    if Utils.IsNotNull(self._p_btn_resident_add) then
        self._p_btn_resident_add.interactable = true
    end
end

function CityFurnitureConstructionProcessCitizenBlock:OnClickAddOrChangeCitizen()
    if self._waitUpdateData then
        return
    end

    if self._param.canAddOrChange then
        if not self._param.canAddOrChange() then
            return
        end
    end
    
    local workId = nil
    if self._param.citizenId then
        local workData = self._param.citizenMgr:GetCitizenWorkDataByCitizenId(self._param.citizenId)
        if workData then
            workId = workData._id
        end
    end
    
    local pageParam = CityCitizenNewManageUIParameter.new(
        self._param.citizenMgr.city,
        self._param.workCfgId,
        workId,
        Delegate.GetOrCreate(self, self.OnSelectedAddOrChangeCitizen),
        false,
        true
    )
    local param = CityFurnitureOverviewUIParameter.new(
        self._param.citizenMgr.city,
        CityFurnitureOverviewUIParameter.PageStatus.CitizenManage,
        CityFurnitureOverviewUIParameter.ToggleStatus.CitizenManage,
        {[CityFurnitureOverviewUIParameter.PageStatus.CitizenManage] = pageParam}
    )
    
    self._currentOpenSelectedUi = g_Game.UIManager:Open(UIMediatorNames.CityFurnitureOverviewUIMediator, param)
end

function CityFurnitureConstructionProcessCitizenBlock:OnClickRemoveCitizen()
    if self._param.canAddOrChange then
        if not self._param.canAddOrChange() then
            return
        end
    end
    self._param.onSelectedChanged(nil)
end

function CityFurnitureConstructionProcessCitizenBlock:OnSelectedAddOrChangeCitizen(citizenId)
    if self._param.onSelectedChanged(citizenId) then
        self._currentOpenSelectedUi = nil
        g_Game.UIManager:CloseByName(UIMediatorNames.CityFurnitureOverviewUIMediator)
        return true
    end
    return false
end

return CityFurnitureConstructionProcessCitizenBlock