local Utils = require('Utils')
local SlgPoolObject = require("SlgPoolObject")
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local TroopConst = require("TroopConst")
local EventConst = require('EventConst')
local PoolUsage = require("PoolUsage")
local KingdomMapUtils = require("KingdomMapUtils")
local UISlgBattleInfo = require('UISlgBattleInfo')
local MonsterBubbleType = require('MonsterBubbleType')
local ConfigRefer = require('ConfigRefer')
local MonsterClassType = require('MonsterClassType')
local RangeVisibleType = require('RangeVisibleType')
local ManualResourceConst = require("ManualResourceConst")
local SLGConst_Manual = require('SLGConst_Manual')
local SlgUtils = require('SlgUtils')
local KingdomConstant = require('KingdomConstant')

local PooledGameObjectHandle = CS.DragonReborn.AssetTool.PooledGameObjectHandle

---@class TroopView : SlgPoolObject
local TroopView = class('TroopView',SlgPoolObject)

---@class SoldierViewGroup
---@field list SoldierView[]

---@class GroupData
---@field count number
---@field data table

local HUD_HeadHeight = 100
local HUD_HeadOffset = 300
local HUD_BottomOffset = 200

---@param ctrl TroopCtrl
function TroopView:ctor(ctrl)
    SlgPoolObject.ctor(self)

    self.troopCtrl = ctrl
    self.isSelected = false
    self.module = ModuleRefer.SlgModule
    self.xCoordScale, self.zCoordScale = self.module:GetServerCoordinateScale()
    self.ShowMinLodLevel,self.ShowMaxLodLevel = self.module.troopManager:GetMinMaxLod()
    self.camSizeMin,self.camSizeMax = self.module.troopManager:GetCamSizeRange()
    self.battleRelationState = 0
    self.ServerPosition = {X = 0,Y = 0,Z = 0}
    self.ServerDirection = {X = 1,Y = 0,Z = 0}
    
    self.rootHandle = PooledGameObjectHandle(PoolUsage.Troop)
    self.simpleModeHandle = PooledGameObjectHandle(PoolUsage.Troop)
    self.lodIconHandle = PooledGameObjectHandle(PoolUsage.Troop)
    self.hudHandle = PooledGameObjectHandle(PoolUsage.Troop)
    self.bubbleHandle = PooledGameObjectHandle(PoolUsage.Troop)
    self.warningHandle = PooledGameObjectHandle(PoolUsage.Troop)
    self.debugInfoHandle = PooledGameObjectHandle(PoolUsage.Troop)

    self.data = ctrl._data
    self.ID = ctrl.ID

    self.behaviourState = 0
end

---@param name string
---@param holder CS.UnityEngine.Transform
---@param callback fun(pObject:TroopView)
function TroopView:StartupTroopView(name, holder, callback)
    self.rootHandle:Create("lod_view_troop", nil, function(go)
        self:DoOnSpawn(go.transform, name)

        self.trans:SetParent(holder, false)
        go.name = name

        if callback then
            callback()
        end
    end)
end

function TroopView:OnSpawn()
    self.HasTroopLine = true
    self.TroopLine = nil
    self.Speed = 0
    self._isShow = false
    self._overMaxLod = false
    self._isEscaping = false
    self._isMoving = false
    self._battleRes = nil

    self.trans:set_position(self.module:ServerCoordinate2Vector3(self.data.MapBasics.Position))

    ---@type CS.UnityEngine.BoxCollider
    self._collider = self.trans:GetComponent(typeof(CS.UnityEngine.BoxCollider))

    ---@type CS.DragonReborn.SLG.Troop.TroopViewProxy
    self._csView = self.trans:GetComponent(typeof(CS.DragonReborn.SLG.Troop.TroopViewProxy))
    if self._csView then
        self._csView.ID = self.ID
    else
        g_Logger.ErrorChannel('TroopView',"[OnSpawn] Missing TroopViewProxy, TroopID:%d", self.ID)              
    end

    g_Game.EventManager:AddListener(EventConst.RADAR_STATE_CHANGE,Delegate.GetOrCreate(self,self.OnRadarStateChanged))

    ---@type number[]
    self.viewVisible = nil
end

function TroopView:SetCSViewEnabled(enabled)
    if self._csView then
        self._csView.enabled = enabled
    end
end

function TroopView:GetForward()
    if self.data then
        return CS.UnityEngine.Vector3(self.ServerDirection.X,0,self.ServerDirection.Y)
    else
        return SlgPoolObject.GetForward(self)
    end
end

function TroopView:StartFromLua()
    self:SetTroopSelectionInfo(false)
end

function TroopView:CreateAvatar()
    if self.hasViewEntity then
        return
    end
    self.hasViewEntity = true
    local troopData, extraInfo = self.module.troopManager:CreateECSTroopData(self.data)
    if troopData then
        troopData.simpleMode = self.troopCtrl:AffectedBySimpleMode()
        g_Game.TroopViewManager:CreateTroopViewEntity(troopData,self.transform.gameObject)
        if not troopData.simpleMode then
            self:CreateBornVfx(troopData)
            self:CreateTroopBornVfx()
        end
    end
    self.extraInfo = extraInfo
end

function TroopView:DestroyAvatar()
    if not self.hasViewEntity then
        return
    end
    self.hasViewEntity = false
    self._isShow = false    
    self:CreateTroopDisappearVfx()
    self:DestroyTroop()
    g_Game.TroopViewManager:DelTroopViewEntity(self.ID)
end

function TroopView:CreateSimpleMode()
    if not self.simpleMode then
        self.simpleModeHandle:Create("troop_hud_simplified", self.transform, function(go)
            if Utils.IsNotNull(go) then
                ---@type TroopHUDSimplified
                self.simpleMode = go:GetLuaBehaviour("TroopHUDSimplified").Instance
                self.simpleMode:FeedData(self.troopCtrl)
                self.simpleMode:SetVisible(self.viewVisible)
            end
        end)
    end
end

function TroopView:DestroySimpleMode()
    self.simpleModeHandle:Delete()
    self.simpleMode = nil
end

function TroopView:CreateBornVfx(troopData)   
    if not self.data or not troopData then
        return
    end
    local bornFxName = nil
    local bornFxScale = 1
    if self.data.MobInfo
        and self.data.Battle and self.data.Battle.BattleWrapper and g_Game.ServerTime:GetServerTimestampInMilliseconds() - self.data.Battle.BattleWrapper.SpawnTime < 500 
    then
        local mobCfg = ConfigRefer.KmonsterData:Find(self.data.MobInfo.MobID)
        if mobCfg then
            local bornFxId = mobCfg:BornFx()
            if bornFxId and bornFxId > 0 then
                local fxArtCfg = ConfigRefer.ArtResource:Find(bornFxId)
                if fxArtCfg then
                    bornFxName = fxArtCfg:Path()
                    bornFxScale = fxArtCfg:ModelScale()
                end
            end
            if string.IsNullOrEmpty(bornFxName) then
                bornFxName = 'fx_monster_juntang_born'                
            end
            if bornFxScale < 0.01 then
                bornFxScale = 1
            end
        end
    elseif self.data.BehemothTroopInfo then
        bornFxName = 'vfx_bigmap_jushouzhaohuan'
    end
    if bornFxName then
        g_Game.TroopViewManager:CreateVfx(bornFxName,troopData.position,troopData.direction,troopData.radius * bornFxScale)
    end
end

function TroopView:UpdateHeroState(onlyDead)
    if self.data and self.data.Battle and self.data.Battle.Group.Heros:Count() > 0 then
        local needUpdateState = false
        local heroIndices = {}
        local heroStats = {}
        local petIndices = {}
        local petStats = {}

        for key, value in pairs(self.data.Battle.Group.Heros) do
            if not onlyDead or value.Hp < 1 then
                table.insert(heroIndices,key)
                table.insert(heroStats, value.Hp < 1 and 0 or 1)
                needUpdateState = true
            end

            if value.Pets and value.Pets[0] then
                if not onlyDead or value.Pets[0].Hp < 1 then
                    table.insert(petIndices,key)
                    table.insert(petStats, value.Pets[0].Hp < 1 and 0 or 1)
                    needUpdateState = true
                end
            end
        end

        if needUpdateState then
            g_Game.TroopViewManager:SetUnitState(self.data.ID, heroIndices, heroStats, petIndices, petStats)
        end
    end
end

function TroopView:CreateHud()
    local hudHeight = HUD_HeadHeight
    local hudOffset = HUD_HeadOffset * self.module.slgScale    
    local hudBtnOffset = HUD_BottomOffset * self.module.slgScale     
    if not self.hud then
        self.hudHandle:Create("troop_hud", self.transform, function(go)
            if Utils.IsNotNull(go) then
                self.hudGo = go
                self.hudGo.transform:SetParent(self.transform)
                self.hud = self.hudGo:GetLuaBehaviour('TroopHUD').Instance
                self.hud:Hide()
                self.hud:SetFacingOffset(hudOffset,hudBtnOffset)
                self.hud:SetYOffset(hudHeight,0)
                self.hud:FeedData(self.troopCtrl)
                if self._curLod then
                    self.hud:OnLodChange(self._curLod,self._overMaxLod)
                end
                if self.battleRelationState > 0 then
                    self.hud:SetBattleRelationState(true)
                end                        
            end
        end)
    else
        self.hud:SetFacingOffset(hudOffset,hudBtnOffset)
        self.hud:SetYOffset(hudHeight,0)
        self.hud:FeedData(self.troopCtrl)                
    end
end

function TroopView:DestroyHud()
    if self.hud then
        self.hud:Release()
        self.hud = nil
    end

    self.hudHandle:Delete()
    self.hudGo = nil
end

function TroopView:OnDespawn()
    if (self.TroopLine) then
        self.TroopLine:SetupEndPointsTrans(nil)
        self.module.troopLineManager:DestroyTroopLine(self.TroopLine)
        self.TroopLine = nil
    end   
    
    self:DestroyAvatar()
    self:DestroyHud()
    self:DestroySimpleMode()

    if self.hud then
        self.hud:Release()
        self.hud = nil
    end

    self.hudHandle:Delete()
    self.hudGo = nil

    self.bubbleHandle:Delete()
    self.bubbleGo = nil
    self.bubble = nil

    self.lodIconHandle:Delete()
    self.lodIcon = nil

    if self._csView then
        self._csView:Release()
        self._csView = nil
    end

    g_Game.EventManager:RemoveListener(EventConst.RADAR_STATE_CHANGE,Delegate.GetOrCreate(self,self.OnRadarStateChanged))

    if self._debugInfo then
        self:RemoveDebugInfo()
    end

    self.rootHandle:Delete()
end

---@param path CS.UnityEngine.Vector3[]
function TroopView:SetPath(path, moving, showLine)
    self.Path = path
    self.HasTroopLine = showLine
    self:ResetTroopLine()

    self._hasPath = path and #path > 0

    if self._hasPath and moving then
        self._isMoving = true
        self:SyncTroopState()
    else
        self._isMoving = false
        self:SyncTroopState()
    end
   
    if self._hasPath then
        self:DoMoveStart()
    else
        self:DoMoveEnd()
    end
end

function TroopView:ToggleAvatar(bShow)
    if bShow then
        self:CreateAvatar()
    else
        self:DestroyAvatar()
    end
end

function TroopView:ToggleHud(bShow)
    local simpleMode = self.troopCtrl:AffectedBySimpleMode()
    if bShow and not simpleMode then
        self:CreateHud()
    else
        self:DestroyHud()
    end
end

function TroopView:ToggleSimpleMode(bShow)
    local simpleMode = self.troopCtrl:AffectedBySimpleMode()
    if bShow and simpleMode then
        self:CreateSimpleMode()
    else
        self:DestroySimpleMode()
    end
end

function TroopView:SetShow(show)
    if (self._isShow ~= show) then
        self._isShow = show

        self.transform:SetVisible(show)
        self:ToggleAvatar(show)
        self:ToggleHud(show)
        self:ToggleSimpleMode(show)
        self:UpdateCollider()

        if self._isShow then
            if self.troopCtrl:IsTroop() and KingdomMapUtils.IsMapState() then
                if not self.lodIcon then
                    self.lodIconHandle:Create(ManualResourceConst.ui3d_hud_troop_lod, self.transform, function(go, data)
                        if Utils.IsNotNull(go) then
                            self.lodIcon = go:GetLuaBehaviour("TroopLodIcon").Instance
                            self.lodIcon:FeedData(self.troopCtrl)
                            self:RefreshLodIcon()
                        end
                    end)
                else
                    self.lodIcon:FeedData(self.troopCtrl)
                    self:RefreshLodIcon()
                end
            end

            self:SetTroopSelectionInfo(self.isSelected)
            self:UpdateLod()
        end
        if self.module.DebugMode then
            self:UpdateDebugInfo()
        end
    end
end

function TroopView:CreateMonsterBubble(bubbleType)

    local bubbleIcon = nil
    if bubbleType == MonsterBubbleType.Battle then
        bubbleIcon = "sp_radar_icon_monster"
    end
    
    local clickCall = Delegate.GetOrCreate(self, self.OnBubbleClick)
    local localPos = CS.UnityEngine.Vector3.up
    local lcoalScale = CS.UnityEngine.Vector3.one * self.module.unitsPerTileX
    
    if not self.bubble then
        self.bubbleHandle:Create("ui3d_bubble_group", self.transform, function(pObject)
            if Utils.IsNotNull(pObject) then
                self.bubbleGo = pObject
                self.bubbleGo.transform:SetParent(self.transform)    
                
                local trans = self.bubbleGo.transform
                trans.localPosition = localPos
                trans.localScale = lcoalScale

                ---@type City3DBubbleStandard
                self.bubble = self.bubbleGo.trans:get_gameObject():GetLuaBehaviour('City3DBubbleStandard').Instance
                self.bubble:ShowBubble(bubbleIcon,true,false,false)  
                self.bubble:SetOnTrigger(clickCall)                     
            end
        end)
    else
        local trans = self.bubbleGo.transform
        trans.localPosition = localPos
        trans.localScale = lcoalScale
        self.bubble:ShowBubble(bubbleIcon,true,false,false)  
        self.bubble:SetOnTrigger(clickCall)   
    end
end

function TroopView:OnBubbleClick()
    self.module:SelectAndOpenTroopMenu(self.troopCtrl)
    return true
end

function TroopView:UpdateCollider()
    self:SetColliderEnabled(self._isShow and not self._overMaxLod)
end

function TroopView:SetColliderEnabled(enabled)
    if self._collider then
        self._collider.enabled = enabled
    end
end

function TroopView:SetColliderSize(size)
    if self._collider then
        self._collider.size = CS.UnityEngine.Vector3(size, 0.1, size)
    end
end

function TroopView:UpdateLod(lod)
    if lod == nil then
        lod = self.module:GetLodValue()
    end

    self._curLod = lod
    
    if self.ShowMinLodLevel < self.ShowMaxLodLevel and self.ShowMaxLodLevel > 0 then
        if (lod > self.ShowMaxLodLevel or lod < self.ShowMinLodLevel) then
            self._overMaxLod = true
        else
            self._overMaxLod = false
        end
    else
        self._overMaxLod = false
    end
    self:OnLodChange(self._overMaxLod,lod)
    if self.hud then
        self.hud:OnLodChange(lod,self._overMaxLod)
    end
    self:RefreshLodIcon()
    self:ShowClassVfx()
end

---@param target TroopCtrl
function TroopView:SetAttackTarget(target)
    if (target) then
        g_Game.TroopViewManager:SetTroopBattleTarget(self.ID, SlgUtils.TargetType.Entity, target.ID)
    else
        g_Game.TroopViewManager:SetTroopBattleTarget(self.ID, SlgUtils.TargetType.None)
    end
end

function TroopView:SetAttackPosition(pos,size)
    g_Game.TroopViewManager:SetTroopBattleTarget(self.ID, SlgUtils.TargetType.Position, 0, pos, size)
end

function TroopView:ResetTroopLine()
    if not self.HasTroopLine then
        return
    end

    if self.TroopLine then
        self.TroopLine:Clear()
    else
        self.TroopLine = self.module.troopLineManager:CreateLine(false)
    end

    self.TroopLine:SetupEndPointsTrans(self.transform)
end

---@param pos wds.Vector3F
function TroopView:SetServerPosition(pos)   
    if not self.ServerPosition then
        self.ServerPosition = {X = 0,Y = 0,Z = 0}
    end
    self.ServerPosition.X = pos.X
    self.ServerPosition.Y = pos.Y
    self.ServerPosition.Z = pos.Z
end

---@param dir wds.Vector3F
function TroopView:SetServerDirection(dir)
    if not self.ServerDirection then
        self.ServerDirection = {X = 0,Y = 0,Z = 0}
    end
    self.ServerDirection.X = dir.X
    self.ServerDirection.Y = dir.Y
    self.ServerDirection.Z = dir.Z
end

function TroopView:ApplyTrans()
    local x = self.ServerPosition.X * self.xCoordScale
    local z = self.ServerPosition.Y * self.zCoordScale
    g_Game.TroopViewManager:SyncViewTransElementWise(self.ID, x, z, self.ServerDirection.X, self.ServerDirection.Y)
end

function TroopView.CalcSqrMagnitudeXZ(pos1,pos2)
    return (pos1.x-pos2.x)*(pos1.x-pos2.x) + (pos1.z-pos2.z)*(pos1.z-pos2.z)
end
function TroopView.CalcMagnitudeXZ(pos1,pos2)
    return math.sqrt(TroopView.CalcSqrMagnitudeXZ(pos1,pos2))
end


function TroopView:GetMoveStopTime()
    local troop = self.troopCtrl:GetData()
    local endTime = SlgUtils.CalculateTroopMoveStopTime(troop.MapBasics, troop.MovePathInfo)
    return endTime
end

function TroopView:OnLodChange(overMaxLod,lod)
    self:UpdateCollider()
    self:SetVisible(not overMaxLod, lod > KingdomConstant.SymbolLod)
    if self.viewVisible and self.hasViewEntity then
        if self._lastState == TroopConst.STATE_MOVE then
            self:ShowMoveVfx()
        else
            self:HideMoveVfx()
        end
    else
        self:HideMoveVfx()
    end

end

function TroopView:UpdateCamSize(size, oldSize)
    if self._overMaxLod then
        return
    end
end

function TroopView:SetTroopSelectionInfo(selected)
    self.isSelected = selected
    if self.hud then
        self.hud:SetDirty()
    end
    g_Game.TroopViewManager:ShowSelectionCircle(self.ID,selected)
   
    if self.bubbleGo then
        self.bubbleGo:SetVisible(not selected)
    end
    if selected then
        self:ShowWarningRange()
    else
        self:HideWarningRange()
    end
end

function TroopView:SetFocus(focused)
    self.isFocus = focused
    self:SetDirty(true)
end

---@param ctrl TroopCtrl
---@param config KmonsterDataConfigCell
function TroopView:ShowWarningRange()

    if not self.troopCtrl:IsMonster() then
        return
    end

    local config = ConfigRefer.KmonsterData:Find(self.troopCtrl._data.MobInfo.MobID)
    local showFlag = config:RangeVisible()    
    if showFlag == RangeVisibleType.None then
        return
    end        

    local setupWarningFx = 
    ---@param pObject SlgPoolObject
    function( pObject )        
        if not pObject or not pObject.transform then
            return
        end
        ---@type PvPTileAssetCircleRangeBehavior
        local luaCtrl = pObject:GetLuaBehaviour('PvPTileAssetCircleRangeBehavior').Instance
        if not luaCtrl then
            return
        end
        local showAlert = showFlag & RangeVisibleType.Alert
        if showAlert ~= 0 then
            pObject.transform:SetVisible(true)
            local aiCfg = ConfigRefer.AiBase:Find(config:Baseai())
            local radius = aiCfg:AlertRadius() * self.module.unitsPerTileX * 2
            luaCtrl.safeAreaMesh.transform.localScale = CS.UnityEngine.Vector3.one * radius
            luaCtrl.safeAreaMesh.gameObject:SetVisible(true)
        end
    end

    if not self.warningFxObj then
        self.warningHandle:Create('prefab_test_defense_tower_circle', self.transform, function(pObject)
            if Utils.IsNotNull(pObject) then
                self.warningFxObj = pObject               
                self.warningFxObj.transform.localPosition = CS.UnityEngine.Vector3.zero
                self.warningFxObj.transform.localScale = CS.UnityEngine.Vector3.one
                self.warningFxObj.transform.localRotation = CS.UnityEngine.Quaternion.identity
                setupWarningFx(pObject)
            end
        end)
    else
        setupWarningFx(self.warningFxObj)
    end
end

function TroopView:HideWarningRange()
    self.warningHandle:Delete()
    self.warningFxObj = nil
end

function TroopView:SetDirty(force, needShake)
    if self.hud then
        if not self._isAttacking or force then
            self.hud:SetDirty(needShake)
            return true
        end
    end
    return false
end

function TroopView:GetState()
    local spState = self.troopCtrl:GetSpState()
    if spState ~= TroopConst.SP_STATE_NONE then
        return TroopConst.STATE_BATTLE
    end
    
    if self._isEscaping then
        return TroopConst.STATE_RETREATING
    end

    if (self._isMoving) then
        return TroopConst.STATE_MOVE
    end

    if self._isAttacking then
        return TroopConst.STATE_BATTLE
    end
    
    return TroopConst.STATE_IDLE
end

function TroopView:SetEscapeState(value)
    if self._isEscaping ~= value then
        self._isEscaping = value
        self:SyncTroopState()
    end
end

function TroopView:SetBehaviourState(value)
    self.behaviourState = value
end

function TroopView:SyncTroopState()
    local curState = self:GetState()
    if self.behaviourState > 0 then
        curState = self.behaviourState + curState
    end
    if self._lastState ~= curState and self.hasViewEntity then
        self._lastState = curState
        g_Game.TroopViewManager:SetTroopMapState(self.ID,curState)
        if curState == TroopConst.STATE_MOVE  then
            self:ShowMoveVfx()
        else
            self:HideMoveVfx()
        end
    end
end


function TroopView:SyncTroopBattleState()
    local dbData = self.troopCtrl:GetData()
    local inBattle = dbData and dbData.MapStates.Battling or false
    local needShow = false
    if self.troopCtrl:IsSelf() then
        needShow = true    
    end

    g_Game.TroopViewManager:ShowBattleStateCircle(self.ID,inBattle and needShow )
end

function TroopView:StartAttackIfNeed(showStartFx)    
    if not self._isAttacking then    
        self._isAttacking = true
        self:SyncTroopState()
        self:SyncTroopBattleState()
        if self.troopCtrl:IsSelf() and self.module.battleManager:CanPopBattleEffect() and showStartFx then
            UISlgBattleInfo.SpawnStartStatus(self.module,self.troopCtrl)
        end
    end    
end

function TroopView:FinishAttack()
    if self._isAttacking then
        self._isAttacking = false
        self:SyncTroopState()
        self:SyncTroopBattleState()
    end
end


function TroopView:DoMoveStart()
    g_Game.TroopViewManager:SetPath(self.ID,self.Path,self.Speed)
    self:ResetTroopLine()
end

function TroopView:DoMoveEnd()
    g_Game.TroopViewManager:SetPath(self.ID,nil,self.Speed)
    if self.TroopLine then
        self.TroopLine:Clear()
    end
end

function TroopView:DestroyTroop()
    self:FinishAttack()
    if self.runVfxGuid ~= nil then       
        g_Game.TroopViewManager:RemoveVfx(self.runVfxGuid)
        self.runVfxGuid = nil
    end
    if self._classVfxGuid ~= nil then
        g_Game.TroopViewManager:RemoveVfx(self._classVfxGuid)
        self._classVfxGuid = nil
    end
end

function TroopView:RefreshLodIcon()
    if self.lodIcon then
        if self:IsLodIconVisible() then
            self.lodIcon:SetVisible(true)
            self.lodIcon:UpdateDirection(self:GetForward())
            self.lodIcon:UpdateHP(self.troopCtrl)
        else
            self.lodIcon:SetVisible(false)
        end
    end
end

function TroopView:IsLodIconVisible()
    local mapState = (KingdomMapUtils.IsMapState() or KingdomMapUtils.IsNewbieState()) 
    local lodState = KingdomMapUtils.InMapIconLod(self._curLod)
    local radarState = not ModuleRefer.RadarModule.isInRadar
    local fogState = self.troopCtrl:IsSelf() or not self.module:IsTroopInFog(self.troopCtrl)
    return mapState and lodState  and radarState and fogState
end

function TroopView:UpdateLodIconDirection()
    if self.lodIcon and self:IsLodIconVisible() then
        self.lodIcon:UpdateDirection(self:GetForward())
    end
end

function TroopView:UpdateLodIconHp()
    if self.lodIcon and self:IsLodIconVisible() then
        self.lodIcon:UpdateHP(self.troopCtrl)
    end
end

function TroopView:ShowHUDForBattle()
    self.battleRelationState = self.battleRelationState + 1
    if self.hud and self.battleRelationState > 0 then
        self.hud:SetBattleRelationState(true)
    end
end

function TroopView:HideHUDForBattle()
    if self.battleRelationState == 0 then
        return
    end
    self.battleRelationState = self.battleRelationState - 1
    if self.hud and self.battleRelationState < 1 then
        self.hud:SetBattleRelationState(false)
    end
end

function TroopView:SetVisible(visible, hideHud)
    self.viewVisible = visible

    g_Game.TroopViewManager:SetTroopVisible(self.ID,visible)

    if self.simpleMode then
        self.simpleMode:SetVisible(visible)
    end

    if self.hudGo and visible then
        self.hudGo:SetVisible(true)
        self.hud:SetDirty()
    end
    if self.hudGo then
        self.hud:SetWorldTaskBubbleState(visible)
    end

    if self.skillWaring then
        self.skillWaring.root:SetVisible(visible)
    end

    if not visible and hideHud and self.hudGo then
        self.hudGo:SetVisible(false)
    end

    if visible then
        self:UpdateCollider()
    else
        self:SetColliderEnabled(false)
    end
end

function TroopView:OnRadarStateChanged(state)
    self:SetVisible(not state,true)
    self:RefreshLodIcon()
end

function TroopView:InsideViewFrustum()
    if not self.viewVisible or not self._csView then
        return false
    end
    return self._csView:IsVisibleInCamera(self.module:GetCamera())
end

---@param win boolean
function TroopView:SetBattleResult(win)
    if not self._resultTimer then
        self._resultTimer = require('TimerUtility').DelayExecute(Delegate.GetOrCreate(self,self.OnShowBattleResult),0.2)
    end
    if self.troopCtrl:IsSelf() then
        --只有自己可以显示胜利
        if not self._battleRes then
            self._battleRes = win
        end
    else
        if win ~= nil and not win then
            self._battleRes = win
        end
    end
end

function TroopView:OnShowBattleResult()
    self._resultTimer = nil
    if self.troopCtrl:IsValid() and self._battleRes ~= nil and self.module.battleManager:CanPopBattleEffect() then
        if self._battleRes then
            UISlgBattleInfo.SpawnWinStatus(self.module,self.troopCtrl)
        else
            UISlgBattleInfo.SpawnFailStatus(self.module,self.troopCtrl)
        end
    end
    self._battleRes = nil
end

function TroopView:ShowMoveVfx()
    if not self.module.battleManager:CanPopBattleEffect() or not self.module:CanShowMovingSmoke() then
        return
    end
    if self.runVfxGuid == nil then
        self.runVfxGuid = g_Game.TroopViewManager:AddVfxToTroop(self.ID,'vfx_w_soldier_run_sm',0,0.8,true)
    else
        g_Game.TroopViewManager:ShowVfxOnTroop(self.runVfxGuid)
    end
end

function TroopView:HideMoveVfx()
    if self.runVfxGuid ~= nil then       
        g_Game.TroopViewManager:HideVfxOnTroop(self.runVfxGuid)
    end
end


function TroopView:ShowClassVfx()

    if not self.data.MobInfo then
        return
    end    
    
    if not self._overMaxLod and self._isShow then
        if self._classVfxGuid == nil then
            local mobConfig = ConfigRefer.KmonsterData:Find(self.data.MobInfo.MobID)
            if not mobConfig then
                return
            end
            local classType = mobConfig:MonsterClass()
            local classVfxName          
            if classType == MonsterClassType.TeamElite then
                classVfxName = 'vfx_w_enemy_effect'          
            else
                self._classVfxGuid = -1
                return 
            end
            
            self._classVfxGuid = g_Game.TroopViewManager:AddVfxToTroop(self.ID,classVfxName,0,0.8,true)
        else
            g_Game.TroopViewManager:ShowVfxOnTroop(self._classVfxGuid)
        end    
    else
        self:HideClassVfx()
    end
end

function TroopView:HideClassVfx()
    if self._classVfxGuid ~= nil then
        g_Game.TroopViewManager:HideVfxOnTroop(self._classVfxGuid)
    end
end

function TroopView:UpdateDebugInfo()   
    if not self._debugInfo then        
        local debugInfoGo = CS.UnityEngine.GameObject('debugInfo')
        self._debugInfo = debugInfoGo.transform
        self._debugInfo.name = self.transform.name .. '_debugInfo'
        self._debugInfo:SetParent(self.module.worldHolder)        
        self._debugInfo.localPosition = CS.UnityEngine.Vector3.zero        
        self._debugInfo.localRotation = CS.UnityEngine.Quaternion.identity
        self.debugInfoHandle:Create('troop_select_debug', self._debugInfo.transform, function(pObject)
            self._debugInfoObject = pObject
            pObject.transform:SetParent(self._debugInfo)
            pObject.transform.localPosition = CS.UnityEngine.Vector3.zero
            pObject.transform.localScale = CS.UnityEngine.Vector3.one
            pObject.transform.localRotation = CS.UnityEngine.Quaternion.identity
        end)        
    end

    self._debugInfo.position = self.module:ServerCoordinate2Vector3(self.data.MapBasics.Position)
    local forward = self:GetForward() 
    self._debugInfo.forward = forward  
    self._debugInfo.localScale = CS.UnityEngine.Vector3.one * self.module.troopManager:CalcTroopRadius(self.data) * 2
end

function TroopView:RemoveDebugInfo()
    if not self._debugInfo then
        return
    end
    
    self.debugInfoHandle:Delete()
    self._debugInfoObject = nil

    CS.UnityEngine.GameObject.Destroy(self._debugInfo.gameObject)
    self._debugInfo = nil
end

function TroopView:CreateTroopBornVfx()
    if not self.troopCtrl:IsSelf() then
        return
    end
    
    local pos = self:GetPosition()
    g_Game.TroopViewManager:CreateVfxExtend(SLGConst_Manual.troopBornVfxInCity,pos,CS.UnityEngine.Vector3.forward,0.4,2,1)
end

function TroopView:CreateTroopDisappearVfx()
    if not self.troopCtrl:IsSelf() then
        return
    end

    local pos = self:GetPosition()
    g_Game.TroopViewManager:CreateVfxExtend(SLGConst_Manual.troopDisapearVfxInCity,pos,CS.UnityEngine.Vector3.forward,0.4,2,1)
end

return TroopView
