local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local TimerUtility = require('TimerUtility')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local PetSkillType = require("PetSkillType")

---@class UIPetSkillMediator : BaseUIMediator
local UIPetSkillMediator = class('UIPetSkillMediator', BaseUIMediator)

---@class UIPetSkillMediatorParam
---@field isLearnPanel boolean
---@field cellIndex number
---@field pet wds.PetInfo
---@field isEquip boolean 有几个地方传了 但是这里似乎没用到

function UIPetSkillMediator:ctor()
    self._rewardList = {}
end

function UIPetSkillMediator:OnCreate()
    self.p_table_tab = self:TableViewPro('p_table_tab')
    self.p_table_ranking = self:TableViewPro('p_table_ranking')

    self.p_txt_free_2 = self:Text('p_txt_free_2')

    self.p_text_title_skill = self:Text('p_text_title_skill', "hero_card")
    self.p_text_title_type = self:Text('p_text_title_type', "gacha_info_cate_history_type")
    self.p_text_title_info = self:Text('p_text_title_info', "pet_skill_info_name")
    self.p_text_title_pet = self:Text('p_text_title_pet', "pet_skill_loaded_name")

    self.child_common_btn_back = self:LuaObject('child_common_btn_back')
    self.child_empty = self:GameObject("child_empty")
    self.p_text_empty = self:Text("p_text_empty", "tip_petskill_empty_desc")
end

---@param param UIPetSkillMediatorParam
function UIPetSkillMediator:OnShow(param)
    self.isLearnPanel = param.isLearnPanel
    if not self.isLearnPanel then
        self.cellIndex = param.cellIndex
    end
    self.curTab = 0
    self.curPet = (param.pet or {}).ID or ModuleRefer.PetModule:GetCurSelectedPet()

    g_Game.EventManager:AddListener(EventConst.PET_LEARN_SKILL, Delegate.GetOrCreate(self, self.RefreshSkills))
    g_Game.EventManager:AddListener(EventConst.PET_UPGRADE_SKILL, Delegate.GetOrCreate(self, self.RefreshSkills))
    g_Game.EventManager:AddListener(EventConst.PET_EQUIP_SKILL, Delegate.GetOrCreate(self, self.OnEquippedSkill))
    g_Game.EventManager:AddListener(EventConst.PET_UNEQUIP_SKILL, Delegate.GetOrCreate(self, self.OnEquipmentChanged))
    self:RefreshTabs()
end

function UIPetSkillMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.PET_LEARN_SKILL, Delegate.GetOrCreate(self, self.RefreshSkills))
    g_Game.EventManager:RemoveListener(EventConst.PET_UPGRADE_SKILL, Delegate.GetOrCreate(self, self.RefreshSkills))
    g_Game.EventManager:RemoveListener(EventConst.PET_EQUIP_SKILL, Delegate.GetOrCreate(self, self.OnEquippedSkill))
    g_Game.EventManager:RemoveListener(EventConst.PET_UNEQUIP_SKILL, Delegate.GetOrCreate(self, self.OnEquipmentChanged))
    g_Game.EventManager:TriggerEvent(EventConst.PET_UI_MAIN_REFRESH)
end

function UIPetSkillMediator:RefreshTabs()
    self.tabs = {}
    self.p_table_tab:Clear()
    for i = 1, PetSkillType.Passive do
        local data = {index = i, type = i - 1, onClick = Delegate.GetOrCreate(self, self.OnTabClick)}
        self.tabs[i] = data
        self.p_table_tab:AppendData(data)
    end
    self:OnTabClick(1)
end

function UIPetSkillMediator:RefreshSkills()
    self.allSkills = ModuleRefer.PetModule:GetPetLearnedSkills()
    self.sortSkills = {}
    local cur = 0
    for k, v in pairs(self.allSkills) do
        -- 取消宠物技能研究
        if v.Active then
            -- 是否推荐
            local isRecommend = false
            local skillCfg = ConfigRefer.PetLearnableSkill:Find(k)

            if not self.isLearnPanel then
                local pet = ModuleRefer.PetModule:GetPetByID(self.curPet)
                local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
                local petSkillBaseCfg = ConfigRefer.PetSkillBase:Find(petCfg:RefSkillTemplate())
                if petSkillBaseCfg then
                    local length = petSkillBaseCfg:RecommendLearnableSkillLength()
                    for i = 1, length do
                        if petSkillBaseCfg:RecommendLearnableSkill(i) == skillCfg:Id() then
                            isRecommend = true
                            break
                        end
                    end
                end
            end
            -- 多少宠物装配了此技能
            local pets = ModuleRefer.PetModule:GetPetsByEquippedSkill(k)
            local equippedNum = #pets
            cur = cur + 1
            local data = {
                isLearnPanel = self.isLearnPanel,
                equippedNum = equippedNum,
                id = skillCfg:Id(),
                isRecommend = isRecommend,
                active = v.Active,
                isLock = not v.Active,
                exp = v.Exp,
                cfg = skillCfg,
                quality = skillCfg:Quality(),
                cellIndex = self.cellIndex,
                curPet = self.curPet,
            }
            table.insert(self.sortSkills, data)
        end
    end

    self.child_empty:SetVisible(cur == 0)

    if self.isLearnPanel then
        table.sort(self.sortSkills, UIPetSkillMediator.SortSkillsLibrary)
    else
        table.sort(self.sortSkills, UIPetSkillMediator.SortSkillsEquipment)
    end

    local sum = 0
    for i = 1, ConfigRefer.PetSkillBase.length do
        if ConfigRefer.PetSkillBase:Find(i):IsAvailable() then
            sum = sum + 1
        end
    end
    self.p_txt_free_2.text = I18N.Get("gacha_select_got") .. cur .. "/" .. sum

    self.p_table_ranking:Clear()
    for k, v in pairs(self.sortSkills) do
        local skillCfg = ConfigRefer.PetLearnableSkill:Find(v.id)
        local type = skillCfg:SkillType()
        if type == self.curTab - 1 or self.curTab == 1 then
            self.p_table_ranking:AppendData(v)
        end
    end
    self.p_table_ranking:RefreshAllShownItem()
end

-- 技能库排序
function UIPetSkillMediator.SortSkillsLibrary(a, b)
    if (a.active ~= b.active) then
        return not a.active
    elseif (a.exp ~= b.exp) then
        return a.exp > b.exp
    elseif (a.equippedNum ~= b.equippedNum) then
        return a.equippedNum < b.equippedNum
    elseif (a.quality ~= b.quality) then
        return a.quality > b.quality
    else
        return a.id < b.id
    end
end

-- 装备技能排序
function UIPetSkillMediator.SortSkillsEquipment(a, b)
    if (a.isRecommend ~= b.isRecommend) then
        return a.isRecommend
    elseif (a.active ~= b.active) then
        return a.active
    elseif (a.exp ~= b.exp) then
        return a.exp > b.exp
    elseif (a.equippedNum ~= b.equippedNum) then
        return a.equippedNum < b.equippedNum
    elseif (a.quality ~= b.quality) then
        return a.quality > b.quality
    else
        return a.id < b.id
    end
end

function UIPetSkillMediator:OnEquipmentChanged()
    self:RefreshSkills()
end

function UIPetSkillMediator:OnEquippedSkill()
    self:CloseSelf()
end

function UIPetSkillMediator:OnTabClick(index)
    if (self.curTab ~= index) then
        local oldData = self.tabs[self.curTab]
        self.curTab = index
        self.tabs[self.curTab].selected = true
        if (oldData) then
            oldData.selected = false
        end
        self.p_table_tab:RefreshAllShownItem()
        self:RefreshSkills()
    end
end

return UIPetSkillMediator
