local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require('UIMediatorNames')
local I18N = require('I18N')
local PetSkillDefine = require('PetSkillDefine')
local ArtResourceUtils = require('ArtResourceUtils')
local UIHelper = require('UIHelper')
local HeroUIUtilities = require('HeroUIUtilities')

---@class UIPetWorkTypeComp : BaseTableViewProCell
local UIPetWorkTypeComp = class('UIPetWorkTypeComp', BaseTableViewProCell)

function UIPetWorkTypeComp:ctor()

end

function UIPetWorkTypeComp:OnCreate()
    self.p_icon_type = self:Image('p_icon_type') or self:Image('p_icon_type_main')
    self.p_text_type_lv = self:Text('p_text_type_lv') or self:Text('p_text_type_lv_main')
    self.p_text_type_name = self:Text('p_text_type_name')
    self.icon_goto = self:Button('icon_goto',Delegate.GetOrCreate(self, self.OnClickType))

end

function UIPetWorkTypeComp:OnFeedData(param)
    self.onClick = param.onClick
    if param.level then
        self.p_text_type_lv.text = param.level
    end
    if self.p_text_type_name then
        self.p_text_type_name.text = param.name
    end
    g_Game.SpriteManager:LoadSprite(param.icon, self.p_icon_type)
end


function UIPetWorkTypeComp:OnClickType()
    if self.onClick then
        self.onClick()
    end
end

-- function UIPetWorkTypeComp:OnBtnClick(param)
--     if self.onClick then
--         self.onClick(self.data)
--     end
-- end

return UIPetWorkTypeComp
