local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local DBEntityPath = require("DBEntityPath")
local OnChangeHelper = require("OnChangeHelper")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local UIHelper = require("UIHelper")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local AllianceBehemothBattleConfirmBtnFuncProvider = require("AllianceBehemothBattleConfirmBtnFuncProvider")
local DisableType = AllianceBehemothBattleConfirmBtnFuncProvider.DisableType

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceBehemothBattleConfirm:BaseUIComponent
---@field new fun():AllianceBehemothBattleConfirm
---@field super BaseUIComponent
local AllianceBehemothBattleConfirm = class('AllianceBehemothBattleConfirm', BaseUIComponent)

function AllianceBehemothBattleConfirm:ctor()
    AllianceBehemothBattleConfirm.super.ctor(self)
    ---@type AllianceBehemothBattleConfirmCellData[]
    self._tableCells = {}
end

function AllianceBehemothBattleConfirm:OnCreate(param)
    self._p_table_confirm = self:TableViewPro("p_table_confirm")
    self._child_comp_btn_b_l = self:Button("child_comp_btn_b_l", Delegate.GetOrCreate(self, self.OnClickButtonReady))
    self._p_text = self:Text("p_text")
    self._p_text_status = self:Text("p_text_status")
    self._p_text_num = self:Text("p_text_num")
    self._p_text_title_player = self:Text("p_text_title_player", "alliance_behemoth_title_playername")
    self._p_text_title_output = self:Text("p_text_title_power", "*状态")
end

---@param data wds.BehemothCage
function AllianceBehemothBattleConfirm:OnFeedData(data)
    self._cage = data
    self._btnDisable = false
    self._hasAuthority = ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.StartBehemothWar)
    self._btnFuncProvider = AllianceBehemothBattleConfirmBtnFuncProvider.new(self._child_comp_btn_b_l, self._cage)
    if self._hasAuthority then
        self.enableType = AllianceBehemothBattleConfirmBtnFuncProvider.EnableType.StartBattle
        self._p_text.text = I18N.Get("alliance_behemoth_title_openwar")
    else
        self.enableType = AllianceBehemothBattleConfirmBtnFuncProvider.EnableType.ReadyBattle
        local playerId = ModuleRefer.PlayerModule:GetPlayerId()
        self._p_text.text = I18N.Get("alliance_behemoth_title_ready")
        for _, v in pairs(self._cage.VillageWar.PlayerPreparation) do
            if v.Ready and v.PlayerId == playerId then
                self.disableType = DisableType.ReadyPlayer
                break
            end
        end
    end
    self._btnDisable = self.disableType ~= nil
    UIHelper.SetGray(self._child_comp_btn_b_l.gameObject, self._btnDisable)
    self:GeneratePrepareInfoMap()
    self:SetupReadyStatus()
end

function AllianceBehemothBattleConfirm:OnShow(param)
    self:SetupEvents(true)
end

function AllianceBehemothBattleConfirm:OnHide(param)
    self:SetupEvents(false)
end

function AllianceBehemothBattleConfirm:OnClose(param)
    self:SetupEvents(false)
end

function AllianceBehemothBattleConfirm:OnClickButtonReady()
    if self._btnDisable then
        self._btnFuncProvider:OnBtnDisableClick(self.disableType)
    else
        self._btnFuncProvider:OnBtnEnableClick(self.enableType)
    end
end

function AllianceBehemothBattleConfirm:SetupEvents(add)
    if not self._eventsAdd and add then
        self._eventsAdd = true
        g_Game.DatabaseManager:AddChanged(DBEntityPath.BehemothCage.VillageWar.PlayerPreparation.MsgPath, Delegate.GetOrCreate(self, self.OnPrepareInfoChanged))
    elseif self._eventsAdd and not add then
        self._eventsAdd = false
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.BehemothCage.VillageWar.PlayerPreparation.MsgPath, Delegate.GetOrCreate(self, self.OnPrepareInfoChanged))
    end
end

function AllianceBehemothBattleConfirm:SetupReadyStatus()
    local readyCount = 0
    local totalCount = 0
    local selfInRange = false
    local playerId = ModuleRefer.PlayerModule:GetPlayerId()
    for _, v in pairs(self._cage.VillageWar.PlayerPreparation) do
        if v.PlayerId == playerId and self._hasAuthority then
            readyCount = readyCount + 1
        elseif v.Ready then
            readyCount = readyCount + 1
        end
        if v.PlayerId == playerId then
            selfInRange = true
        end
        totalCount = totalCount + 1
    end
    if not selfInRange and not self.disableType then
        self.disableType = DisableType.NotInRange
    end
    if self._hasAuthority then
        if totalCount == 0 then
            self.disableType = DisableType.NotInRange
        end
    end
    self._btnDisable = self.disableType ~= nil
    UIHelper.SetGray(self._child_comp_btn_b_l.gameObject, self._btnDisable)
    self._p_text_status.text = I18N.Get("alliance_behemoth_title_readied") .. (" %s"):format(tostring(readyCount))
    self._p_text_num.text = I18N.Get("alliance_behemoth_title_number") .. (" %s"):format(tostring(totalCount))
end

---@param entity wds.BehemothCage
function AllianceBehemothBattleConfirm:OnPrepareInfoChanged(entity, changedData)
   if not entity or not self._cage or entity.ID ~= self._cage.ID then return end
    local AllianceModule = ModuleRefer.AllianceModule
    local add,remove,change = OnChangeHelper.GenerateMapFieldChangeMap(changedData, wds.PlayerPreparationInfo)
    local oldLength = #self._tableCells
    local cellCount = #self._tableCells
    if remove then
        for _, v in pairs(remove) do
            local sentinel = {}
            for j = #self._tableCells, 1, -1 do
                ---@type AllianceBehemothBattleConfirmCellData
                local cell = {}
                cell.checked = self._tableCells[j].checked
                cell.memberInfo = self._tableCells[j].memberInfo
                self._tableCells[j].checked = sentinel.checked
                self._tableCells[j].memberInfo = sentinel.memberInfo
                self._tableCells[j].index = self._tableCells[j].index - 1
                sentinel = cell
                if cell.memberInfo.PlayerID == v.PlayerId then
                    cellCount = cellCount - 1
                    break
                end
            end
        end
    end
    if change then
        for _, v in pairs(change) do
            for j = #self._tableCells, 1, -1 do
                local cell = self._tableCells[j]
                if cell.memberInfo.PlayerID == v[2].PlayerId then
                    cell.memberInfo = AllianceModule:QueryMyAllianceMemberData(v[2].FacebookId)
                    cell.checked = v[2].Ready
                    break
                end
            end
        end
    end
    if add then
        local myPlayerId = ModuleRefer.PlayerModule:GetPlayerId()
        for _, v in pairs(add) do
            ---@type AllianceBehemothBattleConfirmCellData
            local cell = {}
            if v.PlayerId == myPlayerId and self._hasAuthority then
                cell.memberInfo = AllianceModule:QueryMyAllianceMemberData(v.FacebookId)
                cell.checked = true
                if not v.Ready then
                    self._btnFuncProvider:OnBtnEnableClick(AllianceBehemothBattleConfirmBtnFuncProvider.EnableType.ReadyBattle)
                end
            else
                cell.memberInfo = AllianceModule:QueryMyAllianceMemberData(v.FacebookId)
                cell.checked = v.Ready
            end
            cell.index = #self._tableCells + 1
            table.insert(self._tableCells, cell)
            cellCount = cellCount + 1
        end
    end
    for i = oldLength, cellCount + 1, -1 do
        self._tableCells[i] = nil
        self._p_table_confirm:RemAt(i - 1)
    end
    for i = oldLength + 1, cellCount do
        self._p_table_confirm:AppendData(self._tableCells[i])
    end
    self._p_table_confirm:UpdateAllData()
    self.disableType = nil
    if not self._hasAuthority then
        local playerId = ModuleRefer.PlayerModule:GetPlayerId()
        for _, v in pairs(self._cage.VillageWar.PlayerPreparation) do
            if v.Ready and v.PlayerId == playerId then
                self.disableType = DisableType.ReadyPlayer
                break
            end
        end
    end
    self._btnDisable = self.disableType ~= nil
    UIHelper.SetGray(self._child_comp_btn_b_l.gameObject, self._btnDisable)
    self:SetupReadyStatus()
end

function AllianceBehemothBattleConfirm:GeneratePrepareInfoMap()
    table.clear(self._tableCells)
    self._p_table_confirm:Clear()
    local prepareInfo = self._cage.VillageWar.PlayerPreparation
    local myPlayerId = ModuleRefer.PlayerModule:GetPlayerId()
    local AllianceModule = ModuleRefer.AllianceModule
    local index = 1
    for _, v in pairs(prepareInfo) do
        ---@type AllianceBehemothBattleConfirmCellData
        local cell = {}
        if v.PlayerId == myPlayerId and self._hasAuthority then
            cell.memberInfo = AllianceModule:QueryMyAllianceMemberData(v.FacebookId)
            cell.checked = true
        else
            cell.memberInfo = AllianceModule:QueryMyAllianceMemberData(v.FacebookId)
            cell.checked = v.Ready
        end
        cell.index = index
        index = index + 1
        table.insert(self._tableCells, cell)
    end
    for _, v in ipairs(self._tableCells) do
        self._p_table_confirm:AppendData(v)
    end
end

return AllianceBehemothBattleConfirm