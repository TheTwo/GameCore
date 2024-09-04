local Delegate = require('Delegate')
local UnmanagedMemoryEecoder = require('UnmanagedMemoryEecoder_Gen')
---@class Vector2
---@field x number
---@field y number
---
---@class Vector3
---@field x number
---@field y number
---@field z number
---

---@class TroopViewEntityManager
---@field new fun():TroopViewEntityManager
local TroopViewEntityManager = class("TroopViewEntityManager", require("BaseManager"))
function TroopViewEntityManager:ctor()
    self.initialized = false
end

function TroopViewEntityManager:Init()
    CS.ECSHelper.RestartECSWorld() 
    local jsonText = g_Game.AssetManager:LoadText('troop_skill')
    ---@type CS.DragonReborn.SLG.Troop.TroopViewManager
    self.manager = CS.DragonReborn.SLG.Troop.TroopViewManager.Instance;
    self.manager:OnGameInitialize(jsonText)
    g_Game:AddSystemTicker(Delegate.GetOrCreate(self,self.Tick))

    self.initialized = true
end

function TroopViewEntityManager:SetWorldScale(scale)
    if not self.initialized then return end
    self.manager:SetupWorldScale(scale)
end

---@return CS.DragonReborn.SLG.Troop.TroopViewManager
function TroopViewEntityManager:GetCSManager()
    if not self.initialized then return end
    return self.manager
end

function TroopViewEntityManager:Tick(delta)
    if self.initialized then
        self.manager:Tick(delta)
    end
end

---@return CS.DragonReborn.SLG.Troop.TroopData
function TroopViewEntityManager:GetTroopEntityData()
    ---@type CS.DragonReborn.SLG.Troop.TroopData
    local defaultData = {}
    defaultData.id                  = 0              
    defaultData.heroAIType          = 0 
    defaultData.troopType           = 0
    defaultData.position            = {x = 0,y = 0,z = 0} --CS.UnityEngine.Vector3.zero
    defaultData.direction           = {x = 0,y = 0,z = 0} --CS.UnityEngine.Vector3.zero
    defaultData.moveSpeed           = 0
    defaultData.rotateSpeed         = 0
    defaultData.radius              = 0
    defaultData.heroName            = {}
    defaultData.heroScale           = {}
    defaultData.heroType            = {} -- 1：近战；2：远程；3：宠物；4：战争堡垒；5：BOSS
    defaultData.heroOffset          = {}
    defaultData.heroBattleOffset    = {}    
    defaultData.heroState           = {} -- 0：死亡；1：存活
    defaultData.heroNormalAtkId     = {}
    defaultData.layerMask           = 0
    defaultData.attackRange         = 0
    defaultData.petName             = {}
    defaultData.petOffset           = {}
    defaultData.petScale            = {}
    defaultData.petBattleOffset     = {}
    defaultData.petState            = {}
    defaultData.petNormalAtkId      = {}
    return defaultData
end

---@param data CS.DragonReborn.SLG.Troop.TroopData
function TroopViewEntityManager:CreateTroopViewEntity(data,viewGo)
    if not self.initialized then return end  
    local memSize = UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopData(data)
    self:PrepareMemoryBuff(memSize)
    local stringCache = {
        uid = 0,
        stringList = {}
    }
    UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopData(self.memBuffPtr,data,stringCache)
    CS.DragonReborn.SLG.Troop.LuaTroopViewHelper.TransferTroopViewCreateData(self.memBuffPtr,stringCache.stringList,viewGo)
end

function TroopViewEntityManager:SetUnitState(troopId, heroIndices, heroStates, petIndices, petStates)
    if not self.initialized then return end  
    self.manager:SetUnitState(troopId, heroIndices, heroStates, petIndices, petStates)
end

function TroopViewEntityManager:DelTroopViewEntity(id)
    if not self.initialized then return end
    self.manager:DelTroopView(id)
end

function  TroopViewEntityManager:SetPath(id,waypoints,speed)
    if not self.initialized then return end
    self.manager:SetMovePath(id,waypoints,speed)
end

function TroopViewEntityManager:SetTroopMapState(id,state)
    if not self.initialized then return end
    self.manager:SetTroopMapState(id,state)
end

function TroopViewEntityManager:SetTroopSpState(id,state)
    if not self.initialized then return end
    self.manager:SetTroopSpState(id,state)
end

function TroopViewEntityManager:SyncViewHeight(id,height)
    if not self.initialized then return end
    self.manager:SyncViewHeight(id,height)
end

---@param pos {x:number,z:number}
function TroopViewEntityManager:SyncViewPosition(id,pos)
    if not self.initialized then return end
    self.manager:SyncViewPosition(id,pos.x,pos.z)
end

---@param x number
---@param z number
function TroopViewEntityManager:SyncViewPosElementWise(id, x, z)
    if not self.initialized then return end
    self.manager:SyncViewPosition(id, x, z)
end

---@param dir wds.Vector3F
function TroopViewEntityManager:SyncViewDirection(id,dir)
    if not self.initialized then return end
    self.manager:SyncViewDirection(id,dir.X,dir.Y)
end

---@param dir wds.Vector3F
function TroopViewEntityManager:SyncViewDirElementWise(id, dx, dz)
    if not self.initialized then return end
    self.manager:SyncViewDirection(id, dx, dz)
end

---@param pos {x:number,z:number}
---@param dir wds.Vector3F
function TroopViewEntityManager:SyncViewTrans(id,pos,dir)
    if not self.initialized then return end
    self.manager:SyncViewTrans(id,pos.x,pos.z,dir.X,dir.Y)
end

function TroopViewEntityManager:SyncViewTransElementWise(id, px, pz, dx, dz)
    if not self.initialized then return end
    self.manager:SyncViewTrans(id, px, pz, dx, dz)
end

function TroopViewEntityManager:SetTroopVisible(id,visible)
    if not self.initialized then return end
    self.manager:SetTroopVisible(id,visible)
end

function TroopViewEntityManager:SetTroopBattleTarget(id,type,targetId,targetPos,radius)
    if not self.initialized then return end
    targetId = targetId and targetId or 0
    targetPos = targetPos and targetPos or {x = 0,y = 0,z = 0}--CS.UnityEngine.Vector3.zero
    radius = radius and radius or 0
    self.manager:SetTroopTarget(id,type,targetId,targetPos,radius)
end

function TroopViewEntityManager:Reset()
    if not self.initialized then return end
    try_catch_traceback_with_vararg(self.manager.Reset, nil, self.manager)
    g_Game:RemoveSystemTicker(Delegate.GetOrCreate(self,self.Tick))
end

function TroopViewEntityManager:OnLowMemory()
    if not self.initialized then return end
    try_catch_traceback_with_vararg(self.manager.OnLowMemory, nil, self.manager)
end

function TroopViewEntityManager:OnSceneStart(mapSystem)
    if not self.initialized then return end   
    self.manager:OnSceneStart(mapSystem)
end

function TroopViewEntityManager:OnStaticMapDataLoaded()
    if not self.initialized then return end
    self.manager:OnStaticMapDataLoaded()
end

function TroopViewEntityManager:OnSceneEnd()
    if not self.initialized then return end
    self:SetSkillVfxLimit(0,0,0,0)    
    self.manager:ClearSkillDamageEvent()
    self.manager:OnSceneEnd()
    if self.memBuffPtr then
        Unmanaged.Free(self.memBuffPtr)
        self.memBuffPtr = nil
    end
end

function TroopViewEntityManager:InitSkillDamageText(mainCam,orthScale,textStyle,duration)
    self.manager:InitSkillDamageText(mainCam,orthScale,textStyle,duration)
end

function TroopViewEntityManager:SetSkillDamageOffset(offset)
    self.manager:SetSkillDamageOffset(offset)
end

function TroopViewEntityManager:SetSkillVfxLimit(maxFx, maxAudio, maxText, maxPriority)
    if not self.initialized then return end
    self.manager:SetSkillVfxLimit(maxFx, maxAudio, maxText,maxPriority)
end

function TroopViewEntityManager:SetSkillVfxScale(scale)
    if not self.initialized then return end
    self.manager:SetSkillVfxScale(scale)
end

function TroopViewEntityManager:SetupRVO(unitsPerCell,simulateFPS,maxAngle)
    if not self.initialized then return end
    unitsPerCell = math.ceil(unitsPerCell)
    self.manager:SetupRVO(unitsPerCell, unitsPerCell,simulateFPS,maxAngle)
end

function TroopViewEntityManager:ShowSelectionCircle(troopId, selected )
    self.manager:SetTroopSelectState(troopId,selected)
end

function TroopViewEntityManager:ShowBattleStateCircle(troopId,inBattle)
    self.manager:SetTroopBattleState(troopId,inBattle)
end

function TroopViewEntityManager:SetBuffFx(troopId,id,buffName,yOffset,scale,enable)
    if not self.initialized then return end
    self.manager:SetupBuffVfx(troopId,id,buffName,yOffset,scale,enable)
end

function TroopViewEntityManager:AddSkillDamageEvent(onSkillDamage)
    if not self.initialized then return end
    self.manager:AddSkillDamageEvent(onSkillDamage)
end

local TroopViewVfxUtilities = CS.DragonReborn.SLG.Troop.TroopViewVfxUtilities

---@return number @Vfx GUID
function TroopViewEntityManager:AddVfxToTroop(troopId,vfxName,yOffset,scale,follow)
    if not self.initialized then return end    
    return TroopViewVfxUtilities.AddVfxToTroop(troopId,vfxName,yOffset,scale,follow)
end

function TroopViewEntityManager:RemoveVfx(vfxGuid)
    if not self.initialized or not vfxGuid or vfxGuid < 0 then return end
    TroopViewVfxUtilities.RemoveVfxOnTroop(vfxGuid)
end

function TroopViewEntityManager:ShowVfxOnTroop(vfxGuid)
    if not self.initialized or not vfxGuid or vfxGuid < 0 then return end
    TroopViewVfxUtilities.StartVfxOnTroop(vfxGuid)
end

function TroopViewEntityManager:HideVfxOnTroop(vfxGuid)
    if not self.initialized or not vfxGuid or vfxGuid < 0 then return end
    TroopViewVfxUtilities.StopVfxOnTroop(vfxGuid)
end

---@param vfxName string
---@param position CS.UnityEngine.Vector3
---@param direction CS.UnityEngine.Vector3
---@param scale number
---@return number @Vfx GUID
function TroopViewEntityManager:CreateVfx(vfxName,position,direction,scale)
    if not self.initialized then return end    
    return TroopViewVfxUtilities.SimpleCreateVfx(vfxName,position,direction,scale)
end

---@param vfxName string
---@param position CS.UnityEngine.Vector3
---@param direction CS.UnityEngine.Vector3
---@param scale number
---@param duration number
---@param speed number
---@return number @Vfx GUID
function TroopViewEntityManager:CreateVfxExtend(vfxName,position,direction,scale,duration,speed)
    if not self.initialized then return end
    return TroopViewVfxUtilities.CreateVfx(vfxName,position,direction,scale,duration,speed)
end

function TroopViewEntityManager:OnRoundBegin(roundId)    
    self.manager:OnRoundBegin(roundId)
end

---@param skillDatas CS.DragonReborn.SLG.Troop.TroopViewManager.TroopSkillData[]
function TroopViewEntityManager:TransferSkillDatas(skillDatas)
    if not self.initialized then return end

    local dataSize = #skillDatas
    local dataMemSize = 4
    for i = 1, dataSize do
        dataMemSize = dataMemSize + UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopViewManager_TroopSkillData(skillDatas[i])
    end

    self:PrepareMemoryBuff(dataMemSize)    

    Unmanaged.WriteInt32(self.memBuffPtr,dataSize)
    local stringCache = {
        uid = 0,
        stringList = {}
    }
    for i = 1, dataSize do
        UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopViewManager_TroopSkillData(self.memBuffPtr,skillDatas[i],stringCache)
    end
    self.manager:TransferSkillDataMemPtr(self.memBuffPtr,stringCache.stringList)    
end

---@param roundDatas table<int,CS.DragonReborn.SLG.Troop.TroopViewManager.TroopRoundData>
function TroopViewEntityManager:TransferRoundData(roundDatas)
    if not self.initialized or not roundDatas then return end
    local troopIds = table.keys(roundDatas)   
    local dataMemSize = 4
    local dataSize = #troopIds
    for i = 1, dataSize do        
        dataMemSize = dataMemSize + UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopViewManager_TroopRoundData(roundDatas[troopIds[i]])
    end
    
    self:PrepareMemoryBuff(dataMemSize)
    Unmanaged.WriteInt32(self.memBuffPtr,dataSize)
    local stringCache = {
        uid = 0,
        stringList = {}
    }
    for i = 1, dataSize do
        UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopViewManager_TroopRoundData(self.memBuffPtr,roundDatas[troopIds[i]],stringCache)
    end

    self.manager:TransferRoundDataMemPtr(self.memBuffPtr,stringCache.stringList)  
end


function TroopViewEntityManager:PrepareMemoryBuff(memSize)
    if not self.memBuffPtr then
        self.memBuffSize = CS.UnityEngine.Mathf.NextPowerOfTwo(memSize)
        self.memBuffPtr = Unmanaged.Alloc(self.memBuffSize)
    else
        if self.memBuffSize < memSize then
            Unmanaged.Free(self.memBuffPtr)
            self.memBuffSize = CS.UnityEngine.Mathf.NextPowerOfTwo(memSize)
            self.memBuffPtr = Unmanaged.Alloc(self.memBuffSize)
        else
            Unmanaged.Seek(self.memBuffPtr,0,0)--CS.System.IO.SeekOrigin.Begin
        end
    end
end

function TroopViewEntityManager:SetLodLevel(level)
    if not self.initialized then return end
    self.manager:SetTroopLod(0,level)
end

return TroopViewEntityManager