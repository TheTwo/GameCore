---
--- Created by wupei. DateTime: 2022/1/12
---

local AbstractManager = require("AbstractManager")
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local DBEntityType = require('DBEntityType')
local UIMediatorNames = require('UIMediatorNames')
local MonsterClassType = require("MonsterClassType")
local ConfigRefer = require("ConfigRefer")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local I18N = require("I18N")
local KingdomMapUtils = require('KingdomMapUtils')
local SlgBattlePowerHelper = require('SlgBattlePowerHelper')
local KingdomInteractionDefine = require("KingdomInteractionDefine")
local RPPType = require('RPPType')
local GotoUtils = require('GotoUtils')
local SEHudTroopMediatorDefine = require('SEHudTroopMediatorDefine')
local MonsterBattleType = require("MonsterBattleType")
local KingdomTouchInfoOperation = require("KingdomTouchInfoOperation")
local TroopViewProxyType = typeof(CS.DragonReborn.SLG.Troop.TroopViewProxy)
local SlgUtils = require('SlgUtils')
local CheckTroopTrusteeshipStateDefine = require("CheckTroopTrusteeshipStateDefine")
local AllianceAuthorityItem = require('AllianceAuthorityItem')
local ManualResourceConst = require('ManualResourceConst')
local SlgTouchMenuHelper = require("SlgTouchMenuHelper")

---@class SLGTouchManager : AbstractManager
---@field uiTroopDesTip UITroopDesTip
---@field _module SlgModule
---@field _km KingdomScene
local SLGTouchManager = class('SLGTouchManager',AbstractManager)

SLGTouchManager.InputState ={
    None = 0,
    MyCity = 1,
    Kingdom = 2,
}

local SelectTargetType = {
    None = -1,
    Troop = 1,
    Entity = 2,
}
---@protected
function SLGTouchManager:ctor(...)
    AbstractManager.ctor(self, ...)
    self.uiTroopDesTip = nil
    self.playerModule = ModuleRefer.PlayerModule
    self.sceneState = SLGTouchManager.InputState.None
end

function SLGTouchManager:Awake()

    --g_Game.GestureManager:AddListener(self.gestureHandle);
    local scene = require('KingdomMapUtils').GetKingdomScene()   
    self.isInGve = scene:GetName() == require('SlgScene').Name
    self.basicCamera = self._curScene.basicCamera
    self._mapSystem = self._curScene.mapSystem

    ---@type SLGSelectManager
    self._selectManager = self._module.selectManager

    self._module.pool:SpawnAsync('troop_aim_fx',function(pObject)
        if pObject then
            self.animFx = pObject
            self.animFx:SetParent(self._module.worldHolder)
            self.animFx.transform:SetVisible(false)

            self.animColor = {}
            self.animColor[1] = {
                loop = self.animFx.transform:Find("loop/red"),
                scale = self.animFx.transform:Find("scale/red"),
            }
            self.animColor[2] = {
                loop = self.animFx.transform:Find("loop/green"),
                scale = self.animFx.transform:Find("scale/green"),
            }
            self.animColor[3] = {
                loop = self.animFx.transform:Find("loop/blue"),
                scale = self.animFx.transform:Find("scale/blue"),
            }
            self:SetAnimColor(1)
        end
    end)

    --setup input Delegate
    self:Startup()
end

function SLGTouchManager:OnDestroy()
    --g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self,self.Tick))
    --g_Game.GestureManager:RemoveListener(self.gestureHandle);
    self:Shutdown()
end

function SLGTouchManager:IsInMyCity()
    return self.sceneState == SLGTouchManager.InputState.MyCity
end

function SLGTouchManager:OnLodChange(lod, oldLod)
   if lod < 1 then
        if self.sceneState == SLGTouchManager.InputState.Kingdom then
            self:RemoveInputInteraction_Kingdom()
        end
        --in city modle
        if self:SetupInputInteraction_MyCity() then
            self.sceneState = SLGTouchManager.InputState.MyCity
        else
            self.sceneState = SLGTouchManager.InputState.None
        end

   else
        --in kingdom
        if self.sceneState == SLGTouchManager.InputState.MyCity then
            self:RemoveInputInteraction_MyCity()
        end
        --in city modle
        if self:SetupInputInteraction_Kingdom() then
            self.sceneState = SLGTouchManager.InputState.Kingdom
        else
            self.sceneState = SLGTouchManager.InputState.None
        end
   end
end

---@param colorCode number r:1 g:2 b:3
function SLGTouchManager:SetAnimColor(colorCode)
    if not self.animColor then
        return
    end
    for i = 1, 3 do
        if self.animColor[i].loop then
            self.animColor[i].loop:SetVisible(i==colorCode)
        end
        if self.animColor[i].scale then
            self.animColor[i].scale:SetVisible(i==colorCode)
        end
    end
end

function SLGTouchManager:SetAimCircle( tarCtrl, aimed, position,scale)
    if not self.animFx then
        return
    end
    if aimed and self.aimTarCtrl ~= tarCtrl then
        self.aimTarCtrl = tarCtrl
        self.animFx:SetVisible(false)
    elseif not aimed and self.aimTarCtrl == tarCtrl then
        self.aimTarCtrl = nil
    elseif self.aimTarCtrl and not tarCtrl then
        self.aimTarCtrl = nil
        self.animFx:SetVisible(false)
    else
        return
    end
    -- self.animCtrl = ctrl
    self.animFx:SetVisible(aimed)
    if aimed and position then
        self.animFx:SetLocalScale(CS.UnityEngine.Vector3.one * scale)
        self.animFx:SetPosition(position)
    end
end

---@return boolean
function SLGTouchManager:CanCtrl()
    return self.enable and not self._module:IsInCity()
end

---@param trans CS.UnityEngine.Transform[]
---@param sorter fun(a:TroopCtrl,b:TroopCtrl):boolean
---@return TroopCtrl
function SLGTouchManager:FindTroopCtrlByTransform(trans,sorter)
    ---@type TroopCtrl[]
    local ctrls = {}
    if trans and #trans > 0 then
        for index, t in ipairs(trans) do
            local csView = t:GetComponent(TroopViewProxyType)
            if csView and csView then
                local c = self._module.troopManager:FindTroopCtrl(csView.ID)
                if c then
                    table.insert(ctrls,c)
                end
            end
        end
    end
    if #ctrls > 1 and sorter then
        table.sort(ctrls,sorter)
    end
    local retCtrl = nil
    for key, ctrl in pairs(ctrls) do
        if ctrl:CanSelect() then
            retCtrl = ctrl
            break
        end
    end
    return retCtrl
end
function SLGTouchManager:FindEntityByPosition(pos)
    if not pos then
        return nil
    end
    return self._module:GetKingdomEntityByPosWS(pos)
end

function SLGTouchManager:SetPressOnCtrl(ctrl)
    if ctrl then
        self.fingerDownCtrl = ctrl
    else
        self.fingerDownCtrl = self:GetVirtualTroopCtrl()
    end
end

function SLGTouchManager:DoOnPressDown(trans)
    if not self:CanCtrl() then
        return
    end
    local ctrl = self:FindTroopCtrlByTransform(trans,function(a,b)
        if a.troopType == b.troopType then
            return a.ID < b.ID
        else
            return a.troopType < b.troopType
        end
    end
    )
    if ctrl and ctrl:CanCtrl()  then
        self.fingerDownCtrl = ctrl
        if ctrl._data.TypeHash == wds.MobileFortress.TypeHash or self._selectManager:GetSelectCount() < 2 then
            self._module.selectManager:SetSelect(ctrl)
        end
        return true
    end
end

function SLGTouchManager:DoOnRelease(trans,pos)
    self.fingerDownCtrl = nil
end

function SLGTouchManager:DoOnClick(trans,position)
	if (trans) then
		local petCatchIntData = ModuleRefer.PetModule:GetWorldPetIntData()
		local worldRewardIntData = ModuleRefer.WorldRewardInteractorModule:GetIntData()
        for _, tran in ipairs(trans) do
            local cdata = tran.gameObject:GetComponent(typeof(CS.CustomData))
            if (cdata) then
                -- 大世界抓宠
                if (cdata.intData == petCatchIntData) then
                    ModuleRefer.PetModule:TryOpenCatchMenu(cdata.objectData)
                    return true

                    -- 世界奖励交互物
                elseif (cdata.intData == worldRewardIntData) then
                    ModuleRefer.WorldRewardInteractorModule:ShowMenu(cdata.objectData)
                    return true
                end
            end
        end
	end

    if not self:CanCtrl() then
        return false
    end
    local ctrl = self:FindTroopCtrlByTransform(trans,function(a,b)
        if a.troopType == b.troopType then
            return a.ID < b.ID
        else
            return a.troopType < b.troopType
        end
    end)
    if ctrl then
        if not SlgUtils.IsTroopInRally(ctrl:GetData()) then
            self._module:SelectAndOpenTroopMenu(ctrl)
        end
        return true
    else
        self._module:SelectAndOpenTroopMenu(nil)
    end
    return false
end

-----------------------------------------------
---drag start
---@param trans CS.UnityEngine.Transform[]
---@param position CS.UnityEngine.Vector3
---@param screenPos CS.UnityEngine.Vector3
function SLGTouchManager:DoOnDragStart(trans, position, screenPos)
    if not self:CanCtrl() or not self.fingerDownCtrl or not self.fingerDownCtrl:CanCtrl() then
        return
    end

   

    self.isDraging = true
    self._module:CloseTroopMenu()
    if self._selectManager:GetSelectCount() < 2 then
        self._dragStartCtrl = self.fingerDownCtrl
        if self._dragStartCtrl then
            self._dragStartCtrl:CreateTroopLine()
            if self:IsInMyCity() then
                ModuleRefer.CityModule.myCity.cityExplorerManager.SLGTouchInjectedSelectedTarget:SetUpCtrlTroop(self._selectManager:GetFirstSelected())
                ModuleRefer.CityModule.myCity.cityExplorerManager.SLGTouchInjectedSelectedTarget:OnDragStart(screenPos)
            end
            return true
        end
    else
        local datas = self._selectManager:GetAllSelected()
        local vCtrl = nil
        for key, value in pairs(datas) do
            if value and value.ctrl then
                value.ctrl:CreateTroopLine()
            elseif not vCtrl then
                vCtrl = self:GetVirtualTroopCtrl()
                if vCtrl then
                    vCtrl:CreateTroopLine()
                    self.dragingVCtrl = true
                end
            end
        end
        return true
    end
end

function SLGTouchManager:GetVirtualTroopCtrl()
    local city = ModuleRefer.CityModule.myCity
    if self._module:IsInCity() then        
        return self._selectManager:GetVirtualCtrl(self._module:GetCityBasePosition())
    else
        if city then            
            return self._selectManager:GetVirtualCtrl(city:GetKingdomMapPosition())
        end
    end
end

-----------------------------------------------------
---drag update
---@param ctrl TroopCtrl
---@param entity wds.CastleBrief
---@return number @SelectTargetType
function SLGTouchManager:SelectTargetElement(ctrl,entity)

    if ctrl and ( (not ctrl:IsFriendly() and not ctrl:IsSelf() ) or ctrl:IsMonster() ) then
        if ctrl:IsMonster() and not SlgUtils.IsMobCanAttackById(ctrl._data.MobInfo.MobID) then
            return SelectTargetType.None
        end
        --敌方部队
        return SelectTargetType.Troop
    elseif entity and entity.Owner
        and not self.playerModule:IsFriendly(entity.Owner)
        and not self.playerModule:IsMine(entity.Owner)       
        -- and entity.TypeHash ~= DBEntityType.CastleBrief --不进攻敌方主城
    then

        if entity.TypeHash == wds.PlayerMapCreep.TypeHash and not ModuleRefer.MapCreepModule:IsTumorAlive(entity) then
            return SelectTargetType.None
        else
            --敌方建筑
           return SelectTargetType.Entity
        end
    elseif ctrl and ctrl:IsFortress() then
        --我方移动堡垒
        return SelectTargetType.Troop
    elseif entity and entity.Owner and (self.playerModule:IsMine(entity.Owner) or self.playerModule:IsFriendly(entity.Owner) ) then
        --我/友方建筑
        return SelectTargetType.Entity
    end
    return SelectTargetType.None
end

---@param trans CS.UnityEngine.Transform[]
---@param position CS.UnityEngine.Vector3
---@param screenPos CS.UnityEngine.Vector3
---@param ray CS.UnityEngine.Ray
function SLGTouchManager:DoOnDragUpdate(trans, position, screenPos,ray)
    if not self.isDraging then
        return
    end
    local targetCtrl = nil
    if trans then
        targetCtrl = self:FindTroopCtrlByTransform(trans,function(a,b)
            if a.troopType == b.troopType then
                return a.ID < b.ID
            else
                return a.troopType > b.troopType
            end
        end)
    end

    if ray then        
        local terrainPoint = self._module:GetTerrainPos(position)        
        if terrainPoint.y > position.y + 3 then
            local cos = CS.UnityEngine.Vector3.Dot(ray.direction,CS.UnityEngine.Vector3.up)
            position = position + ray.direction * ( terrainPoint.y / cos)
        end
    end

    local mapEntity = self:FindEntityByPosition(position)
    local selectType = self:SelectTargetElement(targetCtrl,mapEntity)

	-- 大世界抓宠
	-- if (self._dragStartCtrl and self._dragStartCtrl:IsSelf()) then
	-- 	local has, list = ModuleRefer.PetModule:HasPetInWorld(position)
	-- 	if (has) then
	-- 		ModuleRefer.PetModule:ShowWorldPetSelection(list[1].id)
	-- 	else
	-- 		ModuleRefer.PetModule:HideLastSelectedWorldPet()
	-- 	end
	-- end

    if self._selectManager:GetSelectCount() < 2 then
        if self._dragStartCtrl then

            if selectType == SelectTargetType.Troop and targetCtrl then
                self:UpdateTroopLineToUnit(self._dragStartCtrl, targetCtrl)
            elseif selectType == SelectTargetType.Entity and mapEntity then
                self:UpdateTroopLineToBuild(self._dragStartCtrl, mapEntity)
            else
                self:UpdateTroopLine(self._dragStartCtrl,position)
                self.uiTroopDesTip:SetTargetEntity(self._dragStartCtrl,nil,not self.isInGve)
            end
            if self:IsInMyCity() then
                local _,x,y,__ = ModuleRefer.CityModule.myCity:RaycastNpcTile(screenPos)
                local inMask = ModuleRefer.CityModule.myCity:IsFogMask(x,y)
                if not inMask then
                    ModuleRefer.CityModule.myCity.cityExplorerManager.SLGTouchInjectedSelectedTarget:OnDragUpdate(screenPos)
                end
            end
            return true
        end
    else
        local datas = self._selectManager:GetAllSelected()
        for key, value in pairs(datas) do
            if value and value.ctrl then
                if selectType == 1 and targetCtrl then
                    self:UpdateTroopLineToUnit(value.ctrl, targetCtrl)
                elseif selectType == 2 and mapEntity then
                    self:UpdateTroopLineToBuild(value.ctrl, mapEntity)
                else
                    self:UpdateTroopLine(value.ctrl,position)
                    self.uiTroopDesTip:SetTargetEntity(value.ctrl,nil,not self.isInGve)
                end
            end
        end
        if self.dragingVCtrl then
            local vCtrl = self._selectManager:GetVirtualCtrl()
            if selectType == 1 and targetCtrl then
                self:UpdateTroopLineToUnit(vCtrl, targetCtrl)
            elseif selectType == 2 and mapEntity then
                self:UpdateTroopLineToBuild(vCtrl, mapEntity)
            else
                self:UpdateTroopLine(vCtrl,position)
                self.uiTroopDesTip:SetTargetEntity(vCtrl,nil,not self.isInGve)
            end
        end
        return true
    end
end

---UpdateTroopLine
---@param ctrl TroopCtrl
---@param target TroopCtrl
function SLGTouchManager:UpdateTroopLineToUnit(ctrl, target)
    if not ctrl or not target then
        return
    end
    local p2 = nil
    if target and target ~= ctrl then
        p2 = target:GetPosition()
    else
        p2 = ctrl:GetPosition()
    end
    if p2 then
        self:UpdateTroopLine(ctrl,p2,target)
        self.uiTroopDesTip:SetTargetEntity(ctrl,target._data,not self.isInGve)
    end
end
---@param ctrl TroopCtrl
---@param entity wds.ViewCastleBriefForMap
function SLGTouchManager:UpdateTroopLineToBuild(ctrl, entity)
    if not entity then
        return
    end

    local entityPos = nil

    -- if entity.TypeHash == DBEntityType.ViewCastleBriefForMap then
    if entity.MapBasics and entity.MapBasics.Position then
        local serverPos = entity.MapBasics.Position
        entityPos = self._module:ServerCoordinate2Vector3(serverPos)
    end
    if entityPos then
        self:UpdateTroopLine(ctrl,entityPos, nil, self._module:IsInCity())
        self.uiTroopDesTip:SetTargetEntity(ctrl,entity,not self.isInGve)
    end
end
---@param sourceCtrl TroopCtrl
---@param targetCtrl TroopCtrlelse
---@param tarEntity wds.ViewCastleBriefForMap
function SLGTouchManager:UpdateTroopLine(sourceCtrl,p1,targetCtrl,isCity)
    local line = sourceCtrl:GetTroopLine()
    local Utils = require('Utils')
    if Utils.IsNull(line) then
        return
    end

    local p0 = sourceCtrl:GetPosition()
    local offset = not isCity and self._module:GetLineHeightOffset() or 0
    local lenSq = (p1 - p0).sqrMagnitude
    local sourceRadius = not isCity and sourceCtrl:GetRadius() or 0.35
    if (lenSq > sourceRadius * sourceRadius) then --指向线不会指向自己
        local terrainP0 = self._module:GetTerrainPos(p0 + (p1 - p0).normalized * sourceRadius,offset)
        local terrainP1 = self._module:GetTerrainPos(p1,offset)
        line:UpdatePoints(terrainP0, terrainP1)
        self:UpdateTroopLineAddObj(sourceCtrl, terrainP0, terrainP1, isCity)
        if targetCtrl and not targetCtrl:IsFriendly() and not targetCtrl:IsSelf() then
            self:SetAimCircle(targetCtrl,true,p1,targetCtrl:GetRadius() * 2)
        else
            self:SetAimCircle(targetCtrl,false)
        end
    else
        p0.y = p0.y + offset
        line:UpdatePoints(p0 ,p0)
        self:DespawnTroopLineAddObj()
        self:SetAimCircle(targetCtrl,false)
    end
end

-----------------------------------------------------
---drag stop
---@param trans CS.UnityEngine.Transform[]
---@param position CS.UnityEngine.Vector3
---@param screenPos CS.UnityEngine.Vector3
function SLGTouchManager:DoOnDragStop(trans, position, screenPos,ray)
    if not self.isDraging then
        return
    end
    --Clear troop line
    self:ReleaseAllTroopLine()
    self:DespawnTroopLineAddObj()
    self._dragStartCtrl = nil
    -- 大世界抓宠
    ModuleRefer.PetModule:HideLastSelectedWorldPet()

    self.isDraging = false

    local selectData = self._selectManager:GetFirstSelected()
    if not selectData then
        return
    end
    
    if ray then        
        local terrainPoint = self._module:GetTerrainPos(position)        
        if terrainPoint.y > position.y + 3 then
            local cos = CS.UnityEngine.Vector3.Dot(ray.direction,CS.UnityEngine.Vector3.up)
            position = position + ray.direction * ( terrainPoint.y / cos)
        end
    end

    
    local isTrusteeship = self._module.troopManager:CheckTroopTrusteeshipState(selectData.entityData,selectData.presetIndex)
    if isTrusteeship == CheckTroopTrusteeshipStateDefine.State.None then
        self:__DoOnDragStop(trans, position, screenPos)
    elseif isTrusteeship == CheckTroopTrusteeshipStateDefine.State.InEscrowPreparing and not self:WillOperationBreakEscrowPreparing(trans, position) then
        self:__DoOnDragStop(trans, position, screenPos)
    elseif CheckTroopTrusteeshipStateDefine.IsStateCanCancel(isTrusteeship) then
        self._module.troopManager:CancelTroopTrusteeshipAndGoOn(selectData.entityData,selectData.presetIndex,nil,isTrusteeship == CheckTroopTrusteeshipStateDefine.State.InAssemblePreparing)
    else
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_team_error06"))
    end
    return true
end

---@param trans CS.UnityEngine.Transform[]
---@param position CS.UnityEngine.Vector3
function SLGTouchManager:WillOperationBreakEscrowPreparing(trans, position)
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return
    end
    ---@type TroopCtrl
    local targetCtrl = nil
    if trans then
        targetCtrl = self:FindTroopCtrlByTransform(trans,function(a,b)
            if a.troopType == b.troopType then
                return a.ID < b.ID
            else
                return a.troopType > b.troopType
            end
        end)
    end
    local mapEntity = self:FindEntityByPosition(position)
    local selectType = self:SelectTargetElement(targetCtrl,mapEntity)
    
    local targetEntity

    if selectType == SelectTargetType.Troop and targetCtrl then
        targetEntity = targetCtrl._data
    elseif selectType == SelectTargetType.Entity and mapEntity then
        targetEntity = mapEntity
    end
    
    local isSE
    isSE,_,_,_ = KingdomMapUtils.CalcRecommendPower(targetEntity)

    if isSE then
        return false
    else
        if targetEntity and targetEntity.TypeHash == DBEntityType.MapMob and not SlgUtils.IsMobCanAttackById(targetEntity.MobInfo.MobID) then
            return false
        end
        if targetEntity and targetEntity.TypeHash == DBEntityType.MapMob then
            --拖动到集结怪上
            local monsterCfg = targetEntity.MobInfo and ConfigRefer.KmonsterData:Find(targetEntity.MobInfo.MobID) or nil
            if monsterCfg and monsterCfg:BattleType() ~= MonsterBattleType.Normal then
                local level = targetEntity.MobInfo.Level
                local canAttackMonster, _ = SlgTouchMenuHelper.CheckMonsterCanAttack(monsterCfg, level)
                if not canAttackMonster then
                    return false
                end
                return true
            end
        end
    end
    return false
end

---@private
---@param trans CS.UnityEngine.Transform[]
---@param position CS.UnityEngine.Vector3
---@param screenPos CS.UnityEngine.Vector3
function SLGTouchManager:__DoOnDragStop(trans, position, screenPos)
    ---@type TroopCtrl
    local targetCtrl = nil
    if trans then
        targetCtrl = self:FindTroopCtrlByTransform(trans,function(a,b)
            if a.troopType == b.troopType then
                return a.ID < b.ID
            else
                return a.troopType > b.troopType
            end
        end)

        if trans[1].name == ManualResourceConst.vfx_bigmap_shenmishijian then
                ModuleRefer.WorldEventModule:GetPreviewPrompt()
        end
    end
    local mapEntity = self:FindEntityByPosition(position)
    local selectType = self:SelectTargetElement(targetCtrl,mapEntity)

    local selectData = self._selectManager:GetFirstSelected()
    if selectData.entityData and selectData.entityData.TypeHash == DBEntityType.MobileFortress then
        self:__DoOnDragStop_Behemoth(trans, position, screenPos,selectType,targetCtrl,mapEntity)
    else
        self:__DoOnDragStop_Normal(trans, position, screenPos,selectType,targetCtrl,mapEntity)
    end
    
end

function SLGTouchManager:__DoOnDragStop_Normal(trans, position, screenPos,selectType,targetCtrl,mapEntity)
    local gotoCtrl = nil
    local gotoPos = position
    local targetEntity

    if selectType == SelectTargetType.Troop and targetCtrl then
        gotoCtrl = targetCtrl
        targetEntity = targetCtrl._data
    elseif selectType == SelectTargetType.Entity and mapEntity then

        if mapEntity.TypeHash == DBEntityType.CastleBrief then
            if not ModuleRefer.PlayerModule:IsFriendly(mapEntity.Owner) and ModuleRefer.PlayerModule:IsProtected(mapEntity) then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("protect_info_castle_under_protection"))
                return true
            end
        elseif mapEntity.TypeHash == DBEntityType.ResourceField then
            if ModuleRefer.MapResourceFieldModule:IsLockedByLandform(mapEntity) then
                local landName = ModuleRefer.MapResourceFieldModule:GetUnlockLandformName(mapEntity.FieldInfo.ConfID)
                local toast = I18N.GetWithParams("mining_info_collection_after_stage", landName)
                ModuleRefer.ToastModule:AddSimpleToast(toast)
                return
            end
            
            if ModuleRefer.MapResourceFieldModule:IsLockedByVillage(mapEntity) then
                local toast = I18N.GetWithParams("mining_info_collection_after_occupying")
                ModuleRefer.ToastModule:AddSimpleToast(toast)
                return
            end

            local datas = self._selectManager:GetAllSelected()
            if table.nums(datas) == 1 then
                local troop = datas[1].entityData
                if troop and ModuleRefer.MapResourceFieldModule:IsTroopLoadFull(troop) then
                    local toast = I18N.GetWithParams("mining_info_collection_after_occupying")
                    ModuleRefer.ToastModule:AddSimpleToast(toast)
                    return
                end
            end
        end

        local serverPos = mapEntity.MapBasics.Position
        gotoPos = self._module:ServerCoordinate2Vector3(serverPos)
        targetEntity = mapEntity
    end

    local canAttack = targetEntity and (not ModuleRefer.PlayerModule:IsFriendly(targetEntity.Owner)) or false
    local isSE,needPower,recommendPower,costPPP
      
    isSE,needPower,recommendPower,costPPP = KingdomMapUtils.CalcRecommendPower(targetEntity)
   
    --Check PPP
    if not self.isInGve and costPPP > 0 and (canAttack) then
        local player = self.playerModule:GetPlayer()
        local curPPP = player and player.PlayerWrapper2.Radar.PPPCur or 0
        if costPPP > curPPP then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("world_tilibuzu"))
            return true
        end
    end

    local function TryGotoTargetFunc()
        local goToOverride = false
        if self:IsInMyCity() and not gotoCtrl then
            goToOverride = ModuleRefer.CityModule.myCity.cityExplorerManager.SLGTouchInjectedSelectedTarget:OnDragEnd(screenPos)
        end
        if not goToOverride then
            self:TryGotoTarget(gotoCtrl, gotoPos)
        end
    end

    if isSE then
        TryGotoTargetFunc()
    else

        if targetEntity and targetEntity.TypeHash == DBEntityType.MapMob and not SlgUtils.IsMobCanAttackById(targetEntity.MobInfo.MobID) then                                                        
            return
        end

        --集结怪的逻辑 提示集结
        if targetEntity and targetEntity.TypeHash == DBEntityType.MapMob then
            ---@type KmonsterDataConfigCell
            local monsterCfg = targetEntity.MobInfo and ConfigRefer.KmonsterData:Find(targetEntity.MobInfo.MobID) or nil
            if monsterCfg and monsterCfg:BattleType() ~= MonsterBattleType.Normal then
                local level = targetEntity.MobInfo.Level
                local canAttackMonster, hintText = SlgTouchMenuHelper.CheckMonsterCanAttack(monsterCfg, level)
                --除了普通与精英，别的类型不判断搜索等级
                if not canAttackMonster then
                    ModuleRefer.ToastModule:AddSimpleToast(hintText)
                    return
                end
                
                ---@type CommonConfirmPopupMediatorParameter
                local parameter = {}
                parameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
                parameter.content = I18N.Get("alliance_team_toast03")
                parameter.confirmLabel = I18N.Get("alliance_team_jiaru")
                parameter.cancelLabel = I18N.Get("alliance_team_faqi")
                parameter.onConfirm = function()
                    if ModuleRefer.AllianceModule:IsInAlliance() then
                        ---@type AllianceWarMediatorParameter
                        local p = {}
                        p.enterTabIndex = 1
                        g_Game.UIManager:Open(UIMediatorNames.AllianceWarNewMediator, p)
                    else
                        g_Game.UIManager:Open(UIMediatorNames.AllianceInitialMediator)
                    end
                    return true
                end
                parameter.onCancel = function()
                    if ModuleRefer.AllianceModule:IsInAlliance() then
                        ---@type HUDSelectTroopListData
                        local selectTroopData = {}
                        selectTroopData.entity = targetEntity
                        selectTroopData.isSE = false
                        selectTroopData.needPower = needPower
                        selectTroopData.recommendPower = recommendPower
                        selectTroopData.costPPP = costPPP
                        selectTroopData.isAssemble = true
                        selectTroopData.trusteeshipRule = ModuleRefer.SlgModule:GetTrusteeshipRule(targetEntity.MobInfo.MobID)
                        require("HUDTroopUtils").StartMarch(selectTroopData)
                    else
                        g_Game.UIManager:Open(UIMediatorNames.AllianceInitialMediator)
                    end
                    return true
                end
                g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, parameter)
                return
            end
        end
        
        --Normal Slg Logic
        if self._selectManager:GetSelectCount() < 2 then
            if not targetEntity or not canAttack then
                TryGotoTargetFunc()
            else
                if targetEntity.TypeHash == DBEntityType.MapMob and not self.isInGve then
                    local monsterCfg = targetEntity.MobInfo and ConfigRefer.KmonsterData:Find(targetEntity.MobInfo.MobID) or nil
                    if monsterCfg then
                        local level = targetEntity.MobInfo.Level
                        local canAttackMonster, hintText = SlgTouchMenuHelper.CheckMonsterCanAttack(monsterCfg, level)
                        --除了普通与精英，别的类型不判断搜索等级
                        if not canAttackMonster then
                            ModuleRefer.ToastModule:AddSimpleToast(hintText)
                            return
                        end
                    end
                end
                TryGotoTargetFunc()
            end
        else
            if not targetEntity or not canAttack then
                self:TryMoveAllCtrlsToTarget(gotoCtrl,gotoPos)
            else
                if targetEntity.TypeHash == DBEntityType.MapMob and not self.isInGve then
                    local monsterCfg = targetEntity.MobInfo and ConfigRefer.KmonsterData:Find(targetEntity.MobInfo.MobID) or nil
                    if monsterCfg then
                        local level = targetEntity.MobInfo.Level
                        local canAttackMonster, hintText = SlgTouchMenuHelper.CheckMonsterCanAttack(monsterCfg, level)
                        --除了普通与精英，别的类型不判断搜索等级
                        if not canAttackMonster then
                            ModuleRefer.ToastModule:AddSimpleToast(hintText)
                            return
                        end
                    end
                end
                self:TryMoveAllCtrlsToTarget(gotoCtrl,gotoPos)
            end
        end
    end
end

function SLGTouchManager:CanBehemothGotoEntity(targetEntity)
    local isMine = ModuleRefer.PlayerModule:IsMine(targetEntity.Owner) or false
    local isFriendly = ModuleRefer.PlayerModule:IsFriendly(targetEntity.Owner) or false

    if targetEntity.TypeHash == DBEntityType.CastleBrief then            
        if isMine then
            --不能回城            
            return false,"alliance_behemothSummon_tips_return"
        elseif isFriendly then
            --不能攻击友方建筑            
            return false,"alliance_behemothSummon_tips_building"
        elseif ModuleRefer.PlayerModule:IsProtected(targetEntity) then            
            return false,"protect_info_castle_under_protection"
        end
    elseif targetEntity.TypeHash == DBEntityType.ResourceField 
        or targetEntity.TypeHash == DBEntityType.Village
        or targetEntity.TypeHash == DBEntityType.CommonMapBuilding
    then
        --资源田/乡镇
        if isFriendly then
            --不能攻击友方建筑            
            return false,"alliance_behemothSummon_tips_building"
        end
    elseif targetEntity.TypeHash == DBEntityType.SlgInteractor then
        ---Slg交互物:SE入口               
        return false,"alliance_behemothSummon_tips_gather"
    elseif targetEntity.TypeHash == DBEntityType.MapMob 
        or targetEntity.TypeHash == wds.PlayerMapCreep.TypeHash
    then
        ---Slg怪物        
        ---菌毯核心        
        return false,"alliance_behemothSummon_tips_creeps"
    end
    return true
end

function SLGTouchManager:__DoOnDragStop_Behemoth(trans, position, screenPos,selectType,targetCtrl,mapEntity)

    local gotoCtrl = nil
    local gotoPos = position
    local targetEntity

    if selectType == SelectTargetType.Troop and targetCtrl then
        gotoCtrl = targetCtrl
        targetEntity = targetCtrl._data
    elseif selectType == SelectTargetType.Entity and mapEntity then
        local serverPos = mapEntity.MapBasics.Position
        gotoPos = self._module:ServerCoordinate2Vector3(serverPos)
        targetEntity = mapEntity
    end

    if targetEntity then
        local canGo,errorMsg = self:CanBehemothGotoEntity(targetEntity)
        if not canGo then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(errorMsg))
            return true
        end        
    end
    
    self:TryGotoTarget(gotoCtrl, gotoPos)   
    return true
end



function SLGTouchManager:CancelDrag()
	-- 大世界抓宠
	ModuleRefer.PetModule:HideLastSelectedWorldPet()

    self:ReleaseAllTroopLine()
    self:DespawnTroopLineAddObj()
    self._selectManager:SetSelect(nil)
    -- self._selectManager:SetFocusCtrl(nil)
    self._dragStartCtrl = nil
    if self:IsInMyCity() then
        ModuleRefer.CityModule.myCity.cityExplorerManager.SLGTouchInjectedSelectedTarget:OnDragCancel()
    end
end

function SLGTouchManager:ReleaseAllTroopLine()
    local allSelect = self._selectManager:GetAllSelected()
    for key, value in pairs(allSelect) do
        if value.ctrl then
            value.ctrl:ReleaseTroopLine()
        end
    end

    local vCtrl = self._selectManager:GetVirtualCtrl()
    if vCtrl then
        vCtrl:ReleaseTroopLine()
    end

    self.dragingVCtrl = false
end

---end of drag
----------------------------------------------------

function SLGTouchManager:UpdateInteractionScale()
    ModuleRefer.KingdomInteractionModule:SetScale(self._module.slgScale)
end



function SLGTouchManager:Startup()
    if not self.uiTroopDesTip then
        self.uiTroopDesTip = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.UITroopDesTip)
        if not self.uiTroopDesTip then
            g_Game.UIManager:Open(UIMediatorNames.UITroopDesTip,nil,function(mediator)
                self.uiTroopDesTip = mediator
            end)
        end
    end
    local kingdomInteraction = ModuleRefer.KingdomInteractionModule
    if kingdomInteraction then
        local p = KingdomInteractionDefine.InteractionPriority.SLGTouchManager
        kingdomInteraction:AddOnPressDown(Delegate.GetOrCreate(self,self.DoOnPressDown), p)
        kingdomInteraction:AddOnRelease(Delegate.GetOrCreate(self,self.DoOnRelease), p)
        kingdomInteraction:AddOnDragStart(Delegate.GetOrCreate(self,self.DoOnDragStart), p)
        kingdomInteraction:AddOnDragEnd(Delegate.GetOrCreate(self,self.DoOnDragStop), p)
        kingdomInteraction:AddOnDragUpdate(Delegate.GetOrCreate(self,self.DoOnDragUpdate), p)
        kingdomInteraction:AddDragCancel(Delegate.GetOrCreate(self,self.CancelDrag))
    end
end

function  SLGTouchManager:Shutdown()
    if self.uiTroopDesTip then
        g_Game.UIManager:Close(self.uiTroopDesTip.runtimeId)
        self.uiTroopDesTip = nil
    end
    local kingdomInteraction = ModuleRefer.KingdomInteractionModule
    if kingdomInteraction then
        kingdomInteraction:RemoveOnPressDown(Delegate.GetOrCreate(self,self.DoOnPressDown))
        kingdomInteraction:RemoveOnRelease(Delegate.GetOrCreate(self,self.DoOnRelease))
        kingdomInteraction:RemoveOnDragStart(Delegate.GetOrCreate(self,self.DoOnDragStart))
        kingdomInteraction:RemoveOnDragEnd(Delegate.GetOrCreate(self,self.DoOnDragStop))
        kingdomInteraction:RemoveOnDragUpdate(Delegate.GetOrCreate(self,self.DoOnDragUpdate))
        kingdomInteraction:RemoveDragCancel(Delegate.GetOrCreate(self,self.CancelDrag))
    end
    self:RemoveInputInteraction_MyCity()
    self:RemoveInputInteraction_Kingdom()
end

---@private
function SLGTouchManager:SetupInputInteraction_MyCity()
    -- local myCity = ModuleRefer.CityModule.myCity
    -- ---@type CityStateNormal
    -- local normalState = myCity.stateMachine.states[CityConst.STATE_NORMAL]
    -- if normalState then
    --     normalState:AddOnClick(Delegate.GetOrCreate(self,self.DoOnClick))
    --     return true
    -- end
    -- return false
    return true
end
---@private
function SLGTouchManager:RemoveInputInteraction_MyCity()
    -- local myCity = ModuleRefer.CityModule.myCity
    -- ---@type CityStateNormal
    -- local normalState = myCity.stateMachine.states[CityConst.STATE_NORMAL]
    -- if normalState then
    --     normalState:RemoveOnClick(Delegate.GetOrCreate(self,self.DoOnClick))
    -- end
end


---@private
function SLGTouchManager:SetupInputInteraction_Kingdom()
    self:RemoveInputInteraction_Kingdom()

    local kingdomInteraction = ModuleRefer.KingdomInteractionModule
    if kingdomInteraction then
        local p = KingdomInteractionDefine.InteractionPriority.SLGTouchManager
        kingdomInteraction:AddOnClick(Delegate.GetOrCreate(self,self.DoOnClick), p)
        return true
    end
    return false
end
---@private
function SLGTouchManager:RemoveInputInteraction_Kingdom()
    local kingdomInteraction = ModuleRefer.KingdomInteractionModule
    if kingdomInteraction then
        kingdomInteraction:RemoveOnClick(Delegate.GetOrCreate(self,self.DoOnClick))
    end
end

---@param ctrl TroopCtrl
---@param target TroopCtrl
---@param troopCount number
function SLGTouchManager:UpdateTroopLineAddObj(ctrl, p1, p2, isCity) --, target, troopCount)
    if not self.uiTroopDesTip then
        self:Startup()
        return
    end
    -- self.uiTroopDesTip:SetTargetCtrl(ctrl,target)
    --if troopCount == 1 then
        self.uiTroopDesTip:SetPos1Pos2(p1, p2, isCity)
    -- else
    --     self.uiTroopDesTip:SetPos1Pos2(nil, p2)
    -- end
    self.troopLineEnabled = true
end

---@param v TroopCtrl
function SLGTouchManager:DespawnTroopLineAddObj()
    if self.uiTroopDesTip then
        self.uiTroopDesTip:HidePos()
    end
    self.troopLineEnabled = false
end

---@param targetCtrl TroopCtrl
function SLGTouchManager:TryGotoTarget(targetCtrl, worldPos)
    local selectData = self._selectManager:GetFirstSelected()
    if not selectData then
        return
    end
    local selectTroopCtrl = selectData.ctrl
    local selectPreset = selectData.presetIndex
    if (selectTroopCtrl and not selectTroopCtrl:CanSelect()) or
       (not selectTroopCtrl and selectPreset < 0)
    then
        if selectTroopCtrl and not selectTroopCtrl:CanSelect() and selectTroopCtrl._data and selectTroopCtrl._data.MapStates.HideOnMap then
            --ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('stationed_warn'))
            -- todo 驻守的部队可以直接拖拽操作了 考虑后期加一个二次确认免得误操作？
            goto continueTryGotoTarget
        end
        return
    end
    ::continueTryGotoTarget::
    local selectTroopId = selectData.entityData and selectData.entityData.ID or 0

    if targetCtrl then
        if selectTroopCtrl then
		    ModuleRefer.PetModule:UnwatchTroopForWorldPetCatch(selectTroopCtrl._data.ID)
        end
        local entity = targetCtrl._data

        if entity.TypeHash == DBEntityType.MobileFortress and self._module:IsMyAlliance(entity) and ModuleRefer.KingdomConstructionModule:IsBuildingConstructing(entity) then
            self._module:MoveTroopToEntity(selectTroopCtrl,selectPreset,targetCtrl._data.ID,wrpc.MovePurpose.MovePurpose_Strengthen)
        elseif entity.TypeHash == DBEntityType.MapMob and entity.MobInfo and entity.MobInfo.BehemothCageId > 0 then
            ---@type wds.BehemothCage
            local cageEntity = targetCtrl:GetCageEntity()
            --检查巢穴状态
            if not ModuleRefer.AllianceModule:IsInAlliance() then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('alliance_team_toast01'))
            elseif not cageEntity then
                g_Logger.Error("Unknow BehemothCageId:"..entity.MobInfo.BehemothCageId)
            else
                --检查是否宣战
                local isMyWar,warInfo = ModuleRefer.VillageModule:HasDeclareWarOnCage(cageEntity.ID)
                if not isMyWar then
                    self._module:SelectAndOpenTroopMenu(targetCtrl)
                    return
                end
                local startTime = warInfo.StartTime
                -- wds.BehemothCageStatusMask = {
                --     BehemothCageStatusMaskInvalid = 0,
                --     BehemothCageStatusMaskActOpen = 1,
                --     BehemothCageStatusMaskHasNeighbor = 2,
                --     BehemothCageStatusMaskOccupied = 4,
                --     BehemothCageStatusMaskInWaiting = 8,
                --     BehemothCageStatusMaskInBattle = 16,
                --     BehemothCageStatusMaskInLocked = 32,
                -- }
                local isMaster = ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.StartBehemothWar)
                if startTime > g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() then
                    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('battlewar_notime'))
                    return
                elseif cageEntity.BehemothCage.Status & wds.BehemothCageStatusMask.BehemothCageStatusMaskInBattle ~= 0 then
                    --进入战斗状态
                    self._module:MoveTroopToEntity(selectTroopCtrl,selectPreset,targetCtrl._data.ID,wrpc.MovePurpose.MovePurpose_Move)
                    return
                elseif cageEntity.BehemothCage.Status & wds.BehemothCageStatusMask.BehemothCageStatusMaskInWaiting ~= 0 then
                    --准备状态
                    if isMaster then
                        local isInCage = selectTroopCtrl and selectTroopCtrl._data.MapStates.StateWrapper2.InBehemothCage
                        if isInCage then
                            ---Copy From AllianceBehemothBattleConfirmBtnFuncProvider:EnableBtnFuncStartBattle()
                            ---@type CommonConfirmPopupMediatorParameter
                            local param = {}
                            param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
                            param.confirmLabel = I18N.Get("confirm")
                            param.cancelLabel = I18N.Get("cancle")
                            param.content = I18N.Get("alliance_behemoth_pop_Open")
                            param.onConfirm = function()
                                ModuleRefer.AllianceModule.Behemoth:StartBehemothBattleNow(nil, cageEntity.ID)
                                return true
                            end
                            g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
                        else
                            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemoth_tips_enterCage"))
                        end                    
                    else
                        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemoth_tips_OpenWar"))                    
                    end   
                    return             
                else
                    self._module:SelectAndOpenTroopMenu(targetCtrl)
                    return
                end
            end
        elseif entity.TypeHash == DBEntityType.MapMob then
            local canAutoFinish = SlgUtils.IsMobCanTriggerAutoFinish(entity)           

            if SlgUtils.GetMonsterBattleType(entity) > 0 then
                self._module:SelectAndOpenTroopMenu(targetCtrl)
            elseif canAutoFinish then
                if selectTroopCtrl and selectTroopCtrl._data and selectTroopCtrl._data.MapStates.StateWrapper2.AutoBattle then
                    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('autobattle_turnoff'))
                else                    
                    self._module:MoveTroopToEntity(selectTroopCtrl,selectPreset,targetCtrl._data.ID,wrpc.MovePurpose.MovePurpose_AutoClearExpedition)
                end
            else
                self._module:MoveTroopToEntity(selectTroopCtrl,selectPreset,targetCtrl._data.ID,wrpc.MovePurpose.MovePurpose_Move)
            end
        else
            self._module:MoveTroopToEntity(selectTroopCtrl,selectPreset,targetCtrl._data.ID)
        end
    else
        local entity = self._module:GetKingdomEntityByPosWS(worldPos)
        if entity == nil then
            if selectTroopCtrl and selectTroopCtrl._data and selectTroopCtrl._data.MapStates.StateWrapper2.AutoBattle then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('autofight_stopalert'))
            end
            self._module:MoveTroopToPosition(selectTroopCtrl,selectPreset, worldPos)
        else
			-- if (selectTroopCtrl) then
			-- 	ModuleRefer.PetModule:UnwatchTroopForWorldPetCatch(selectTroopCtrl._data.ID)
			-- end
            --Check Target Type
            if self._module:IsMyEntity(entity) or self._module:IsMyAlliance(entity) then
                --1day 资源田临时屏蔽驻军功能，因为进去就出不来了
                if entity.TypeHash == DBEntityType.ResourceField then
                    
                elseif entity.TypeHash == DBEntityType.FakeCastle then
                    ModuleRefer.ToastModule:AddSimpleToast(require('I18N').Get('world_sj_jzhc'))                    
                elseif entity.TypeHash == DBEntityType.CastleBrief then
                    if ModuleRefer.PlayerModule:IsMine(entity.Owner) then
                        if selectTroopCtrl then
                            self._module:ReturnToHome(selectTroopCtrl.ID)
                        end
                    else
                        self._module:MoveTroopToEntity(selectTroopCtrl,selectPreset,entity.ID, wrpc.MovePurpose.MovePurpose_Reinforce)
                    end
                else
                    if ModuleRefer.KingdomConstructionModule:IsBuildingConstructing(entity) then
                        self._module:MoveTroopToEntity(selectTroopCtrl,selectPreset,entity.ID, wrpc.MovePurpose.MovePurpose_Strengthen)
                    else
                        self._module:MoveTroopToEntity(selectTroopCtrl,selectPreset,entity.ID, wrpc.MovePurpose.MovePurpose_Reinforce)
                    end
                end
            else

                local fromType = ModuleRefer.SlgModule:IsInCity()
                    and SEHudTroopMediatorDefine.FromType.City
                    or SEHudTroopMediatorDefine.FromType.World

                if entity.TypeHash == wds.PlayerMapCreep.TypeHash and ModuleRefer.MapCreepModule:IsTumorAlive(entity) then

                    local tid = KingdomMapUtils.GetSEMapInstanceIdInEntity(entity)
                    if tid > 0 then
                        ModuleRefer.SEPreModule:PrepareEnv(true, selectTroopId, true, true,
                        fromType)
                        GotoUtils.GotoSceneClearCreepTumor(tid,selectTroopId,entity.ID,selectPreset)
                    else
                        self._module:MoveTroopToEntity(selectTroopCtrl,selectPreset,entity.ID, wrpc.MovePurpose.MovePurpose_Move)
                    end

                elseif  entity.TypeHash == DBEntityType.SlgInteractor then
                    local conf = ConfigRefer.Mine:Find(entity.Interactor.ConfigID)
                    local tid = conf:MapInstanceId()
                    if tid and tid > 0 and entity.Interactor.State.CannotEnterSe then
                        local dialogParam = {}
                        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
                        dialogParam.title = I18N.Get("setips_title_inbattle")
                        dialogParam.content = I18N.Get("setips_des_inbattle")
                        dialogParam.onConfirm = function()
                            self._module:MoveTroopToEntity(selectTroopCtrl,selectPreset,entity.ID)
                            return true
                        end
                        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
                    elseif entity.Owner.ExclusivePlayerId ~= 0 then
                        if conf:CanCollect() then
                            self._module:MoveTroopToEntity(selectTroopCtrl,selectPreset,entity.ID)
                        else
                            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("world_mine_wfcj"))
                        end
                    elseif tid and tid > 0 then
                        local gridPos = entity.MapBasics.BuildingPos
                        ModuleRefer.SEPreModule:PrepareEnv(true, self.troopId, true, true,
                                fromType, gridPos.X, gridPos.Y)

                        GotoUtils.GotoSceneByInteractor(tid,selectTroopId,entity.ID,selectPreset)
                    else
                        self._module:MoveTroopToEntity(selectTroopCtrl,selectPreset,entity.ID)
                    end
                else
                    self._module:MoveTroopToEntity(selectTroopCtrl,selectPreset,entity.ID)
                end
            end
        end
    end
end

---@param ctrls TroopCtrl[]
---@param targetCtrl TroopCtrl
function SLGTouchManager:TryMoveAllCtrlsToTarget(targetCtrl, worldPos)

    local selectDatas = self._selectManager:GetAllSelected()

    ---@type TroopData[]
    local troopDatas = {}
    if selectDatas and #selectDatas > 0 then
        for key, value in pairs(selectDatas) do
            ---@type TroopData
            local troopData = {
                presetIndex = value.presetIndex
            }
            if value.ctrl and value.ctrl:CanSelect() then
                troopData.troop = value.ctrl
            end
            table.insert(troopDatas,troopData)
        end
    end

    if troopDatas == nil or #troopDatas < 1 then
        return
    elseif #troopDatas < 2 then
        self._selectManager:SetSelect(troopDatas[1].troop)
        self:TryGotoTarget(targetCtrl,worldPos)
        return
    end


    if targetCtrl then
		--ModuleRefer.PetModule:UnwatchTroopsForWorldPetCatch(troopDatas)
        local entity = targetCtrl._data
        if entity.TypeHash == DBEntityType.MobileFortress and self._module:IsMyAlliance(entity) and ModuleRefer.KingdomConstructionModule:IsBuildingConstructing(entity) then
            self._module:MoveTroopsToEntity(troopDatas,targetCtrl._data.ID,wrpc.MovePurpose.MovePurpose_Strengthen)
        else
            self._module:MoveTroopsToEntity(troopDatas,targetCtrl._data.ID)
        end
    else

        local entity = self._module:GetKingdomEntityByPosWS(worldPos)
        if entity == nil then
            self._module:MoveTroopsToPosition(troopDatas,worldPos)
			return
        else
			--ModuleRefer.PetModule:UnwatchTroopsForWorldPetCatch(troopDatas)
            --Check Target Type
            if self._module:IsMyEntity(entity) or self._module:IsMyAlliance(entity) then
                --1day 资源田临时屏蔽驻军功能，因为进去就出不来了
                if entity.TypeHash == DBEntityType.ResourceField then
                    return
                end
                if ModuleRefer.KingdomConstructionModule:IsBuildingConstructing(entity) then
                    self._module:MoveTroopsToEntity(troopDatas, entity.ID, wrpc.MovePurpose.MovePurpose_Strengthen)
                else
                    self._module:MoveTroopsToEntity(troopDatas, entity.ID, wrpc.MovePurpose.MovePurpose_Reinforce)
                end
            else
                if entity.TypeHash == wds.PlayerMapCreep.TypeHash then
                    self._module:MoveTroopsToEntity(troopDatas, entity.ID, wrpc.MovePurpose.MovePurpose_ClearCenterSlgCreep)
                elseif  entity.TypeHash == DBEntityType.SlgInteractor then
                    local conf = ConfigRefer.Mine:Find(entity.Interactor.ConfigID)
                    local isSeMapInstance = conf:MapInstanceId() > 0
                    if isSeMapInstance and entity.Interactor.State.CannotEnterSe then
                        local dialogParam = {}
                        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
                        dialogParam.title = I18N.Get("setips_title_inbattle")
                        dialogParam.content = I18N.Get("setips_des_inbattle")
                        dialogParam.onConfirm = function()
                            self._module:MoveTroopsToEntity(troopDatas,entity.ID)
                            return true
                        end
                        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
                    elseif entity.Owner.ExclusivePlayerId ~= 0 then
                        --TODO
                    else
                        self._module:MoveTroopsToEntity(troopDatas,entity.ID)
                    end
                else
                    self._module:MoveTroopsToEntity(troopDatas,entity.ID)
                end
            end
        end
    end
end

---@param monsterConfig KmonsterDataConfigCell
function SLGTouchManager:CheckMonsterCanAttack(monsterConfig, level)
    if true or monsterConfig:CanForceFight() then
        return true, string.Empty
    end
    
    local attackLv = SlgTouchMenuHelper.GetAttackLv(monsterConfig)
    --除了普通与精英，别的类型不判断搜索等级
    if attackLv > 0 and attackLv < level then
        local hintText = SlgTouchMenuHelper.GetHintText(monsterConfig)
        return false, hintText
    end
    return true, string.Empty
end

return SLGTouchManager
