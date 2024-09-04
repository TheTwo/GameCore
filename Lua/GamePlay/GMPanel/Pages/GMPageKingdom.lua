local GUILayout = require("GUILayout")
local GMPage = require("GMPage")
local KingdomScene = require("KingdomScene")
local ModuleRefer = require("ModuleRefer")
local CastleAssignHouseParameter = require("CastleAssignHouseParameter")
local CityCitizenManageUIMediatorDefine = require("CityCitizenManageUIMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")
local CityConst = require("CityConst")
local TimerUtility = require("TimerUtility")
local KingdomMapUtils = require("KingdomMapUtils")

local EventConst = require("EventConst")
local CityElementType = require("CityElementType")

---@class GMPageKingdom:GMPage
local GMPageKingdom = class('GMPageKingdom', GMPage)

function GMPageKingdom:Tick()
    if self.needRestart then
        self.panel:PanelShow(false)
        self.needRestart = false
        g_Game:RestartGame();
    end
end

function GMPageKingdom:InitOnce()
    self._scrollPos = CS.UnityEngine.Vector2.zero
    self.mapName = g_Game.PlayerPrefsEx:GetString("map_name", "mvp_map")
    self.inputX = "0"
    self.inputY = "0"
    --self.troopPosX = "300"
    --self.troopPosZ = "300"
    self._buildingId = ""
    self._heroId = ""
    self._targetType = ""
    self._zoneId = ""
    self._cityId = ""

    self.establishTerritory = "100895"
    self.establishX = "1443"
    self.establishZ = "6242"
    self.establishRange = "10000"
    self.establishDuration = "2"

    self.territoryIDList = ""
    self.territoryID = 1
    self.occupyTerritoryIDList = ""

    self.needRestart = false

    ModuleRefer.LandformModule.TestLandformID = 200001
    ModuleRefer.LandformModule.TestCastleX = 7000
    ModuleRefer.LandformModule.TestCastleZ = 1500
    ModuleRefer.LandformModule.TestOffset = -0.05
    
    self.init = true
end

function GMPageKingdom:OnGUI()
    if not self.init then
        self:InitOnce()
    end
    
    self._scrollPos = GUILayout.BeginScrollView(self._scrollPos)

    GUILayout.BeginHorizontal()
    GUILayout.Label("Choose Map Name:", GUILayout.shrinkWidth)
    self.mapName = GUILayout.TextField(self.mapName)
    if GUILayout.Button("Change") then
        g_Game.PlayerPrefsEx:SetString("map_name", self.mapName)
        self.needRestart = true
    end
    GUILayout.EndHorizontal()
    
    GUILayout.BeginHorizontal()
    GUILayout.Label("X", GUILayout.shrinkWidth)
    self.inputX = GUILayout.TextField(self.inputX)
    GUILayout.Label("Y", GUILayout.shrinkWidth)
    self.inputY = GUILayout.TextField(self.inputY)

    if GUILayout.Button("Go") then
        ---@type KingdomScene
        local scene = g_Game.SceneManager.current
        if scene and scene:is(KingdomScene) then
            local x = tonumber(self.inputX) or 0
            local z = tonumber(self.inputY) or 0
            local pos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(x,z, KingdomMapUtils.GetMapSystem())
            scene.basicCamera:LookAt(pos)
        end
    end

    if GUILayout.Button("Return My City") then
        ---@type KingdomScene
        local scene = g_Game.SceneManager.current
        local camera = scene.basicCamera
        local castle = ModuleRefer.PlayerModule:GetCastle()
        local mapBasic = castle.MapBasics
        local buildingPos = mapBasic.BuildingPos
        local pos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(buildingPos.X,buildingPos.Y, KingdomMapUtils.GetMapSystem())
        camera:LookAt(pos)
    end

    GUILayout.EndHorizontal() 

    -- city explorer
    GUILayout.BeginHorizontal()
    if GUILayout.Button("DumpExplorers") then
        local city = ModuleRefer.CityModule.myCity
        if city then
            local explorers = {}
            for key, value in pairs(city:GetCastle().InCityInfo.Explorers) do
                explorers[tostring(key)] = tostring(value)
            end
            dump(explorers)
        end
    end
    if GUILayout.Button("DumpCitizens") then
        local city = ModuleRefer.CityModule.myCity
        if city then
            local citizens = {}
            for key, value in pairs(city:GetCastle().CastleCitizens) do
                citizens[tostring(key)] = tostring(value)
            end
            dump(citizens)
        end
    end
    if GUILayout.Button("DumpCastleWorks") then
        local city = ModuleRefer.CityModule.myCity
        if city then
            local castleWork = {}
            for key, value in pairs(city:GetCastle().CastleWork) do
                castleWork[tostring(key)] = tostring(value)
            end
            dump(castleWork)
        end
    end
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    if GUILayout.Button("assign house") then
        local request = CastleAssignHouseParameter.new()
        request.args.CitizenId = tonumber(self._heroId)
        request.args.HouseId = tonumber(self._buildingId)
        request:Send()
    end
    if GUILayout.Button("Test work") then
        require("ModuleRefer").CityModule.myCity.cityCitizenManager:StartWork(tonumber(self._heroId),tonumber(self._buildingId), tonumber(self._targetType))
    end
    if GUILayout.Button("Stop Work") then
        require("ModuleRefer").CityModule.myCity.cityCitizenManager:StopWorkImpl(tonumber(self._heroId))
    end
    if GUILayout.Button("家具指派") then
        require("ModuleRefer").CityModule.myCity.cityCitizenManager:AssignProcessPlan(tonumber(self._heroId), tonumber(self._buildingId), tonumber(self._targetType))
    end
    if GUILayout.Button("收取") then
        require("ModuleRefer").CityModule.myCity.cityCitizenManager:GetProcessOutput(nil, tonumber(self._buildingId))
    end
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    if GUILayout.Button("居民管理UI") then
        ---@type CityCitizenManageUIMediatorParam
        local param = {}
        param.mode = CityCitizenManageUIMediatorDefine.Mode.DragAssign
        g_Game.UIManager:Open(UIMediatorNames.CityCitizenManageUIMediator, param)
    end
    if GUILayout.Button("Go") then
        local CityCitizenResidentFeedbackUIDataProvider = require("CityCitizenResidentFeedbackUIDataProvider")
        local provider = CityCitizenResidentFeedbackUIDataProvider.new(UIMediatorNames.UIOneDaySuccessMediator)
        provider:Init(require("ModuleRefer").CityModule.myCity.uid, {
            [1] = { ConfigId = 2},
            [2] = { ConfigId = 3},
            [3] = { ConfigId = 4},
            [4] = { ConfigId = 5},
            [5] = { ConfigId = 6},
            [6] = { ConfigId = 1},
        }, function()
            self._inWaitingShowFeedbackProvider = nil
        end)
        g_Game.UIManager:SendOpenCmd(provider._useInMediatorName, provider)
    end

    GUILayout.EndHorizontal()

    GUILayout.BeginHorizontal()
    if GUILayout.Button("全自动解锁大地图全部迷雾！！") then
        self:AutoUnlockAllMists()
    end
    GUILayout.EndHorizontal()

    GUILayout.BeginHorizontal()
    GUILayout.Label("Territory ID:", GUILayout.shrinkWidth)
    self.establishTerritory = GUILayout.TextField(tostring(self.establishTerritory))
    GUILayout.Label("X:", GUILayout.shrinkWidth)
    self.establishX = GUILayout.TextField(tostring(self.establishX))
    GUILayout.Label("Z:", GUILayout.shrinkWidth)
    self.establishZ = GUILayout.TextField(tostring(self.establishZ))
    GUILayout.Label("Range:", GUILayout.shrinkWidth)
    self.establishRange = GUILayout.TextField(tostring(self.establishRange))
    GUILayout.Label("Duration:", GUILayout.shrinkWidth)
    self.establishDuration = GUILayout.TextField(tostring(self.establishDuration))
    if GUILayout.Button("清除领地道路菌毯") then
        ModuleRefer.RoadModule:TestCleanCreep(self.establishTerritory, self.establishX, self.establishZ, self.establishRange, self.establishDuration)
    end
    GUILayout.EndHorizontal()

    GUILayout.BeginHorizontal()
    GUILayout.Label("Territory ID:", GUILayout.shrinkWidth)
    self.occupyTerritoryIDList = GUILayout.TextField(tostring(self.occupyTerritoryIDList))
    if GUILayout.Button("测试占领指定领地") then
        local territoryIDList = string.split(self.occupyTerritoryIDList, ',')
        ModuleRefer.TerritoryModule:TestOccupyVillage(territoryIDList)
    end
    GUILayout.EndHorizontal()

    GUILayout.BeginHorizontal()
    if GUILayout.Button("Test Create Territory Mesh") then
        local territoryIDList = string.split(self.territoryIDList, ',')
        local territoryIDSet = CS.System.Collections.Generic.HashSet(typeof(CS.System.Int32))()
        for _, str in ipairs(territoryIDList) do
            local id = tonumber(str)
            territoryIDSet:Add(id)
        end
        local request = CS.Voronoi.VoronoiMeshRequest()
        request.Name = "territory_mesh"
        request.ScaleX = 10
        request.ScaleY = 10
        request.CoordinateType = CS.Voronoi.CoordinateType.XY
        request.IDSet = territoryIDSet
        request.CompleteCallback = function(go)
            g_Logger.Error(go.name)
        end
        ModuleRefer.TerritoryModule:GenerateTerritoryMesh(request)
    end
    GUILayout.EndHorizontal()

    GUILayout.BeginHorizontal()
    if GUILayout.Button("Cancel Territory Mesh") then
        ModuleRefer.TerritoryModule:CancelTerritoryMesh()
    end
    GUILayout.EndHorizontal()

    GUILayout.BeginHorizontal()
    if GUILayout.Button("Show Creep Area") then
        -- 罗灵占领涂色
        ModuleRefer.TerritoryModule:ShowCreepAreas()
    end
    if GUILayout.Button("Hide Creep Area") then
        ModuleRefer.TerritoryModule:HideCreepAreas()
    end
    if GUILayout.Button("Show Territory Area") then
        -- 联盟领地涂色
        ModuleRefer.TerritoryModule:ShowTerritory()
    end
    if GUILayout.Button("Hide Territory Area") then
        ModuleRefer.TerritoryModule:HideTerritory()
    end
    GUILayout.EndHorizontal()

    GUILayout.BeginHorizontal()
    if GUILayout.Button("Show Fog") then
        ModuleRefer.MapFogModule:ShowPlaneFog()
    end
    if GUILayout.Button("Hide Fog") then
        -- 不显示迷雾
        ModuleRefer.MapFogModule:HidePlaneFog()
    end
    if GUILayout.Button("Show ECS Deco") then
        KingdomMapUtils.ShowMapDecorations()
    end
    if GUILayout.Button("Hide ECS Deco") then
        -- 隐藏装饰物
        KingdomMapUtils.HideMapDecorations()
    end

    if GUILayout.Button("Show ECS HUD") then
        ModuleRefer.MapHUDModule:ShowHud()
    end
    if GUILayout.Button("Hide ECS HUD") then
        -- 隐藏Hud
        ModuleRefer.MapHUDModule:HideHud()
    end
    GUILayout.EndHorizontal()

    GUILayout.BeginHorizontal()
    GUILayout.Label("Castle X:", GUILayout.shrinkWidth)
    ModuleRefer.LandformModule.TestCastleX = GUILayout.TextField(tostring(ModuleRefer.LandformModule.TestCastleX))
    GUILayout.Label("Castle Z:", GUILayout.shrinkWidth)
    ModuleRefer.LandformModule.TestCastleZ = GUILayout.TextField(tostring(ModuleRefer.LandformModule.TestCastleZ))
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    GUILayout.Label("Landform ID:", GUILayout.shrinkWidth)
    ModuleRefer.LandformModule.TestLandformID = GUILayout.TextField(tostring(ModuleRefer.LandformModule.TestLandformID))
    GUILayout.Label("Offset:", GUILayout.shrinkWidth)
    ModuleRefer.LandformModule.TestOffset = GUILayout.TextField(tostring(ModuleRefer.LandformModule.TestOffset))
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    if GUILayout.Button("开启圈层图测试") then
        ModuleRefer.LandformModule.TestLandformEnable = true
    end
    if GUILayout.Button("关闭圈层图测试") then
        ModuleRefer.LandformModule.TestLandformEnable = false
    end
    GUILayout.EndHorizontal()

    GUILayout.EndScrollView()

end

function GMPageKingdom:AutoUnlockAllMists()
    local unlockCount = 10
    local mists = ModuleRefer.MapFogModule:GetNeighborMistsCanUnlock(unlockCount)
    if table.nums(mists) <= 0 then
        return
    end
    local zoomOutDuration = 0.5
    local unlockDuration = 2.5
    ModuleRefer.MapFogModule.isPlayingMultiUnlockEffect = true
    ModuleRefer.MapFogModule:LookAtMists(mists, zoomOutDuration, function()
        ModuleRefer.MapFogModule:UnlockMistCell(mists)
    end)

    local basicCamera = KingdomMapUtils.GetBasicCamera()
    TimerUtility.DelayExecute(function()
        basicCamera.enableDragging = true
        basicCamera.enablePinch = true
        ModuleRefer.MapFogModule.isPlayingMultiUnlockEffect = false
        self:AutoUnlockAllMists()
    end, unlockDuration + zoomOutDuration)
end

return GMPageKingdom
