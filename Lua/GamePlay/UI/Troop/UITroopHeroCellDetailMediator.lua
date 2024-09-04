local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local HeroUIUtilities = require('HeroUIUtilities')
local UIMediatorNames = require('UIMediatorNames')
local Utils = require('Utils')
local TipsRectTransformUtils = require('TipsRectTransformUtils')
local AudioConsts = require('AudioConsts')
local EventConst = require('EventConst')
local UIHeroLocalData = require('UIHeroLocalData')
---@class UITroopHeroCellDetailMediator : BaseUIMediator
local UITroopHeroCellDetailMediator = class('UITroopPetCellDetailMediator', BaseUIMediator)

---@class UITroopHeroCellDetailParam
---@field heroId number
---@field rectTransform CS.UnityEngine.RectTransform

function UITroopHeroCellDetailMediator:ctor()
end

function UITroopHeroCellDetailMediator:OnCreate()
    self.content = self:Transform('content')

    ---@see HeroInfoItemSmallComponent
    self.luaHeroHead = self:LuaObject('child_card_hero_s_ex')
    self.textName = self:Text('p_text_name')

    self.imgIconType = self:Image('p_icon')
    self.textType = self:Text('p_text_type')

    self.textPower = self:Text('p_text_power')

    ---@see UIHeroStrengthenCellGroup
    self.luaStars = self:LuaObject('child_strengthen_hero_group')

    self.luaSkill1 = self:LuaObject('child_item_skill_1')
    self.luaSkill2 = self:LuaObject('child_item_skill_2')
    self.luaSkill3 = self:LuaObject('child_item_skill_3')

    self.skills = {self.luaSkill1, self.luaSkill2, self.luaSkill3}
end

---@param param UITroopHeroCellDetailParam
function UITroopHeroCellDetailMediator:OnOpened(param)
    self.rectTransform = param.rectTransform
    self.heroId = param.heroId
    self.heroData = ModuleRefer.HeroModule:GetHeroByCfgId(self.heroId)

    ---@type HeroInfoData
    local heroHeadData = {}
    heroHeadData.heroData = self.heroData
    self.luaHeroHead:FeedData(heroHeadData)

    self.textName.text = I18N.Get(self.heroData.configCell:Name())
    self.textPower.text = ModuleRefer.HeroModule:CalcHeroPower(self.heroId)

    local icon = HeroUIUtilities.GetHeroBattleTypeTextureName(self.heroData.configCell:BattleType())
    g_Game.SpriteManager:LoadSprite(icon, self.imgIconType)
    self.textType.text = HeroUIUtilities.GetBattleLabelStr(self.heroData.configCell:BattleType())

    self.luaStars:FeedData(self.heroData.dbData.StarLevel)

    local heroCfg = self.heroData.configCell
    local strengthenCfg = ConfigRefer.HeroStrengthen:Find(heroCfg:StrengthenCfg())
    local strengthenLvl = (self.heroData.dbData or {}).StarLevel or 0
    local skillLvl
    if strengthenLvl == 0 then
        skillLvl = 1
    else
        skillLvl = strengthenCfg:StrengthenInfoList(strengthenLvl):SkillLevel()
    end
    local petId = ModuleRefer.HeroModule:GetHeroLinkPet(self.heroId)
    local isHasPet = petId and petId > 0

    ---从UIHeroInfoComponent抄的
    for i = 1, #self.skills do
        local isShow = i <= heroCfg:SlgSkillDisplayLength()
        self.skills[i]:SetVisible(isShow)
        if isShow then
            local slgSkillId = heroCfg:SlgSkillDisplay(i)
            local slgSkillCell = ConfigRefer.SlgSkillInfo:Find(slgSkillId)
            local seSkillId = heroCfg:CardsDisplay(i)
            local seSkillCell = ConfigRefer.Card:Find(seSkillId)
            local skillParam = {}
            skillParam.skillId = slgSkillCell:SkillId()
            skillParam.index = i
            skillParam.isSlg = true
            skillParam.skillLevel = skillLvl
            skillParam.isLock = i == 3 and not isHasPet
            skillParam.showLvl = true
            skillParam.cardId = seSkillId
            skillParam.clickCallBack = function()
                ---@type UISkillCommonTipMediatorParameter
                local param = {}
                param.ShowHeroSkillTips = {
                    slgSkillId = skillParam.skillId,
                    cardId = skillParam.cardId,
                    isLock = skillParam.isLock,
                    skillLevel = skillParam.skillLevel,
                    slgSkillCell = slgSkillCell,
                    hasHero = false
                }
                param.offset = CS.UnityEngine.Vector2(520, 40)
                g_Game.UIManager:Open(UIMediatorNames.UISkillCommonTipMediator, param)
            end
            self.skills[i]:FeedData(skillParam)
        end
    end

    -- if Utils.IsNotNull(self.rectTransform) then
    --     CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.content)
    --     self:OnLateTick(0)
    --     g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateTick))
    -- end
end

function UITroopHeroCellDetailMediator:OnClose()
    -- g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateTick))
end

function UITroopHeroCellDetailMediator:OnLateTick(dt)
    if Utils.IsNull(self.rectTransform) then return end
    self.lastEdge = TipsRectTransformUtils.TryAnchorTipsNearTargetRectTransform(self.rectTransform, self.content, self.lastEdge)
end

return UITroopHeroCellDetailMediator