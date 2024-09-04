local BaseUIComponent = require("BaseUIComponent")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ReinforceUtils = require("ReinforceUtils")
local EventConst = require("EventConst")
local UIMediatorNames = require("UIMediatorNames")
local NewFunctionUnlockIdDefine = require("NewFunctionUnlockIdDefine")
local I18N = require("I18N")

---@class WallReinforcePage : BaseUIComponent
local WallReinforcePage = class("WallReinforcePage", BaseUIComponent)

function WallReinforcePage:OnCreate()
    self.p_table_troop = self:TableViewPro("p_table_ally")
    self.p_status_empty = self:Transform("p_status_empty")
    self.p_text_empty = self:Text("p_text_empty", "base_defence_no_allytroop")
    self.p_status_join = self:Transform("p_status_join")
    self.p_text_join = self:Text("p_text_join", "bw_info_base_no_alliance")
    self.p_text = self:Text("p_text", "alliance_worldevent_big_button_enter")
    self.p_btn_join = self:Button("p_btn_join", Delegate.GetOrCreate(self, self.OnJoinAlliance))
end

function WallReinforcePage:OnOpened()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Army.MsgPath, Delegate.GetOrCreate(self, self.OnArmyChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_JOINED, Delegate.GetOrCreate(self, self.OnAllianceJoined))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnAllianceLeaved))
    self:InitializeListData()
    self:RefreshUI()
end

function WallReinforcePage:OnClose()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Army.MsgPath, Delegate.GetOrCreate(self, self.OnArmyChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_JOINED, Delegate.GetOrCreate(self, self.OnAllianceJoined))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnAllianceLeaved))
end

---@param data wds.CastleBrief
function WallReinforcePage:OnArmyChanged(data, change)
    local castle = ModuleRefer.PlayerModule:GetCastle()
    if data.ID == castle.ID then
        self:HandleListDataChange(change)
        self:RefreshUI()
    end
end

function WallReinforcePage:InitializeListData()
    ---@type table<number, ReinforceListData>
    self.troopDict = {}

    ---@type ReinforceListData[]
    self.troopList = {}

    ---@type wds.CastleBrief
    local castle = ModuleRefer.PlayerModule:GetCastle()
    local playerId = ModuleRefer.PlayerModule:GetPlayerId()

    for guid, member in pairs(castle.Army.PlayerTroopIDs) do
        if member.PlayerId ~= playerId then
            local data = ReinforceUtils.CreateListData(guid, member, true)
            self.troopDict[guid] = data
            table.insert(self.troopList, data)
        end
    end

    for guid, member in pairs(castle.Army.PlayerOnRoadTroopIDs) do
        if member.PlayerId ~= playerId then
            local data = ReinforceUtils.CreateListData(guid, member, false)
            self.troopDict[guid] = data
            table.insert(self.troopList, data)
        end
    end
end

function WallReinforcePage:RefreshUI()
    local castle = ModuleRefer.PlayerModule:GetCastle()
    local troopCount = castle.Army.PlayerTroopIDs:Count()
    local onRoadCount = castle.Army.PlayerOnRoadTroopIDs:Count()
    local totalCount = troopCount + onRoadCount
    local hasTroops = totalCount > 0
    local inAlliance = ModuleRefer.AllianceModule:IsInAlliance()

    self.p_table_troop:SetVisible(inAlliance and hasTroops)
    self.p_status_empty:SetVisible(inAlliance and not hasTroops)
    self.p_status_join:SetVisible(not inAlliance)

    self:UpdateList()
end

function WallReinforcePage:UpdateList()
    local onFold = Delegate.GetOrCreate(self, self.OnFold)
    self.p_table_troop:Clear(false, false)

    table.sort(self.troopList, function(x, y) return x.sortKey < y.sortKey end)

    for _, data in ipairs(self.troopList) do
        data.onFold = onFold
        self.p_table_troop:AppendData(data, 0)
        if data.fold == 0 then
            self.p_table_troop:AppendData({data = data}, 1)
        end
    end
end

---@param data ReinforceListData
function WallReinforcePage:OnFold(data)
    local index = self.p_table_troop:GetDataIndex(data)
    if data.fold == 0 then
        self.p_table_troop:InsertData(index + 1, {data = data}, 1)
    else
        self.p_table_troop:RemAt(index + 1)
    end
end

function WallReinforcePage:OnJoinAlliance()
    if ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NewFunctionUnlockIdDefine.Global_alliance) then
        g_Game.UIManager:CloseAllByName(UIMediatorNames.DefenceMediator)
        g_Game.UIManager:Open(UIMediatorNames.AllianceInitialMediator)
    else
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("city_competition_unlock_alliance"))
    end
end

function WallReinforcePage:OnAllianceJoined()
    self:RefreshUI()
end

function WallReinforcePage:OnAllianceLeaved()
    self:RefreshUI()
end

function WallReinforcePage:HandleListDataChange(change)
    if change == nil then
        return
    end

    local playerId = ModuleRefer.PlayerModule:GetPlayerId()

    if change.PlayerTroopIDs then
        if change.PlayerTroopIDs.Add then
            for guid, member in pairs(change.PlayerTroopIDs.Add) do
                if member.PlayerId ~= playerId then
                    local data = self.troopDict[guid]
                    if data then
                        data.arrived = true
                    else
                        data = ReinforceUtils.CreateListData(guid, member, true)
                        self.troopDict[guid] = data
                        table.insert(self.troopList, data)
                    end
                end
            end
        end

        if change.PlayerTroopIDs.Remove then
            for guid, member in pairs(change.PlayerTroopIDs.Remove) do
                if member.PlayerId ~= playerId then
                    if not ReinforceUtils.DoesChangeFieldContain(guid, change.PlayerTroopIDs, "Add") and
                    not ReinforceUtils.DoesChangeFieldContain(guid, change.PlayerOnRoadTroopIDs, "Add")
                    then
                        local data = self.troopDict[guid]
                        if data then
                            self.troopDict[guid] = nil
                            table.removebyvalue(self.troopList, data)
                        end
                    end
                end
            end
        end
    end

    if change.PlayerOnRoadTroopIDs then
        if change.PlayerOnRoadTroopIDs.Add then
            for guid, member in pairs(change.PlayerOnRoadTroopIDs.Add) do
                if member.PlayerId ~= playerId then
                    local data = self.troopDict[guid]
                    if data then
                        data.arrived = false
                    else
                        data = ReinforceUtils.CreateListData(guid, member, false)
                        self.troopDict[guid] = data
                        table.insert(self.troopList, data)
                    end
                end
            end
        end

        if change.PlayerOnRoadTroopIDs.Remove then
            for guid, member in pairs(change.PlayerOnRoadTroopIDs.Remove) do
                if member.PlayerId ~= playerId then
                    if not ReinforceUtils.DoesChangeFieldContain(guid, change.PlayerTroopIDs, "Add") and
                    not ReinforceUtils.DoesChangeFieldContain(guid, change.PlayerOnRoadTroopIDs, "Add")
                    then
                        local data = self.troopDict[guid]
                        if data then
                            self.troopDict[guid] = nil
                            table.removebyvalue(self.troopList, data)
                        end
                    end
                end
            end
        end
    end

    for _, data in pairs(self.troopList) do
        data.sortKey = ReinforceUtils.MakeSortKey(data.member.Index, data.arrived)
    end
end

return WallReinforcePage