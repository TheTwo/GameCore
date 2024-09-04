local LayoutRebuilder = CS.UnityEngine.UI.LayoutRebuilder
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local HUDWarWarningComponent = require("HUDWarWarningComponent")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local KingdomMapUtils = require("KingdomMapUtils")

local BaseUIComponent = require("BaseUIComponent")

---@class HUDBottomRightButtonsAllianceGroup:BaseUIComponent
---@field new fun():HUDBottomRightButtonsAllianceGroup
---@field super BaseUIComponent
local HUDBottomRightButtonsAllianceGroup = class('HUDBottomRightButtonsAllianceGroup', BaseUIComponent)

function HUDBottomRightButtonsAllianceGroup:ctor()
    BaseUIComponent.ctor(self)
    self._eventAdd = false
    self._expended = false
    self._childCount = 0
    self._foldCount = 2
end

function HUDBottomRightButtonsAllianceGroup:OnCreate(param)
    self._selfTrans = self:RectTransform("")
    ---@type CS.UnityEngine.UI.GridLayoutGroup
    self._p_layout = self:BindComponent("p_layout", typeof(CS.UnityEngine.UI.GridLayoutGroup))
    ---@type HUDAllianceVillage
    self._p_group_town = self:LuaObject("p_group_town")
    self._childCount = self._childCount + 1
    ---@type HUDAllianceTeam
    self._p_group_league_team = self:LuaObject("p_group_league_team")
    self._childCount = self._childCount + 1
    ---@type HUDAllianceActivityBattle
    self._p_group_league_boss = self:LuaObject("p_group_league_boss")
    self._childCount = self._childCount + 1
    self._p_btn_injured = self:Button("p_btn_injured", Delegate.GetOrCreate(self, self.OnInjuredClick))
    self._childCount = self._childCount + 1
end

function HUDBottomRightButtonsAllianceGroup:OnShow(param)
    self:SetupEvent(true)
    self:OnHudMediatorBlackboardChanged(self:GetParentBaseUIMediator(), "HUDTroopListExtended")
    self:OnUnderAttackWarning()
end

function HUDBottomRightButtonsAllianceGroup:OnHide(param)
    self:SetupEvent(false)
end

function HUDBottomRightButtonsAllianceGroup:OnClose(param)
    self:SetupEvent(false)
end

function HUDBottomRightButtonsAllianceGroup:SetupEvent(add)
    if not self._eventAdd and add then
        self._eventAdd = true
        g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecTick))
        g_Game.EventManager:AddListener(EventConst.HUD_BLACKBOARD_CHANGED, Delegate.GetOrCreate(self, self.OnHudMediatorBlackboardChanged))
        g_Game.EventManager:AddListener(EventConst.SLG_UNDER_ATTACK_WARNING, Delegate.GetOrCreate(self, self.OnUnderAttackWarning))
    elseif self._eventAdd and not add then
       self._eventAdd = false
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecTick))
        g_Game.EventManager:RemoveListener(EventConst.HUD_BLACKBOARD_CHANGED, Delegate.GetOrCreate(self, self.OnHudMediatorBlackboardChanged))
        g_Game.EventManager:RemoveListener(EventConst.SLG_UNDER_ATTACK_WARNING, Delegate.GetOrCreate(self, self.OnUnderAttackWarning))
    end
end

function HUDBottomRightButtonsAllianceGroup:SecTick(dt)
    self:OnAllianceGroupNeedRefresh(self._expended)
end

function HUDBottomRightButtonsAllianceGroup:OnAllianceGroupNeedRefresh(expended)
    self._expended = expended
    if not self._selfTrans.gameObject.activeInHierarchy then
        return
    end
    LayoutRebuilder.ForceRebuildLayoutImmediate(self._selfTrans)
    local size = self._selfTrans.sizeDelta
    local targetSize = (self._expended and self._childCount or self._foldCount) * self._p_layout.cellSize.x
    local sizeX = math.min(targetSize, self._p_layout.preferredWidth)
    if math.abs(sizeX - size.x) < 0.1 then
        return
    end
    size.x = sizeX
    self._selfTrans.sizeDelta = size
end

---@param mediator HUDMediator
function HUDBottomRightButtonsAllianceGroup:OnHudMediatorBlackboardChanged(hudMediator, key)
    if not hudMediator or not hudMediator.ReadBlackboard or key ~= "HUDTroopListExtended" then return end
    local isTroopListExpended = hudMediator:ReadBlackboard("HUDTroopListExtended") or false
    if isTroopListExpended then
        local p = self._selfTrans.anchoredPosition
        p.x = -120
        self._selfTrans.anchoredPosition = p
    else
        local p = self._selfTrans.anchoredPosition
        p.x = 0
        self._selfTrans.anchoredPosition = p
    end
end

function HUDBottomRightButtonsAllianceGroup:OnUnderAttackWarning()
    self._p_btn_injured:SetVisible(HUDWarWarningComponent.UnderAttack)
end

function HUDBottomRightButtonsAllianceGroup:OnInjuredClick()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("animal_work_interface_desc20"))

    if not ModuleRefer.SlgModule:IsInCity() then
        KingdomMapUtils.GetKingdomScene():FocusToMyCityTile()
    end
end

return HUDBottomRightButtonsAllianceGroup