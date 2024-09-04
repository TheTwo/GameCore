local ModuleRefer = require("ModuleRefer")
local DBEntityType = require("DBEntityType")
local TroopManager = require("TroopManager")

local BaseModule = require("BaseModule")

--由于 SlgModule 的生命周期和KingdomScene强绑定， 这个module用来提供诸如非KingdomScene 选编队一类操作时的数据兼容SlgModule
--在 SlgModule 本身存在初始化的情况下， SlgModule:Init() 后调用 这里的 SetSlgModule ， 这里提供的接口和SlgModule等效
--在 g_Game.ModuleManager:RemoveModule("SlgModule") 前 SetSlgModule(nil) 则数据兼容逻辑生效
--这里涉及的方法 尽量使用 SlgModule 内抽离的 .方法来保证逻辑一致，单涉及 SlgModule 内状态的一些接口 在 SlgModule 不存在时 不提供支持
---@class SlgInterfaceModule:BaseModule
---@field new fun():SlgInterfaceModule
---@field super BaseModule
local SlgInterfaceModule = class('SlgInterfaceModule', BaseModule)

function SlgInterfaceModule:ctor()
    SlgInterfaceModule.super.ctor(self)
    self.myTroops = nil
    self.gmTroops = nil
end

---@param validSlgModule SlgModule
function SlgInterfaceModule:SetSlgModule(validSlgModule)
    self._validSlgModule = validSlgModule
    if self._validSlgModule == nil then
        self:UpdateTroopCache()
    end
end

---@param forceUpdate boolean
---@return table<number,TroopInfo>,TroopInfo[]
function SlgInterfaceModule:GetMyTroops(forceUpdate)
    if self._validSlgModule then
        return self._validSlgModule:GetMyTroops(forceUpdate)
    end
    if not self.myTroops or forceUpdate then
        self:UpdateTroopCache()
    end
    return self.myTroops, self.gmTroops
end

---@param preset wds.TroopPreset | TroopPresetCache
---@return number,number @hp,maxHp
function SlgInterfaceModule:GetTroopHpByPreset(preset)
    return require("SlgModule").GetTroopHpByPreset(preset)
end

---@param preset wds.TroopPreset
function SlgInterfaceModule:GetTroopPowerByPreset(preset)
    return require("SlgModule").DoGetTroopPowerByPreset(preset)
end

---@return TroopCtrl
function SlgInterfaceModule:GetTroopCtrl(id)
    if self._validSlgModule then
        return self._validSlgModule:GetTroopCtrl(id)
    end
    -- not support
end

---@param troopdatas TroopData[]
---@param targetId number
---@param purpose number @wrpc.MovePurpose
function SlgInterfaceModule:MoveTroopsToEntity(troopdatas,targetId,purpose)
    if self._validSlgModule then
        return self._validSlgModule:MoveTroopsToEntity(troopdatas,targetId,purpose)
    end
    -- not support
end

---@param troopdatas TroopData[]
---@param coord CS.DragonReborn.Vector2Short
---@param purpose number @wrpc.MovePurpose
function SlgInterfaceModule:MoveTroopsToCoord(troopdatas,coord,purpose)
    if self._validSlgModule then
        return self._validSlgModule:MoveTroopsToCoord(troopdatas,coord,purpose)
    end
    -- not support
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param userData any
---@param targetId number
---@param attackType wds.CreateAllianceAssembleType
---@param presetIndexArray number[]
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function SlgInterfaceModule:TroopEscrowToEntityViaData(lockable, userData, targetId, attackType, presetIndexArray, callback)
    return require("SlgModule").DoTroopEscrowToEntityViaData(lockable, userData, targetId, attackType, presetIndexArray, callback)
end

---@param presetIndex number
---@return number|nil
function SlgInterfaceModule:GetTroopEscrowStartTimeByPresetIndex(presetIndex)
    if self._validSlgModule then
        return self._validSlgModule:DoGetTroopEscrowStartTimeByPresetIndex(presetIndex)
    end
    return require("SlgModule").DoGetTroopEscrowStartTimeByPresetIndex(self, presetIndex)
end

function SlgInterfaceModule:GetStrongestTroopPower()
    if self._validSlgModule then
        return self._validSlgModule:DoGetStrongestTroopPower()
    end
    return require("SlgModule").DoGetStrongestTroopPower(self)
end

function SlgInterfaceModule:GetTroopInfoByPresetIndex(presetIndex, forceUpdate)
    if self._validSlgModule then
        return self._validSlgModule:GetTroopInfoByPresetIndex(presetIndex, forceUpdate)
    end
    if not self.myTroops or forceUpdate then
        self:UpdateTroopCache()
    end
    return self.myTroops[presetIndex]
end

---@type wds.Troop | wds.MapBuilding | wds.TroopChariot
function SlgInterfaceModule:IsMyTroop(troop)
    if troop == nil or troop.Owner == nil then
        return false
    end
    local myPlayer = ModuleRefer.PlayerModule:GetPlayer()
    if not myPlayer then return false end

    if troop.TypeHash == DBEntityType.Troop and myPlayer.ID == troop.Owner.PlayerID then
        return true
    end

    return false
end

function SlgInterfaceModule:UpdateTroopCache()
    self.myTroops, self.gmTroops = TroopManager.BuildTroopCache(ModuleRefer.TroopEditModule, self)
end

return SlgInterfaceModule
