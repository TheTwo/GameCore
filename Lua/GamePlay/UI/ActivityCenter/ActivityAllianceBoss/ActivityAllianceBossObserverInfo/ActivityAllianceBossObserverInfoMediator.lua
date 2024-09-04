local BaseUIMediator = require("BaseUIMediator")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
---@class ActivityAllianceBossObserverInfoMediator : BaseUIMediator
local ActivityAllianceBossObserverInfoMediator = class("ActivityAllianceBossObserverInfoMediator", BaseUIMediator)

---@class ActivityAllianceBossObserverInfoMediatorParam
---@field facebookIds table<number, number> @playerId -> facebookId
---@field observerNum number

function ActivityAllianceBossObserverInfoMediator:OnCreate()
    self.textObserver = self:Text("p_text_watch")
    self.tableObserver = self:TableViewPro("p_table_watch")
end

---@param param ActivityAllianceBossObserverInfoMediatorParam
function ActivityAllianceBossObserverInfoMediator:OnOpened(param)
    self.facebookIds = param.facebookIds
    self.observerNum = param.observerNum
    self.textObserver.text = I18N.GetWithParams('*观战人数: {1} (观战加成: {2})', self.observerNum, '')
    self.tableObserver:Clear()
    local allMembers = ModuleRefer.AllianceModule:GetMyAllianceMemberDic()
    ---@type wrpc.AllianceMemberInfo[]
    local observingMembers = {}
    for _, member in ipairs(allMembers) do
        if self.facebookIds[member.PlayerID] then
            table.insert(observingMembers, member)
        end
    end
    local numCols = 2
    local members = {}
    for _, member in ipairs(observingMembers) do
        if #members == numCols then
            self.tableObserver:AppendData({members = members})
            members = {}
        end
        table.insert(members, member)
    end
    if #members > 0 then
        self.tableObserver:AppendData({members = members})
    end
end

return ActivityAllianceBossObserverInfoMediator