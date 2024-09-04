local ModuleRefer = require('ModuleRefer')
local Utils = require('Utils')
local BaseTableViewProCell = require('BaseTableViewProCell')
local I18N = require('I18N')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')

---@class PetTagComponent : BaseTableViewProCell
---@field data HeroConfigCache
local PetTagComponent = class('PetTagComponent', BaseTableViewProCell)

function PetTagComponent:OnCreate()
    self.p_icon = self:Image('p_icon')
    self.p_icon_base = self:Image('p_icon_base')
    self.p_text_feature = self:Text('p_text_feature')
end

function PetTagComponent:OnFeedData(petTagId)
    local cfg = ConfigRefer.PetTag:Find(petTagId)
    if not cfg then
        return
    end
    local icon = cfg:Icon()
    self.p_text_feature.text = I18N.Get(cfg:Desc())
    self.p_icon:SetVisible(icon ~= 0)
    self:LoadSprite(icon, self.p_icon)
    self:LoadSprite(cfg:Frame(), self.p_icon_base)
end

return PetTagComponent
