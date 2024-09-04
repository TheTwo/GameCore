local CityState = require("CityState")
---@class CityStateClearCreep:CityState
---@field new fun():CityStateClearCreep
---@field vfxLife number UI交互特效的生命管理
local CityStateClearCreep = class("CityStateClearCreep", CityState)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local RectDyadicMap = require("RectDyadicMap")
local CastleCreepSweepByItemParameter = require("CastleCreepSweepByItemParameter")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local ConfigRefer = require("ConfigRefer")
local Utils = require("Utils")
local CityConst = require("CityConst")
local ManualResourceConst = require("ManualResourceConst")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")

function CityStateClearCreep:Enter()
    CityState.Enter(self)
    self.x = self.stateMachine:ReadBlackboard("x")
    self.y = self.stateMachine:ReadBlackboard("y")
    self.itemId = self.stateMachine:ReadBlackboard("itemId")
    self.brushSize = ConfigRefer.CityConfig:SprayMedicineOperateCellSize()
    self.singleCost = ConfigRefer.CityConfig:CostDurabilityPerTile()
    self.vfxLife = 0

    self.sendHeartBeat = 0.33
    self.sendRequestDelay = 0.33

    self.lastMinX, self.lastMinY = nil, nil
    self.lastMaxX, self.lastMaxY = nil, nil
    self.isFirstDrag = true

    self.lastFullTip = g_Game.RealTime.frameCount
    self.lastRequestTime = g_Game.RealTime.time
    self.working = false
    self.gridConfig = self.city.gridConfig
    g_Game.UIManager:CloseAllByName(UIMediatorNames.CityCreepClearInteractUIMediator)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.CityCreepClearNewUIMediator)
    self:CameraLookAt()

    g_Game.EventManager:AddListener(EventConst.CITY_CREEP_PESTICIDE_START, Delegate.GetOrCreate(self, self.StartWorking))
    g_Game.EventManager:AddListener(EventConst.CITY_CREEP_PESTICIDE_DRAG, Delegate.GetOrCreate(self, self.OnWorkingDrag))
    g_Game.EventManager:AddListener(EventConst.CITY_CREEP_PESTICIDE_END, Delegate.GetOrCreate(self, self.StopWorking))
    g_Game.EventManager:AddListener(EventConst.CITY_CREEP_UI_CLOSE_BY_BUTTON, Delegate.GetOrCreate(self, self.ExitToIdleState))
end

function CityStateClearCreep:OnCameraPosReady()
    self:InitBatch(self.gridConfig.cellsX, self.gridConfig.cellsY)
    self:OpenUI()
    self:InitSelector()
    self:InitHighlight()
    self.svfxX, self.svfxY, self.svfxSizeX, self.svfxSizeY = self:GetSelectVfxParam(self.x, self.y)
    self:InitVfx()
end

function CityStateClearCreep:Exit()
    self:TryRequestSweep()
    self:ReleaseHighlight()
    self:RecoverCamera()
    self:ReleaseSelector()
    self:ReleaseVfx()
    self:CloseUI()
    g_Game.EventManager:RemoveListener(EventConst.CITY_CREEP_PESTICIDE_START, Delegate.GetOrCreate(self, self.StartWorking))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CREEP_PESTICIDE_DRAG, Delegate.GetOrCreate(self, self.OnWorkingDrag))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CREEP_PESTICIDE_END, Delegate.GetOrCreate(self, self.StopWorking))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CREEP_UI_CLOSE_BY_BUTTON, Delegate.GetOrCreate(self, self.ExitToIdleState))
    self.batch = nil
    self.batchBigCell = nil
    self.limit = nil
    self.isFirstDrag = false
    CityState.Exit(self)
end

function CityStateClearCreep:Tick(delta)
    local lastLife = self.vfxLife
    self.vfxLife = math.max(0, self.vfxLife - delta)
    if lastLife >= 0 and self.vfxLife == 0 then
        self:DisableVfx()
    end

    if self.isFirstDrag and self.batchBigCell and self.batchBigCell.count > 0 then
        self:TryRequestSweep()
        self.isFirstDrag = false
    end

    self.sendHeartBeat = self.sendHeartBeat - delta
    if self.sendHeartBeat <= 0 then
        self.sendHeartBeat = self.sendRequestDelay
        self:TryRequestSweep()
    end
end

function CityStateClearCreep:TryRequestSweep()
    if self.batchBigCell and self.batchBigCell.count > 0 then
        self:RequestSweeper()
        self.batch:Clear()
        self.batchBigCell:Clear()
    end
end

function CityStateClearCreep:CameraLookAt()
    local position = self.city:GetWorldPositionFromCoord(self.x + 0.5, self.y + 0.5)
    local baseCamera = self.city:GetCamera()
    local camera = baseCamera.mainCamera
    local viewPoint = camera:WorldToViewportPoint(position)
    if viewPoint.x <= 0.1 or viewPoint.y <= 0.1 or viewPoint.x >= 0.9 or viewPoint.y >= 0.9 then
        baseCamera:LookAt(position, 0.1, function()
            self:OnCameraPosReady()
        end)
    else
        self:OnCameraPosReady()
    end
end

function CityStateClearCreep:OnDragStart(gesture)
    if self.working then
        return
    end
end

function CityStateClearCreep:OnClick(gesture)
    if self.working then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_STATE_CLICK)
end

function CityStateClearCreep:OnDragEnd()
    if self.working then
        return
    end
end

function CityStateClearCreep:StartWorking(itemCfgId)
    self.working = true
    self:BlockCamera()
    if self.selector then
        self.selector.behaviour.gameObject:SetActive(self.working)
    end
    self.currentItemCfgId = itemCfgId
    self:EnableVfx()
    self:InitCurrentSweeperDurabilitySum()
end

function CityStateClearCreep:InitCurrentSweeperDurabilitySum()
    self.allDurability = ModuleRefer.CityCreepModule:GetSweeperDurabilitySum(self.currentItemCfgId)
end

function CityStateClearCreep:OnWorkingDrag(screenPos)
    if not self.working then return end
    
    local canShowVfx = self:OnDragSweeper(screenPos)
    self:UpdateVfxPosition(canShowVfx or self.vfxLife > 0)
end

---@param ox number
---@param oy number
---@return number,number,number,number,number,number
function CityStateClearCreep:FixCoordToOperateCellSize(ox, oy)
    local gridConfig = self.gridConfig
    ox = math.min(math.max(ox, gridConfig.minX), gridConfig.minX + gridConfig.cellsX - 1)
    oy = math.min(math.max(oy, gridConfig.minX), gridConfig.minX + gridConfig.cellsX - 1)
    local startX = ox // self.brushSize * self.brushSize
    local startY = oy // self.brushSize * self.brushSize
    startX = math.min(math.max(startX, gridConfig.minX), gridConfig.minX + gridConfig.cellsX - 1)
    startY = math.min(math.max(startY, gridConfig.minY), gridConfig.minY + gridConfig.cellsY - 1)
    local endX = math.min(startX + self.brushSize - 1, gridConfig.minX + gridConfig.cellsX - 1)
    local endY = math.min(startY + self.brushSize - 1, gridConfig.minY + gridConfig.cellsY - 1)
    return ox,oy,startX,startY,endX,endY
end

---@return boolean
function CityStateClearCreep:OnDragSweeper(screenPos)
    local cityCamera = self.city:GetCamera()
    local worldPos = cityCamera:GetHitPoint(screenPos)
    local ox,oy,minX,minY,maxX,maxY
    local x, y = self.city:GetCoordFromPosition(worldPos, true)
    ox, oy = self.city:GetCoordFromPosition(worldPos, false)
    ox,oy,minX,minY,maxX,maxY = self:FixCoordToOperateCellSize(ox, oy)

    if self.selector then
        self.selector:UpdatePosition(x - self.brushSize / 2, y - self.brushSize / 2)
    end

    if minX == self.lastMinX and minY == self.lastMinY and maxX == self.lastMaxX and maxY == self.lastMaxY then
        return
    end

    self.lastMinX = minX
    self.lastMinY = minY
    self.lastMaxX = maxX
    self.lastMaxY = maxY

    ---是合法的菌毯位置就更新示意器
    self.x, self.y = ox,oy

    local legal = true
    for x = minX, maxX do
        for y = minY, maxY do
            legal = legal and (not self.city:IsFogMask(x, y) or not self.city.creepManager:IsAffectWithBlockCheck(x, y))
        end
    end

    local ret = false
    local needEndDrag, cost = false, 0
    local begin = self:BeginLocalRemove()
    if not legal then return ret end
    for y = minY, maxY do
        for x = minX, maxX do
            local bigAdd = self:DragSweeperTileAt(x, y)
            ret = ret or bigAdd
            if bigAdd then
                needEndDrag, cost = ModuleRefer.CityCreepModule:CalculateSweepCost(minX, maxX, minY, maxY, self.allDurability, self.city.creepManager)
                self.allDurability = self.allDurability - cost
                ret = true
                self.vfxLife = 3
                if needEndDrag then
                    local realTilesCount = cost / self.singleCost
                    self:FakeBlockPartial(minX, minY, maxX, maxY, realTilesCount)
                else
                    self:FakeBlockArea(minX, minY, maxX, maxY)
                end
                g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_CLEAR_BIG_ADD, cost)
            end
        end
    end
    
    if self:EndLocalRemove(begin) then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_CLEAR_DO)
    end

    if needEndDrag then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_FORCE_END_DRAG)
    end
    return ret
end

---@return boolean,boolean,boolean
function CityStateClearCreep:DragSweeperTileAt(x, y)
    if not self.city.creepManager:IsAffectWithBlockCheck(x, y) then
        return false
    end
    
    if self.batch:Get(x, y) then
        return false
    end

    self.batch:Add(x, y, true)
    if self.selectVfxHandle and self:InSelectVfxRange(x, y) then
        self:ReleaseSelectVfx()
    end
    return self.batchBigCell:TryAdd(x // self.bigCellSize, y // self.bigCellSize, true)
end

---@param x number
---@param y number
---@return boolean
function CityStateClearCreep:BigCellContains(x, y)
    local bigX = x // self.bigCellSize
    local bigY = y // self.bigCellSize
    return self.batchBigCell:Get(bigX, bigY) == true
end

function CityStateClearCreep:HideSelector()
    if self.selector then
        self.selector.behaviour.gameObject:SetActive(false)
    end
end

function CityStateClearCreep:StopWorking()
    self.working = false
    self:HideSelector()
    self:DisableVfx()
    self:TryRequestSweep()
    self:RecoverCamera()

    if self.allDurability > 0 then
        self.stateMachine:ChangeState(self.city:GetSuitableIdleState(self.city.cameraSize))
    end
end

function CityStateClearCreep:InitBatch(sizeX, sizeY)
    local bigCellSize = ConfigRefer.CityConfig:SprayMedicineOperateCellSize()
    if not bigCellSize or bigCellSize < 1 then
        bigCellSize = 1
    end
    self.batch = RectDyadicMap.new(sizeX, sizeY)
    self.bigCellSize = bigCellSize
    self.batchBigCell = RectDyadicMap.new(math.ceil(sizeX / bigCellSize), math.ceil(sizeY / bigCellSize))
end

function CityStateClearCreep:RequestSweeper()
    local param = CastleCreepSweepByItemParameter.new()
    local points = param.args.Points
    local userdata = {}
    for x, y, _ in self.batchBigCell:pairs() do
        local point2 = wds.Point2.New(x, y)
        points:Add(point2)
        table.insert(userdata, point2)
    end
    param.args.ItemId = self.currentItemCfgId
    param:SendOnceCallback(nil, userdata, true, Delegate.GetOrCreate(self, self.OnCallback), Delegate.GetOrCreate(self, self.OnFailed))
end

function CityStateClearCreep:OnCallback(cmd, isSuccess, rsp)
    if not isSuccess then return end

    ---@type wds.Point2[]
    local userdata = cmd.msg.userdata
    local cancelBlocks = {}
    for i, v in ipairs(userdata) do
        local minX, minY = v.X * self.brushSize, v.Y * self.brushSize
        local maxX, maxY = minX + self.brushSize - 1, minY + self.brushSize - 1
        table.insert(cancelBlocks, {minX = minX, minY = minY, maxX = maxX, maxY = maxY})
    end
    self.city.creepManager:CancelBlockCreepAreas(cancelBlocks)
end

function CityStateClearCreep:OnFailed(msgId, errorCode, jsonTable)
    self.city.creepManager:CancelAllBlockCreepArea()
    g_Logger.Error("clear creep failed [code:%d]. recreate creep", errorCode)
end

function CityStateClearCreep:OpenUI()
    ---@type CityCreepClearInteractUIParameter
    local param = {
        camera = self.city:GetCamera(),
    }
    self.runTimeId = g_Game.UIManager:Open(UIMediatorNames.CityCreepClearNewUIMediator, param, nil, true)
    if not g_Game.UIManager:IsOpenedByName(UIMediatorNames.CityItemHarvestMediator) then
        g_Game.UIManager:Open(UIMediatorNames.CityItemHarvestMediator)
    end
    if not g_Game.UIManager:IsOpenedByName(UIMediatorNames.CityItemResumeMediator) then
        g_Game.UIManager:Open(UIMediatorNames.CityItemResumeMediator)
    end
end

function CityStateClearCreep:GetDurabilityFixValue()
    return self.batch.count
end

function CityStateClearCreep:CloseUI()
    g_Game.UIManager:UIMediatorCloseSelf(self.runTimeId)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.CityCreepClearNewUIMediator)
    self.runTimeId = nil
end

function CityStateClearCreep:BlockCamera()
    local camera = self.city:GetCamera()
    if camera ~= nil then
        camera.enablePinch = false
        camera.enableDragging = false
    end
end

function CityStateClearCreep:RecoverCamera()
    local camera = self.city:GetCamera()
    if camera ~= nil then
        camera.enablePinch = true
        camera.enableDragging = true
    end
end

function CityStateClearCreep:InitHighlight()
    self:InitHighlightOfActive()
    self.city.creepManager:DOHighlight(self.highlight)
end

function CityStateClearCreep:InitHighlightOfActive()
    self.highlight = self.city.creepManager:CollectHighlight(self.x, self.y, false)
end

function CityStateClearCreep:ReleaseHighlight()
    self.highlight = nil
    self.city.creepManager:DOHighlight(self.highlight)
end

function CityStateClearCreep:InitVfx()
    self.vfxHandle = self.city.createHelper:Create(ManualResourceConst.vfx_city_xiaosha_xishou, self.city.CityVfxRoot, Delegate.GetOrCreate(self, self.OnSweeperVfxCreated))
    self.selectVfxHandle = self.city.createHelper:Create(ManualResourceConst.vfx_city_tileselected, self.city.CityVfxRoot, Delegate.GetOrCreate(self, self.OnSelectVfxCreated))
end

function CityStateClearCreep:GetSelectVfxParam(x, y)
    local ox, oy = x // self.bigCellSize * self.bigCellSize, y // self.bigCellSize * self.bigCellSize
    local sizeX, sizeY = self.bigCellSize, self.bigCellSize
    if ox + sizeX - 1 >= self.city.gridConfig.cellsX then
        sizeX = self.city.gridConfig.cellsX - ox
    end
    if oy + sizeY - 1 >= self.city.gridConfig.cellsY then
        sizeY = self.city.gridConfig.cellsY - oy
    end
    return ox, oy, sizeX, sizeY
end

---@param go CS.UnityEngine.GameObject
function CityStateClearCreep:OnSweeperVfxCreated(go, userdata)
    go:SetLayerRecursively("City")
    go:SetActive(self.working)
    self.sweeperVfxTrans = go.transform
    self:UpdateVfxPosition(self.vfxLife > 0)
end

function CityStateClearCreep:OnSelectVfxCreated(go, userdata)
    go:SetLayerRecursively("City")
    if self.batch:Get(self.svfxX, self.svfxY) ~= true then
        go:SetActive(true)
        go.transform.position = self.city:GetCenterWorldPositionFromCoord(self.svfxX, self.svfxY, self.svfxSizeX, self.svfxSizeY) + CS.UnityEngine.Vector3.up * 0.1 * self.city.scale
        go.transform.localScale = CS.UnityEngine.Vector3(self.svfxSizeX, 1, self.svfxSizeY)
    else
        self:ReleaseSelectVfx()
    end
end

function CityStateClearCreep:ReleaseSelectVfx()
    if self.selectVfxHandle then
        self.selectVfxHandle:Delete()
        self.selectVfxHandle = nil
    end
end

function CityStateClearCreep:InSelectVfxRange(x, y)
    return self.svfxX <= x and x < self.svfxX + self.svfxSizeX and self.svfxY <= y and y < self.svfxY + self.svfxSizeY
end

function CityStateClearCreep:UpdateVfxPosition(canShowVfx)
    if not self.working then return end

    local trans = self.sweeperVfxTrans
    if Utils.IsNull(trans) then return end

    trans.position = self.city:GetWorldPositionFromCoord(self.x, self.y)
    trans.localPosition = trans.localPosition + self:VfxOffset()
    trans:SetVisible(canShowVfx)
end

function CityStateClearCreep:VfxOffset()
    return self.sweeper and CS.UnityEngine.Vector3(-1.2, 2.6, -1.2) or CS.UnityEngine.Vector3.up
end

function CityStateClearCreep:ReleaseVfx()
    if self.vfxHandle then
        self.vfxHandle:Delete()
        self.vfxHandle = nil
    end
    self.sweeperVfxTrans = nil
    self:ReleaseSelectVfx()
end

function CityStateClearCreep:EnableVfx()
    if Utils.IsNotNull(self.sweeperVfxTrans) then
        self.sweeperVfxTrans.gameObject:SetActive(true)
    end
end

function CityStateClearCreep:DisableVfx()
    if Utils.IsNotNull(self.sweeperVfxTrans) then
        self.sweeperVfxTrans.gameObject:SetActive(false)
    end
end

function CityStateClearCreep:BeginLocalRemove()
    return self.batch.count
end

function CityStateClearCreep:FakeBlockArea(minX, minY, maxX, maxY)
    self.city.creepManager:BlockCreepArea(minX, minY, maxX, maxY)
end

function CityStateClearCreep:FakeBlockPartial(minX, minY, maxX, maxY, tileCount)
    self.city.creepManager:BlockCreepAreaPartial(minX, minY, maxX, maxY, tileCount)
end

function CityStateClearCreep:EndLocalRemove(origin)
    return self.batch.count > origin
end

function CityStateClearCreep:InitSelector()
    self.handle = self.city.createHelper:Create(ManualResourceConst.city_map_affair_selector, self.city.CityRoot.transform, Delegate.GetOrCreate(self, self.OnSelectorCreate), nil, 0, true)
end

function CityStateClearCreep:ReleaseSelector()
    if self.handle then
        self.city.createHelper:Delete(self.handle)
        self.handle = nil
    end
end

---@param go CS.UnityEngine.GameObject
function CityStateClearCreep:OnSelectorCreate(go, userdata)
    ---@type CitySelector
    local selector = go:GetComponent(typeof(CS.DragonReborn.LuaBehaviour)).Instance
    selector:Init(self.city, self.x, self.y, self.brushSize, self.brushSize)
    self.selector = selector
    self.selector.behaviour.gameObject:SetActive(self.working)
    go:SetLayerRecursively("City")
    go:SetActive(self.working)
    if self.working then
        self.selector:UpdatePosition(self.x - self.brushSize * 0.5, self.y - self.brushSize * 0.5)
    end
end

function CityStateClearCreep:OnCameraSizeChanged(oldValue, newValue)
    local state = self.city:GetSuitableIdleState(newValue)
    if state ~= CityConst.STATE_NORMAL then
        self.stateMachine:ChangeState(state)
    end
end

return CityStateClearCreep