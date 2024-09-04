local Delegate = require('Delegate')
local DBEntityPath = require('DBEntityPath')
local ModuleRefer = require('ModuleRefer')
local AbstractManager = require("AbstractManager")
local SlgLocalConfig = require('SlgLocalConfig')
local AllianceParameters = require('AllianceParameters')
local AllianceAuthorityItem = require('AllianceAuthorityItem')
local UIMediatorNames = require('UIMediatorNames')
local EventConst = require('EventConst')
local TimerUtility = require('TimerUtility')
local Utils = require("Utils")
local BattleSignalConfig = require('BattleSignalConfig')
local OnChangeHelper = require("OnChangeHelper")
local ManualResourceConst = require("ManualResourceConst")

---@class BattleSignalCache
---@field poolObj CS.PoolObject
---@field signal BattleSignal


---@class SlgBattleSignalManager : AbstractManager
---@field hud HUDBattleSignalMediator
---@field allianceModule AllianceModule
---@field allianceId number
---@field showSignal boolean
---@field signals table<int, BattleSignalCache>
local SlgBattleSignalManager = class('SlgBattleSignalManager',AbstractManager)

---@protected
function SlgBattleSignalManager:ctor(...)
    AbstractManager.ctor(self,...)
    self.allianceModule = ModuleRefer.AllianceModule    
    self.allianceId = -1
    self.signals = {}
    self.signalsFollowingTroop = {}
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
    self.vfxCreateHelper = nil
end

function SlgBattleSignalManager:Awake()
    --g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceMessage.MapLabels.MsgPath,Delegate.GetOrCreate(self,self.OnSignalChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_CACHED_MARK_DATA_CHANGED, Delegate.GetOrCreate(self,self.OnSignalChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.Owner.AllianceID.MsgPath,Delegate.GetOrCreate(self,self.OnAllianceChanged))
    g_Game.EventManager:AddListener(EventConst.ON_TROOP_CREATED,Delegate.GetOrCreate(self,self.OnTroopCreated))
    g_Game.EventManager:AddListener(EventConst.ON_TROOP_DESTROYED,Delegate.GetOrCreate(self,self.OnTroopDestory))
    g_Game.EventManager:AddListener(EventConst.ON_UIMEDIATOR_CLOSEED, Delegate.GetOrCreate(self, self.OnSignalHudClose))
    self.vfxCreateHelper = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper.Create("BattleSignal_vfx")
end

function SlgBattleSignalManager:Start()    
    self.signalRoot = CS.UnityEngine.GameObject("SignalHolder").transform
    self.signalRoot:SetParent(self._module.worldHolder, false)
    self.allianceId = self.allianceModule:GetAllianceId()
end

function SlgBattleSignalManager:OnDestroy()
    --g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceMessage.MapLabels.MsgPath,Delegate.GetOrCreate(self,self.OnSignalChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_CACHED_MARK_DATA_CHANGED, Delegate.GetOrCreate(self,self.OnSignalChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.Owner.AllianceID.MsgPath,Delegate.GetOrCreate(self,self.OnAllianceChanged))
    g_Game.UIManager:CloseAllByName(UIMediatorNames.HUDBattleSignalMediator)
    g_Game.EventManager:RemoveListener(EventConst.ON_TROOP_CREATED,Delegate.GetOrCreate(self,self.OnTroopCreated))
    g_Game.EventManager:RemoveListener(EventConst.ON_TROOP_DESTROYED,Delegate.GetOrCreate(self,self.OnTroopDestory))
    g_Game.EventManager:RemoveListener(EventConst.ON_UIMEDIATOR_CLOSEED, Delegate.GetOrCreate(self, self.OnSignalHudClose))
    if self.refresher then
        self.refresher:Stop()
        self.refresher = nil
    end
    if self.vfxCreateHelper then
        self.vfxCreateHelper:DeleteAll()
    end
    self.vfxCreateHelper = nil
end

function SlgBattleSignalManager:OnLodChange(lod, oldLod)
    local showSignal = false
    if lod > SlgLocalConfig.TroopMinLod then
        showSignal = true
    else
        showSignal = false
    end
    if showSignal ~= self.showSignal then
        self.showSignal = showSignal
        self:UpdateSignals()
    end
end

function SlgBattleSignalManager:OnCamSizeChange(size, oldSize)
    if self.showSignal and self.hud then
        self.hud:SetViewDirty()
    end
end

function SlgBattleSignalManager:OnAllianceChanged(entity,changed)
    self.allianceId = ModuleRefer.PlayerModule:GetPlayer().Owner.AllianceID
    self:UpdateSignals()
end

---@param coordX number @Coord X
---@param coordY number @Coord Y
---@param targetId number
---@param type number @AllianceMapLabelType
---@param content string
---@param configId number
---@param btnTrans CS.UnityEngine.Transform
---@param userData any
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function SlgBattleSignalManager:AddSignal(coordX, coordY, targetId, type, content, configId, btnTrans, userData, callback)
    if not self.allianceModule:IsInAlliance()  
        or not self.allianceModule:CheckHasAuthority(AllianceAuthorityItem.ModifyMapLabel)
    then
        return
    end
    local param = AllianceParameters.AddAllianceMapLabelParameter.new()
    param.args.X = coordX or 0
    param.args.Y = coordY or 0
    param.args.Type = type
    param.args.Target = targetId
    param.args.Content = content
    param.args.ConfigId = configId
    param:SendOnceCallback(btnTrans, userData, nil, callback)
end

---@param coordX number @Coord X
---@param coordY number @Coord Y
---@param targetId number
---@param type number @AllianceMapLabelType
---@param content string
---@param configId number
---@param btnTrans CS.UnityEngine.Transform
---@param userData any
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function SlgBattleSignalManager:ModifySignal(id,coordX, coordY, targetId, type, content, configId, btnTrans, userData, callback)
    if not self.allianceModule:IsInAlliance()
            or not self.allianceModule:CheckHasAuthority(AllianceAuthorityItem.ModifyMapLabel)
    then
        return
    end
    local param = AllianceParameters.SetAllianceMapLabelParameter.new()
    param.args.Id = id
    param.args.X = coordX or 0
    param.args.Y = coordY or 0
    param.args.Type = type
    param.args.Target = targetId
    param.args.Content = content
    param.args.ConfigId = configId
    param:SendOnceCallback(btnTrans, userData, nil, callback)
end

---@param id number
---@param btnTrans CS.UnityEngine.Transform
---@param userData any
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function SlgBattleSignalManager:DelSignal(id, btnTrans, userData, callback)
    if not self.allianceModule:IsInAlliance()  
        or not self.allianceModule:CheckHasAuthority(AllianceAuthorityItem.ModifyMapLabel)
    then
        return
    end
    local param = AllianceParameters.RemoveAllianceMapLabelParameter.new()
    param.args.Id = id
    param:SendOnceCallback(btnTrans, userData, nil, callback)
end

function SlgBattleSignalManager:GetHUD(callback)
    if not self.hud or Utils.IsNull(self.hud.CSComponent) then
        self.hud = nil
        g_Game.UIManager:Open(UIMediatorNames.HUDBattleSignalMediator,nil,function(mediator)
            self.hud = mediator
            if callback then
                callback()
            end
        end)
        return nil
    end
    return self.hud
end

---@param entity wds.Alliance
function SlgBattleSignalManager:OnSignalChanged(entity, add, remove, change)
    if not entity or entity.ID ~= ModuleRefer.AllianceModule:GetAllianceId() then
        return
    end
    if remove then
        for id, _ in pairs(remove) do
            self:RemoveSignal(id)
        end
    end

    if add then
        for id, value in pairs(add) do
            self:AddOrUpdateSignal(id,value)
        end
    end

    if change then
        for id, value in pairs(change) do
            self:AddOrUpdateSignal(id,value[2])
        end
    end

    -- self:UpdateSignals()
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_MAPLABLE_CHANGED)
end

function SlgBattleSignalManager:UpdateSignals()
    if not self.showSignal then
        -- if self.hud then
        --     g_Game.UIManager:Close(self.hud.runtimeId)
        --     self.hud = nil
        -- end
        self:ClearSignal()
        return
    end
    -- if not self.hud then
    --     self:GetHUD(function()
    --         self:UpdateSignals()
    --     end)
    --     return
    -- end    
    -- self.hud:ClearSignal()
    -- self:ClearSignal()
    if self.allianceModule:IsInAlliance() then
        local mapLabels = self.allianceModule:GetMyAllianceMapLabels()
        for key, value in pairs(mapLabels) do
            -- self.hud:AddOrUpdateSignal(key, value)
            self:AddOrUpdateSignal(key,value)
        end
    end

end

function SlgBattleSignalManager:OnTroopCreated(troopId,troopType,position)
    if not self.showSignal or self.allianceId < 1 then return end
    if not self.signalsFollowingTroop[troopId] then return end
    local signalId = self.signalsFollowingTroop[troopId]
    local signalCacheData = self.signals[signalId]
    local mapLabels = self.allianceModule:GetMyAllianceMapLabels()
    if table.isNilOrZeroNums(mapLabels) then
        self.signalsFollowingTroop[troopId] = nil
        return
    end
    local signalData = mapLabels[signalId]
    if not signalData or signalData.TargetId ~= troopId then
        self.signalsFollowingTroop[troopId] = nil
        return
    end
    if not signalCacheData then
        self:AddOrUpdateSignal(signalId,signalData)
    else       
        local param = BattleSignalConfig.MakeParameter(signalData)  
        if param then
            signalCacheData.signal:FeedData(param)
        else
            g_Logger.ErrorChannel("SlgBattleSignalManager","OnTroopCreated MakeParameter failed")
        end  
    end
end

function SlgBattleSignalManager:OnTroopDestory(troopId,troopType)
    if not self.showSignal or self.allianceId < 1 then return end
    if not self.signalsFollowingTroop[troopId] then return end
    local signalId = self.signalsFollowingTroop[troopId]
    local signalCacheData = self.signals[signalId]
    if signalCacheData then
        self:RemoveSignal(signalId)
    end    
end

function SlgBattleSignalManager:RefreshSignals()
    if not self.showSignal 
        -- or not self.hud 
    then
        return
    end   

    if not self.refresher then
        self.refresher = TimerUtility.DelayExecuteInFrame(function()
            self.refresher = nil
            self.hud:UpdateAllShowSignal()
        end,2)
    end    
end

function SlgBattleSignalManager:OnSignalHudClose(uiName)
    if uiName ~= UIMediatorNames.HUDBattleSignalMediator then
        return
    end
    self.hud = nil
    if self.refresher then
        self.refresher:Stop()
        self.refresher = nil
    end
end

---@param coordX number @Coord X
---@param coordY number @Coord Y
function SlgBattleSignalManager:HasSignalOnTile(coordX,coordY)
    if not self.allianceModule:IsInAlliance() then
        return false
    end
    local labels = self.allianceModule:GetMyAllianceMapLabels()
    if table.isNilOrZeroNums(labels) then
        return false
    end
    for key, value in pairs(labels) do
        if value.X == coordX and value.Y == coordY then
            return true
        end
    end
    return false
end

---@param coordX number @Coord X
---@param coordY number @Coord Y
---@return number,wds.AllianceMapLabel
function SlgBattleSignalManager:GetSignalOnTile(coordX,coordY)
    if not self.allianceModule:IsInAlliance() then
        return
    end
    local mapLabels = self.allianceModule:GetMyAllianceMapLabels()
    if table.isNilOrZeroNums(mapLabels) then
        return
    end
    for id, value in pairs(mapLabels) do
        if value.X == coordX and value.Y == coordY then
            return id,value
        end
    end    
end

function SlgBattleSignalManager:HasSignalOnEntity(entity)
    if not self.allianceModule:IsInAlliance() then
        return false
    end
    local mapLabels = self.allianceModule:GetMyAllianceMapLabels()
    if table.isNilOrZeroNums(mapLabels) then
        return false
    end
    for key, value in pairs(mapLabels) do
        if value.TargetId == entity then
            return true
        end
    end
    return false
end 

---@return number|nil,wds.AllianceMapLabel
function SlgBattleSignalManager:GetSignalOnEntity(entity)
    if not self.allianceModule:IsInAlliance() then
        return
    end
    local mapLabels = self.allianceModule:GetMyAllianceMapLabels()
    if table.isNilOrZeroNums(mapLabels) then
        return
    end
    for key, value in pairs(mapLabels) do
        if value.TargetId == entity then
            return key,value
        end
    end
    return
end

---@param id number
---@param data wds.AllianceMapLabel
function SlgBattleSignalManager:AddOrUpdateSignal(id,data)    
    if not data then
        return
    end
    local param = BattleSignalConfig.MakeParameter(data)  
    if not param then
        return
    end  
    if not self.signals[id] then
        self.signals[id] = {}
        self._module.pool:SpawnAsync(ManualResourceConst.ui3d_league_mark,function(pObject)
            if pObject and pObject.trans then
                --对应异步还没完成时signal 数据就被删除的情况
                if not self.signals[id] then
                    pObject:Despawn(0)
                    return
                end
                self.signals[id].poolObj = pObject
                pObject.trans:SetParent(self.signalRoot,false)
                local signalGo = pObject.transform.gameObject            
                if signalGo then
                    local signalBehaviour = signalGo:GetLuaBehaviour('BattleSignal')
                    self.signals[id].signal = signalBehaviour.Instance                    
                end
                if self.signals[id].signal then
                    self.signals[id].signal.transform = pObject.transform
                    self.signals[id].signal:FeedData(param)
                    self.signals[id].signal:PlayDropDownAni()
                end            
            end        
        end
    )
    else
        if self.signals[id].signal then
            self.signals[id].signal:FeedData(param)
        end
    end

    if data.TargetId and data.TargetId > 0 and BattleSignalConfig.TroopOrMobTypeHash[data.TargetTypeHash] then        
        self.signalsFollowingTroop[data.TargetId] = id         
    end
end


function SlgBattleSignalManager:RemoveSignal(id)
    if not self.signals[id] then
        return
    end
    if self.signals[id].poolObj then
        self.signals[id].poolObj:Despawn(0)
        -- self._module.pool:Despawn(self.signals[id].poolObj)
    end
    self.signals[id] = nil
end

function SlgBattleSignalManager:ClearSignal()
    for id, signal in pairs(self.signals) do
        if signal.poolObj then
            CS.TransformHelper.SetPositionSyncHelper(signal.poolObj.transform,nil)
            signal.poolObj:Despawn(0)
            -- self._module.pool:Despawn(signal.poolObj)
        end
    end
    table.clear(self.signals)
    table.clear(self.signalsFollowingTroop)
end

return SlgBattleSignalManager
