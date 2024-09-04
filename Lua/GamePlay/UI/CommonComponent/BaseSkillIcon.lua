local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local ManualUIConst = require('ManualUIConst')

---@class BaseSkillIconData
---@field isLock boolean
---@field skillId number
---@field skillLevel number|nil @default 1
---@field index number
---@field clickCallBack fun(index:number, skillLevel:number, clickTrans:CS.UnityEngine.RectTransform)
---@field isSlg boolean
---@field isSoc boolean
---@field showLvl boolean

---@class BaseSkillIcon : BaseUIComponent
---@field super BaseUIComponent
local BaseSkillIcon = class('BaseSkillIcon', BaseUIComponent)
local ModuleRefer = require('ModuleRefer')

function BaseSkillIcon:OnCreate()
    self.btnSkill = self:Button('p_btn_skill', Delegate.GetOrCreate(self, self.OnBtnSkillClicked))
    self.imgIconSkill = self:Image('p_icon_skill')
    self.textLv = self:Text('p_text_lv')
    self.goLock = self:GameObject('p_lock')
    self.imgIconLock = self:Image('p_icon_lock')
    self.textName = self:Text("p_text_name")
    self.p_add = self:GameObject('p_add')
    self.p_base_frame = self:Image('p_base_frame')
    if self.p_base_frame then
        self.p_base_frame:SetVisible(false)
    end
    self.imgIconSkill:SetVisible(true)

    -- 宠物技能星级用
    -- self.p_star = self:GameObject('p_star')
    -- self.child_pet_star_s_1 = self:LuaObject('child_pet_star_s_1')
    -- self.child_pet_star_s_2 = self:LuaObject('child_pet_star_s_2')

    -- ---@type PetSkillStarGroup
    -- self.stars = {self.child_pet_star_s_1, self.child_pet_star_s_2}

    --新版宠物技能星级用...
    self.go_p_grop_lvl = self:GameObject('p_grop_lvl')
    self.p_grop_lvl = self:Image('p_grop_lvl')
    self.p_img_quantity = self:Image('p_img_quantity')
    self.p_text_lvl = self:Text('p_text_lvl')
    self.trigger_add = self:BindComponent("trigger_add", typeof(CS.FpAnimation.FpAnimationCommonTrigger))
    g_Game.SpriteManager:LoadSprite(ManualUIConst.sp_common_base_bar_m,self.p_grop_lvl)
end

---@param param BaseSkillIconData
function BaseSkillIcon:OnFeedData(param)
    if param.isLock then
        self.goLock:SetVisible(true)
        self.imgIconSkill:SetVisible(false)
    else
        self.goLock:SetVisible(false)
        self.imgIconSkill:SetVisible(true)
    end
    self.param = param
    self.p_add:SetVisible(param.isAdd)
    self.skillId = param.skillId or 0
    self.skillLevel = param.skillLevel or 0
    self.index = param.index
    self.clickCallBack = param.clickCallBack

    if (param.isSlg) then
        local skillId = ModuleRefer.SkillModule:GetSkillLevelUpId(self.skillId, self.skillLevel)
        local skillCfgCell = ConfigRefer.KheroSkillLogical:Find(skillId)
        if skillCfgCell then
            local skillIconId = skillCfgCell:SkillPic()
            if skillIconId > 0 then
                self:LoadSprite(skillIconId, self.imgIconSkill)
            end
            self.textName.text = I18N.Get(skillCfgCell:NameKey())
            self.textLv.text = param.skillLevel
        end
        self.go_p_grop_lvl:SetVisible(param.showLvl)
        if param.showLvl then
            self.p_text_lvl.text = self.skillLevel
            self.p_img_quantity.gameObject:SetVisible(false)
        end
    elseif (param.isSoc) then
        local skillId = ModuleRefer.SkillModule:GetSkillLevelUpId(self.skillId, self.skillLevel)
        local skillCfg = ConfigRefer.CitizenSkillInfo:Find(skillId)
        if (skillCfg) then
            local skillIconId = skillCfg:Icon()
            if skillIconId > 0 then
                self:LoadSprite(skillIconId, self.imgIconSkill)
            end
            self.textName.text = I18N.Get(skillCfg:Name())
            self.textLv.text = param.skillLevel
        end
        self.p_grop_lvl:SetVisible(false)
    elseif (param.isSe) then
        local skillId = ModuleRefer.SkillModule:GetSkillLevelUpId(self.skillId, self.skillLevel)
        local skillCfgCell = ConfigRefer.KheroSkillLogicalSe:Find(skillId)
        if skillCfgCell then
            local skillIconId = skillCfgCell:SkillPic()
            if skillIconId > 0 then
                self:LoadSprite(skillIconId, self.imgIconSkill)
            end
            self.textName.text = I18N.Get(skillCfgCell:NameKey())
            self.textLv.text = param.skillLevel
        end
        self.p_grop_lvl:SetVisible(false)
    elseif (param.isPet) then
        local cell = ConfigRefer.PetLearnableSkill:Find(param.index)
        if cell then
            local slgSkillId = cell:SlgSkill()
            local slgSkillCell = ConfigRefer.SlgSkillInfo:Find(slgSkillId)
            self.param.index = slgSkillCell:SkillId()
            local skillIconId = cell:Icon()
            if skillIconId > 0 then
                self:LoadSprite(skillIconId, self.imgIconSkill)
            end
            self.textName.text = I18N.Get(cell:Desc())
            self.textLv.text = param.skillLevel
            if self.p_base_frame then
                self.p_base_frame:SetVisible(true)
                local quality = cell:Quality()
                self.quality = quality
                g_Game.SpriteManager:LoadSprite("sp_hero_item_circle_" .. (quality + 2), self.p_base_frame)
            end
        else
            if self.p_base_frame then
                self.p_base_frame:SetVisible(false)
            end
            g_Game.SpriteManager:LoadSprite(ManualUIConst.sp_common_base_black, self.imgIconSkill)
        end
        self:SetStars()
    elseif (param.isPetFix) then
        -- 宠物固有技能读的slg技能
        local skillId = ModuleRefer.SkillModule:GetSkillLevelUpId(self.skillId, self.skillLevel)
        local skillCfgCell = ConfigRefer.KheroSkillLogical:Find(skillId)
        if skillCfgCell then
            local skillIconId = skillCfgCell:SkillPic()
            if skillIconId > 0 then
                self:LoadSprite(skillIconId, self.imgIconSkill)
            end
            self.textName.text = I18N.Get(skillCfgCell:NameKey())
            self.textLv.text = param.skillLevel
        end
        self.p_base_frame:SetVisible(true)
        self.imgIconSkill:SetVisible(true)
        self.quality = param.quality
        g_Game.SpriteManager:LoadSprite("sp_frame_skill_0" .. (param.quality + 2), self.p_base_frame)
        self:SetStars()
    end
end

function BaseSkillIcon:OnBtnSkillClicked()
    if self.clickCallBack then
        self.clickCallBack(self.param, self.btnSkill.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform)))
    end
end

function BaseSkillIcon:FeedDataCustomData(param)
    self:LoadSprite(param.icon, self.imgIconSkill)
    self.textName.text = param.name
    self.textLv.text = ""
    self.clickCallBack = param.clickCallBack
end

function BaseSkillIcon:SetStars()
    self.p_grop_lvl:SetVisible(self.param.showLvl or (self.skillLevel > 0 and self.skillId > 0))
    if self.param.isPet or self.param.isPetFix then
        if self.param.isLock or self.param.isAdd then
            return
        end
        local icon = ModuleRefer.PetModule:GetPetSkillIcon(self.quality)
        g_Game.SpriteManager:LoadSprite(icon,self.p_img_quantity)
        self.p_text_lvl.text = self.skillLevel .. "/" .. "<color=#aeb4b6>".. 10 .."</color>"
    end

    -- self.p_star:SetVisible(self.skillLevel > 0 and self.skillId > 0)
    -- if self.skillId > 0 then
    --     if self.param.isPet or self.param.isPetFix then
    --         for i = 2, 1, -1 do
    --             self.stars[i]:FeedData({level = self.skillLevel - (i - 1) * 5, quality = self.quality, playEquipVfx = self.param.playEquipVfx})
    --         end

    --         if self.param.playNextStarVfx then
    --             local nextStar = self.skillLevel + 1
    --             local starIndex = math.ceil(nextStar / 5)
    --             local starNum = nextStar - (starIndex-1) * 5
    --             if starIndex > 2 or starNum > 5 then
    --                 return
    --             end
    --             self.stars[starIndex]:playNextStarVfx(starNum)
    --         end
    --     end
    -- end
end

function BaseSkillIcon:PlaySkillAddVfx(play)
    if play then
        self.trigger_add:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    else
        self.trigger_add:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
end

return BaseSkillIcon;
