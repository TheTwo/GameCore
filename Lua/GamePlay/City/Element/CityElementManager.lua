local CityManagerBase = require("CityManagerBase")
---@class CityElementManager:CityManagerBase
---@field new fun():CityElementManager
---@field eleResHashMap table<number, CityElementResource>
local CityElementManager = class("CityElementManager", CityManagerBase)
local ConfigRefer = require("ConfigRefer")
local CityElementType = require("CityElementType")
local CityElementResource = require("CityElementResource")
local CityElementNpc = require("CityElementNpc")
local CityElementCreep = require("CityElementCreep")
local CityElementSpawner = require("CityElementSpawner")
local RectDyadicMap = require("RectDyadicMap")
local ArtResourceUtils = require("ArtResourceUtils")
local CastleStartWorkParameter = require("CastleStartWorkParameter")
local Delegate = require("Delegate")
local Utils = require("Utils")
local GuideUtils = require("GuideUtils")
local EventConst = require("EventConst")
local CityWorkHelper = require("CityWorkHelper")
local CityWorkTargetType = require("CityWorkTargetType")
local ManualResourceConst = require("ManualResourceConst")
local CityStaticObjectTileSpawnerBubble = require("CityStaticObjectTileSpawnerBubble")
local CityStaticObjectTileSpawnerRangeCircle = require("CityStaticObjectTileSpawnerRangeCircle")
local DBEntityType = require("DBEntityType")
local DBEntityPath = require("DBEntityPath")
local CityGridLayerMask = require("CityGridLayerMask")

---@class InQueueUnloadVfx
---@field handle CS.DragonReborn.VisualEffect.VisualEffectHandle

function CityElementManager:OnDataLoadStart()
    CityManagerBase.OnDataLoadStart(self)
    self:SwitchEditorNotice(true)
end

function CityElementManager:OnDataLoadFinish()
    self:SwitchEditorNotice(false)
    CityManagerBase.OnDataLoadFinish(self)
end

function CityElementManager:DoDataLoad()
    self.gridConfig = self.city.gridConfig
    ---@type table<number, boolean>
    self.tempHiddenByTimeline = {}
    ---@type table<number, boolean>
    self.inBattleSpawnerIds = {}
    self.tickRefreshInBattleExpedtionMap = true
    self:InitElements()
    self:LoadElementsToGrid()
    g_Game.ServiceManager:AddResponseCallback(CastleStartWorkParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFailedStartWork))
    g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_HIDE_CITY_ELEMENTS_REFRESH, Delegate.GetOrCreate(self, self.OnStoryTimelineHideCityElementsRefresh))
    g_Game.EventManager:AddListener(EventConst.CITY_BUBBLE_STATE_CHANGE, Delegate.GetOrCreate(self, self.RefreshAllSpawnerBubbleTileShow))
    g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.Expedition, Delegate.GetOrCreate(self, self.OnExpeditionCreated))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Expedition.ExpeditionInfo.SpawnerId.MsgPath, Delegate.GetOrCreate(self, self.OnExpeditionSpawnerIdChanged))
    g_Game.DatabaseManager:AddEntityDestroyByType(DBEntityType.Expedition, Delegate.GetOrCreate(self, self.OnExpeditionDestoryed))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.PresetList.MsgPath, Delegate.GetOrCreate(self, self.OnScenePlayerPresetChanged))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    self:LoadSpawnerBubbles()
    return self:DataLoadFinish()
end

function CityElementManager:DoDataUnload()
    self:UnLoadSpawnerBubbles()
    g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_HIDE_CITY_ELEMENTS_REFRESH, Delegate.GetOrCreate(self, self.OnStoryTimelineHideCityElementsRefresh))
    g_Game.ServiceManager:RemoveResponseCallback(CastleStartWorkParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFailedStartWork))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUBBLE_STATE_CHANGE, Delegate.GetOrCreate(self, self.RefreshAllSpawnerBubbleTileShow))
    g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.Expedition, Delegate.GetOrCreate(self, self.OnExpeditionCreated))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Expedition.ExpeditionInfo.SpawnerId.MsgPath, Delegate.GetOrCreate(self, self.OnExpeditionSpawnerIdChanged))
    g_Game.DatabaseManager:RemoveEntityDestroyByType(DBEntityType.Expedition, Delegate.GetOrCreate(self, self.OnExpeditionDestoryed))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.PresetList.MsgPath, Delegate.GetOrCreate(self, self.OnScenePlayerPresetChanged))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    self.elementMap = nil
    self.hiddenMap = nil
    self.gridConfig = nil
    self.eleResHashMap = nil
    self.eleNpcHashMap = nil
    self.spawnerMap = nil
    self.eleSpawnerHashMap = nil
    self.eleSpawnerBubbleTile = {}
    self.eleSpawnerCircleTile = {}
    self.eleSpawnerBubbleTileShow = {}
    self.eleSpawnerLinkExpedition = {}
    self.eleExpeditionLinkSpawner = {}
    self.needRefreshSpawnerBubbleTileShow = false
    table.clear(self.tempHiddenByTimeline)
end

function CityElementManager:DoViewLoad()
    ---@type table<CS.DragonReborn.VisualEffect.VisualEffectHandle, CS.DragonReborn.VisualEffect.VisualEffectHandle>
    self.inQueueUnloadVfx = {}
    return self:ViewLoadFinish()
end

function CityElementManager:DoViewUnload()
    for i, v in pairs(self.inQueueUnloadVfx) do
        self.inQueueUnloadVfx[i] = nil
        if Utils.IsNotNull(v) then
            v:Delete()
        end
    end
end

function CityElementManager:InitElements()
    self.elementMap = RectDyadicMap.new(self.gridConfig.cellsX, self.gridConfig.cellsY)
    self.hiddenMap = {}
    self.eleResHashMap = {}
    self.eleNpcHashMap = {}

    self.spawnerMap = RectDyadicMap.new(self.gridConfig.cellsX, self.gridConfig.cellsY)
    ---@type table<number, CityElementSpawner>
    self.eleSpawnerHashMap = {}
    ---@type table<number, CityStaticObjectTileSpawnerBubble>
    self.eleSpawnerBubbleTile = {}
    ---@type table<number, CityStaticObjectTileSpawnerRangeCircle>
    self.eleSpawnerCircleTile = {}
    ---@type table<number, CityElementSpawner>
    self.eleSpawnerBubbleTileShow = {}
    ---@type table<number, table<number, boolean>>
    self.eleSpawnerLinkExpedition = {}
    ---@type table<number, number>
    self.eleExpeditionLinkSpawner = {}
    self.needRefreshSpawnerBubbleTileShow = false
    ---@type table<number, boolean>
    self.spawnerActiveStatus = {}

    local castle = self.city:GetCastle()
    local elementMap = castle.CastleElements.Status;
    local processMap = castle.CastleElements.InProgressResource;

    if castle.CastleElements.ActivatedSpawner then
        for spawnerId, actived in pairs(castle.CastleElements.ActivatedSpawner) do
            self.spawnerActiveStatus[spawnerId] = actived
        end
    end

    ---@type CityElement
    local element = nil
    for _, cell in ConfigRefer.CityElementData:pairs() do
        local rectMap = self.elementMap
        if self:Check(cell:Id(), elementMap, processMap) then
            if cell:Type() == CityElementType.Resource then
                element = CityElementResource.CreateResourceFromElementData(self, cell)
            elseif cell:Type() == CityElementType.Npc then
                element = CityElementNpc.new(self, cell)
            elseif cell:Type() == CityElementType.Creep then
                element = CityElementCreep.new(self, cell)
            elseif cell:Type() == CityElementType.Spawner then
                element = CityElementSpawner.new(self, cell)
                rectMap = self.spawnerMap
            else
                self:LogErrorWithEditorDialog("又偷偷改类型没跟前端说:%s", cell:Id())
                goto continue
            end
            
            if self:IsHidden(element.id) then
                self.hiddenMap[element.id] = element
            else
                if not rectMap:TryAdd(element.x, element.y, element) then
                    ---@type CityElement
                    local exist = rectMap:Get(element.x, element.y)
                    self:LogErrorWithEditorDialog(("位置[X:%d,Y:%d]上已经存在[%s]类型的CityElement[configId:%d], 当前添加[configId:%d]失败"):format(element.x, element.y, GetClassName(exist), exist.id, element.id))
                else
                    if element:IsResource() then
                        self.eleResHashMap[element.id] = element
                    elseif element:IsNpc() then
                        self.eleNpcHashMap[element.id] = element
                    elseif element:IsSpawner() then
                        self.eleSpawnerHashMap[element.id] = element
                    end
                end
            end
        end
        ::continue::
    end

    local generatedMap = castle.CastleElements.GeneratedResourcePoint
    for id, data in pairs(generatedMap) do
        local element = CityElementResource.CreateResourceFromManual(self, id, data.Pos.X, data.Pos.Y, data.ConfigId)
        if not self.elementMap:TryAdd(element.x, element.y, element) then
            ---@type CityElement
            local exist = self.elementMap:Get(element.x, element.y)
            self:LogErrorWithEditorDialog(("位置[X:%d,Y:%d]上已经存在[%s]类型的CityElement[configId:%d], 当前添加[configId:%d]失败"):format(element.x, element.y, GetClassName(exist), exist.id, element.id))
        else
            self.eleResHashMap[element.id] = element
        end
    end
end

function CityElementManager:LoadElementsToGrid()
    for _, _, element in self:pairs() do
        if not element:IsHidden() then
            self.city.grid:AddCell(element:ToCityNode(true))
            element:RegisterInteractPoints()
        end
    end
end

---@private
---@param id number
---@param elementMap table<number, number>
---@param processMap table<number, wds.CastleTreeInfo>
---@return boolean 此行配置的资源是否在场上
function CityElementManager:Check(id, elementMap, processMap)
    if processMap and processMap[id] then
        return true
    end

    if not elementMap then
        return true
    end
    
    local mapIdx = id // 64
    if not elementMap[mapIdx] then
        return true
    end

    local valueIdx = id % 64
    local mask = 1 << valueIdx
    return (elementMap[mapIdx] & mask) == 0
end

---@param data wds.CastleResourcePoint
function CityElementManager:AddGeneratedRes(id, data)
    local element = CityElementResource.CreateResourceFromManual(self, id, data.Pos.X, data.Pos.Y, data.ConfigId)
    self.elementMap:Add(element.x, element.y, element)
    self.eleResHashMap[id] = element
    element:RegisterInteractPoints()
    return element
end

function CityElementManager:AddConfigElement(id)
    local cell = ConfigRefer.CityElementData:Find(id)
    if not cell then
        g_Logger.Error(("Can't find ID:%d CityElementData"):format(id))
        return
    end

    local element = nil
    local rectMap = self.elementMap
    if cell:Type() == CityElementType.Resource then
        element = CityElementResource.CreateResourceFromElementData(self, cell)
    elseif cell:Type() == CityElementType.Npc then
        element = CityElementNpc.new(self, cell)
    elseif cell:Type() == CityElementType.Spawner then
        element = CityElementSpawner.new(self, cell)
        rectMap = self.spawnerMap
    end

    if rectMap:TryAdd(element.x, element.y, element) then
        if cell:Type() == CityElementType.Resource then
            self.eleResHashMap[element.id] = element
            element:RegisterInteractPoints()
        elseif cell:Type() == CityElementType.Npc then
            self.eleNpcHashMap[element.id] = element
            element:RegisterInteractPoints()
        elseif cell:Type() == CityElementType.Spawner then
            self.eleSpawnerHashMap[element.id] = element
            if not self.eleSpawnerBubbleTile[element.id] then
                ---@type CityElementSpawner
                local spawner = element
                local bubbleTile = CityStaticObjectTileSpawnerBubble.new(self.city.gridView, spawner)
                self.eleSpawnerBubbleTile[element.id] = bubbleTile
                if spawner:CanShowBubble() then
                    self.eleSpawnerBubbleTileShow[element.Id] = element
                    g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_ADD, self.city, bubbleTile)
                end
                if spawner:CanShowRangeCircle() and not self.eleSpawnerCircleTile[element.Id] then
                    local circle = CityStaticObjectTileSpawnerRangeCircle.new(self.city.gridView, spawner)
                    self.eleSpawnerCircleTile[element.Id] = circle
                    g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_ADD, self.city, circle)
                end
            end
        end
        return element
    end
    return nil
end

function CityElementManager:Exist(x, y)
    return self.elementMap:Get(x, y) ~= nil
end

function CityElementManager:ExistSpawner(x, y)
    return self.spawnerMap:Get(x, y) ~= nil
end

function CityElementManager:Remove(x, y)
    if not self.city:IsMyCity() then
        return
    end

    if self.elementMap:Contains(x, y) then
        ---@type CityElementNpc|CityElement
        local ele = self.elementMap:Delete(x, y)
        ele:UnRegisterInteractPoints()
        if ele and ele:IsResource() then
            self.eleResHashMap[ele.id] = nil
        end
        if ele and ele:IsNpc() then
            self.eleNpcHashMap[ele.id] = nil
        end

        if ele and ele:IsNpc() and ele.npcConfigCell then
            local guideCallId = ele.npcConfigCell:OnRemoveGuideCall()
            if guideCallId > 0 then
                local guideCall = ConfigRefer.GuideCall:Find(guideCallId)
                if not guideCall then
                    g_Logger.Error("NPC ele:%s, npcConfig:%s OnRemoveGuideCall:%s, GuideCall config is nil", ele.id, ele.npcConfigCell:Id(), guideCallId)
                    return
                end
                if not GuideUtils.GotoByGuide(guideCallId) then
                    if UNITY_EDITOR and not CS.LogicRepoUtils.IsSsrLogicRepoExist() then
                        require("WarningToolsForDesigner").DisplayEditorDialog(("引导触发失败！Id:%s eleId:%s npcConfigId:%s"):format(guideCallId, ele.id, ele.npcConfigCell:Id()))
                    end
                end
            end
        end
    elseif self.spawnerMap:Contains(x, y) then
        ---@type CityElementSpawner
        local ele = self.spawnerMap:Delete(x, y)
        self.eleSpawnerHashMap[ele.id] = nil
        local spawnerBubble = self.eleSpawnerBubbleTile[ele.id]
        self.eleSpawnerBubbleTile[ele.id] = nil
        if spawnerBubble and self.eleSpawnerBubbleTileShowp[ele.id] then
            self.eleSpawnerBubbleTileShowp[ele.id] = nil
            g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_REMOVE, self.city, spawnerBubble)
        end
        if self.eleSpawnerCircleTile[ele.id] then
            local circle = self.eleSpawnerCircleTile[ele.id]
            self.eleSpawnerCircleTile[ele.id] = nil
            g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_REMOVE, self.city, circle)
            circle:Release()
        end
        if spawnerBubble then
            spawnerBubble:Release()
        end
    end
end

function CityElementManager:AddSpawnerActiveStatus(spawnerId, status)
    self.spawnerActiveStatus[spawnerId] = status
end

function CityElementManager:RemoveSpawnerActiveStatus(spawnerId)
    self.spawnerActiveStatus[spawnerId] = nil
    local elementConfig = ConfigRefer.CityElementData:Find(spawnerId)
    if not elementConfig then return end
    local spawnerConfig = ConfigRefer.CityElementSpawner:Find(elementConfig:ElementId())
    if not spawnerConfig then return end
    local guideCallId = spawnerConfig:OnRemoveGuideCall()
    if guideCallId == 0 then return end
    local guideCallConfig = ConfigRefer.GuideCall:Find(guideCallId)
    if not guideCallConfig then return end
    if not GuideUtils.GotoByGuide(guideCallId) then
        if UNITY_EDITOR and not CS.LogicRepoUtils.IsSsrLogicRepoExist() then
            require("WarningToolsForDesigner").DisplayGameViewAndSceneViewNotification(("引导触发失败！Id:%s spawnerId:%s"):format(guideCallId, spawnerId))
        end
    end
end

function CityElementManager:UpdateSpawnerActiveStatus(spawnerId, status)
    self.spawnerActiveStatus[spawnerId] = status
end

---@return CityElementResource|CityElementNpc|CityElementCreep|CityElementSpawner
function CityElementManager:GetElementById(id)
    if self.eleResHashMap[id] then
        return self.eleResHashMap[id]
    end

    if self.eleNpcHashMap[id] then
        return self.eleNpcHashMap[id]
    end

    if self.eleSpawnerHashMap[id] then
        return self.eleSpawnerHashMap[id]
    end

    local cfg = ConfigRefer.CityElementData:Find(id)
    if not cfg then return nil end

    local x, y = cfg:Pos():X(), cfg:Pos():Y()
    return self.spawnerMap:Get(x, y) or self.elementMap:Get(x, y)
end

---@return fun():number, number, CityElement
function CityElementManager:pairs()
    return self.elementMap:pairs()
end

function CityElementManager:IsPollutedAt(x, y)
    local element = self.elementMap:Get(x, y)
    if element then
        return self.city:GetCastle().CastleElements.PollutedElements[element.id] == true
    end
    return false
end

function CityElementManager:IsPolluted(id)
    local ele = self:GetElementById(id)
    if ele == nil then return false end
    
    local pollutedMap = self.city:GetCastle().CastleElements.PollutedElements
    if not pollutedMap then
        return false
    end

    return pollutedMap[id] == true
end

function CityElementManager:IsNpcPollutedById(cfgId)
    local cell = ConfigRefer.CityElementNpc:Find(cfgId)
    if not cell then
        return false
    end

    local pollutedMap = self.city:GetCastle().CastleElements.PollutedElements
    if not pollutedMap then
        return false
    end

    for _, v in pairs(self.elementMap.map) do
        if v:IsNpc() and pollutedMap[v.id] then
            return true
        end
    end
    
    return false
end

---@return wds.CastleResourceInfo|nil 返回资源进度(只有被消耗过的资源存在进度值)
function CityElementManager:GetResourceProcess(id)
    local castle = self.city:GetCastle()
    local processMap = castle.CastleElements.InProgressResource;
    if processMap then
        return processMap[id]
    end
end

---@return boolean 是否为隐藏起来的element
function CityElementManager:IsHidden(id)
    local castle = self.city:GetCastle()
    local hiddenMap = castle.CastleElements.HiddenElements
    return hiddenMap[id] ~= nil
end

---@param element CityElement
function CityElementManager:IsFogMask(element)
    return self.city:IsFogMaskRect(element.x, element.y, element.sizeX or 0, element.sizeY or 0)
end

---@param x number
---@param y number
---@param sx number
---@param sy number
---@param effectAssetId number
function CityElementManager:SpawnElementUnloadVfx(x, y, sx, sy ,effectAssetId)
    local prefab,scale = ArtResourceUtils.GetItemAndScale(effectAssetId)
    if not prefab then
        return
    end
    if scale <= 0 then
        scale = 1
    end
    local city = self.city
    local pos = city:GetCenterWorldPositionFromCoord(x, y, sx, sy)
    local vfxHandle = CS.DragonReborn.VisualEffect.VisualEffectHandle()
    self.inQueueUnloadVfx[vfxHandle] = vfxHandle
    vfxHandle:Create(prefab, "city_npc_unload_vfx", city:GetRoot().transform, function(success, obj, handle)
        if success then
            local trans = handle.Effect.transform
            trans.position = pos
            if prefab == "vfx_common_build" then
                trans.localScale = CS.UnityEngine.Vector3(sx * 0.28, 1, sy * 0.28) * scale
            else
                trans.localScale = CS.UnityEngine.Vector3.one * scale
            end
        end
    end, nil, 0, false, false, function(userData)
        self.inQueueUnloadVfx[vfxHandle] = nil
    end)
end

---@param x number
---@param y number
---@param sx number
---@param sy number
---@param langKey string
---@param pos CS.UnityEngine.Vector3
function CityElementManager:SpawnElementUnloadVfxI18N(x, y, sx, sy , langKey, pos)
    local city = self.city
    local vfxHandle = CS.DragonReborn.VisualEffect.VisualEffectHandle()
    self.inQueueUnloadVfx[vfxHandle] = vfxHandle
    vfxHandle:Create(ManualResourceConst.ui3d_bubble_building_repaired, "city_npc_unload_vfx", city:GetRoot().transform, function(success, obj, handle)
        if success then
            ---@type CS.UnityEngine.GameObject
            local go = handle.Effect.gameObject
            ---@type CityNPCUnloadLangContentVfx
            local logic = go:GetLuaBehaviour("CityNPCUnloadLangContentVfx").Instance
            logic:SetLangContent(langKey)
            local trans = handle.Effect.transform
            trans.position = pos
            trans.localScale = CS.UnityEngine.Vector3.one
        end
    end, nil, 0, false, false, function(userData)
        self.inQueueUnloadVfx[vfxHandle] = nil
    end)
end

---@param isSuccess boolean
---@param abstractRpc AbstractRpc
function CityElementManager:OnFailedStartWork(isSuccess, reply, abstractRpc, errCode)
    if isSuccess then return end
    local wrpc = abstractRpc.request
    if wrpc.WorkTarget == 0 then return end
    if errCode ~= 46016 then return end

    local workCfg = ConfigRefer.CityWork:Find(wrpc.WorkCfgId)
    if CityWorkHelper.GetWorkTargetTypeByCfg(workCfg) == CityWorkTargetType.Resource then
        local element = self:GetElementById(wrpc.WorkTarget)
        if element then
            self.city:RemoveElement(element.x, element.y)
        end
    end
end

function CityElementManager:OnStoryTimelineHideCityElementsRefresh(hideElements)
    hideElements = hideElements or {}
    local city = self.city
    for elementId, _ in pairs(self.tempHiddenByTimeline) do
        if not hideElements[elementId] then
            self.tempHiddenByTimeline[elementId] = nil
            g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_IN_TIMELINE_VISIBLE_CHANGED, city, elementId, true)
        end
    end
    for elementId, v in pairs(hideElements) do
        if not self.tempHiddenByTimeline[elementId] then
            self.tempHiddenByTimeline[elementId] = true
            g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_IN_TIMELINE_VISIBLE_CHANGED, city, elementId, false)
        end
    end
end

function CityElementManager:IsTempHiddenByTimeline(elementId)
    return self.tempHiddenByTimeline[elementId] or false
end

function CityElementManager:GetElementResourceCount(eleResCfgId)
    local count = 0
    for id, element in pairs(self.eleResHashMap) do
        if element.resCfgId == eleResCfgId and not self:IsHidden(id) and not self:IsFogMask(element) then
            count = count + 1
        end
    end
    return count
end

function CityElementManager:GetElementResourceCountByType(eleResType)
    local count = 0
    for id, element in pairs(self.eleResHashMap) do
        if element.resType == eleResType and not self:IsHidden(id) and not self:IsFogMask(element) and not self:IsPolluted(id) then
            count = count + 1
        end
    end
    return count
end

function CityElementManager:NeedLoadData()
    return true
end

function CityElementManager:NeedLoadView()
    return true
end

function CityElementManager:SwitchEditorNotice(flag)
    if not UNITY_EDITOR then return end

    self.showEditorDialog = flag
end

function CityElementManager:LogErrorWithEditorDialog(msg)
    g_Logger.ErrorChannel("CityElementManager", msg)
    
    if not self.showEditorDialog then return end
    local WarningToolsForDesigner = require("WarningToolsForDesigner")
    WarningToolsForDesigner.DisplayEditorDialog("CityElement冲突,检查配置", msg)
end

---@param element CityElement
function CityElementManager:RegisterInteractPoints(element, pointConfig, rotation, building, rangeMinX, rangeMinY, rangeMaxX, rangeMaxY, sx, sy)
    local x = element.x
    local y = element.y
    ---@type CityCitizenTargetInfo
    local ownerInfo = {}
    ownerInfo.id = element.id
    if element:IsResource() then
        ownerInfo.type = CityWorkTargetType.Resource
    else
        ownerInfo.type = CityWorkTargetType.Unknown
    end
    local point = self.city.cityInteractPointManager.MakePoint(self.city, pointConfig, self.city.gridConfig.cellsX ,x, y, rotation, nil, ownerInfo, sx, sy)
    if rangeMinX and rangeMinY and rangeMaxX and rangeMaxY then
        if point.gridX <= rangeMinX or point.gridX >= rangeMaxX then return end
        if point.gridY <= rangeMinY or point.gridY >= rangeMaxY then return end
    end
    if building ~= self.city.legoManager:GetLegoBuildingAt(point.gridX, point.gridY) then return end
    local index = self.city.cityInteractPointManager:DoAddInteractPoint(point)
    element.interactPoints[#element.interactPoints + 1] = index
    return true
end

---@param element CityElement
function CityElementManager:UnRegisterInteractPoints(element)
    local mgr = self.city.cityInteractPointManager
    for _, pointIndex in pairs(element.interactPoints) do
        mgr:RemoveInteractPoint(pointIndex)
    end
end

function CityElementManager:LoadSpawnerBubbles()
    ---@type table<number, wds.Expedition>
    local expedition = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.Expedition)
    if expedition then
        for _, expeditionData in pairs(expedition) do
            self:OnExpeditionCreated(DBEntityType.Expedition, expeditionData)
        end
    end
    for elemetnId, spawner in pairs(self.eleSpawnerHashMap) do
        local tile = CityStaticObjectTileSpawnerBubble.new(self.city.gridView, spawner)
        self.eleSpawnerBubbleTile[elemetnId] = tile
        if spawner:CanShowBubble() then
            self.eleSpawnerBubbleTileShow[elemetnId] = spawner
            g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_ADD, self.city, tile)
        end
        if spawner:CanShowRangeCircle() and not self.eleSpawnerCircleTile[elemetnId] then
            local circle = CityStaticObjectTileSpawnerRangeCircle.new(self.city.gridView, spawner)
            self.eleSpawnerCircleTile[elemetnId] = circle
            g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_ADD, self.city, circle)
        end
    end
end

function CityElementManager:UnLoadSpawnerBubbles()
    for elemetnId, bubbleTile in pairs(self.eleSpawnerBubbleTile) do
        if self.eleSpawnerBubbleTileShow[elemetnId] then
            g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_REMOVE, self.city, bubbleTile)
            bubbleTile:Release()
        end
    end
    for _, circle in pairs(self.eleSpawnerCircleTile) do
        g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_REMOVE, self.city, circle)
        circle:Release()
    end
    table.clear(self.eleSpawnerBubbleTileShow)
    table.clear(self.eleSpawnerBubbleTile)
    table.clear(self.eleSpawnerCircleTile)
end

function CityElementManager:Tick(dt)
    if self.tickRefreshInBattleExpedtionMap then
        self:RefreshSpawnerBattleStatus()
    end
    if self.needRefreshSpawnerBubbleTileShow then
        self:RefreshAllSpawnerBubbleTileShow()
    end
end

---@param entity wds.Expedition
function CityElementManager:OnExpeditionCreated(_, entity)
    local spawnerId = entity.ExpeditionInfo.SpawnerId
    if spawnerId == 0 then return end
    local set = self.eleSpawnerLinkExpedition[spawnerId]
    if not set then
        set = {}
        self.eleSpawnerLinkExpedition[spawnerId] = set
    end
    self.eleExpeditionLinkSpawner[entity.ID] = spawnerId
    if set[entity.ID] then return end
    set[entity.ID] = true
    self.needRefreshSpawnerBubbleTileShow = true
    self.tickRefreshInBattleExpedtionMap = true
end

---@param entity wds.Expedition
function CityElementManager:OnExpeditionSpawnerIdChanged(entity, _)
    local oldSpawnerId = self.eleExpeditionLinkSpawner[entity.ID]
    if not oldSpawnerId then return end
    self.eleExpeditionLinkSpawner[entity.ID] = nil
    local set = self.eleSpawnerLinkExpedition[oldSpawnerId]
    if not set or not set[entity.ID] then return end
    set[entity.ID] = nil
    self.needRefreshSpawnerBubbleTileShow = true
    self.tickRefreshInBattleExpedtionMap = true
    local spawnerId = entity.ExpeditionInfo.SpawnerId
    if spawnerId == 0 then return end
    self.eleExpeditionLinkSpawner[entity.ID] = spawnerId
    set = self.eleSpawnerLinkExpedition[spawnerId]
    if not set then
        set = {}
        self.eleSpawnerLinkExpedition[spawnerId] = set
    end
    set[entity.ID] = true
end

---@param entity wds.Expedition
function CityElementManager:OnExpeditionDestoryed(_, entity)
    local spawnerId = self.eleExpeditionLinkSpawner[entity.ID]
    if not spawnerId then return end
    self.needRefreshSpawnerBubbleTileShow = true
    self.tickRefreshInBattleExpedtionMap = true
    self.eleExpeditionLinkSpawner[entity.ID] = nil
    local set = self.eleSpawnerLinkExpedition[spawnerId]
    if not set then return end
    set[entity.ID] = nil
end

function CityElementManager:OnScenePlayerPresetChanged()
    self.tickRefreshInBattleExpedtionMap = true
end

function CityElementManager:IsSpawnerActived(spawnerId)
    return self.spawnerActiveStatus[spawnerId]
end

function CityElementManager:GetSpawnerLinkExpeditionId(spawnerId)
    return self.eleSpawnerLinkExpedition[spawnerId]
end

function CityElementManager:IsSpawnerLinkExpeditionInfoCreated(spawnerId)
    return not table.isNilOrZeroNums(self.eleSpawnerLinkExpedition[spawnerId])
end

function CityElementManager:IsSpawnerLinkExpeditionInBattle(spawnerId)
    return self.inBattleSpawnerIds[spawnerId] or false
end

function CityElementManager:RefreshAllSpawnerBubbleTileShow()
    self.needRefreshSpawnerBubbleTileShow = false
    for elementId, spawner in pairs(self.eleSpawnerBubbleTileShow) do
        if not spawner:CanShowBubble() then
            self.eleSpawnerBubbleTileShow[elementId] = nil
            g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_REMOVE, self.city, self.eleSpawnerBubbleTile[elementId])
        end
    end
    for elementId, bubbleTile in pairs(self.eleSpawnerBubbleTile) do
        local spawner = self.eleSpawnerHashMap[elementId]
        if not self.eleSpawnerBubbleTileShow[elementId] and spawner:CanShowBubble() then
            self.eleSpawnerBubbleTileShow[elementId] = spawner
            g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_ADD, self.city, bubbleTile)
        end
        local circle = self.eleSpawnerCircleTile[elementId]
        if spawner:CanShowRangeCircle() and not circle then
            local circle = CityStaticObjectTileSpawnerRangeCircle.new(self.city.gridView, spawner)
            self.eleSpawnerCircleTile[elementId] = circle
            g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_ADD, self.city, circle)
        elseif circle then
            self.eleSpawnerCircleTile[elementId] = nil
            g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_REMOVE, self.city, circle)
            circle:Release()
        end
    end
end

function CityElementManager:RefreshSpawnerBattleStatus()
    self.tickRefreshInBattleExpedtionMap = false
    local oldCount = 0
    local oldInBattleSpawnerIds = {}
    for key, value in pairs(self.inBattleSpawnerIds) do
        oldCount = oldCount + 1
        oldInBattleSpawnerIds[key] = value
    end
    local newCount = 0
    table.clear(self.inBattleSpawnerIds)
    ---@type table<number, wds.ScenePlayer>
    local scenePlayer = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.ScenePlayer)
    if scenePlayer then
        for _, value in pairs(scenePlayer) do
            for _, preset in pairs(value.ScenePlayerPreset.PresetList) do
                if preset.InBattle and preset.BattleEntityId ~= 0 then
                    local spawnerId = self.eleExpeditionLinkSpawner[preset.BattleEntityId]
                    if spawnerId then
                        newCount = newCount + 1
                        self.inBattleSpawnerIds[spawnerId] = true
                    end
                end
            end
        end
    end
    if newCount == oldCount then
        for key, _ in pairs(oldInBattleSpawnerIds) do
            if not self.inBattleSpawnerIds[key] then
                self.needRefreshSpawnerBubbleTileShow = true
                break
            end
        end
    else
        self.needRefreshSpawnerBubbleTileShow = true
    end
end

function CityElementManager:FindResInRangeByCenter(worldPos, distance, distanceLimit)
    ---@type {tileId:number, distance:number}[]
    local ret = {}
    local xCenter, yCenter = self.city:GetCoordFromPosition(worldPos)
    local requireDistanceSqrt = distanceLimit * distanceLimit
    local distance2GridCount = distance / (self.city.gridConfig.unitsPerCellX * self.city.scale)
    distance2GridCount = math.max(1, math.floor(distance2GridCount + 0.5))
    for x = xCenter - distance2GridCount, xCenter + distance2GridCount do
        for y = yCenter - distance2GridCount, yCenter + distance2GridCount do
            if not self.city.gridConfig:IsLocationValid(x, y) then
                goto continue
            end
            if self.city:IsFogMask(x, y) then
                goto continue
            end
            local mask = self.city.gridLayer:Get(x, y)
            if not CityGridLayerMask.HasResource(mask) then
                goto continue
            end
            ---@type CityGridCell
            local gridCell = self.city.grid:GetCell(x, y)
            if not gridCell then
                goto continue
            end
            if not gridCell.IsElement or not gridCell:IsElement() then
                goto continue
            end
            if not gridCell.IsResource or not gridCell:IsResource() then
                goto continue
            end
            if self:IsPolluted(gridCell.tileId) then
                goto continue
            end
            local progress = self:GetResourceProcess(gridCell.tileId)
            if progress and progress.WorkId ~= 0 then
                goto continue
            end
            local posDistanceSqrt = math.abs(x - xCenter) * math.abs(x - xCenter) + math.abs(y - yCenter) * math.abs(y - yCenter)
            if posDistanceSqrt > requireDistanceSqrt then
                goto continue
            end
            ---@type {tileId:number, distance:number}
            local info = {}
            info.tileId = gridCell.tileId
            info.distance = posDistanceSqrt
            table.insert(ret, info)
            ::continue::
        end
    end
    table.sort(ret, function(a, b) return a.distance < b.distance end)
    return ret
end

return CityElementManager