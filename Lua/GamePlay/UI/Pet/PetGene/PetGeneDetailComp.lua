local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local ArtResourceUtils = require('ArtResourceUtils')
local UIHelper = require('UIHelper')
local HeroUIUtilities = require('HeroUIUtilities')

---@class PetGeneDetailComp : BaseTableViewProCell
local PetGeneDetailComp = class('PetGeneDetailComp', BaseTableViewProCell)
local GeneImg = {"sp_pet_icon_dna_3", "sp_pet_icon_dna_2", "sp_pet_icon_dna_1"}

function PetGeneDetailComp:ctor()

end

function PetGeneDetailComp:OnCreate()

end

function PetGeneDetailComp:OnFeedData(param)
    self.p_base = self:Image('')
    self.p_text_lv = self:Text('p_text_lv_' .. param.index)
    self.p_text_name = self:Text('p_text_name_' .. param.index)
    self.p_text_detail = self:Text('p_text_detail_' .. param.index)

    local quality = param.quality > 0 and param.quality or 0
    g_Game.SpriteManager:LoadSprite(GeneImg[quality], self.p_base)
    -- self.p_text_lv.text = HeroUIUtilities.RomanChar[param.level]
    self.p_text_name.text = param.name
    self.p_text_detail.text = param.desc
end
return PetGeneDetailComp
