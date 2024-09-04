local GMPage = require("GMPage")
---@class GMPageMyCity:GMPage
---@field new fun():GMPageMyCity
local GMPageMyCity = class("GMPageMyCity", GMPage)
local GUILayout = require("GUILayout")
local Delegate = require("Delegate")
function GMPageMyCity:OnShow()
    local ModuleRefer = require("ModuleRefer")
    self.city = ModuleRefer.CityModule.myCity
    self.wallHorizontal = true
    self.progress = "0.5"
    self._scrollPosition = CS.UnityEngine.Vector2.zero
    self._areaX = ""
    self._areaY = ""
    self._areaId = ""
    self._areaStatus = ""

    if not self.city then return end
    local camera = self.city:GetCamera()
    if not camera then return end
    self.minSize = tostring(camera:GetMinSize())
    self.maxSize = tostring(camera:GetMaxSize())
end

function GMPageMyCity:OnGUI()
    if not self.city then return end

    self._scrollPosition = GUILayout.BeginScrollView(self._scrollPosition)
    self:GUI_LegoRoof()
    self:GUI_DebugBubble()
    self:GUI_DebugTest()
    GUILayout.EndScrollView()
end

function GMPageMyCity:GUI_CityState()
    local stateName = self.city.stateMachine:GetCurrentStateName()
    GUILayout.BeginHorizontal()
    GUILayout.Label("内城当前状态：", GUILayout.Width(100))
    GUILayout.Button(stateName, GUILayout.ExpandWidth(true))
    GUILayout.EndHorizontal()
end

function GMPageMyCity:GUI_CityCameraLookAtCoord()
    GUILayout.Space(5)
    local position = self.city:GetCamera():GetLookAtPosition()
    local x, y = self.city:GetCoordFromPosition(position)
    GUILayout.BeginHorizontal()
    GUILayout.Label("相机所在坐标：", GUILayout.Width(100))
    GUILayout.Button(("X:%d,Y:%d"):format(x, y), GUILayout.ExpandWidth(true))
    GUILayout.EndHorizontal()
end

function GMPageMyCity:GUI_CityRoomWallBuild()
    GUILayout.Space(5)
    GUILayout.BeginVertical()
    GUILayout.Label("调试内城墙壁和门的建造与删除")
    GUILayout.BeginHorizontal()
    GUILayout.Label("坐标:", GUILayout.Width(100))
    GUILayout.Label("X:", GUILayout.MinWidth(10))
    self.wallXStr = GUILayout.TextField(self.wallXStr, GUILayout.MinWidth(25))
    GUILayout.Label("Y:", GUILayout.MinWidth(10))
    self.wallYStr = GUILayout.TextField(self.wallYStr, GUILayout.MinWidth(25))
    if GUILayout.Button(self.wallHorizontal and "水平" or "垂直") then
        self.wallHorizontal = not self.wallHorizontal
    end
    if self:IsValidCoord() and self.city:CanPlaceWallAtWorldCoord(self.wallX, self.wallY, self.wallHorizontal) then
        if GUILayout.ColoredButton("放置", CS.UnityEngine.Color.green) then
            self.city:PlaceWallAtWorldCoord(self.wallX, self.wallY, 1, self.isHorizontal)
        end
    else
        GUILayout.ColoredButton("不可放置", CS.UnityEngine.Color.red)
    end
    GUILayout.EndHorizontal()
    GUILayout.EndVertical()
end

function GMPageMyCity:GUI_CityTestCamera()
    GUILayout.Space(5)
    GUILayout.BeginHorizontal()
    if GUILayout.Button("切换顶视角") then
        self.city:TweenToBuildViewport()
    end
    if GUILayout.Button("切换正常视角") then
        self.city:TweenToDefaultViewport()
    end
    GUILayout.EndHorizontal()
end

function GMPageMyCity:GUI_CityTestMapGrid()
    GUILayout.Space(5)
    GUILayout.BeginHorizontal()
    if GUILayout.Button("切换正常编辑网格") then
        self.city:OnMapGridDefault()
    end
    if GUILayout.Button("切换编辑房间网格") then
        self.city:OnMapGridShowOnlyInBuilding()
    end
    GUILayout.EndHorizontal()
end

function GMPageMyCity:GUI_CityWallNavmesh()
    GUILayout.Space(5)
    if GUILayout.Button("测试Navmesh数据构建") then
        local data = self.city.buildingManager:GenerateBuildingsNavmeshData()
        g_Logger.Trace(FormatTable(data))
    end
    if GUILayout.Button("打印建筑墙体信息") then
        self.city.buildingManager:PrintWallVH()
    end
end

function GMPageMyCity:GUI_CityWallFind()
    GUILayout.Space(5)
    self.wallFXStr = GUILayout.TextField(self.wallFXStr, GUILayout.MinWidth(25))
    self.wallFYStr = GUILayout.TextField(self.wallFYStr, GUILayout.MinWidth(25))
    GUILayout.BeginHorizontal()
    if GUILayout.Button("上") then
        g_Logger.Log(self.city:HasWallOrDoorAtTop(tonumber(self.wallFXStr), tonumber(self.wallFYStr)))
    end
    if GUILayout.Button("下") then
        g_Logger.Log(self.city:HasWallOrDoorAtBottom(tonumber(self.wallFXStr), tonumber(self.wallFYStr)))
    end
    if GUILayout.Button("左") then
        g_Logger.Log(self.city:HasWallOrDoorAtLeft(tonumber(self.wallFXStr), tonumber(self.wallFYStr)))
    end
    if GUILayout.Button("右") then
        g_Logger.Log(self.city:HasWallOrDoorAtRight(tonumber(self.wallFXStr), tonumber(self.wallFYStr)))
    end
    GUILayout.EndHorizontal()
end

function GMPageMyCity:IsValidCoord()
    self.wallX = tonumber(self.wallXStr)
    if not self.wallX then
        return false
    end
    self.wallY = tonumber(self.wallYStr)
    return self.wallY ~= nil
end

function GMPageMyCity:GUI_CityTestTransition()
    GUILayout.Space(5)
    self.progress = GUILayout.TextField(self.progress)
    if GUILayout.Button("测试菌毯淡入") then
        local EventConst = require("EventConst")
        for id, building in pairs(self.city.buildingManager.buildingMap) do
            -- g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_DEBUG_POLLUTED_IN, id, checknumber(self.progress))
            g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_POLLUTED_IN, id, checknumber(self.progress))
        end
    end
    if GUILayout.Button("测试菌毯淡出") then
        local EventConst = require("EventConst")
        for id, building in pairs(self.city.buildingManager.buildingMap) do
            -- g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_DEBUG_POLLUTED_OUT, id, checknumber(self.progress))
            g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_POLLUTED_OUT, id, checknumber(self.progress))
        end
    end
end

function GMPageMyCity:GUI_CityZoneTest()
    GUILayout.Space(5)
    GUILayout.BeginHorizontal()
    GUILayout.Label("x")
    self._areaX = GUILayout.TextField(self._areaX)
    GUILayout.Label("y")
    self._areaY = GUILayout.TextField(self._areaY)
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    if GUILayout.Button("所属区域") then
        local zone = self.city.zoneManager:GetZone(checknumber(self._areaX), checknumber(self._areaY))
        if zone then
            self._areaId = tostring(zone.id)
        end
    end
    GUILayout.Label(self._areaId)
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    if GUILayout.Button("区域状态") then
        local zone = self.city.zoneManager:GetZone(checknumber(self._areaX), checknumber(self._areaY))
        if zone then
            self._areaStatus = tostring(zone.status)
        end
    end
    GUILayout.Label(self._areaStatus)
    GUILayout.EndHorizontal()
end

function GMPageMyCity:GUI_TestVFXPlay()
    GUILayout.Space(5)
    GUILayout.BeginHorizontal()
    GUILayout.Label("X")
    self._posX = GUILayout.TextField(self._posX)
    GUILayout.Label("Y")
    self._posY = GUILayout.TextField(self._posY)
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    GUILayout.Label("SizeX")
    self._sizeX = GUILayout.TextField(self._sizeX)
    GUILayout.Label("SizeY")
    self._sizeY = GUILayout.TextField(self._sizeY)
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    GUILayout.Label("特效名")
    self._vfxName = GUILayout.TextField(self._vfxName)
    if GUILayout.Button("播放") then
        if not string.IsNullOrEmpty(self._vfxName) and tonumber(self._posX) and tonumber(self._posY) and tonumber(self._sizeX) and tonumber(self._sizeY) then
            self.city.createHelper:Create(self._vfxName, self.city.CityRoot.transform, Delegate.GetOrCreate(self, self.OnTestPlayVfx))
        end
    end
    GUILayout.EndHorizontal()
end

function GMPageMyCity:OnTestPlayVfx(go, userdata, handle)
    local Utils = require("Utils")
    if Utils.IsNull(go) then return handle:Delete() end

    go:SetLayerRecursively("City")
    local trans = go.transform
    trans.position = self.city:GetCenterWorldPositionFromCoord(checknumber(self._posX), checknumber(self._posY), checknumber(self._sizeX), checknumber(self._sizeY))
    trans.localScale = {x = checknumber(self._sizeX) / 10, y = 1, z = checknumber(self._sizeY) / 10}
    handle:Delete(5)
end

function GMPageMyCity:Tick()

end

function GMPageMyCity:OnHide()
    
end

function GMPageMyCity:Release()
    self.city = nil
end

function GMPageMyCity:GUI_TestMVC()
    if not self.city then return end

    if GUILayout.Button("释放显示层") then
        self.city:SetActive(false)
        self.city:UnloadView()
    end

    if GUILayout.Button("加载显示层") then
        self.city:LoadView()
        self.city:SetActive(true)
    end

    if GUILayout.Button("重载菌毯") then
        self.city.creepManager:DoViewUnload()
        self.city.creepManager:DoDataUnload()
        self.city.creepManager:TryDoDataLoad()
        self.city.creepManager:TryDoViewLoad()
    end
end

function GMPageMyCity:GUI_LegoRoof()
    if GUILayout.Button("开关屋顶") then
        self.city:ChangeRoofState(not self.city.roofHide)
    end
    if GUILayout.Button("开关前侧墙面显示") then
        self.city:ChangeWallHideState(not self.city.wallHide)
    end

    GUILayout.BeginHorizontal()
    GUILayout.Label("相机最近距离")
    self.minSize = GUILayout.TextField(self.minSize)
    if GUILayout.Button("强制设置") and tonumber(self.minSize) and tonumber(self.minSize) < self.city:GetCamera():GetMaxSize() then
        self.city:GetCamera().cameraDataPerspective.minSize = tonumber(self.minSize)
    end
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    GUILayout.Label("相机最远距离")
    self.maxSize = GUILayout.TextField(self.maxSize)
    if GUILayout.Button("强制设置") and tonumber(self.maxSize) and tonumber(self.maxSize) > self.city:GetCamera():GetMinSize() then
        self.city:GetCamera().cameraDataPerspective.maxSize = tonumber(self.maxSize)
    end
    
    GUILayout.EndHorizontal()
end

function GMPageMyCity:GUI_DebugBubble()
    if GUILayout.Button("刷新所有气泡") then
        local EventConst = require("EventConst")
        g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
    end
    if GUILayout.Button("刷新安全区状态") then
        local EventConst = require("EventConst")
        g_Game.EventManager:TriggerEvent(EventConst.CITY_SAFE_AREA_STATUS_REFRESH)
    end
end

function GMPageMyCity:GUI_DebugTest()
    if GUILayout.Button("打印Castle数据") then
        local castle = self.city:GetCastle()
        CS.UnityEngine.GUIUtility.systemCopyBuffer = FormatTable(castle)
    end
    if GUILayout.Button("打印CastleAttrModule家具属性缓存信息") then
        local ModuleRefer = require("ModuleRefer")
        local castleAttrModule = ModuleRefer.CastleAttrModule
        CS.UnityEngine.GUIUtility.systemCopyBuffer = FormatTable(castleAttrModule.m_FurnitureProviders)
    end
end

return GMPageMyCity
