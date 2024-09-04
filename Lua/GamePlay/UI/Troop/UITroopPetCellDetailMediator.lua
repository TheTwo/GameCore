---scene: scene_common_tips_pet_power
local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local LuaReusedComponentPool = require('LuaReusedComponentPool')
local UIMediatorNames = require('UIMediatorNames')
local I18N = require('I18N')
local Utils = require('Utils')
local TipsRectTransformUtils = require('TipsRectTransformUtils')
local HeroUIUtilities = require('HeroUIUtilities')
---@class UITroopPetCellDetailMediator : BaseUIMediator
local UITroopPetCellDetailMediator = class('UITroopPetCellDetailMediator', BaseUIMediator)

---@class UITroopPetCellDetailParam
---@field petId number
---@field rectTransform CS.UnityEngine.RectTransform

function UITroopPetCellDetailMediator:ctor()
end

function UITroopPetCellDetailMediator:OnCreate()
    self.content = self:Transform('content')
    --- top
    ---@see CommonPetIconSmall
    self.luaPetHead = self:LuaObject('child_card_pet_circle')

    self.textName = self:Text('p_text_name')
    self.layoutType = self:Transform("p_layout_type")

    ---@see PetTagComponent
    self.luaPetTag = self:LuaObject('p_group_feature')

    self.goPower = self:GameObject('p_go_power')
    self.textPower = self:Text('p_text_power')
    ---@see PetGeneComp
    self.luaDNA = self:LuaObject('child_pet_dna')

    --- star
    ---@see PetStarLevelComponent
    self.luaStars = self:LuaObject('p_star')

    self.luaSkill1 = self:LuaObject('child_item_skill_1')
    self.luaSkill2 = self:LuaObject('child_item_skill_2')
    self.luaSkill3 = self:LuaObject('child_item_skill_3')

    --- status
    self.goWork = self:GameObject('p_status')
    self.textWork = self:Text('p_text_work')

    self.imgIconPosition = self:Image('p_icon_position')
    self.textPosition = self:Text('p_text_position')
end

---@param param UITroopPetCellDetailParam
function UITroopPetCellDetailMediator:OnOpened(param)
    self.rectTransform = param.rectTransform
    self.petId = param.petId
    self.petData = ModuleRefer.PetModule:GetPetByID(self.petId)
    local petCfgId = self.petData.ConfigId
    self.petCfg = ConfigRefer.Pet:Find(petCfgId)

    ---@type CommonPetIconBaseData
    local petIconData = {}
    petIconData.id = self.petId
    petIconData.showJobIcon = true
    petIconData.showLevelPrefix = true
    self.luaPetHead:FeedData(petIconData)

    self.textName.text = ModuleRefer.PetModule:GetPetName(self.petId)
    self.textPower.text = ModuleRefer.PetModule:GetPetPower(self.petId)

    ---@type PetGeneCompData
    local dnaData = {}
    dnaData.ConfigId = petCfgId
    dnaData.PetGeneInfo = ModuleRefer.PetModule:GetPetByID(self.petId).PetGeneInfo
    self.luaDNA:FeedData(dnaData)

    ---@type PetStarLevelComponentParam
    local starData = {}
    starData.petId = self.petId
    self.luaStars:FeedData(starData)

    local petTypeCfg = ModuleRefer.PetModule:GetTypeCfg(self.petData.Type)
    local petTagId = petTypeCfg:PetTagDisplay()
    if petTagId and petTagId > 0 then
        self.luaPetTag:SetVisible(true)
        self.luaPetTag:FeedData(petTagId)
    else
        self.luaPetTag:SetVisible(false)
    end

    local labelIcon = HeroUIUtilities.GetHeroBattleTypeTextureName(self.petCfg:BattleType())
    local labelName = HeroUIUtilities.GetBattleLabelStr(self.petCfg:BattleType())
    g_Game.SpriteManager:LoadSprite(labelIcon, self.imgIconPosition)
    self.textPosition.text = labelName


    ---从UIPetMediator抄的
    local skillId = self.petCfg:SLGSkillID(2)
    if (skillId and skillId > 0) then
        local slgSkillCell = ConfigRefer.SlgSkillInfo:Find(skillId)
        local data = {
            index = skillId,
            skillId = slgSkillCell:SkillId(),
            skillLevel = self.petData.SkillLevels[1],
            isPetFix = true,
            isLock = false,
            quality = self.petCfg:Quality(),
            clickCallBack = function()
                g_Game.UIManager:Open(UIMediatorNames.UICommonPopupCardDetailMediator,
                {
                    isPetFix = true,
                    type = 2,
                    cfgId = slgSkillCell:SkillId(),
                    level = self.petData.SkillLevels[1],
                    offset = CS.UnityEngine.Vector2(520, 40),
                })
            end,
        }
        self.luaSkill1:FeedData(data)
    end

    ---从UIPetMediator抄的
    local skills = self.petData.PetInfoWrapper.LearnedSkill
    for i = 1, 2 do
        local unlockLevel = ConfigRefer.PetConsts:PetExtraSkillUnlockLevel(i)
        local skillId = skills and skills[i] or nil
        local level = ModuleRefer.PetModule:GetSkillLevel(self.petId, false, skills[i])
        local cellIndex = i
        local isLock = self.petData.Level < unlockLevel
        local data = {
            petId = self.petId,
            index = skillId,
            skillId = skillId,
            unlockLevel = unlockLevel,
            cellIndex = cellIndex,
            skillLevel = level,
            isPet = true,
            isAdd = (skillId == nil or skillId == 0) and not isLock,
            isLock = isLock,
            quality = self.petCfg:Quality(),
            clickCallBack = Delegate.GetOrCreate(self, self.OnSkillClick),
        }
        if i == 1 then
            self.luaSkill2:FeedData(data)
        elseif i == 2 then
            self.luaSkill3:FeedData(data)
        end
    end

    local city = ModuleRefer.CityModule:GetMyCity()
    local isWorking = city.petManager:IsAssignedOnFurniture(self.petId)
    self.goWork:SetActive(isWorking)
    self.textWork.text = I18N.GetWithParams("troop_pet_status", city.petManager:GetWorkPosition(self.petId))

    -- if Utils.IsNotNull(self.rectTransform) then
    --     CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.content)
    --     self:OnLateTick(0)
    --     g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateTick))
    -- end
end

function UITroopPetCellDetailMediator:OnClose()
    -- g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateTick))
end

function UITroopPetCellDetailMediator:OnLateTick(dt)
    if Utils.IsNull(self.rectTransform) then return end
    self.lastEdge = TipsRectTransformUtils.TryAnchorTipsNearTargetRectTransform(self.rectTransform, self.content, self.lastEdge)
end

function UITroopPetCellDetailMediator:OnSkillClick(param)
    if param == nil then
        return
    end

    if param.isAdd then
        local pet = ModuleRefer.PetModule:GetPetByID(self.petId)
        local data = {}
        data.isEquip = true
        data.pet = pet
        data.cellIndex = param.cellIndex
        g_Game.UIManager:Open(UIMediatorNames.UIPetSkillMediator, data)
    elseif param.isLock then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("pet_skill_slot_unlock_tips", param.unlockLevel))
    else
        g_Game.UIManager:Open(UIMediatorNames.UICommonPopupCardDetailMediator, {petId = param.petId, type = 6, cfgId = param.skillId, skillLevel = param.skillLevel, cellIndex = param.cellIndex, offset = CS.UnityEngine.Vector2(520, 40)})
    end

    self:CloseSelf()
end

return UITroopPetCellDetailMediator