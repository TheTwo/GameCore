local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local UIMediatorNames = require('UIMediatorNames')
local ModuleRefer = require("ModuleRefer")
local NoviceConst = require("NoviceConst")
local NotificationType = require("NotificationType")
local I18N = require("I18N")
local HeroUIUtilities = require("HeroUIUtilities")
---@class NoviceTaskPopupMediator:BaseUIMediator
local NoviceTaskPopupMediator = class('NoviceTaskPopupMediator', BaseUIMediator)

function NoviceTaskPopupMediator:OnCreate()
    self.btnClose = self:Button('child_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
    self.btnGoto = self:Button('child_comp_btn_b_l', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
    self.textBtnGoto = self:Text('p_text', 'popup_windows_survival_rules_btn_goto')

    self.textName = self:Text('p_text_name', '*p_text_name')
    self.textQuality = self:Text('p_text_quality', '*p_text_quality')

    self.textNameHero = self:Text('p_text_name_hero', '*p_text_name_hero')
    self.textNameFurniture = self:Text('p_text_name_furniture', '*p_text_name_furniture')

    self.textTitle = self:Text('p_text_title', 'popup_windows_survival_rules_title')
    self.textDetail = self:Text('p_text_detail', 'popup_windows_survival_rules_desc')

    self.notifyNode = self:LuaObject('child_reddot_default')
end

function NoviceTaskPopupMediator:OnOpened(params)
    self.popIds = (params or {}).popIds
    local notifyLogicNode = ModuleRefer.NotificationModule:GetDynamicNode(
        NoviceConst.NoviceNotificationNodeNames.NovicePopupBtn, NotificationType.NOVICE_POPUP_BTN)
    ModuleRefer.NotificationModule:AttachToGameObject(notifyLogicNode, self.notifyNode.go, self.notifyNode.redDot)

    local spRewardIdxs = ModuleRefer.NoviceModule:GetSpecialRewardIdxs()

    local furName = ModuleRefer.NoviceModule:GetSpeicalRewardConfig(spRewardIdxs[2] or 1):NameKey()
    local heroName = ModuleRefer.NoviceModule:GetSpeicalRewardConfig(spRewardIdxs[1] or 1):NameKey()
    local petName = ModuleRefer.NoviceModule:GetSpeicalRewardConfig(spRewardIdxs[3] or 1):NameKey()
    local petQuality = ModuleRefer.NoviceModule:GetSpeicalRewardConfig(NoviceConst.SpecialRewardPetIndex):Quality()
    self.textNameFurniture.text = I18N.Get(furName)
    self.textNameHero.text = I18N.Get(heroName)
    self.textName.text = I18N.Get(petName)
    self.textQuality.text = I18N.Get(HeroUIUtilities.GetQualityText(petQuality - 2))
end

function NoviceTaskPopupMediator:OnClose()
    if self.popIds then
        ModuleRefer.LoginPopupModule:OnPopupShown(self.popIds)
    end
end

function NoviceTaskPopupMediator:OnBtnCloseClicked()
    self:CloseSelf()
end

function NoviceTaskPopupMediator:OnBtnGotoClicked()
    g_Game.UIManager:Open(UIMediatorNames.NoviceTaskMediator)
end

return NoviceTaskPopupMediator