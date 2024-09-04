local AllianceActivityWarMainTroopSelection = require("AllianceActivityWarMainTroopSelection")
local ActivityAllianceBossConst = require("ActivityAllianceBossConst")
local ActivityAllianceBossRegisterStateHelper = require("ActivityAllianceBossRegisterStateHelper")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require("ModuleRefer")
local Utils = require("Utils")
local I18N = require("I18N")
---@class ActivityAllianceBossRegisterTroopSelect : BaseUIComponent
local ActivityAllianceBossRegisterTroopSelect = class("ActivityAllianceBossRegisterTroopSelect", AllianceActivityWarMainTroopSelection)

---@class ActivityAllianceBossRegisterTroopSelectParam
---@field battleData wds.AllianceActivityBattleInfo
---@field uiState number
---@field uiRole number

local I18N_KEY = ActivityAllianceBossConst.I18N_KEY

local BEHAVIOR = {
    ADD = 1,
    EDIT = 2,
}

function ActivityAllianceBossRegisterTroopSelect:OnCreate()
    self.super.OnCreate(self)
    self.textLabelTroops = self:Text('p_text_troops_add', I18N_KEY.LABEL_TROOPS)
end

---@param param ActivityAllianceBossRegisterTroopSelectParam
function ActivityAllianceBossRegisterTroopSelect:OnFeedData(param)
    local battleData = {}
    Utils.CopyTable(param.battleData, battleData)
    battleData.allowEdit = (param.uiState == ActivityAllianceBossConst.BATTLE_STATE.REGISTER)
    -- battleData.allowEdit = false
    self.super.OnFeedData(self, battleData)
    self.battleData = param.battleData
    self.uiState = param.uiState
    self.uiRole = param.uiRole
    if ActivityAllianceBossRegisterStateHelper.IsRegisteredTroop(self.battleData.CfgId) then
        self.textLabelTroops.text = I18N.Get("alliance_behemoth_challenge_state13")
    else
        self.textLabelTroops.text = I18N.Get(I18N_KEY.LABEL_TROOPS)
    end
end

function ActivityAllianceBossRegisterTroopSelect:OnClickAdd(trans)
    self.trans = trans
    if ActivityAllianceBossConst.ROLE.NOT_PARTICIPATED == self.uiRole then
        ModuleRefer.ToastModule:AddSimpleToast(I18N_KEY.TOAST_NO_AUTH)
        return
    end
    ---@type HUDSelectTroopListData
    local troopSelectParam = {}
    troopSelectParam.overrideItemClickGoFunc = function(data)
        self:OnClickGoto(data)
    end
    self.behavior = BEHAVIOR.ADD
    require("HUDTroopUtils").StartMarch(troopSelectParam)
end

---@param data HUDSelectTroopListItemData
function ActivityAllianceBossRegisterTroopSelect:OnClickGoto(data)
    local queueIndex = data.index
    if self.behavior == BEHAVIOR.ADD then
        if not self._inListTroopPresetId[queueIndex] then
            ModuleRefer.AllianceModule:SignUpAllianceActivityBattle(self.trans, self.battleData.ID, {queueIndex - 1})
        end
    elseif self.behavior == BEHAVIOR.EDIT then

    end
end

function ActivityAllianceBossRegisterTroopSelect:OnClickBtnInfo()
    ---@type ActivityAllianceBossTroopListMediatorParam
    local data = {}
    data.battleData = self.battleData
    data.uiState = self.uiState
    g_Game.UIManager:Open(UIMediatorNames.ActivityAllianceBossTroopListMediator, data)
end

return ActivityAllianceBossRegisterTroopSelect