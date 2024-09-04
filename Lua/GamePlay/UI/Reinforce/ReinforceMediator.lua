---scene: scene_league_popup_troop_help

local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local MailUtils = require("MailUtils")
local ConfigRefer = require("ConfigRefer")
local KingdomTouchInfoOperation = require("KingdomTouchInfoOperation")
local DBEntityPath = require("DBEntityPath")
local NumberFormatter = require("NumberFormatter")
local I18N = require("I18N")
local ReinforceUtils = require("ReinforceUtils")

---@class ReinforceMediator : BaseUIMediator
local ReinforceMediator = class("ReinforceMediator", BaseUIMediator)

function ReinforceMediator:OnCreate()
    self.p_text_title = self:Text("p_text_title", "base_defence_reinforce")

    ---@type PlayerInfoComponent
    self.child_ui_head_master_player = self:LuaObject("child_ui_head_master_player")
    self.p_text_master_player_name = self:Text("p_text_master_player_name")
    self.p_text_master_power = self:Text("p_text_master_power")
    self.p_text_troop_number = self:Text("p_text_troop_number")
    self.p_table_troop = self:TableViewPro("p_table_troop")
    self.p_status_empty = self:Transform("p_status_empty")
    self.p_text_empty = self:Text("p_text_empty", "base_defence_no_allytroop")
    self.p_text_hint = self:Text("p_text_hint")
    self.p_btn_help = self:Button("p_btn_help", Delegate.GetOrCreate(self, self.OnReinforce))
    self.p_btn_help_rect = self:RectTransform("p_btn_help")
    self.p_text = self:Text("p_text", "world_zhushou")
end

---@param param ReinforceMediatorDatum
function ReinforceMediator:OnShow(param)
    self.param = param

    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Army.MsgPath, Delegate.GetOrCreate(self, self.OnArmyChanged))

    self:InitializeListData()
    self:RefreshUI()
end

function ReinforceMediator:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Army.MsgPath, Delegate.GetOrCreate(self, self.OnArmyChanged))
end

function ReinforceMediator:RefreshUI()
    ---@type wds.CastleBrief
    local castle = self.param.tile.entity
    local owner = castle.Owner
    
    --建筑驻防上限
    local fixedBuilding = ConfigRefer.FixedMapBuilding:Find(ConfigRefer.ConstMain:SlgCastleFixedMapBuilding())
    local troopCount = castle.Army.PlayerTroopIDs:Count()
    local empty = troopCount <= 0
    local reachTroopMax = troopCount >= fixedBuilding:MaxReinforceCount()
    local playerName = MailUtils.MakePlayerName(owner.AllianceAbbr.String, owner.PlayerName.String)
    local totalPower = ReinforceMediator.CalculateTotalPower(castle.Army.PlayerTroopIDs)

    self.child_ui_head_master_player:FeedData(owner)
    self.p_text_master_player_name.text = playerName
    self.p_text_master_power.text = I18N.GetWithParams("base_defence_totalpower", NumberFormatter.Normal(totalPower))
    self.p_text_troop_number.text = I18N.GetWithParams("base_defence_allytroop_2", troopCount,  fixedBuilding:MaxReinforceCount())
    self.p_status_empty:SetVisible(empty)

    -- local hasMyTroop = ReinforceUtils.HasMyReinforceTroop(castle.Army)
    local shouldShowHint = false --hasMyTroop or reachTroopMax
    self.p_text_hint:SetVisible(shouldShowHint)
    self.p_btn_help:SetVisible(not shouldShowHint)

    -- if hasMyTroop then
    --     self.p_text_hint.text = I18N.Get("base_defence_reinforce_already")
    -- elseif reachTroopMax then
    --     self.p_text_hint.text = I18N.Get("base_defence_reinforce_max")
    -- end

    if reachTroopMax then
        self.p_text_hint.text = I18N.Get("base_defence_reinforce_max")
    end

    self:UpdateList()
end

---@param troops table<number, wds.ArmyMemberInfo>
---@return number
function ReinforceMediator.CalculateTotalPower(troops)
    local power = 0

    for _, member in pairs(troops) do
        power = power + member.Power
    end

    return power
end

---@param castle wds.CastleBrief
function ReinforceMediator:UpdateList()
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
function ReinforceMediator:OnFold(data)
    local index = self.p_table_troop:GetDataIndex(data)
    if data.fold == 0 then
        self.p_table_troop:InsertData(index + 1, {data = data}, 1)
    else
        self.p_table_troop:RemAt(index + 1)
    end
end

function ReinforceMediator:OnReinforce()
    KingdomTouchInfoOperation.MoveTroopToTile(self.param.tile, self.p_btn_help_rect, wrpc.MovePurpose.MovePurpose_Reinforce)
    self:CloseSelf()
end

---@param data wds.CastleBrief
function ReinforceMediator:OnArmyChanged(data, change)
    if data.ID == self.param.tile.entity.ID then
        self:HandleListDataChange(change)
        self:RefreshUI()
    end
end

function ReinforceMediator:InitializeListData()
    ---@type table<number, ReinforceListData>
    self.troopDict = {}

    ---@type ReinforceListData[]
    self.troopList = {}

    ---@type wds.CastleBrief
    local castle = self.param.tile.entity
    local playerId = castle.Owner.PlayerID

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

function ReinforceMediator:HandleListDataChange(change)
    if change == nil then
        return
    end

    ---@type wds.CastleBrief
    local castle = self.param.tile.entity
    local playerId = castle.Owner.PlayerID

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

return ReinforceMediator