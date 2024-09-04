local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ManualUIConst = require('ManualUIConst')

---@class PetSkillLearnIconComp : BaseTableViewProCell
---@field data HeroConfigCache
local PetSkillLearnIconComp = class('PetSkillLearnIconComp', BaseTableViewProCell)

function PetSkillLearnIconComp:ctor()

end

function PetSkillLearnIconComp:OnCreate()
    self.child_card_pet_s = self:LuaObject('child_card_pet_s')
    self.child_pet_dna = self:LuaObject('child_pet_dna')
    self.p_group_dna = self:GameObject('p_group_dna')
    self.p_group_working = self:Image('p_group_working')
    self.p_text_working = self:Text('p_text_working','ui_ufo_working')
end

function PetSkillLearnIconComp:OnFeedData(param)
    self.child_card_pet_s:FeedData(param)
    if self.child_pet_dna then
        if param.hideGene then
            self.p_group_dna:SetVisible(false)
        else
            self.p_group_dna:SetVisible(true)
            local petInfo = ModuleRefer.PetModule:GetPetByID(param.id)
            self.child_pet_dna:FeedData(petInfo)
        end
    end

    local isWorking = ModuleRefer.PetModule:IsPetWorking(param.id)
    self.p_group_working:SetVisible(isWorking)
    g_Game.SpriteManager:LoadSprite(ManualUIConst.sp_white_solid,self.p_group_working)
end

function PetSkillLearnIconComp:Select(param)
    self.child_card_pet_s:OnSelect()
end

function PetSkillLearnIconComp:UnSelect(param)
    self.child_card_pet_s:OnUnselect()
end

return PetSkillLearnIconComp
