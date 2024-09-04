local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local TimerUtility = require('TimerUtility')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local PetSkillType = require("PetSkillType")
local CommonDropDown = require('CommonDropDown')
local NotificationType = require('NotificationType')

local PetSkillPopUpMediator = class('PetSkillPopUpMediator', BaseUIMediator)
function PetSkillPopUpMediator:ctor()
    self._rewardList = {}
end

function PetSkillPopUpMediator:OnCreate()
    self.skill1 = self:LuaObject('child_item_skill_1')
    self.skill2 = self:LuaObject('child_item_skill_2')
    self.skill3 = self:LuaObject('child_item_skill_3')
    self.p_text_name = self:Text('p_text_name')
    self.p_text_skill_detail = self:Text('p_text_skill_detail')
    self.p_text_unload = self:Text('p_text_unload', 'pet_skill_unload_name')
    self.p_text_hint = self:Text('p_text_hint', 'hero_level_full')
    self.p_text = self:Text('p_text', 'pet_rank_up_name')

    ---@type PetSkillTypeComp
    self.p_type_1 = self:LuaObject('p_type_1')
    self.p_btn_upgrade = self:Button('p_btn_upgrade', Delegate.GetOrCreate(self, self.OnClickUpgrade))
    self.p_btn_unload = self:Button('p_btn_unload', Delegate.GetOrCreate(self, self.OnClickUnload))
    self.child_btn_close = self:Button('child_btn_close', Delegate.GetOrCreate(self, self.OnClickClose))

    ---@type PetStarLevelComponent
    self.group_star = self:LuaObject('group_star')

    self.p_img_select_1 = self:GameObject('p_img_select_1')
    self.p_img_select_2 = self:GameObject('p_img_select_2')
    self.p_img_select_3 = self:GameObject('p_img_select_3')
    self.selectFrame = {self.p_img_select_1, self.p_img_select_2, self.p_img_select_3}

    -- self.child_reddot_default_1 = self:LuaObject("child_reddot_default_1")
    self.child_reddot_default_2 = self:LuaObject("child_reddot_default_2")
    self.child_reddot_default_3 = self:LuaObject("child_reddot_default_3")
    self.redDots = {self.child_reddot_default_2,self.child_reddot_default_3}

    self.child_reddot_default_upgrade = self:LuaObject("child_reddot_default_upgrade")
end

function PetSkillPopUpMediator:OnOpened(param)
    g_Game.EventManager:AddListener(EventConst.PET_EQUIP_SKILL, Delegate.GetOrCreate(self, self.OnEquipSkill))
    g_Game.EventManager:AddListener(EventConst.PET_UNEQUIP_SKILL, Delegate.GetOrCreate(self, self.OnUnEquipSkill))
    g_Game.EventManager:AddListener(EventConst.PET_UPGRADE_SKILL, Delegate.GetOrCreate(self, self.OnUpgradeSkill))
    g_Game.EventManager:AddListener(EventConst.PET_UPGRADE_SKILL_COMPLETE, Delegate.GetOrCreate(self, self.PlayUpgradeVfx))

    self.petId = param.petId
    self:RefreshPetSkill()
    self:RefreshLevels()
end
function PetSkillPopUpMediator:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.PET_EQUIP_SKILL, Delegate.GetOrCreate(self, self.OnEquipSkill))
    g_Game.EventManager:RemoveListener(EventConst.PET_UNEQUIP_SKILL, Delegate.GetOrCreate(self, self.OnUnEquipSkill))
    g_Game.EventManager:RemoveListener(EventConst.PET_UPGRADE_SKILL, Delegate.GetOrCreate(self, self.OnUpgradeSkill))
    g_Game.EventManager:RemoveListener(EventConst.PET_UPGRADE_SKILL_COMPLETE, Delegate.GetOrCreate(self, self.PlayUpgradeVfx))
    g_Game.EventManager:TriggerEvent(EventConst.PET_UI_MAIN_REFRESH)
end

function PetSkillPopUpMediator:OnShow(param)
end

function PetSkillPopUpMediator:OnHide(param)
end

function PetSkillPopUpMediator:PlayUpgradeVfx(param)
    self:RefreshPetSkill(self.curTab)
    self.group_star:FeedData({skillLevels = self.skillLevels})
    for k,v in pairs(self.skillLevels) do
        v.playEquipVfx = false
    end
end

function PetSkillPopUpMediator:OnUpgradeSkill(skillId)
    --技能升级后播星星升级特效
    local starLevel, skillLevels = ModuleRefer.PetModule:GetSkillLevelQuality(self.petId)
    self.skillLevels = skillLevels
    for k,v in pairs(self.skillLevels) do
        if skillId == v.skillId then
            v.playEquipVfx = true
            break
        end
    end

    -- self:RefreshPetSkill()
    -- self:RefreshLevels()
end

function PetSkillPopUpMediator:OnUnEquipSkill(param)
    self:RefreshPetSkill()
    self:RefreshLevels()
end

function PetSkillPopUpMediator:RefreshLevels()
    local starLevel, skillLevels = ModuleRefer.PetModule:GetSkillLevelQuality(self.petId)
    self.skillLevels = skillLevels
    self.group_star:FeedData({skillLevels = self.skillLevels})
end

function PetSkillPopUpMediator:OnEquipSkill(param)
    local skillId = param.skillId
    local cellIndex = param.cellIndex
    local level = ModuleRefer.PetModule:GetSkillLevel(self.petId,false,skillId)
    local quality = ConfigRefer.PetLearnableSkill:Find(skillId):Quality()
    table.insert(self.skillLevels,{quality = quality, level = level, playEquipVfx = true})
    table.sort(self.skillLevels,function(a,b)
        return a.quality > b.quality
    end)
    self.group_star:FeedData({skillLevels = self.skillLevels})
    self:RefreshPetSkill(cellIndex)
end

function PetSkillPopUpMediator:RefreshPetSkill(equipCellIndex)
    local pet = ModuleRefer.PetModule:GetPetByID(self.petId)
    local petCfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
    self.skills = {}
    -- 第一固有技能 读SLGSkillID(2)
    local skillId = petCfg:SLGSkillID(2)
    if (skillId and skillId > 0) then
        local slgSkillCell = ConfigRefer.SlgSkillInfo:Find(skillId)
        local data = self:AddSkill(slgSkillCell:SkillId(), pet.SkillLevels[1], true, nil, true)
        data.isPetFix = true
        data.isPet = false
        data.quality = petCfg:Quality()
        self.skill1:FeedData(data)
        table.insert(self.skills, skillId)
    end

    -- 第二三技能找数据
    local skills = pet.PetInfoWrapper.LearnedSkill
    for i = 1, 2 do
        local unlockLevel = ConfigRefer.PetConsts:PetExtraSkillUnlockLevel(i)
        local skillId = skills and skills[i] or nil
        local level = ModuleRefer.PetModule:GetSkillLevel(self.petId, false, skills[i])
        local cellIndex = i
        local data = self:AddSkill(skillId, level, pet.Level >= unlockLevel, unlockLevel, nil, cellIndex)
        if i == 1 then
            self.skill2:FeedData(data)
        elseif i == 2 then
            self.skill3:FeedData(data)
        end
        table.insert(self.skills, skillId)

        local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PetSkillEquip_"..self.petId.."_"..i, NotificationType.PET_SKILL_EQUIP)
        ModuleRefer.NotificationModule:AttachToGameObject(node, self.redDots[i].go, self.redDots[i].redDot)
    end

    -- 装备后回到此cell
    if equipCellIndex then
        self:SelectSkill(equipCellIndex + 1)
    else
        self:SelectSkill(1)
    end
end

function PetSkillPopUpMediator:AddSkill(skillId, skillLevel, isUnlock, unlockLevel, isFixed, cellIndex)
    local isAdd = (skillId == nil or skillId == 0) and isUnlock
    local data = {
        unlockLevel = unlockLevel,
        isAdd = isAdd,
        index = skillId,
        skillId = skillId,
        skillLevel = skillLevel,
        isPet = true,
        isLock = not isUnlock,
        cellIndex = cellIndex,
        clickCallBack = isFixed and Delegate.GetOrCreate(self, self.OnFixedSkillClick) or Delegate.GetOrCreate(self, self.OnSkillClick),
    }
    return data
end

function PetSkillPopUpMediator:SelectSkill(index)
    self.skillId = self.skills[index]
    if self.skillId == 0 then
        self:SelectSkill(index - 1)
        return
    end
    if self.curSelect == index then
        return
    end

    if self.curSelect then
        self.selectFrame[self.curSelect]:SetVisible(false)
    end
    self.selectFrame[index]:SetVisible(true)
    self.curSelect = index
    self.skillId = self.skills[index]
    self.p_btn_upgrade:SetVisible(index ~= 1 and self.skillId > 0)
    self.p_btn_unload:SetVisible(index ~= 1 and self.skillId > 0)

    local cfg = ConfigRefer.PetLearnableSkill:Find(self.skillId)

    if index == 1 then
        local pet = ModuleRefer.PetModule:GetPetByID(self.petId)
        local desc, name = ModuleRefer.PetModule:GetPetFixedSkillDesc(self.petId, pet.ConfigId)
        self.p_text_name.text = name
        self.p_text_skill_detail.text = desc
        local text = ModuleRefer.PetModule:GetSkillTypePetCfgId(pet.ConfigId)
        self.p_type_1:FeedData({text = text, icon = ''})
        self.p_text_hint:SetVisible(true)
        self.p_text_hint.text =I18N.Get('pet_bound_skill_upgrade_tips')
    else
        self.p_text_name.text = I18N.Get(cfg:Name())
        self.p_text_skill_detail.text = ModuleRefer.PetModule:GetPetSkillDesc(self.petId, self.skillId)
        local skillType = cfg:SkillType()
        local text = ModuleRefer.PetModule:GetSkillTypeStr(skillType)
        self.p_type_1:FeedData({text = text, icon = ''})
        local cur, max, level = ModuleRefer.PetModule:GetPetSkillExpAndLevel(self.skillId)
        self.p_btn_upgrade:SetVisible(level ~= 10)
        self.p_text_hint:SetVisible(level == 10)
        self.p_text_hint.text =I18N.Get('hero_level_full')

        local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PetSkillUpgrade_"..self.petId.."_"..(index-1), NotificationType.PET_SKILL_UPGRADE)
        ModuleRefer.NotificationModule:AttachToGameObject(node, self.child_reddot_default_upgrade.go, self.child_reddot_default_upgrade.redDot)
    end
end

function PetSkillPopUpMediator:OnSkillClick(param)
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
        self:SelectSkill(param.cellIndex + 1)
        -- local cfg = ConfigRefer.PetLearnableSkill:Find(param.skillId)
        -- local slgSkillId = cfg:SlgSkill()
        -- local cardId = cfg:PetCard()
        -- local slgSkillCell = ConfigRefer.SlgSkillInfo:Find(slgSkillId)
        -- local data = {}
        -- data.type = 5
        -- data.slgSkillId = slgSkillCell:SkillId()
        -- data.cardId = cardId
        -- data.isLock = false
        -- data.skillLevel = param.skillLevel
        -- data.slgSkillCell = slgSkillCell
        -- data.unloadFunc = function()
        --     ModuleRefer.PetModule:UnEquipSkill(self._selectedId, param.cellIndex)
        --     g_Game.UIManager:CloseByName(UIMediatorNames.UICommonPopupCardDetailMediator)
        -- end
        -- g_Game.UIManager:Open(UIMediatorNames.UICommonPopupCardDetailMediator, data)
    end
end

function PetSkillPopUpMediator:OnFixedSkillClick()
    self:SelectSkill(1)
    -- local pet = ModuleRefer.PetModule:GetPetByID(self.petId)
    -- local petCfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
    -- local cardId = petCfg:SESkillID(1)
    -- local slgSkillId = petCfg:SLGSkillID(1)
    -- local slgSkillCell = ConfigRefer.SlgSkillInfo:Find(slgSkillId)
    -- local param = {}
    -- param.type = 4
    -- param.slgSkillId = slgSkillCell:SkillId()
    -- param.cardId = cardId
    -- param.isLock = false
    -- param.skillLevel = 1
    -- param.slgSkillCell = slgSkillCell
    -- g_Game.UIManager:Open(UIMediatorNames.UICommonPopupCardDetailMediator, param)
end

function PetSkillPopUpMediator:OnClickUpgrade(param)
    if self.curSelect == 1 then
        return
    end

    g_Game.UIManager:Open(UIMediatorNames.UIPetSkillLearnMediator, {skillId = self.skillId, cellIndex = self.curSelect})
end

function PetSkillPopUpMediator:OnClickUnload(param)
    ModuleRefer.PetModule:UnEquipSkill(self.petId, self.curSelect - 1)
end

function PetSkillPopUpMediator:OnClickClose(param)
    self:CloseSelf()
end

return PetSkillPopUpMediator
