local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local AudioConsts = require("AudioConsts")
local Utils = require("Utils")

---@class UIHeroBreakResComponent : BaseUIComponent
local UIHeroBreakResComponent = class('UIHeroBreakResComponent', BaseUIComponent)

function UIHeroBreakResComponent:ctor()
    self.module = ModuleRefer.HeroModule
end

function UIHeroBreakResComponent:OnCreate()

    self.textBreakTitle = self:Text('p_text_break_title', I18N.Get("hero_breakthrough_done"))
    self.textLv = self:Text('p_text_lv')
    self.goSkill = self:GameObject('p_skill')
    self.textSkill = self:Text('p_text_skill', I18N.Get("hero_new_skill_unlock"))
    self.goFunction = self:GameObject('p_function')
    self.textFunction = self:Text('p_text_function', I18N.Get("hero_new_skill_unlock"))
    self.imgIconFunction = self:Image('icon_function')
    self.btnComp = self:Button('p_empty', Delegate.GetOrCreate(self, self.OnBtnCompClicked))
    self.imgHero = self:Image('p_img_hero')
    self.textHint = self:Text("p_text_hint_close", I18N.Get("equip_clickempty"))
end


function UIHeroBreakResComponent:OnShow(param)
    ---@type UIHeroMainUIMediator
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_breakthrough)
    self.parentWin = self:GetParentBaseUIMediator()
    local selectHero = self.parentWin:GetSelectHero()
    if not selectHero.dbData then
        return
    end
    local breakConfig = self.module:FindBreakConfig(selectHero.configCell,selectHero.dbData.LevelUpperLimit)
    self.textLv.text =  I18N.Get("hero_level_uplimit") .. tostring(breakConfig:LevelUpperLimit())
    self.goSkill:SetVisible(false)
    self.goFunction:SetVisible(false)
    local heroClientConfig = ConfigRefer.HeroClientRes:Find(selectHero.configCell:ClientResCfg())
    self:LoadSprite(heroClientConfig:BodyPaint(),self.imgHero)
    if Utils.IsNotNull(self.imgHero) then
        self.imgHero:SetNativeSize()
    end
end


function UIHeroBreakResComponent:OnBtnCompClicked(args)
    if self.parentWin then
        self.parentWin:OnBackBtnClick()
    end
end

return UIHeroBreakResComponent;
