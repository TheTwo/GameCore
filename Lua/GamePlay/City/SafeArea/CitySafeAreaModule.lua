local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local DBEntityPath = require("DBEntityPath")
local DBEntityType = require("DBEntityType")
local CastleSafeAreaWallRepairParameter = require("CastleSafeAreaWallRepairParameter")

local BaseModule = require("BaseModule")

---@class CitySafeAreaModule:BaseModule
---@field new fun():CitySafeAreaModule
---@field super BaseModule
local CitySafeAreaModule = class('CitySafeAreaModule', BaseModule)

function CitySafeAreaModule:ctor()
    BaseModule.ctor(self)
    ---@type number
    self._castleBriefId = nil
    ---@type number[]
    self._destroyedWallIds = {}
    ---@type table<number, number>
    self._castleWallStatus = {}
    ---@type table<number, number>
    self._safeAreaStatus = {}
    ---@type table<number, boolean>
    self._pollutedWallOrDoor = {}
    ---@type number[]
    self._inUsingWall = {}
end

function CitySafeAreaModule:OnRegister()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    self._castleBriefId = player.SceneInfo.CastleBriefId
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.SafeAreaStatus.MsgPath, Delegate.GetOrCreate(self, self.OnCitySafeAreaDataChange))
    self:InitDataMap()
end

function CitySafeAreaModule:OnRemove()
    self._castleBriefId = nil
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.SafeAreaStatus.MsgPath, Delegate.GetOrCreate(self, self.OnCitySafeAreaDataChange))
end

function CitySafeAreaModule:InitDataMap()
    local castle = ModuleRefer.PlayerModule:GetCastle().Castle
    self:RefreshSafeAreaStatus(castle)
end

---@param castle wds.Castle
function CitySafeAreaModule:RefreshSafeAreaStatus(castle)
    table.clear(self._safeAreaStatus)
    local safeAreaStatus = castle.SafeAreaStatus
    for i, v in pairs(safeAreaStatus) do
        self._safeAreaStatus[i] = v and 0 or 1
    end
    self:RefreshWallStatus()
end

function CitySafeAreaModule:RefreshWallStatus()
    table.clear(self._inUsingWall)
    ---@type table<number, CitySafeAreaLinkWallConfigCell>
    local safeAreas = {}
    for _, value in ConfigRefer.CitySafeAreaLinkWall:pairs() do
        if self:IsSafeAreaValid(value:Id()) then
            safeAreas[value:Id()] = value
        end
    end
    local CitySafeAreaWallExtra = ConfigRefer.CitySafeAreaWallExtra
    for _,config in pairs(safeAreas) do
        local wallConut = config:RequireWallLength()
        for i = 1, wallConut do
            local wallId = config:RequireWall(i)
            local wallConfig = CitySafeAreaWallExtra:Find(wallId)
            if not wallConfig then
                table.insert(self._inUsingWall, wallId)
                goto continue
            end
            local checkAreaCount = wallConfig:HideWhenAllAreaSafeLength()
            if checkAreaCount <= 0 then
                table.insert(self._inUsingWall, wallId)
                goto continue
            end
            local canHide = true
            for idx = 1, checkAreaCount do
                local areaId = wallConfig:HideWhenAllAreaSafe(idx)
                if not safeAreas[areaId] then
                    canHide = false
                    break
                end
            end
            if canHide then
                goto continue
            end
            table.insert(self._inUsingWall, wallId)
            ::continue::
        end
    end
    table.sort(self._inUsingWall)
end

function CitySafeAreaModule:GetDoorIdsIntArray()
    local tempTable = {}
    for _, v in ConfigRefer.CitySafeAreaWall:ipairs() do
        if v:IsDoor() then
            table.insert(tempTable, string.pack("<B", v:Id()))
        end
    end
    return table.concat(tempTable)
end

function CitySafeAreaModule:GetNeedShowWalls()
    local tempTable = {}
    for _, v in ipairs(self._inUsingWall) do
        table.insert(tempTable, string.pack("<B", v))
    end
    return table.concat(tempTable)
end

function CitySafeAreaModule:GetDestroyedWalls()
    local tempTable = {}
    for _, v in ipairs(self._destroyedWallIds) do
        table.insert(tempTable, string.pack("<B", v))
    end
    return table.concat(tempTable)
end

---@return number @0-normal,1-broken
function CitySafeAreaModule:GetWallStatus(wallId)
    return self._castleWallStatus[wallId] or 0
end

function CitySafeAreaModule:GetVaildSafeAreas()
    local ret = {}
    for id, v in pairs(self._safeAreaStatus) do
        if v == 0 then
            table.insert(ret, id)
        end
    end
    table.sort(ret)
    return ret
end

function CitySafeAreaModule:IsSafeAreaValid(safeAreaId)
    if safeAreaId == 0 then
        return false
    end
    local status = self._safeAreaStatus[safeAreaId]
    return status and status == 0
end

---@return boolean
function CitySafeAreaModule:GetWallOrDoorIsPolluted(wallId)
    return self._pollutedWallOrDoor[wallId]
end

---@param entity wds.CastleBrief
function CitySafeAreaModule:OnCitySafeAreaDataChange(entity, changedData)
    if not self._castleBriefId or self._castleBriefId ~= entity.ID then
        return
    end
    local oldStatus = {}
    for i, v in pairs(self._safeAreaStatus) do
        oldStatus[i] = v
    end
    table.clear(self._safeAreaStatus)
    local castle = ModuleRefer.PlayerModule:GetCastle().Castle
    local safeAreaStatus = castle.SafeAreaStatus
    local changeToBroken = {}
    local changeToNormal = {}
    for i, v in pairs(safeAreaStatus) do
        local oldValue = oldStatus[i] or 1
        self._safeAreaStatus[i] = v and 0 or 1
        if self._safeAreaStatus[i] ~= oldValue then
            if oldValue == 0 then
                changeToBroken[i] = true
            else
                changeToNormal[i] = true
            end
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SAFE_AREA_STATUS_REFRESH, self._castleBriefId, changeToNormal, changeToBroken)
    local oldWalls = {}
    for _, wallId in ipairs(self._inUsingWall) do
        table.insert(oldWalls, wallId)
    end
    self:RefreshWallStatus()
    if #oldWalls ~= #self._inUsingWall then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_SAFE_AREA_WALL_STATUS_REFRESH, self._castleBriefId)
        return
    end
    for i = 1, #self._inUsingWall do
        if oldWalls[i] ~= self._inUsingWall[i] then
            g_Game.EventManager:TriggerEvent(EventConst.CITY_SAFE_AREA_WALL_STATUS_REFRESH, self._castleBriefId)
        return
        end
    end
end

function CitySafeAreaModule:RequestAddMatToRepairWall(wallId, costIndex)
    local sendCmd = CastleSafeAreaWallRepairParameter.new()
    sendCmd.args.WallId = wallId
    sendCmd.args.CostIdx = costIndex
    sendCmd:Send()
end

return CitySafeAreaModule