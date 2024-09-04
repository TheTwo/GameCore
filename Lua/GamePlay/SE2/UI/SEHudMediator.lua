---scene:scene_se_hud
local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require('Delegate')
local SEEnvironment = require("SEEnvironment")
local ConfigRefer = require("ConfigRefer")
local EventConst = require("EventConst")

---@class SEHudMediatorParameter
---@field tid number
---@field hideExitBtn boolean
---@field noCardMode boolean
---@field hideSkillShow boolean
---@field noAutoMode boolean

---@class SEHudMediator : BaseUIMediator
local SEHudMediator = class('SEHudMediator', BaseUIMediator)
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")

function SEHudMediator:OnCreate(param)
	self._effectNode = self:GameObject("p_effect")
	self._effectEnergyRestore = self:GameObject("p_effect_energy_restore")
	self.btnExit = self:Button('p_btn_exit', Delegate.GetOrCreate(self, self.OnBtnExitClicked))
	---@type SEHudBattlePanel
	self.battlePanel = self:LuaObject("p_battle")
	self.toastPanel = self:LuaObject("p_toast")
	self.topLeftPanel = self:GameObject("p_top_left")
end

function SEHudMediator:GetEffectNode()
	return self._effectNode
end

function SEHudMediator:GetEffectEnergyRestore()
	return self._effectEnergyRestore
end

---@param param SEHudMediatorParameter
function SEHudMediator:OnShow(param)
	g_Logger.Log("SEHudMediator:OnShow")
	if not param or self._env then return end
    self._env = require ("SEEnvironment").Instance()
	self:SetupPanel(param)
end

---@param param SEHudMediatorParameter
function SEHudMediator:SetupPanel(param)
	g_Logger.Log("SEHudMediator:SetupPanel")
	self._env:SetHud(self)

	self.battlePanel:SetVisible(false)
    self._env:GetUiBattlePanel():Init(self.battlePanel, self, param.noCardMode, param.hideSkillShow, param.noAutoMode)
    self._env:GetUiToastPanel():Init(self.toastPanel)

    -- 退出按钮
    local conf = ConfigRefer.MapInstance:Find(param.tid)
    if (conf) then
        self.btnExit.gameObject:SetActive((conf.AllowExit and conf:AllowExit() == true) and not param.hideExitBtn)
    end
	g_Game.EventManager:TriggerEvent(EventConst.SE_HUD_OPENED)
end

function SEHudMediator:OnHide(param)
	if self._env then
		self._env:HideToast()
	end
	if (Utils.IsNotNull(self._effectEnergyRestore)) then
		self._effectEnergyRestore.transform:DOKill()
	end
end

function SEHudMediator:OnClose()
	if self.battlePanel then
		local cards = self.battlePanel:GetCardItems()
		if cards then
			for _, card in pairs(cards) do
				card:ResetToDefault()
			end
		end
	end
	if not self._env then return end
	local panel = self._env:GetUiBattlePanel()
	if not panel then return end
	panel:OnPanelUIClose()
	self._env = nil
end

function SEHudMediator:OnBtnExitClicked(args)
	g_Game.UIManager:CloseAllByName(UIMediatorNames.CommonConfirmPopupMediator)
	---@type CommonConfirmPopupMediatorParameter
    local dialogParam = {}
    dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel --| CommonConfirmPopupMediatorDefine.Style.ExitBtn
    dialogParam.title = I18N.Get("se_quit_title")
    local content = I18N.Get("se_quit")
    dialogParam.content = I18N.Get(content)
    dialogParam.onConfirm = function(context)
		SEEnvironment.Instance():RequestLeave(self.btnExit:GetComponent(typeof(CS.UnityEngine.RectTransform)), true)
        return true
    end
	dialogParam.onCancel = function(context)
		CS.UnityEngine.Time.timeScale = 1
		ModuleRefer.GuideModule:StopCurrentStep()
		SEEnvironment.Instance():GetInputManager():SetNoControl(true, 0.5)
		return true
	end
	SEEnvironment.Instance():GetInputManager():SetNoControl(true)
    dialogParam.forceClose = true
	g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
end

return SEHudMediator
