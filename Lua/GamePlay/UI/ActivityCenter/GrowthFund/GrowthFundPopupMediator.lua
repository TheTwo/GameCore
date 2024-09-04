local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local ActivityCenterConst = require("ActivityCenterConst")
local GrowthFundConst = require("GrowthFundConst")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
---@class GrowthFundPopupMediator:BaseUIMediator
local GrowthFundPopupMediator = class("GrowthFundPopupMediator", BaseUIMediator)

local I18N_KEYS = GrowthFundConst.I18N_KEYS

function GrowthFundPopupMediator:OnCreate()
    self.btnClose = self:Button('child_btn_close', Delegate.GetOrCreate(self, self.OnClickClose))
    self.textTitle = self:Text('p_text_title', I18N_KEYS.POPUP_TITLE)
    self.textDetail = self:Text('p_text_detail', I18N_KEYS.POPUP_DESC)
    self.btnGoto = self:Button('child_comp_btn_b_l', Delegate.GetOrCreate(self, self.OnClickGoto))
    self.textBtnGoto = self:Text('p_text', 'task_btn_goto')
end

function GrowthFundPopupMediator:OnOpened(param)
    self.cfgId = ModuleRefer.GrowthFundModule:GetCurOpeningGrowthFundCfgId()
    local maxLvl = #ModuleRefer.GrowthFundModule:GetRewardInfosByCfgId(self.cfgId)
    local maxSpeices = ModuleRefer.GrowthFundModule:GetTotalSpeciesByLevel(self.cfgId, maxLvl, true)
    local maxSpeicesNormal = ModuleRefer.GrowthFundModule:GetTotalSpeciesByLevel(self.cfgId, maxLvl, false)
    local spReward = ModuleRefer.GrowthFundModule:GetRewardInfosByCfgId(self.cfgId)[maxLvl]
    local spRewardName = I18N.Get(ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(spReward.adv)[2].configCell:NameKey())
    self.textDetail.text = I18N.GetWithParams(I18N_KEYS.POPUP_DESC, maxSpeicesNormal, maxSpeices)
end

function GrowthFundPopupMediator:OnClickClose()
    self:CloseSelf()
end

function GrowthFundPopupMediator:OnClickGoto()
    self:CloseSelf()
    ModuleRefer.ActivityCenterModule:GotoActivity(ActivityCenterConst.GrowthFundTabId)
end

return GrowthFundPopupMediator