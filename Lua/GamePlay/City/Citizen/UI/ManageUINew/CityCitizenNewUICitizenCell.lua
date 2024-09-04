local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local HeroQuality = require("HeroQuality")
local CityWorkTargetType = require("CityWorkTargetType")

local I18N = require("I18N")
local TimeFormatter = require("TimeFormatter")
local CityWorkFormula = require("CityWorkFormula")
local NumberFormatter = require("NumberFormatter")

---@class CityCitizenNewUICitizenCell:BaseUIComponent
local CityCitizenNewUICitizenCell = class('CityCitizenNewUICitizenCell', BaseUIComponent)

---@class CityCitizenNewManageUICitizenCellData
---@field city MyCity
---@field citizenData CityCitizenData
---@field citizenWorkData CityCitizenWorkData
---@field showPower boolean 是否需要显示属性
---@field showWorkProperty boolean 是否需要显示额外属性
---@field workCfg number|nil 显示属性所用的工作配置
---@field isRecommand boolean 是否是属性最高的Free Citizen
---@field onClick fun(data:CityCitizenNewManageUICitizenCellData, lockable:CS.UnityEngine.RectTransform)
---@field onCanCelWork fun(data:CityCitizenNewManageUICitizenCellData, lockable:CS.UnityEngine.RectTransform)
---@field onTimeUp fun(data:CityCitizenNewManageUICitizenCellData)

function CityCitizenNewUICitizenCell:OnCreate()
    --- 居民头像
    self._p_base_citizen = self:Image("p_base_citizen")
    self._group_resident = self:GameObject("group_resident")
    self._p_img_resident_a = self:Image("p_img_resident_a")

    --- 居民工作家具
    self._p_group_furniture = self:GameObject("p_group_furniture")
    self._p_img_furniture = self:Image("p_img_furniture")

    --- 内政官技能
    self._p_group_skill = self:GameObject("p_group_skill")
    self._p_text_skill_1 = self:Text("p_text_skill_1")
    self._p_text_skill_2 = self:Text("p_text_skill_2")
    self._p_text_skill_num_1 = self:Text("p_text_skill_num_1")
    self._p_text_skill_num_2 = self:Text("p_text_skill_num_2")

    --- 挂的宠
    self._p_pet = self:GameObject("p_pet")
    self._p_base_frame = self:Image("p_base_frame")
    self._p_img_pet = self:Image("p_img_pet")

    self._p_icon_recommened = self:GameObject("p_icon_recommened")

    self._p_btn = self:Button("p_btn", Delegate.GetOrCreate(self, self.OnClick))
    self._p_btn_delete = self:Button("p_btn_delete", Delegate.GetOrCreate(self, self.OnClickCancelWork))
end

---@param data CityCitizenNewManageUICitizenCellData
function CityCitizenNewUICitizenCell:OnFeedData(data)
    self._data = data
    g_Game.SpriteManager:LoadSprite(self._data.citizenData:GetCitizenIcon(), self._p_img_resident_a)

    local quality = self._data.citizenData:GetCitizenQuality()
    if quality == HeroQuality.Green then
        g_Game.SpriteManager:LoadSprite("sp_city_citizen_base_green", self._p_base_citizen)
    elseif quality == HeroQuality.Blue then
        g_Game.SpriteManager:LoadSprite("sp_city_citizen_base_blue", self._p_base_citizen)
    elseif quality == HeroQuality.Purple then
        g_Game.SpriteManager:LoadSprite("sp_city_citizen_base_purple", self._p_base_citizen)
    elseif quality == HeroQuality.Golden then
        g_Game.SpriteManager:LoadSprite("sp_city_citizen_base_orange", self._p_base_citizen)
    else
        g_Game.SpriteManager:LoadSprite("sp_city_citizen_base_grey", self._p_base_citizen)
    end

    self:UpdatePet()
    self:UpdateFurniture()
    self:UpdateCitizenSkill()

    self._p_icon_recommened:SetActive(self._data.isRecommand)
    self._p_btn_delete:SetVisible(self._data.onCanCelWork ~= nil)
end

function CityCitizenNewUICitizenCell:UpdatePet()
    local petUid = ModuleRefer.HeroModule:GetHeroLinkPet(self._data.citizenData._config:HeroId())
    self._p_pet:SetActive(petUid ~= nil)
    if petUid then
        local petInfo = ModuleRefer.PetModule:GetPetByID(petUid)
        local petCfg = ConfigRefer.Pet:Find(petInfo.ConfigId)
        self:LoadSprite(petCfg:Icon(), self._p_img_pet)
        local quality = petCfg:Quality()
		g_Game.SpriteManager:LoadSprite(("sp_hero_frame_circle_%d"):format(quality), self._p_base_frame)
    end
end

function CityCitizenNewUICitizenCell:UpdateFurniture()
    local citizenWorkData = self._data.city.cityWorkManager:GetCitizenWorkDataByCitizenId(self._data.citizenData._id)
    if citizenWorkData ~= nil and citizenWorkData._targetType == CityWorkTargetType.Furniture then
        local furnitureId = citizenWorkData._target
        local furniture = self._data.city.furnitureManager:GetFurnitureById(furnitureId)
        if furniture then
            self._p_group_furniture:SetActive(true)
            local typCfg = ConfigRefer.CityFurnitureTypes:Find(furniture.furType)
            g_Game.SpriteManager:LoadSprite(typCfg:Image(), self._p_img_furniture)
            return
        end
    end
    self._p_group_furniture:SetActive(false)
end

function CityCitizenNewUICitizenCell:UpdateCitizenSkill()
    local heroCfg = self._data.citizenData:GetHeroCfg()
    local length = heroCfg:CitizenSkillCfgLength()
    if length == 0 then
        self._p_group_skill:SetActive(false)
        return
    end

    self._p_group_skill:SetActive(true)
    
    self._p_text_skill_1:SetVisible(length >= 1)
    self._p_text_skill_2:SetVisible(length >= 2)
    self._p_text_skill_num_1:SetVisible(length >= 1)
    self._p_text_skill_num_2:SetVisible(length >= 2)

    local index = 0
    for i = 1, math.min(length, 2) do
        local skillCfgId = heroCfg:CitizenSkillCfg(i)
        local skillCfg = ConfigRefer.CitizenSkillInfo:Find(skillCfgId)
        if skillCfg:CitizenAttrDisplayLength() > 0 then
            -- local attrList = ModuleRefer.AttrModule:CalcAttrGroupByTemplateId(skillCfg:AttrTemplateCfg(), 1)
            -- local dispConf = ConfigRefer.AttrDisplay:Find(skillCfg:CitizenAttrDisplay(1))
            -- local value, desc, formattedValue = ModuleRefer.AttrModule:GetDisplayValueWithData(dispConf, attrList)
            local value, desc, formattedValue = ModuleRefer.SkillModule:GetFirstShowCitizenSkillAttr(skillCfgId, 1)

			-- if (ModuleRefer.AttrModule:IsAttrValueShow(dispConf, value)) then
                index = index + 1
                local textComp = index == 1 and self._p_text_skill_1 or self._p_text_skill_2
				textComp.text = I18N.Get(desc)
                local valueComp = index == 1 and self._p_text_skill_num_1 or self._p_text_skill_num_2
                valueComp.text = formattedValue
			-- end
        end
    end 
end

function CityCitizenNewUICitizenCell:OnClick()
    if self._data.onClick then
        self._data.onClick(self._data)
    end
end

function CityCitizenNewUICitizenCell:OnClickCancelWork()
    if self._data.onCanCelWork then
        self._data.onCanCelWork(self._data)
    end
end

return CityCitizenNewUICitizenCell