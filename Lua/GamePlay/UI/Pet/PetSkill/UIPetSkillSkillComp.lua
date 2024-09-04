local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require('UIMediatorNames')
local I18N = require('I18N')
local PetSkillDefine = require('PetSkillDefine')
local ManualUIConst = require('ManualUIConst')
local EventConst = require('EventConst')
local NotificationType = require('NotificationType')

---@class UIPetSkillSkillComp : BaseTableViewProCell
---@field data HeroConfigCache
local UIPetSkillSkillComp = class('UIPetSkillSkillComp', BaseTableViewProCell)

function UIPetSkillSkillComp:ctor()

end

function UIPetSkillSkillComp:OnCreate()
    ---@type BaseSkillIcon
    self.child_item_skill = self:LuaObject('child_item_skill')
    self.p_text_skill_name = self:Text('p_text_skill_name')
    self.p_text_league = self:Text('p_text_league')
    self.p_text_equip = self:Text('p_text_equip', 'pet_skill_load_name')
    self.p_text_full = self:Text('p_text_full', 'pet_skill_load_name')
    self.p_text_study = self:Text('p_text_study', "pet_skill_practice_name")
    self.p_text_finish = self:Text('p_text_finish', "hero_level_full")
    self.p_text_study_num = self:Text('p_text_study_num')

    self.p_icon_recomment = self:Image('p_icon_recomment')
    self.p_btn_equip = self:Button('p_btn_equip', Delegate.GetOrCreate(self, self.OnEquipClick))
    self.p_btn_study = self:Button('p_btn_study', Delegate.GetOrCreate(self, self.OnLearnClick))
    self.p_btn_full = self:Button('p_btn_full', Delegate.GetOrCreate(self, self.OnEquipFullClick))
    -- 装配格
    self.p_pet = self:GameObject('p_pet')
    self.p_empty = self:GameObject('p_empty')
    self.p_progress = self:Image('p_progress')
    self.p_finish = self:GameObject('p_finish')

    ---@type CommonPetIconBase
    self.p_pet_1 = self:LuaObject('p_pet_1')
    ---@type CommonPetIconBase
    self.p_pet_2 = self:LuaObject('p_pet_2')
    self.petEquipped = {self.p_pet_1, self.p_pet_2}

    self.base_1 = self:GameObject('base_1')
    self.base_2 = self:GameObject('base_2')

    ---@type PetSkillTypeComp
    self.p_type_1 = self:LuaObject('p_type_1')
    -- self.p_type_2 = self:LuaObject('p_type_2')
    -- self.p_type_2:SetVisible(false)
    self.p_finish:SetVisible(false)

    self.child_reddot_default = self:LuaObject('child_reddot_default')
end

function UIPetSkillSkillComp:OnFeedData(param)
    self.param = param
    self:InitContent(param)
    self:RefreshContent(param)


    local receiveNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PetSkillReceive_"..param.cfg:Id(), NotificationType.PET_SKILL_RECEIVE)
    ModuleRefer.NotificationModule:AttachToGameObject(receiveNode, self.child_reddot_default.go, self.child_reddot_default.redNew)
    self.child_reddot_default:SetVisible(true)
end

function UIPetSkillSkillComp:OnHide(param)
    self:ClearRedDot()
end

function UIPetSkillSkillComp:ClearRedDot()
    local receiveNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PetSkillReceive_"..self.param.cfg:Id(), NotificationType.PET_SKILL_RECEIVE)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(receiveNode, 0)
end

function UIPetSkillSkillComp:InitContent(param)
    self.curPet = param.curPet
    self.equippedNum = param.equippedNum
    self.skillId = param.cfg:Id()
    self.skillType = param.cfg:SkillType()
    self.cellIndex = param.cellIndex
    self.canEquipNum = param.cfg:CanLearnNum()
    self.p_text_skill_name.text = I18N.Get(param.cfg:Name())
    self.p_text_league.text = ModuleRefer.PetModule:GetPetSkillDesc(self.curPet, self.skillId)

    if self.param.isLearnPanel then
        self.base_1:SetVisible(false)
        self.base_2:SetVisible(false)
    else
        self.base_1:SetVisible(self.canEquipNum >= 1)
        self.base_2:SetVisible(self.canEquipNum >= 2)
    end

    g_Game.SpriteManager:LoadSprite(ManualUIConst.sp_mission_icon_recomment, self.p_icon_recomment)
    self.child_item_skill:FeedData({
        isPet = true,
        skillId = self.skillId,
        index = self.skillId,
        skillLevel = ModuleRefer.PetModule:GetSkillLevel(self.curPet, false, self.skillId),
        clickCallBack = Delegate.GetOrCreate(self, self.OnSkillClick),
    })
    self.p_icon_recomment:SetVisible(param.isRecommend)
    local name = ModuleRefer.PetModule:GetSkillTypeStr(self.skillType)
    self.p_type_1:FeedData({text = name, icon = ''})
end

function UIPetSkillSkillComp:RefreshContent(param)
    self.isLearned = ModuleRefer.PetModule:IsSkillLearned(self.skillId)
    local cur, max, level = ModuleRefer.PetModule:GetPetSkillExpAndLevel(self.skillId)
    if level == 10 then
        self.isMax = true
    end
    self.p_progress.fillAmount = cur / max
    self.p_text_study_num.text = cur .. "/" .. max
    self:RefreshEquippment()
    self:RefreshButton()
end

-- 当前装备此技能的宠物
function UIPetSkillSkillComp:RefreshEquippment()
    self.isEquip = false
    local pets = ModuleRefer.PetModule:GetPetsByEquippedSkill(self.skillId)
    self.petEquipped[1]:SetVisible(#pets >= 1)
    self.petEquipped[2]:SetVisible(#pets >= 2)

    self.petCount = 0
    for i = 1, #pets do
        local skills = pets[i].PetInfoWrapper.LearnedSkill
        local cellIndex = 1
        for k, v in pairs(skills) do
            if self.skillId == v then
                cellIndex = k
            end
        end
        ---@type UIPetIconData
        local UIPetIconData = {
            id = pets[i].ID,
            cfgId = pets[i].ConfigId,
            selected = false,
            level = pets[i].Level,
            removeFunc = function()
                ModuleRefer.PetModule:UnEquipSkill(pets[i].ID, cellIndex, function()
                    g_Game.UIManager:CloseByName(UIMediatorNames.CityPetDetailsTipUIMediator)
                end)

            end,
        }
        UIPetIconData.onClick = function()
            g_Game.UIManager:Open(UIMediatorNames.CityPetDetailsTipUIMediator, UIPetIconData)
        end
        if self.curPet == pets[i].ID then
            self.isEquip = true
        end
        self.petEquipped[i]:FeedData(UIPetIconData)
        self.petCount = self.petCount + 1
    end
end

function UIPetSkillSkillComp:RefreshButton()
    --学习或者研究
    if self.isLearned then
        self.p_text_study.text = I18N.Get("pet_rank_up_name")
    else
        self.p_text_study.text = I18N.Get("pet_skill_practice_name")
    end
    self.p_progress:SetVisible(self.isLearned)
    self.p_text_study_num:SetVisible(self.isLearned)

    if self.param.isLearnPanel and self.isLearned then
        self.p_pet:SetVisible(self.isLearned)
        self.p_btn_equip:SetVisible(false)
        self.p_btn_full:SetVisible(false)

        if self.isMax then
            self.p_btn_study:SetVisible(false)
            self.p_finish:SetVisible(true)
        else
            self.p_finish:SetVisible(false)
            self.p_btn_study:SetVisible(true)
        end

        -- self.param.isLearnPanel = false
        return
    end

    self.p_pet:SetVisible(self.isLearned)
    self.p_empty:SetVisible(not self.isLearned)
    self.p_btn_study:SetVisible(not self.isLearned)
    -- 配置格装满
    if self.petCount == self.canEquipNum then
        self.p_btn_equip:SetVisible(false)
        self.p_btn_full:SetVisible(true)
    elseif self.isEquip then
        self.p_btn_full:SetVisible(true)
        self.p_btn_equip:SetVisible(false)
    else
        self.p_btn_equip:SetVisible(self.isLearned)
        self.p_btn_full:SetVisible(false)
    end

end

function UIPetSkillSkillComp:OnEquipClick(param)
    if self.isEquip then
        return
    end

    local isEquipped = ModuleRefer.PetModule:IsPetEquipSkillAtSlot(self.curPet, self.cellIndex)
    -- 已装备时，先脱再装
    if isEquipped then
        ModuleRefer.PetModule:UnEquipSkill(self.curPet, self.cellIndex, function()
            ModuleRefer.PetModule:EquipSkill(self.curPet, self.skillId, self.cellIndex)
        end)
        return
    end

    ModuleRefer.PetModule:EquipSkill(self.curPet, self.skillId, self.cellIndex)
end

function UIPetSkillSkillComp:OnLearnClick(param)
    if self.skillId then
        g_Game.UIManager:Open(UIMediatorNames.UIPetSkillLearnMediator, {skillId = self.skillId})
    end
end

function UIPetSkillSkillComp:OnEquipFullClick()
    -- ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("# Skill Grid Full"))
end

return UIPetSkillSkillComp
