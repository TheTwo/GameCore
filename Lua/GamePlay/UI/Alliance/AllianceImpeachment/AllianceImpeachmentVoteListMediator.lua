--- scene:scene_league_popup_impeach_vote_list

local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local EventConst = require("EventConst")
local I18N = require("I18N")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceImpeachmentVoteListMediator:BaseUIMediator
---@field new fun():AllianceImpeachmentVoteListMediator
---@field super BaseUIMediator
local AllianceImpeachmentVoteListMediator = class('AllianceImpeachmentVoteListMediator', BaseUIMediator)

function AllianceImpeachmentVoteListMediator:ctor()
    AllianceImpeachmentVoteListMediator.super.ctor(self)
    self._allianceId = nil
end

function AllianceImpeachmentVoteListMediator:OnCreate(param)
    self._p_text_support = self:Text("p_text_support")
    self._p_text_support_quantity = self:Text("p_text_support_quantity")
    self._p_table_support = self:TableViewPro("p_table_support")
    
    self._p_text_oppose = self:Text("p_text_oppose")
    self._p_text_oppose_quantity = self:Text("p_text_oppose_quantity")
    self._p_table_oppose = self:TableViewPro("p_table_oppose")
end

function AllianceImpeachmentVoteListMediator:OnOpened(param)
    self._allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    self:RefreshListRight()
    self:RefreshListLeft()
end

function AllianceImpeachmentVoteListMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.IsImpeach.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachmentStatusChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.AgreeFbIds.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachmentInfoAgreeChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.DisAgreeFbIds.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachmentInfoDisagreeChanged))
end

function AllianceImpeachmentVoteListMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.IsImpeach.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachmentStatusChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.AgreeFbIds.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachmentInfoAgreeChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.DisAgreeFbIds.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachmentInfoDisagreeChanged))
end

function AllianceImpeachmentVoteListMediator:RefreshListLeft()
    local allianceModule = ModuleRefer.AllianceModule
    ---@type AllianceImpeachInfo
    local impeachInfo = allianceModule:GetMyAllianceImpeachInfo()
    self._p_text_oppose.text = I18N.GetWithParams("alliance_retire_impeach_against", tostring(table.nums(impeachInfo.DisAgreeFbIds)))
    self._p_table_oppose:Clear()
    local players = {}
    for facebookId, _ in pairs(impeachInfo.DisAgreeFbIds) do
        local memberInfo = allianceModule:QueryMyAllianceMemberData(facebookId)
        if memberInfo then
            table.insert(players, memberInfo)
        end
    end
    table.sort(players, AllianceImpeachmentVoteListMediator.SortMembers)
    for i, v in ipairs(players) do
        self._p_table_oppose:AppendData(v)
    end
end

function AllianceImpeachmentVoteListMediator:RefreshListRight()
    local allianceModule = ModuleRefer.AllianceModule
    ---@type AllianceImpeachInfo
    local impeachInfo = allianceModule:GetMyAllianceImpeachInfo()
    self._p_text_support.text = I18N.GetWithParams("alliance_retire_impeach_support", tostring(table.nums(impeachInfo.AgreeFbIds)))
    self._p_table_support:Clear()
    local players = {}
    for facebookId, _ in pairs(impeachInfo.AgreeFbIds) do
        local memberInfo = allianceModule:QueryMyAllianceMemberData(facebookId)
        if memberInfo then
            table.insert(players, memberInfo)
        end
    end
    table.sort(players, AllianceImpeachmentVoteListMediator.SortMembers)
    for i, v in ipairs(players) do
        self._p_table_support:AppendData(v)
    end
end

function AllianceImpeachmentVoteListMediator:OnLeaveAlliance()
    self:CloseSelf()
end

---@param entity wds.Alliance
function AllianceImpeachmentVoteListMediator:OnImpeachmentStatusChanged(entity)
    if not entity or not self._allianceId or entity.ID ~= self._allianceId then
        return
    end
    if not entity.AllianceLeaderCtrl.IsImpeach then
        self:CloseSelf()
    end
end

---@param entity wds.Alliance
function AllianceImpeachmentVoteListMediator:OnImpeachmentInfoAgreeChanged(entity)
    if not entity or not self._allianceId or entity.ID ~= self._allianceId then
        return
    end
    self:RefreshListRight()
end

---@param entity wds.Alliance
function AllianceImpeachmentVoteListMediator:OnImpeachmentInfoDisagreeChanged(entity)
    if not entity or not self._allianceId or entity.ID ~= self._allianceId then
        return
    end
    self:RefreshListLeft()
end

---@param a wds.AllianceMember
---@param b wds.AllianceMember
---@return boolean
function AllianceImpeachmentVoteListMediator.SortMembers(a, b)
    if a.Rank > b.Rank then
        return true
    end
    if a.Rank < b.Rank then
        return false
    end
    if a.Rank == b.Rank then
        if a.Power > b.Power then
            return true
        end
    end
    return false
end

return AllianceImpeachmentVoteListMediator