local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local UIHelper = require('UIHelper')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local HeroUIUtilities = require('HeroUIUtilities')
local I18N = require('I18N')
local NumberFormatter = require('NumberFormatter')
local ArtResourceUIConsts = require("ArtResourceUIConsts")
local ArtResourceUtils = require('ArtResourceUtils')
local DBEntityType = require('DBEntityType')
local EnumSoldierType = require('EnumSoldierType')
local SlgUtils = require('SlgUtils')
---@class TroopCircleMenuInfo : BaseUIComponent
local TroopCircleMenuInfo = class('TroopCircleMenuInfo', BaseUIComponent)

function TroopCircleMenuInfo:ctor()

end

function TroopCircleMenuInfo:OnCreate()
    self.imgImgBase = self:Image('p_img_base')
    ---@type CommonHeroHeadIcon
    self.imgImgHero = self:LuaObject('child_card_hero_s')
    
    self.goTroopStateBase = self:GameObject('p_base_troop')
    self.imgIconTroopState = self:Image('p_icon_troop_state')

    self.goTroopKindBase = self:GameObject('base')
    self.imgIconTroopKind = self:Image('p_icon_troop_kind')
    self.sliderSliderHealthbar = self:Slider('p_slider_healthbar')
    self.sliderSkill = self:Slider('p_slider_skill')
    self.textTroopNum = self:Text('p_text_troop_num')
    self.textTroopName = self:Text('p_text_troop_name') 
    self.iconEscrow = self:Image("p_icon_escrow")
    self.rageMax = ModuleRefer.SlgModule:TroopRageMax()
    self.maxMpAmount = 0.38
    self.minMpAmount = 0.18
end
function TroopCircleMenuInfo:OnFeedData(data)
    ---@type TroopCtrl
    local troopCtrl = data.troopCtrl   
    local troopData = troopCtrl._data
    if troopData.TypeHash == DBEntityType.MobileFortress then
        g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_monster_juyantanglang), self.imgImgHero.imgHero)
        self:LoadSprite(ArtResourceUIConsts.sp_troop_frame_b,self.imgImgBase)
        self:LoadSprite(HeroUIUtilities.GetHeroTypeTextureID(nil),self.imgIconTroopKind)
    elseif troopData.Battle.Group.Heros and troopData.Battle.Group.Heros[0] then
        --Hero Image
        local mainHero = troopData.Battle.Group.Heros[0]
        ---@type HeroesConfigCell
        local heroCfg = ConfigRefer.Heroes:Find(mainHero.HeroID)    
        if heroCfg == nil then
            -- self:GetParentBaseUIMediator():CloseSelf()
            return
        end
        if troopCtrl:IsMonster() then
            self.imgImgHero:ShowMonsterIcon(heroCfg:Id())
        else
            self.imgImgHero:ShowHeroIcon(heroCfg:Id())
        end
        self.imgIconTroopKind:SetVisible(true)       
        
        if troopCtrl.troopType == SlgUtils.TroopType.MySelf then            
            self:LoadSprite(ArtResourceUIConsts.sp_troop_frame_a,self.imgImgBase)
        elseif troopCtrl.troopType == SlgUtils.TroopType.Friend then
            self:LoadSprite(ArtResourceUIConsts.sp_troop_frame_b,self.imgImgBase)
        else
            self:LoadSprite(ArtResourceUIConsts.sp_troop_frame_c,self.imgImgBase)
        end
        self:LoadSprite(HeroUIUtilities.GetTroopTypeTextureId(troopData.Battle.Group.Heros),self.imgIconTroopKind)
    end
    
    if UNITY_DEBUG or UNITY_EDITOR then
        self.textTroopName.text = troopData.Owner.PlayerName.String .. "(" .. troopData.ID .. ")"
    else
        self.textTroopName.text = troopData.Owner.PlayerName.String
    end

    local troopType
    if troopCtrl.troopType == SlgUtils.TroopType.MySelf or troopCtrl.troopType == SlgUtils.TroopType.Friend then
        troopType = troopCtrl.troopType
    else
        troopType = SlgUtils.TroopType.Enemy 
    end
    self.textTroopName.color = SlgUtils.GetEntityColor(troopType)         
    self.goTroopStateBase:SetVisible(troopCtrl:IsSelf())
   

    if data.onlyHpBar then
        self.imgImgBase:SetVisible(false)
        self.imgImgHero:SetVisible(false)
        self.sliderSkill:SetVisible(false)
        self.goTroopStateBase:SetVisible(false)
        self.goTroopKindBase:SetVisible(false)
    elseif troopCtrl.troopType == SlgUtils.TroopType.Boss 
        or troopCtrl.troopType == SlgUtils.TroopType.Behemoth
    then
        self.sliderSkill:SetVisible(false)
    end

end

---@param data wds.Troop
function TroopCircleMenuInfo:UpdateBattleData(data)
    local battleData = data.Battle
    if battleData then 
        self.sliderSliderHealthbar.value = math.clamp01( battleData.Hp / battleData.MaxHp )
        self.textTroopNum.text = NumberFormatter.Normal(battleData.Hp)
        self.sliderSkill.value = (self.maxMpAmount - self.minMpAmount) * math.clamp01(battleData.RageValue / self.rageMax) + self.minMpAmount
    else    
        self.sliderSliderHealthbar.value = 0
        self.textTroopNum.text = NumberFormatter.Normal(0)
        self.sliderSkill.value = 0
    end
end

---@param troopData wds.Troop
function TroopCircleMenuInfo:UpdateMapStates(troopData)
    if not troopData then return end
    local troopStateIcon = HeroUIUtilities.TroopStateIcon(troopData)
    UIHelper.LoadSprite(troopStateIcon, self.imgIconTroopState)
end

function TroopCircleMenuInfo:OnHide(param)

end




return TroopCircleMenuInfo;
