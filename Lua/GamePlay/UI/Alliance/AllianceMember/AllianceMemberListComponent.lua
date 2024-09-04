local DBEntityPath = require("DBEntityPath")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local AllianceMemberListRankCellData = require("AllianceMemberListRankCellData")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceMemberListComponentData
---@field InTableIndex number
---@field MemberId number
---@field MemberData wds.AllianceMember
---@field RankLv number

---@class AllianceMemberListComponent:BaseUIComponent
---@field new fun():AllianceMemberListComponent
---@field super BaseUIComponent
local AllianceMemberListComponent = class('AllianceMemberListComponent', BaseUIComponent)

function AllianceMemberListComponent:ctor()
    BaseUIComponent.ctor(self)
    self._allianceId = nil
    ---@type AllianceMemberListRankCellData[]
    self._tableData = {}
end

function AllianceMemberListComponent:OnCreate(param)
    self._p_table_member = self:TableViewPro("p_table_member")
    self._p_btn_position = self:Button("p_btn_position", Delegate.GetOrCreate(self, self.OnClickBtnPosition))
    self._p_text_btn_position = self:Text("p_text_btn_position", "league_architecture")
    self._p_btn_authority = self:Button("p_btn_authority", Delegate.GetOrCreate(self, self.OnClickBtnAuthority))
    self._p_text_authority = self:Text("p_text_authority", "league_permission")
end

function AllianceMemberListComponent:OnOpened(param)
    self._allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    self:ReGenerateCells()
end

function AllianceMemberListComponent:OnShow(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceMembers.Members.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceMemberDataChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.SwitchLeaderTargetFacebookId.MsgPath, Delegate.GetOrCreate(self, self.OnSwitchLeaderTargetFacebookIdChanged))
    if self._allianceId and self._allianceId > 0 then
        self:ReGenerateCells()
    end
end

function AllianceMemberListComponent:OnHide(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.SwitchLeaderTargetFacebookId.MsgPath, Delegate.GetOrCreate(self, self.OnSwitchLeaderTargetFacebookIdChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceMembers.Members.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceMemberDataChanged))
end

function AllianceMemberListComponent:OnClose(param)
    self._allianceId = 0
end

function AllianceMemberListComponent:OnClickBtnPosition()
    g_Game.UIManager:Open(UIMediatorNames.AllianceAuthorityPositionMediator, ModuleRefer.AllianceModule:GetMyAllianceMemberComp())
end

function AllianceMemberListComponent:OnClickBtnAuthority()
    g_Game.UIManager:Open(UIMediatorNames.AllianceAuthorityMediator)
end

---@param entity wds.Alliance
---@param changedData table
function AllianceMemberListComponent:OnAllianceMemberDataChanged(entity, changedData)
    if not self._allianceId or self._allianceId == 0 or entity.ID ~= self._allianceId or not changedData then
        return
    end
    self:ReGenerateCells()
end

---@param entity wds.Alliance
function AllianceMemberListComponent:OnSwitchLeaderTargetFacebookIdChanged(entity)
    if not self._allianceId or self._allianceId == 0 or entity.ID ~= self._allianceId then
        return
    end
    self:ReGenerateCells()
end

---@param a wds.AllianceMember
---@param b wds.AllianceMember
---@return boolean
function AllianceMemberListComponent.SortMember(a, b)
    if ModuleRefer.AllianceModule:IsAllianceMemberSwitchLeaderTarget(a) then
        return false
    end
    local aOnLine = false
    local bOnLine = false
    if not a.LatestLoginTime or not a.LatestLogoutTime or a.LatestLogoutTime.ServerSecond <= 0 or a.LatestLogoutTime.ServerSecond < a.LatestLoginTime.ServerSecond then
        aOnLine = true
    end
    if not b.LatestLoginTime or not b.LatestLogoutTime or b.LatestLogoutTime.ServerSecond <= 0 or b.LatestLogoutTime.ServerSecond < b.LatestLoginTime.ServerSecond then
        bOnLine = true
    end
    if aOnLine and bOnLine then
        return a.Power > b.Power
    elseif aOnLine then
        return true
    elseif bOnLine then
        return false
    end
    return a.LatestLogoutTime.ServerSecond > b.LatestLogoutTime.ServerSecond
end

function AllianceMemberListComponent:ReGenerateCells()
    self._p_table_member:Clear()
    table.clear(self._tableData)
    local allMembers = ModuleRefer.AllianceModule:GetMyAllianceMemberDic()
    if table.isNilOrZeroNums(allMembers) then
        return
    end
    ---@type table<number, wds.AllianceMember[]>
    local rankMap = {}
    local ranks = {}
    for _, v in pairs(allMembers) do
        if not rankMap[v.Rank] then
            rankMap[v.Rank] = {}
        end
        table.insert(rankMap[v.Rank], v)
        table.insert(ranks, v.Rank)
    end
    ranks = table.unique(ranks, true)
    table.sort(ranks)
    -- local isFirst = true
    repeat
        local rank = table.remove(ranks)
        local rankMembers = rankMap[rank]
        table.sort(rankMembers, AllianceMemberListComponent.SortMember)
        ---@type AllianceMemberListRankCellData
        local rankCellData = AllianceMemberListRankCellData.new()
        rankCellData.Rank = rank
        rankCellData.count = #rankMembers
        rankCellData.max = ModuleRefer.AllianceModule:GetRankNumberLimit(rank)
        -- if isFirst then
            rankCellData:SetExpanded(true)
        --     isFirst = false
        -- end
        table.addrange(rankCellData.__childCellsData, rankMembers)
        self._p_table_member:AppendData(rankCellData)
        table.insert(self._tableData, rankCellData)
    until #ranks <= 0
end

return AllianceMemberListComponent