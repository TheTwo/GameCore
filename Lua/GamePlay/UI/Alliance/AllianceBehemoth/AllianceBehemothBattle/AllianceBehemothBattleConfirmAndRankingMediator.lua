--- scene:ui_league_behemoth_popup_ranking

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local DBEntityPath = require("DBEntityPath")
local HUDLogicPartDefine = require("HUDLogicPartDefine")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceBehemothBattleConfirmAndRankingMediatorParameter
---@field cage wds.BehemothCage
---@field mapMob wds.MapMob

---@class AllianceBehemothBattleConfirmAndRankingMediator:BaseUIMediator
---@field new fun():AllianceBehemothBattleConfirmAndRankingMediator
---@field super BaseUIMediator
local AllianceBehemothBattleConfirmAndRankingMediator = class('AllianceBehemothBattleConfirmAndRankingMediator', BaseUIMediator)

function AllianceBehemothBattleConfirmAndRankingMediator:ctor()
    AllianceBehemothBattleConfirmAndRankingMediator.super.ctor(self)
    ---@type AllianceBehemothBattleConfirmAndRankingMediatorParameter
    self._parameter = nil
    self._currentStatus = nil
    self._inWaitingBattle = false
    self._inBattle = false
end

function AllianceBehemothBattleConfirmAndRankingMediator:OnCreate(param)
    self._p_btn_fold = self:Button("p_btn_fold", Delegate.GetOrCreate(self, self.OnClickFold))
    ---@see AllianceBehemothBattleRanking
    self._p_group_ranking = self:LuaBaseComponent("p_group_ranking")
    ---@see AllianceBehemothBattleConfirm
    self._p_group_confirm = self:LuaBaseComponent("p_group_confirm")
end

---@param param AllianceBehemothBattleConfirmAndRankingMediatorParameter
function AllianceBehemothBattleConfirmAndRankingMediator:OnOpened(param)
    self._parameter = param
    self._inWaitingBattle = (param.cage ~= nil) and (param.cage.BehemothCage.Status & wds.BehemothCageStatusMask.BehemothCageStatusMaskInWaiting) ~= 0
    self._inBattle = not param.cage or (param.cage.BehemothCage.Status & wds.BehemothCageStatusMask.BehemothCageStatusMaskInBattle) ~= 0
    self:OnShowStatusChanged()
end

function AllianceBehemothBattleConfirmAndRankingMediator:OnShow(param)
    self:SetupEvents(true)
    g_Game.EventManager:TriggerEvent(EventConst.HUD_LOGIC_SHOW_HIDE_CHANGE, HUDLogicPartDefine.bossDmgRankComp, false)
    g_Game.EventManager:TriggerEvent(EventConst.GVE_RANK_POP_SHOW_HIDE, true)
end

function AllianceBehemothBattleConfirmAndRankingMediator:OnHide(param)
    self:SetupEvents(false)
    g_Game.EventManager:TriggerEvent(EventConst.HUD_LOGIC_SHOW_HIDE_CHANGE, HUDLogicPartDefine.bossDmgRankComp, true)
    g_Game.EventManager:TriggerEvent(EventConst.GVE_RANK_POP_SHOW_HIDE, false)
end

function AllianceBehemothBattleConfirmAndRankingMediator:OnClickFold()
    self:CloseSelf()
end

function AllianceBehemothBattleConfirmAndRankingMediator:SetupEvents(add)
    if not self._eventsAdd and add then
        self._eventsAdd = true
        g_Game.EventManager:AddListener(EventConst.MAP_FOCUS_BOSS_CHANGED, Delegate.GetOrCreate(self, self.OnMapFocusBossChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.BehemothCage.BehemothCage.Status.MsgPath, Delegate.GetOrCreate(self, self.OnBehemothCageStatusChanged))
    elseif self._eventsAdd and not add then
        self._eventsAdd = false
        g_Game.EventManager:RemoveListener(EventConst.MAP_FOCUS_BOSS_CHANGED, Delegate.GetOrCreate(self, self.OnMapFocusBossChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.BehemothCage.BehemothCage.Status.MsgPath, Delegate.GetOrCreate(self, self.OnBehemothCageStatusChanged))
    end
end

function AllianceBehemothBattleConfirmAndRankingMediator:OnShowStatusChanged()
    self._p_group_ranking:SetVisible(self._inBattle)
    self._p_group_confirm:SetVisible(self._inWaitingBattle)
    if self._inWaitingBattle then
        self._p_group_confirm:FeedData(self._parameter.cage)
    elseif self._inBattle then
        self._p_group_ranking:FeedData(self._parameter.mapMob)
    end
end

---@param entity wds.BehemothCage
function AllianceBehemothBattleConfirmAndRankingMediator:OnBehemothCageStatusChanged(entity, changed)
    if not entity or not self._parameter or not self._parameter.cage or self._parameter.cage.ID ~= entity.ID then return end
    local inWaiting = (entity.BehemothCage.Status & wds.BehemothCageStatusMask.BehemothCageStatusMaskInWaiting) ~= 0
    if inWaiting ~= self._inWaitingBattle then
        self._inWaitingBattle = inWaiting
        self:OnShowStatusChanged()
    end
end

---@param focusBoss TroopCtrl
function AllianceBehemothBattleConfirmAndRankingMediator:OnMapFocusBossChanged(focusBoss)
    if not focusBoss then
        self:CloseSelf()
    end
end

return AllianceBehemothBattleConfirmAndRankingMediator