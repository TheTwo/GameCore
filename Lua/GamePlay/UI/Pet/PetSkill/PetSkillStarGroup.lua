local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local Utils = require('Utils')
local ModuleRefer = require('ModuleRefer')

local GameObjectCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper

---@class PetSkillStarGroup : BaseUIComponent
---@field handle CS.DragonReborn.UI.UIHelper.CallbackHolder
local PetSkillStarGroup = class('PetSkillStarGroup', BaseTableViewProCell)

function PetSkillStarGroup:OnCreate()
    self.p_star_1 = self:Image('p_icon_satr_1')
    -- UE名字不统一
    if self.p_star_1 == nil then
        self.p_star_1 = self:Image('p_star_1')
        self.p_star_2 = self:Image('p_star_2')
        self.p_star_3 = self:Image('p_star_3')
        self.p_star_4 = self:Image('p_star_4')
        self.p_star_5 = self:Image('p_star_5')
    else
        self.p_star_1 = self:Image('p_icon_satr_1')
        self.p_star_2 = self:Image('p_icon_satr_2')
        self.p_star_3 = self:Image('p_icon_satr_3')
        self.p_star_4 = self:Image('p_icon_satr_4')
        self.p_star_5 = self:Image('p_icon_satr_5')
    end

    self.line = self:GameObject("p_star_line")
    self.stars = {self.p_star_1, self.p_star_2, self.p_star_3, self.p_star_4, self.p_star_5}
    self.p_base_lock = self:GameObject('p_base_lock')
    self.p_base_unlock = self:GameObject('p_base_unlock')
    self.p_layout_star = self:Transform("p_layout_star")

end

---@class PetSkillStarGroupParam
---@field skillLevels {level:number, quality:number}[] @技能组数据
---@field start number @与skillLevels配套使用字段, 从第几个星星开始显示
---@field level number @当skillLevels为空时使用, 直接指定等级
---@field quality number @当skillLevels为空时使用, 直接指定品质
---@field forceLoad boolean @当skillLevels为空时使用, 是否强制按品质色Load每一个花瓣片

---@param param PetSkillStarGroupParam
function PetSkillStarGroup:OnFeedData(param)
    self.param = param
    local level = param.level
    local forceLoad = param.forceLoad or false
    local skillLevels = param.skillLevels
    if skillLevels then
        -- Init
        for i = 1, 5 do
            self.stars[i]:SetVisible(false)
            if self.line then
                self.line:SetVisible(false)
            end
        end
        local counter = 1
        local nodes = 1
        local located = false
        for k, v in pairs(skillLevels) do
            for i = 1, v.level do
                if not located and counter == param.start then
                    located = true
                    nodes = counter % 5
                    if self.line then
                        self.line:SetVisible(true)
                    end
                end

                if located then
                    if nodes == 5 then
                        if self.line then
                            self.line:SetVisible(false)
                        end
                    end
                    if nodes > 5 then
                        break
                    end
                    self.stars[nodes]:SetVisible(true)
                    local sprite =  ModuleRefer.PetModule:GetPetSkillIcon(v.quality)
                    g_Game.SpriteManager:LoadSprite(sprite, self.stars[nodes])
                    if v.playEquipVfx then
                        --self:DoPlayEquipVfx(nodes)
                         self:PlayEquipVfx(nodes)
                    end
                    nodes = nodes + 1
                else
                    counter = counter + 1
                end
            end
        end
    elseif level then
        for i = 1, 5 do
            if self.stars[i] then
                self.stars[i]:SetVisible(level >= i)
                if level >= i or forceLoad then
                    local quality = param.quality or 3
                    local icon = ModuleRefer.PetModule:GetPetSkillIcon(quality)
                    g_Game.SpriteManager:LoadSprite(icon, self.stars[i])
                    if self.param.playEquipVfx then
                         self:PlayEquipVfx(i)
                        --self:DoPlayEquipVfx(i)
                    end
                end
            end
        end
    end
end

function PetSkillStarGroup:SetLock(isLock)
    if self.p_base_lock then
        self.p_base_lock:SetVisible(isLock)
    end
    if self.p_base_unlock then
        self.p_base_unlock:SetVisible(not isLock)
    end
end

function PetSkillStarGroup:OnShow(param)

end

function PetSkillStarGroup:OnHide(param)
    if self.helper then
        self.helper:CancelAllCreate()
        self.helper = nil
    end
end

function PetSkillStarGroup:PlayEquipVfx(index)
    self:LoadVX(Delegate.GetOrCreate(self, self.DoPlayEquipVfx), index)
end

function PetSkillStarGroup:DoPlayEquipVfx(index)
    if not self.trigger then
        return
    end

    if index == 1 then
        self.trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    elseif index == 2 then
        self.trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    elseif index == 3 then
        self.trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
    elseif index == 4 then
        self.trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom4)
    elseif index == 5 then
        self.trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom5)
    end
end

function PetSkillStarGroup:LoadVX(callback, param)
    if not self.helper then
        self.helper = GameObjectCreateHelper.Create()
        ---@param go CS.UnityEngine.GameObject
        self.helper:CreateAsap("child_vx_star_pet_l", self.p_layout_star, function(go)
            if Utils.IsNotNull(go) then
                self.trigger_huxi = go.transform:Find("trigger_huxi"):GetComponent(typeof(CS.FpAnimation.FpAnimationCommonTrigger))
                self.trigger = go.transform:Find("trigger"):GetComponent(typeof(CS.FpAnimation.FpAnimationCommonTrigger))
                self.trigger_bresk = go.transform:Find("trigger_bresk"):GetComponent(typeof(CS.FpAnimation.FpAnimationCommonTrigger))
            end
            if callback then callback(param) end
        end)
    else
        if callback then callback(param) end
    end
end

return PetSkillStarGroup;
