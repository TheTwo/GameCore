local BaseModule = require('BaseModule')
local DBEntityType = require('DBEntityType')
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")

---@class KingdomModule : BaseModule
local KingdomModule = class("KingdomModule", BaseModule)

function KingdomModule:OnRegister()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Kingdom.SystemEntry.OpenSystems.MsgPath, Delegate.GetOrCreate(self, self.OnKingdomEntryChanged))
end

function KingdomModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Kingdom.SystemEntry.OpenSystems.MsgPath, Delegate.GetOrCreate(self, self.OnKingdomEntryChanged))
end

---@param entity wds.Kingdom
function KingdomModule:OnKingdomEntryChanged(entity, changedData)
    if not changedData then
        return
    end
    local IdSet = {}
    local Add = changedData.Add
    local Remove = changedData.Remove
    if Add then
        for id, v in pairs(Add) do
            IdSet[id] = true
        end
    end
    if Remove then
        for id, v in pairs(Remove) do
            IdSet[id] = true
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.KINGDOM_SYSTEM_ENTRY_REFRESH, entity.ID, IdSet)
end

function KingdomModule:GetKingdomTime()
    local kingdom = self:GetKingdomEntity()
    if kingdom then
        return kingdom.KingdomBasic.OsTime.Seconds
    end
    return 0
end

function KingdomModule:GetTimeAfterOpenServer(seconds)
    return self:GetKingdomTime() + seconds
end

--判断服务器是否存在开服时间
function KingdomModule:IsServerTimeExist()
    local kingdomEntity = self:GetKingdomEntity()
    local OS = kingdomEntity.KingdomBasic.OsTime
    return OS.Seconds ~= 0
end

function KingdomModule:IsSystemOpen(id)
    if id == 0 then return true end
    
    local config = ConfigRefer.SystemEntry:Find(id)
    local versionCheck = false
    if config then
        versionCheck = ModuleRefer.AppInfoModule:IsCSharpVersionMatch(config:CSharpVersion())
    end
    local kingdom = self:GetKingdomEntity()
    if kingdom and kingdom.SystemEntry and kingdom.SystemEntry.OpenSystems then
        return kingdom.SystemEntry.OpenSystems[id], versionCheck
    end

    return false, versionCheck
end

---@return wds.Kingdom
function KingdomModule:GetKingdomEntity()
    local kingdoms = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.Kingdom)
    for _, k in pairs(kingdoms) do
        return k
    end
    return nil
end

return KingdomModule