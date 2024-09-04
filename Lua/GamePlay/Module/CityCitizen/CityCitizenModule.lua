---@type CS.UnityEngine.PlayerPrefs
local PlayerPrefs = CS.UnityEngine.PlayerPrefs
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local NotificationType = require("NotificationType")
local ConfigRefer = require("ConfigRefer")
local CityCitizenModuleDefine = require("CityCitizenModuleDefine")
local DBEntityPath = require("DBEntityPath")
local DBEntityType = require("DBEntityType")
local OnChangeHelper = require("OnChangeHelper")

local BaseModule = require("BaseModule")

---@class CityCitizenModule:BaseModule
---@field new fun():CityCitizenModule
---@field super BaseModule
local CityCitizenModule = class('CityCitizenModule', BaseModule)

function CityCitizenModule:ctor()
    BaseModule.ctor(self)
    self._playerId = nil
    ---@type table<number, boolean>
    self._delayMarkItem = {}
    ---@type table<number, boolean>
    self._markedItem = {}
    self._writeDataDirty = false
    ---@type table<number, CS.Notification.NotificationDynamicNode>
    self._notifyNodes = {}
    ---@type table<number, table<number, number>>
    self._notifyAbilityTypeToProcessId = {}
end

function CityCitizenModule:OnRegister()
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleAbility.MsgPath, Delegate.GetOrCreate(self, self.OnAbilityChanged))
end

function CityCitizenModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleAbility.MsgPath, Delegate.GetOrCreate(self, self.OnAbilityChanged))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

---@param id number
function CityCitizenModule:SetPlayerId(id)
    if self._playerId ~= id then
        self._playerId = id
    end
end

function CityCitizenModule:OnLoggedIn()
    if self._playerId then
        local player = g_Game.DatabaseManager:GetEntity(self._playerId, DBEntityType.Player)
        local sceneInfo = player.SceneInfo
        self._castleBriefId = sceneInfo.CastleBriefId
        self:ReloadSavedData()
        ---FIXME:字段修改
        -- self:GenerateNotifyData()
    end
end

function CityCitizenModule:IsProcessUnlocked(configId)
    local process = ConfigRefer.CityProcess:Find(configId)
    if not process then
        return false
    end
    local need = process:AbilityNeed()
    local ability = ConfigRefer.CityAbility:Find(need)
    if ability then
        local castle = g_Game.DatabaseManager:GetEntity(self._castleBriefId, DBEntityType.CastleBrief)
        if castle then
            local hasAbility = castle and castle.Castle and castle.Castle.CastleAbility and  castle.Castle.CastleAbility[ability:Type()] or 0
            if ability:Level() > hasAbility then
                return false
            end
        end
    end
    return true
end

---@param configId number
---@param includeInDelayMark boolean
---@return boolean
function CityCitizenModule:CheckProcessFormulaIsNew(configId, includeInDelayMark)
    if self._markedItem[configId] then
        return false
    end
    if not self:IsProcessUnlocked(configId) then
        return false
    end
    if not includeInDelayMark then
        return true
    end
    return not self._delayMarkItem[configId]
end

---@param configId number
function CityCitizenModule:MarkFormulaCheckedDelay(configId)
    self._delayMarkItem[configId] = true
end

function CityCitizenModule:ApplyDelayMarkItem(writeNow)
    local NotificationModule = ModuleRefer.NotificationModule
    for id, _ in pairs(self._delayMarkItem) do
        self._markedItem[id] = true
        local node = self._notifyNodes[id]
        if node then
            NotificationModule:SetDynamicNodeNotificationCount(node, 0)
        end
    end
    table.clear(self._delayMarkItem)
    if writeNow then
        self:WritePlayerPlayerPrefs()
    else
        self._writeDataDirty = true
    end
end

function CityCitizenModule:Tick(_)
    if not self._writeDataDirty then
        return
    end
    self:WritePlayerPlayerPrefs()
end

---@param entity wds.CastleBrief
---@param changedData any
function CityCitizenModule:OnAbilityChanged(entity, changedData)
    if not entity or entity.ID ~= self._castleBriefId then
        return
    end
    local NotificationModule = ModuleRefer.NotificationModule
    local add,_,updated = OnChangeHelper.GenerateMapFieldChangeMap(changedData)
    if add then
        for type, v in pairs(add) do
            local m = self._notifyAbilityTypeToProcessId[type]
            if m then
                for configId, reqLv in pairs(m) do
                    if v >= reqLv and (not self._markedItem[configId]) and (not self._delayMarkItem[configId]) then
                        local node = self._notifyNodes[configId]
                        if node then
                            NotificationModule:SetDynamicNodeNotificationCount(node, 1)
                        end
                    end
                end
            end
        end
    end
    if updated then
        for type, v in pairs(updated) do
            local m = self._notifyAbilityTypeToProcessId[type]
            if m then
                for configId, reqLv in pairs(m) do
                    if v >= reqLv and (not self._markedItem[configId]) and (not self._delayMarkItem[configId]) then
                        local node = self._notifyNodes[configId]
                        if node then
                            NotificationModule:SetDynamicNodeNotificationCount(node, 1)
                        end
                    end
                end
            end
        end
    end
end

function CityCitizenModule:ReloadSavedData()
    if not self._playerId then
        return
    end
    self._writeDataDirty = false
    table.clear(self._markedItem)
    table.clear(self._delayMarkItem)
    local saveKey = string.format(CityCitizenModuleDefine.SaveKeyFormat, self._playerId)
    local savedValue = PlayerPrefs.GetString(saveKey, string.Empty)
    if string.IsNullOrEmpty(savedValue) then
        return
    end
    local values = string.split(savedValue, ',')
    for _, checkConfigIdStr in pairs(values) do
        local checkConfigId = tonumber(checkConfigIdStr)
        if checkConfigId then
            self._markedItem[checkConfigId] = true
        end
    end
end

function CityCitizenModule:GenerateNotifyData()
    local NotificationModule = ModuleRefer.NotificationModule
    for _, node in pairs(self._notifyNodes) do
        NotificationModule:DisposeDynamicNode(node, false)
    end
    table.clear(self._notifyNodes)
    table.clear(self._notifyAbilityTypeToProcessId)
    ---@type wds.CastleBrief
    local castle = g_Game.DatabaseManager:GetEntity(self._castleBriefId, DBEntityType.CastleBrief)
    local castleAbility = castle and castle.Castle and castle.Castle.CastleAbility or {}
    for _, config in ConfigRefer.CityProcess:ipairs() do
        local unlock = true
        local id = config:Id()
        local need = config:AbilityNeed()
        if need then
            local ability = ConfigRefer.CityAbility:Find(need)
            if ability then
                local map = self._notifyAbilityTypeToProcessId[ability:Type()]
                if not map then
                    map = {}
                    self._notifyAbilityTypeToProcessId[ability:Type()] = map
                end
                map[id] = ability:Level()
                local abV = castleAbility[ability:Type()] or 0
                if ability:Level() > abV then
                    unlock = false
                end
            end
        end
        local node = NotificationModule:GetOrCreateDynamicNode(CityCitizenModuleDefine.GetNotifyFormulaKey(id), NotificationType.CITY_FURNITURE_PROCESS_FORMULA)
        local notify = (self._markedItem[id] or (not unlock)) and 0 or 1
        NotificationModule:SetDynamicNodeNotificationCount(node, notify)
        self._notifyNodes[id] = node
    end
end

function CityCitizenModule:WritePlayerPlayerPrefs()
    self._writeDataDirty = false
    if table.isNilOrZeroNums(self._markedItem) then
        return
    end
    local ids = table.keys(self._markedItem)
    table.sort(ids)
    local saveKey = string.format(CityCitizenModuleDefine.SaveKeyFormat, self._playerId)
    local savedValue = table.concat(ids, ',')
    PlayerPrefs.SetString(saveKey, savedValue)
    PlayerPrefs.Save()
end

return CityCitizenModule

