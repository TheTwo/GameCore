local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
---@class PetSkillTypeComp : BaseTableViewProCell
---@field data HeroConfigCache
local PetSkillTypeComp = class('PetSkillTypeComp', BaseTableViewProCell)

function PetSkillTypeComp:ctor()

end

function PetSkillTypeComp:OnCreate()
    self.p_base = self:Image('p_base')
    self.p_text_type = self:Text('p_text_type')
end

function PetSkillTypeComp:OnFeedData(param)
    self.p_text_type.text = param.text
end


return PetSkillTypeComp
