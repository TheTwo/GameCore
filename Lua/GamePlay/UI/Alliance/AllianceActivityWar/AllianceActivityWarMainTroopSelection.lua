local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local ConfigRefer = require("ConfigRefer")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceActivityWarMainTroopSelection:BaseUIComponent
---@field new fun():AllianceActivityWarMainTroopSelection
---@field super BaseUIComponent
local AllianceActivityWarMainTroopSelection = class('AllianceActivityWarMainTroopSelection', BaseUIComponent)

function AllianceActivityWarMainTroopSelection:ctor()
    self._slotCount = 2
    ---@type AllianceActivityWarMainTroopCellData[]
    self._tableData = {}
    ---@type table<number, boolean>
    self._inListTroopPresetId = {}
end

function AllianceActivityWarMainTroopSelection:OnCreate(param)
    self._p_text_troop = self:Text("p_text_troop")
    self._p_text_troop_num = self:Text("p_text_troop_num")
    self._p_btn_info = self:Button("p_btn_info", Delegate.GetOrCreate(self, self.OnClickBtnInfo))
    self._p_text_info = self:Text("p_text_info", "alliance_battle_button2")
    self._p_text_troop_my = self:Text("p_text_troop_my", "alliance_battle_hud10")
    self._p_table_troop = self:TableViewPro("p_table_troop")
end

---@param data wds.AllianceActivityBattleInfo
function AllianceActivityWarMainTroopSelection:OnFeedData(data)
    self._data = data
    local config = ConfigRefer.AllianceBattle:Find(data.CfgId)
    local allowEdit
    if data.allowEdit ~= nil then
        allowEdit = data.allowEdit
    else
        allowEdit = data.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated
    end
    local slotCount = config:MaxTroopCountPerMember()
    self._slotCount = slotCount - 1
    local myPlayerId = ModuleRefer.PlayerModule.playerId
    ---@type wds.AllianceBattleMemberInfo
    local myMemberData = nil
    local memberCount = 0
    if data.Members then
        for _, v in pairs(data.Members) do
            if v.PlayerId == myPlayerId then
                myMemberData = v
            end
            memberCount = memberCount + 1
        end
    end
    local addFunc = Delegate.GetOrCreate(self, self.OnClickAdd)
    
    self._p_text_troop.text = I18N.GetWithParams("alliance_battle_hud9", memberCount, config:MaxJoinMemberCount())
    self._p_table_troop:Clear()
    table.clear(self._inListTroopPresetId)
    table.clear(self._tableData)
    local cellCount = 0
    if myMemberData and myMemberData.Troops then
        for i, v in ipairs(myMemberData.Troops) do
            ---@type AllianceActivityWarMainTroopCellData
            local cellData = {}
            cellData.battleId = data.ID
            cellData.queueIndex = i
            cellData.troopInfo = v
            cellData.allowEdit = allowEdit
            cellCount = cellCount + 1
            self._p_table_troop:AppendData(cellData)
            table.insert(self._tableData, cellData)
            self._inListTroopPresetId[i] = true
        end
    end
    if allowEdit then
        for i = cellCount, self._slotCount do
            ---@type AllianceActivityWarMainTroopCellData
            local cellData = {}
            cellData.battleId = data.ID
            cellData.queueIndex = i
            cellData.onClickAdd = addFunc
            table.insert(self._tableData, cellData)
            self._p_table_troop:AppendData(cellData)
        end
    end
end

---@param trans CS.UnityEngine.Transform
function AllianceActivityWarMainTroopSelection:OnClickAdd(trans)
    local troopPresets = ModuleRefer.PlayerModule:GetCastle().TroopPresets.Presets
    local selfId = ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID
    local hasIdleButZeroHpTroop = false
    local selectIndex
    for index, v in ipairs(troopPresets) do
        if v.Status == wds.TroopPresetStatus.TroopPresetIdle and not self._inListTroopPresetId[index] and not table.isNilOrZeroNums(v.Heroes) then
            local troopHp = 0
            for _, hero in pairs(v.Heroes) do
                troopHp = troopHp + hero.HP
            end
            if troopHp <= 0 then
                if not selectIndex then
                    selectIndex = index
                end
                hasIdleButZeroHpTroop = true
                goto OnClickAdd_continue
            end
            if self._data.Members and self._data.Members[selfId] then
                ModuleRefer.AllianceModule:ModifySignUpTroopPresetParameter(trans, self._data.ID, index -1, false)
            else
                ModuleRefer.AllianceModule:SignUpAllianceActivityBattle(trans, self._data.ID, {index - 1})
            end
            return
        end
        ::OnClickAdd_continue::
    end
    if hasIdleButZeroHpTroop then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("gvewarning_test3"))
    end
    if selectIndex then
        ---@type UITroopMediatorParam
        local param = {}
        param.selectedTroopIndex = selectIndex
        g_Game.UIManager:Open(UIMediatorNames.UITroopMediator, param)
    else
        g_Game.UIManager:Open(UIMediatorNames.UITroopMediator)
    end
end

function AllianceActivityWarMainTroopSelection:OnClickBtnInfo()
    g_Game.UIManager:Open(UIMediatorNames.AllianceActivityWarTroopListPopupMediator, self._data)
end

return AllianceActivityWarMainTroopSelection
