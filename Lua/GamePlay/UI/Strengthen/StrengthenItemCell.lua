local BaseTableViewProCell = require ('BaseTableViewProCell')
local I18N = require('I18N')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local UIStrengthenProvider = require("UIStrengthenProvider")
local GuideUtils = require("GuideUtils")


---@class StrengthenItemCell:BaseUIComponent
local StrengthenItemCell = class('StrengthenItemCell', BaseTableViewProCell)

function StrengthenItemCell:OnCreate()
    self.textName = self:LinkText('p_text_name')
    self.imgIconQuality = self:Image('p_icon_quality')
    self.imgIconType = self:Image('p_icon_type')
    self.sliderGrogressTransform = self:Slider('p_grogress_transform')
    self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClicked))
    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
    self.textGoto = self:Text('p_text_goto', I18N.Get("getmore_go"))
    self.goImgRecomment = self:GameObject('p_img_recomment')
end

function StrengthenItemCell:CheckIsRecommond(recommendCfg, subType)
    for i = 1, recommendCfg:RecommendSubtypeLength() do
        if recommendCfg:RecommendSubtype(i) == subType then
            return true
        end
    end
    return false
end


function StrengthenItemCell:OnFeedData(param)
    local playerData = ModuleRefer.PlayerModule:GetPlayer()
    local subTypePowers = playerData.PlayerWrapper2.PlayerPower.SubTypePowers
    local strongHoldLv = ModuleRefer.PlayerModule:StrongholdLevel()
    local recommendCfg = ConfigRefer.RecommendPowerTable:Find(strongHoldLv)
    local subTypePower = recommendCfg:SubTypePowers(param.index)
    local subType = subTypePower:SubType()
    local subPower = subTypePower:PowerValue()
    local curPower = subTypePowers[subType] or 0
    if subPower <= 0 then
        subPower = 1
    end
    local percent = curPower / subPower
    self.config = param.config
    self.textName.text = I18N.Get(self.config:Name())
    self:LoadSprite(self.config:Icon(), self.imgIconType)
    if percent >= 1.2 then
        g_Game.SpriteManager:LoadSprite("sp_strengthen_icon_quality_s", self.imgIconQuality)
    elseif percent >= 1 then
        g_Game.SpriteManager:LoadSprite("sp_strengthen_icon_quality_a", self.imgIconQuality)
    elseif percent >= 0.8 then
        g_Game.SpriteManager:LoadSprite("sp_strengthen_icon_quality_b", self.imgIconQuality)
    else
        g_Game.SpriteManager:LoadSprite("sp_strengthen_icon_quality_c", self.imgIconQuality)
    end
    self.sliderGrogressTransform.value = math.clamp(curPower / (subPower * 1.2), 0, 1)
    self.goImgRecomment:SetActive(self:CheckIsRecommond(recommendCfg, subType))
    self.index = param.index
end

function StrengthenItemCell:OnBtnDetailClicked(args)
    local data = {}
    data.index = self.index
    data.overrideDefaultProvider = UIStrengthenProvider.new()
    g_Game.UIManager:Open(UIMediatorNames.UIRaisePowerPopupMediator, data)
end

function StrengthenItemCell:OnBtnGotoClicked(args)
    GuideUtils.GotoByGuide(self.config:UIGoto())
end

return StrengthenItemCell