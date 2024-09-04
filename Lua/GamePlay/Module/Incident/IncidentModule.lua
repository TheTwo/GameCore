local BaseModule = require('BaseModule')
local ModuleRefer = require('ModuleRefer')
local I18N = require("I18N")
local DBEntityPath = require('DBEntityPath')
local ProtocolId = require("ProtocolId")
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')

---@class IncidentModule
local IncidentModule = class('IncidentModule',BaseModule)

function IncidentModule:OnRegister()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Incident.MsgPath, Delegate.GetOrCreate(self,self.UpdateIncidentInfo))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.FinishIncidentTask, Delegate.GetOrCreate(self, self.ShowWorldToast))
end

function IncidentModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Incident.MsgPath, Delegate.GetOrCreate(self,self.UpdateIncidentInfo))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.FinishIncidentTask, Delegate.GetOrCreate(self, self.ShowWorldToast))
end

function IncidentModule:UpdateIncidentInfo()
    g_Game.EventManager:TriggerEvent(EventConst.INCIDENT_INFO_UPDATE)
end

function IncidentModule:GetIncidents()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if (player) then
        return player.PlayerWrapper.Incident.Incidents
    end
    return nil
end

function IncidentModule:GetFinishedIncidents()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if (player) then
        return player.PlayerWrapper.Incident.FinishedIncidents
    end
    return nil
end

function IncidentModule:IsIncidentFinish(incidentId)
    local finishIncidents = self:GetFinishedIncidents() or {}
    for _, finishId in ipairs(finishIncidents) do
        if incidentId == finishId then
            return true
        end
    end
    return false
end

function IncidentModule:IsIncidentUnlock(incidentId)
    return self:GetIncidentInfo(incidentId) ~= nil or self:IsIncidentFinish(incidentId)
end

function IncidentModule:GetIncidentInfo(incidentId)
    local incidents = self:GetIncidents() or {}
    return incidents[incidentId]
end

function IncidentModule:CheckIsAward(incidentId)
    local incidentInfo = self:GetIncidentInfo(incidentId)
    if not incidentInfo then
        return false
    end
    return incidentInfo.Progress >= ConfigRefer.Incident:Find(incidentId):MaxProgress()
end

function IncidentModule:GetRewards(incidentId)
    local incidentCfg = ConfigRefer.Incident:Find(incidentId)
    local itemGroupId = incidentCfg:FixedReward()
    if itemGroupId == 0 then
        return nil
    end
    return ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(itemGroupId)
end

function IncidentModule:ShowWorldToast(isSuccess, data)
    if not isSuccess then
        return
    end
    local param = {}
    param.questId = data.TaskId
    param.incidentId = data.IncidentId
    --ModuleRefer.ToastModule:AddWorldToast(param)
end

function IncidentModule:ShowRewardPanel(isSuccess, data)
    -- if not isSuccess then
    --     return
    -- end
    -- local incidentId = data.IncidentId
    -- local items = data.Items
    -- local rewards = {}
    -- for itemId, count in pairs(items) do
    --     local single = {}
    --     single.id = itemId
    --     single.count = count
    --     rewards[#rewards + 1] = single
    -- end
    -- local param = {}
    -- param.detailText = I18N.Get("*您在此次事件中完成了") .. self:GetProgressText(incidentId) .. I18N.Get("*的任务,获得以下奖励:")
    -- param.items = rewards
    -- g_Game.UIManager:Open(require('UIMediatorNames').GetRewardMeidator, param)
end

function IncidentModule:GetProgressText(incidentId)
    local incidentInfo = self:GetIncidentInfo(incidentId)
    if incidentInfo then
        local totalProgress = ConfigRefer.Incident:Find(incidentId):MaxProgress()
        return string.format("%d", (incidentInfo.Progress / totalProgress) * 100) .. "%"
    end
    return ""
end

return IncidentModule