local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class UIHeroUpgradeComponent : BaseUIComponent
---@field parentMediator UIHeroMainUIMediator
---@field heroList table<number,HeroConfigCache>
local UIHeroUpgradeComponent = class('UIHeroUpgradeComponent', BaseUIComponent)

function UIHeroUpgradeComponent:ctor()

end

function UIHeroUpgradeComponent:OnCreate()
    
    self.goGroupLv = self:GameObject('group_lv')
    self.textTitle = self:Text('p_text_title')
    self.textAttack = self:Text('p_text_attack')
    self.textAddAttack = self:Text('p_text_add_attack')
    self.tableviewproTableStrengthen = self:TableViewPro('p_table_strengthen')
    self.goStateA = self:GameObject('p_state_a')
    self.btnCompStrengthen = self:Button('p_comp_btn_strengthen', Delegate.GetOrCreate(self, self.OnBtnCompStrengthenClicked))
    self.goStateB = self:GameObject('p_state_b')
    self.goStateC = self:GameObject('p_state_c')
    self.btnCompGoto = self:Button('p_comp_btn_goto', Delegate.GetOrCreate(self, self.OnBtnCompGotoClicked))

    self.parentMediator = self:GetUIMediator().Lua
end


function UIHeroUpgradeComponent:OnShow(param)
end

function UIHeroUpgradeComponent:OnOpened(param)
end

function UIHeroUpgradeComponent:OnClose(param)
end

function UIHeroUpgradeComponent:OnFeedData(param)
    
end



function UIHeroUpgradeComponent:OnBtnCompStrengthenClicked(args)
    -- body
end
function UIHeroUpgradeComponent:OnBtnCompGotoClicked(args)
    -- body
end

return UIHeroUpgradeComponent;
