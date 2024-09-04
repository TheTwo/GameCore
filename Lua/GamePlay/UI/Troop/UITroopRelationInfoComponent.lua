local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHeroAssociateHelper = require('UIHeroAssociateHelper')
local NumberFormatter = require('NumberFormatter')
local UIMediatorNames = require('UIMediatorNames')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
---@class UITroopRelationInfoComponent : BaseUIComponent
local UITroopRelationInfoComponent = class('UITroopRelationInfoComponent', BaseUIComponent)

---@class UITroopRelationInfoComponentData
---@field heroIds number[] @HeroesConfigCell.Id
---@field showText boolean

function UITroopRelationInfoComponent:ctor()

end

function UITroopRelationInfoComponent:OnCreate()
    self.textBuff = self:Text('p_text_buff', 'formation_taglevelshow')
    ---@type UIHeroAssociateIconComponent[]
    self.compChildIconStyles = {}
    self.compChildIconStyles[1] = self:LuaObject('child_icon_style_1')
    self.compChildIconStyles[2] = self:LuaObject('child_icon_style_2')
    self.compChildIconStyles[3] = self:LuaObject('child_icon_style_3')

    self.textBuffNum = self:Text('p_text_buff_num')
    self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClicked))
    self.goTextNone = self:GameObject('p_text_normal')
    -- self:Text("p_text_normal", "formation_taglevel1")
    self.goTextGood = self:GameObject('p_text_good')
    -- self:Text("p_text_good", "formation_taglevel2")
    self.goTextExcellent = self:GameObject('p_text_excellent')
    -- self:Text("p_text_excellent", "formation_taglevel3")
    self.vfxTrigger = self:AnimTrigger('vfx_trigger')
end


function UITroopRelationInfoComponent:OnShow(param)

end

function UITroopRelationInfoComponent:OnHide(param)
end

function UITroopRelationInfoComponent:OnOpened(param)
end

function UITroopRelationInfoComponent:OnClose(param)
end

function UITroopRelationInfoComponent:ResetTroop()
    self.lastReleationKey = nil
end

---@param param number[] | UITroopRelationInfoComponentData
function UITroopRelationInfoComponent:OnFeedData(param)
    if not param then
        param = {}
    end
    self.heroIds = (param.heroIds or param) or {}
    self.showText = param.showText
    local relationCfg = ModuleRefer.TroopModule:GetHerosRelation(self.heroIds)
    local needPlayVfx = false
    if relationCfg then
        if self.vfxTrigger and (self.lastReleationKey == nil or self.lastReleationKey ~= relationCfg.key) then
            needPlayVfx = true
            self.lastReleationKey = relationCfg.key
            self.vfxTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
        end
        self:SetupRelationInfo(relationCfg,ModuleRefer.TroopModule:GetRelationConfigData(),needPlayVfx)
    else
        if self.vfxTrigger and self.lastReleationKey ~= nil and self.lastReleationKey ~= '' then
            needPlayVfx = true
            self.lastReleationKey = ''
            self.vfxTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
        end
        self:SetupRelationInfo(nil,nil,needPlayVfx)
    end

end

function UITroopRelationInfoComponent:OnBtnDetailClicked(args)
    -- body
    g_Game.UIManager:Open(UIMediatorNames.UITroopRelationTipsMediator, {
        heroIds = self.heroIds,
        associateData = self:GetConfigData(),
    }
)
end

---@return HeroAssociateData
function UITroopRelationInfoComponent:GetConfigData()
    if not self.cfgData then
        self.cfgData = ModuleRefer.TroopModule:GetRelationConfigData()
        if not self.cfgData then
            g_Logger.ErrorChannel("UITroopRelationInfoComponent","GetConfigData failed, cfgData is nil")
        end
    end
    return self.cfgData
end

---@param relationCfg HeroAssociateData_RelationCfg
---@param configData HeroAssociateData
function UITroopRelationInfoComponent:SetupRelationInfo(relationCfg,configData,needPlayVfx)
    if not self.showText then
        if self.goTextGood then
            self.goTextGood:SetActive(false)
        end
        if self.goTextExcellent then
            self.goTextExcellent:SetActive(false)
        end
        if self.goTextNone then
            self.goTextNone:SetActive(false)
        end
    else
        if self.goTextGood then
            self.goTextGood:SetActive(true)
        end
        if self.goTextExcellent then
            self.goTextExcellent:SetActive(true)
        end
        if self.goTextNone then
            self.goTextNone:SetActive(true)
        end
    end
    if not relationCfg or not relationCfg.tags or #relationCfg.tags < 1 then
        for i = 1, #self.compChildIconStyles do
            self.compChildIconStyles[i]:SetVisible(false)
        end
        self.textBuffNum.text = ''
        if self.goTextGood and self.goTextExcellent then
            self.goTextGood:SetActive(false)
            self.goTextExcellent:SetActive(false)
        end
        if self.goTextNone then
            self.goTextNone:SetActive(true)
        end
        return
    end

    local tagIds = relationCfg.tags
    for i = 1, #self.compChildIconStyles do
        local tagId = tagIds[i]
        if not tagId then
            self.compChildIconStyles[i]:SetVisible(false)
            goto continue
        end

        self.compChildIconStyles[i]:SetVisible(true)
        self.compChildIconStyles[i]:FeedData({
            cfgData = configData,
            tagType = tagId,
            playVfx = needPlayVfx
        })
        ::continue::
    end
    self.textBuffNum.text = I18N.Get(relationCfg.displayValue)
    if self.goTextGood and self.goTextExcellent then
        if #relationCfg.tags == 2 then
            self.goTextGood:SetActive(true)
            self.goTextExcellent:SetActive(false)
        elseif #relationCfg.tags == 3 then
            self.goTextGood:SetActive(false)
            self.goTextExcellent:SetActive(true)
        else
            self.goTextGood:SetActive(false)
            self.goTextExcellent:SetActive(false)
        end
    end
    if self.goTextNone then
        self.goTextNone:SetActive(false)
    end
end



return UITroopRelationInfoComponent
