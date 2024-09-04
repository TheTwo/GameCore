local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local GotoUtils = require('GotoUtils')
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local UIMediatorNames = require('UIMediatorNames')
---@class UIGveHudMediator : BaseUIMediator
---@field compBattle GveHudBattlePanel
---@field module GveModule
local UIGveHudMediator = class('UIGveHudMediator', BaseUIMediator)

function UIGveHudMediator:ctor()
    self.module = ModuleRefer.GveModule
end

function UIGveHudMediator:OnCreate()    
    self.btnExit = self:Button('p_btn_exit', Delegate.GetOrCreate(self, self.OnBtnExitClicked))
    self.compBattle = self:LuaObject('p_battle')
    ---@type GveTroopHint
    self.troopHint = self:LuaObject('p_troop_position_hint')
    self.compBattle:SetVisible(false)
end


function UIGveHudMediator:OnShow(param)   
    g_Game.EventManager:AddListener(EventConst.GVE_BATTLEFIELD_STATE,Delegate.GetOrCreate(self,self.OnBattleFieldState))
    self.compBattle:SetVisible(true)

    local curState,curParam = self.module:GetCurrentBattleFieldState()

    if curState then
        self:OnBattleFieldState(curState,curParam)
    else
        self.compBattle:PanelState_Prepare({})
    end
end

function UIGveHudMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.GVE_BATTLEFIELD_STATE,Delegate.GetOrCreate(self,self.OnBattleFieldState))
end

function UIGveHudMediator:OnOpened(param)
end

function UIGveHudMediator:OnClose(param)
end



function UIGveHudMediator:OnBtnExitClicked(args)
    local showConfirm = self:IsShowExitConfirm()
    if not showConfirm then
        self.module:Exit()
        return
    end
    local popupParameter = {}
    popupParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel |  CommonConfirmPopupMediatorDefine.Style.Toggle
    popupParameter.content = I18N.Get("alliance_battle_confirm1")
    popupParameter.confirmLabel = I18N.Get("confirm")
    popupParameter.cancelLabel = I18N.Get("cancle")
    popupParameter.toggleDescribe = I18N.Get('alliance_battle_confirm2')
    popupParameter.onConfirm = function()
        self.module:Exit()
        if not showConfirm then
            self:NotShowExitConfirmToday()
        end
        return true
    end    
    popupParameter.toggle = true
    showConfirm = false
    popupParameter.toggleClick = function(context,checked)
        showConfirm = not checked
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, popupParameter)    
end


function UIGveHudMediator:NotShowExitConfirmToday()
    local today = os.date('%Y:%j')
    g_Game.PlayerPrefsEx:SetStringByUid('GveExitConfirmKey',today)
end

function UIGveHudMediator:IsShowExitConfirm()
    local savedToday = g_Game.PlayerPrefsEx:GetStringByUid('GveExitConfirmKey')
    local today = os.date('%Y:%j')
    return savedToday ~= today
end

function UIGveHudMediator:PanelState_Prepare(param)
    self.compBattle:PanelState_Prepare(param)
    self.troopHint:SetVisible(false)
end
function UIGveHudMediator:PanelState_TroopSelection(param)
    self.compBattle:PanelState_TroopSelection(param)
    self.troopHint:SetVisible(false)
end
function UIGveHudMediator:PanelState_Battling(param)
    self.compBattle:PanelState_Battling(param)
    self.troopHint:SetVisible(true)
end
function UIGveHudMediator:PanelState_DeadWait(param)
    self.compBattle:PanelState_DeadWait(param)
    self.troopHint:SetVisible(false)
end
function UIGveHudMediator:PanelState_OB(param)
    self.compBattle:PanelState_OB(param)
    self.troopHint:SetVisible(false)
end

function UIGveHudMediator:PanelState_Watching(param)
    self.compBattle:PanelState_Watching(param)
    self.troopHint:SetVisible(false)
end

UIGveHudMediator.stateChanged ={
    [ModuleRefer.GveModule.BattleFieldState.Ready] = UIGveHudMediator.PanelState_Prepare,
    [ModuleRefer.GveModule.BattleFieldState.Select] = UIGveHudMediator.PanelState_TroopSelection,
    [ModuleRefer.GveModule.BattleFieldState.Battling] = UIGveHudMediator.PanelState_Battling,
    [ModuleRefer.GveModule.BattleFieldState.DeadCd] = UIGveHudMediator.PanelState_DeadWait,
    [ModuleRefer.GveModule.BattleFieldState.OB] = UIGveHudMediator.PanelState_OB,
    [ModuleRefer.GveModule.BattleFieldState.Watching] = UIGveHudMediator.PanelState_Watching,
}
---@param state number @GveModule.BattleFieldState
function UIGveHudMediator:OnBattleFieldState(state,param)    
    if self.module:IsInWatchState() then
        state = ModuleRefer.GveModule.BattleFieldState.Watching
    end
    local changer = UIGveHudMediator.stateChanged[state]
    if changer then
        self.compBattle:SetState(state)
        changer(self,param)
    end
    self.troopHint:Init()
end
return UIGveHudMediator
