local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local DBEntityPath = require('DBEntityPath')
local CommonTipsInfoDefine = require('CommonTipsInfoDefine')
local CommonLeaderboardPopupDefine = require('CommonLeaderboardPopupDefine')
local WorldTrendDefine = require('WorldTrendDefine')
local UIHelper = require('UIHelper')
local KingdomMapUtils = require('KingdomMapUtils')
local Vector3 = CS.UnityEngine.Vector3

---@class EarthRevivalMapComponent : BaseUIComponent
local EarthRevivalMapComponent = class('EarthRevivalMapComponent', BaseUIComponent)

local MAX_MAP_MODE_SCALE = 2.5

function EarthRevivalMapComponent:OnCreate()
    --left
    self.sliderProgress = self:Slider("p_set_bar")
    self.textRolin = self:Text("p_text_rolin", "worldstage_luoling")
    self.textRolinProgress = self:Text("p_text_rolin_num")
    self.textHuman = self:Text("p_text_human", "worldstage_ren")
    self.textHumanProgress = self:Text("p_text_human_num")
    self.btnBuff = self:Button("p_btn_buff", Delegate.GetOrCreate(self, self.OnClickShowBuff))
    self.btnContribution = self:Button("p_btn_contribution", Delegate.GetOrCreate(self, self.OnClickShowContribution))

    --mid
    self.imgMap = self:Image('p_img_map')
    -- self.btnMap = self:Button('p_btn_map', Delegate.GetOrCreate(self, self.OnClickMap))
    self:PointerClick('node_map',Delegate.GetOrCreate(self,self.OnClickMap))
    self.btn1x = self:Button("p_btn_1x", Delegate.GetOrCreate(self, self.OnClick1x))
    self.goSelect1x = self:GameObject("p_img_select_1x")
    self.text1x = self:Text("p_text_1x", "worldstage_cheng1")
    self.btn2x = self:Button("p_btn_2x", Delegate.GetOrCreate(self, self.OnClick2x))
    self.goSelect2x = self:GameObject("p_img_select_2x")
    self.text2x = self:Text("p_text_2x", "worldstage_cheng2")
    self.btn3x = self:Button("p_btn_3x", Delegate.GetOrCreate(self, self.OnClick3x))
    self.goSelect3x = self:GameObject("p_img_select_3x")
    self.text3x = self:Text("p_text_3x", "[*o*]3x")
    self.rectMapRoot = self:RectTransform("p_empty")
    self.rectNodeMap = self:RectTransform("node_map")
    self.rectDetailMap = self:RectTransform("node_detail")
    self.goNodeMap = self:GameObject("node_map")
    self.imgMapBig = self:Image("p_img_map_big")
    self.imgMapMid = self:Image("p_img_map_mid")
    self.imgMapSmall = self:Image("p_img_map_small")
    self.imgDetailBig = self:Image("detail_big")
    self.imgDetailMid = self:Image("detail_mid")
    self.imgDetailSmall = self:Image("detail_small")
    self.goMeshParent = self:GameObject("mesh_Parent")
    self.nodeMapList = {
        [1] = self.imgMapBig,
        [2] = self.imgMapMid,
        [3] = self.imgMapSmall,
    }
    self.nodeDetailList = {
        [1] = self.imgDetailBig,
        [2] = self.imgDetailMid,
        [3] = self.imgDetailSmall,
    }

    --right
    self.textWorldStageName = self:Text("p_text_level_info")
    self.imgStage = self:Image("p_img_stage")
    self.textTimeDayTitle = self:Text("p_text_time_d", "worldstage_tian")
    self.textTimeDay = self:Text("p_text_time_day")
    self.textTimeHourTitle = self:Text("p_text_time_h", "worldstage_xiaoshi")
    self.textTimeHour = self:Text("p_text_time_hear")
    self.textTimeMinTitle = self:Text("p_text_time_m", "worldstage_fenzhong")
    self.textTimeMinute = self:Text("p_text_time_min")

    self.goNewSystem = self:GameObject("p_system")
    self.textNewSystemTitle = self:Text("p_text_new_systems", "worldstage_xinxitong")
    self.tableviewproNewSystem = self:TableViewPro("p_table_systems")

    self.goTask = self:GameObject("p_task")
    self.textTaskTitle = self:Text("p_text_tasks", "worldstage_jieduanrw")
    self.textTaskContent = self:Text("p_text_task_content")

    self.goTrends = self:GameObject("p_trends")
    self.textTrendTitle = self:Text("p_text_trends", "worldstage_fenzhi")
    self.btnWorldTrendDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnClickWorldTrendDetail))
    self.sliderBranch_1 = self:Slider("p_pb_01")
    self.goWin_1 = self:GameObject("p_icon_win_01")
    self.goLose_1 = self:GameObject("p_icon_lose_01")
    self.textBranchContent_1 = self:Text("p_text_answer_01")
    self.btnAnswer_1 = self:Button("p_btn_answer_01", Delegate.GetOrCreate(self, self.OnClickAnswer_1))
    self.btnReward_1 = self:Button("p_btn_reward_status_01", Delegate.GetOrCreate(self, self.OnClickRewardIcon_1))
    self.imgReward_1 = self:Image("p_icon_01")
    self.statusReward_1 = self:StatusRecordParent("p_btn_reward_status_01")
    self.imgSlider_1 = self:Image("p_fill_01")
    self.sliderBranch_2 = self:Slider("p_pb_02")
    self.goWin_2 = self:GameObject("p_icon_win_02")
    self.goLose_2 = self:GameObject("p_icon_lose_02")
    self.textBranchContent_2 = self:Text("p_text_answer_02")
    self.btnAnswer_2 = self:Button("p_btn_answer_02", Delegate.GetOrCreate(self, self.OnClickAnswer_2))
    self.btnReward_2 = self:Button("p_btn_reward_status_02", Delegate.GetOrCreate(self, self.OnClickRewardIcon_2))
    self.imgReward_2 = self:Image("p_icon_02")
    self.statusReward_2 = self:StatusRecordParent("p_btn_reward_status_02")
    self.imgSlider_2 = self:Image("p_fill_02")

    self.textHumanPower = self:Text("p_text_human_r", "[*o*]人类势力")
    self.textRolinPower = self:Text("p_text_rolin_r", "[*o*]罗灵势力")

    --mapGroup
    self.goMapGroup = self:GameObject("p_group_info_map")
    self.luagoMapGroup = self:LuaObject("p_group_info_map")
end

function EarthRevivalMapComponent:OnShow()
    self:ResetMaterial()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.TickSecond))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Kingdom.WorldStage.TerritoryOccupyCache.MsgPath, Delegate.GetOrCreate(self,self.RefreshTerritoryProgress))
end

function EarthRevivalMapComponent:OnHide()
    self:ResetMaterial()
    if not self.territoryMesh then
        ModuleRefer.TerritoryModule:CancelTerritoryMesh()
    else
        ModuleRefer.TerritoryModule:DestroyTerritoryMesh(self.territoryMesh)
        self.territoryMesh = nil
    end
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TickSecond))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Kingdom.WorldStage.TerritoryOccupyCache.MsgPath, Delegate.GetOrCreate(self,self.RefreshTerritoryProgress))
end

function EarthRevivalMapComponent:OnClose()
    
end

function EarthRevivalMapComponent:OnFeedData()
    --Left
    self:RefreshTerritoryProgress()

    --Map
    self:RefreshMap()

    --RightContent
    -- self:RefreshWorldStageContent()
end

function EarthRevivalMapComponent:RefreshTerritoryProgress()
    local total = ModuleRefer.EarthRevivalModule:GetTerritoryTotalCount()
    local occupy = ModuleRefer.EarthRevivalModule:GetTerritoryOccupyCount()
    local progress = occupy / total
    self.progressNum = math.ceil(progress * 100)
    self.sliderProgress.value = progress
    self.textRolinProgress.text = (100 - self.progressNum) .. "%"
    self.textHumanProgress.text = self.progressNum .. "%"
end

function EarthRevivalMapComponent:RefreshMap()
    self.btn3x:SetVisible(false)
    self:ResetMaterial()
    self:RefreshTerritoryOccupy()
end

function EarthRevivalMapComponent:RefreshTerritoryOccupy()
    local territoryMap = ModuleRefer.EarthRevivalModule:GetTerritoryOccupyMap()
    local territoryIDSet = CS.System.Collections.Generic.HashSet(typeof(CS.System.Int32))()
    for k, v in pairs(territoryMap) do
        territoryIDSet:Add(k)
    end
    
    local request = CS.Territory.TerritoryMeshRequest()
    request.Name = "territory_mesh"
    --todo:load your material
    request.Material = self.imgMap.material
    request.ScaleX = 1
    request.ScaleY = 1
    request.CoordinateType = CS.Territory.CoordinateType.XY
    request.TerritoryIDSet = territoryIDSet
    request.CustomCallback = function(go, mesh, material)
        go:AddComponent(typeof(CS.UnityEngine.CanvasRenderer))
        local uimesh = go:AddComponent(typeof(CS.DragonReborn.UI.UGUIExtends.UiMesh))
        mesh:UploadMeshData(false)
        uimesh:SetMesh(mesh)
        uimesh:SetScale(Vector3(0.128, 0.128, 0.128))
        uimesh:SetColor(UIHelper.TryParseHtmlString("#4494f5"))
        uimesh.material = material
    end
    request.CompleteCallback = function(go)
        self.territoryMesh = go
        self.territoryMesh.transform:SetParent(self.goMeshParent.transform)
        self.territoryMesh.transform.localPosition = Vector3.zero
        self.territoryMesh.transform.localScale = Vector3.one
    end
    ModuleRefer.TerritoryModule:GenerateTerritoryMesh(request)
end

function EarthRevivalMapComponent:RefreshWorldStageContent()
    self.goMapGroup:SetActive(false)
    ---@type wds.WorldStageNode
    local curStage = ModuleRefer.WorldTrendModule:GetCurStage()
    ---@type WorldStageConfigCell
    self.stageConfig = ConfigRefer.WorldStage:Find(curStage.Stage)
    if not self.stageConfig then
        return
    end
    self.textWorldStageName.text = I18N.Get(self.stageConfig:Name())
    if self.stageConfig:StageBackgroundLength() > 0 then
        g_Game.SpriteManager:LoadSprite(self.stageConfig:StageBackground(1), self.imgStage)
    end

    local stageEndTime = curStage.EndTime.Seconds
    local curTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    self.stageRemainTime = stageEndTime - curTime
    self:UpdateStageRemainTime()

    self.tableviewproNewSystem:Clear()
    if self.stageConfig:UnlockSystemsLength() > 0 then
        for i = 1, self.stageConfig:UnlockSystemsLength() do
            self.tableviewproNewSystem:AppendData(self.stageConfig:UnlockSystems(i))
        end
        self.goNewSystem:SetActive(true)
    else
        self.goNewSystem:SetActive(false)
    end

    if self.stageConfig:KingdomTasksLength() > 0 then
        self.textTaskContent.text = ModuleRefer.WorldTrendModule:GetKingdomTaskScheduleContent(self.stageConfig:KingdomTasks(1))
        self.goTask:SetActive(true)
    else
        self.goTask:SetActive(false)
    end

    if self.stageConfig:BranchKingdomTasksLength() > 1 then
        self:InitBranchTask_1(self.stageConfig:BranchKingdomTasks(1))
        self:InitBranchTask_2(self.stageConfig:BranchKingdomTasks(2))
        self:BranchCompare()
        self.goTrends:SetActive(true)
    else
        self.goTrends:SetActive(false)
    end
end

function EarthRevivalMapComponent:UpdateStageRemainTime()
    if not self.stageRemainTime or self.stageRemainTime < 0 then
        return
    end
    local day = math.floor(self.stageRemainTime / 86400)
    local hour = math.floor((self.stageRemainTime % 86400) / 3600)
    local minute = math.floor((self.stageRemainTime % 3600) / 60)
    self.textTimeDay.text = day
    self.textTimeHour.text = hour
    self.textTimeMinute.text = minute
end

function EarthRevivalMapComponent:InitBranchTask_1(taskID)
    local cur, total = ModuleRefer.WorldTrendModule:GetKingdomTaskSchedule(taskID)
    if total > 0 then
        self.branchProgress_1 = cur / total
    else
        self.branchProgress_1 = 0
    end
    self.sliderBranch_1.value = self.branchProgress_1
    self.textBranchContent_1.text = ModuleRefer.WorldTrendModule:GetKingdomTaskScheduleContent(taskID)
    if self.stageConfig:BranchResultsIconLength() > 0 then
        g_Game.SpriteManager:LoadSprite(self.stageConfig:BranchResultsIcon(1), self.imgReward_1)
    else
        self.imgReward_1:SetVisible(false)
    end
    if self.stageConfig:BranchResultDescLength() > 0 then
        self.rewardTips_1 = self.stageConfig:BranchResultDesc(1)
    end
    self.goWin_1:SetActive(false)
    self.goLose_1:SetActive(false)
end

function EarthRevivalMapComponent:InitBranchTask_2(taskID)
    local cur, total = ModuleRefer.WorldTrendModule:GetKingdomTaskSchedule(taskID)
    if total > 0 then
        self.branchProgress_2 = cur / total
    else
        self.branchProgress_2 = 0
    end
    self.sliderBranch_2.value = self.branchProgress_2
    self.textBranchContent_2.text = ModuleRefer.WorldTrendModule:GetKingdomTaskScheduleContent(taskID)
    if self.stageConfig:BranchResultsIconLength() > 1 then
        g_Game.SpriteManager:LoadSprite(self.stageConfig:BranchResultsIcon(2), self.imgReward_2)
    else
        self.imgReward_2:SetVisible(false)
    end
    if self.stageConfig:BranchResultDescLength() > 1 then
        self.rewardTips_2 = self.stageConfig:BranchResultDesc(2)
    end
    self.goWin_2:SetActive(false)
    self.goLose_2:SetActive(false)
end

function EarthRevivalMapComponent:BranchCompare()
    self.imgSlider_1.color = UIHelper.TryParseHtmlString(WorldTrendDefine.EarthRevivalMap_ProcessingSliderColor)
    self.imgSlider_2.color = UIHelper.TryParseHtmlString(WorldTrendDefine.EarthRevivalMap_ProcessingSliderColor)
    self.statusReward_1:ApplyStatusRecord(0)
    self.statusReward_2:ApplyStatusRecord(0)
    --未结束
    if self.branchProgress_1 < 1 and self.branchProgress_2 < 1 then
        return
    end
    local isBranch_1_Win = self.branchProgress_1 >= 1
    local isBranch_2_Win = self.branchProgress_2 >= 1
    self.goWin_1:SetActive(isBranch_1_Win)
    self.goLose_1:SetActive(not isBranch_1_Win)
    self.goWin_2:SetActive(isBranch_2_Win)
    self.goLose_2:SetActive(not isBranch_2_Win)
end

function EarthRevivalMapComponent:OnClickShowBuff()
    local attrAddonConfigInfo = ConfigRefer.WorldStageAttrAddon:Find(ModuleRefer.WorldTrendModule:GetCurSeasonAttrAddonID())
    if not attrAddonConfigInfo then
        return
    end
    local percentLength = attrAddonConfigInfo:PercentsLength()
    local attrLength = attrAddonConfigInfo:AddonLength()
    if percentLength ~= attrLength then
        g_Logger.Error("Table WorldStageAttrAddon percentLength ~= attrLength!")
        return
    end
    ---@type CommonTipsInfoMediatorParameter
    local param = {}
    param.clickTransform = self.btnBuff:GetComponent(typeof(CS.UnityEngine.RectTransform))
    param.title = I18N.Get("WorldStage_renleijiacheng")
    param.contentList = {}
    for i = 1, percentLength do
        ---@type CommonTipsInfoContentCellParam
        local percent = attrAddonConfigInfo:Percents(i)
        local cellParam = {}
        cellParam.content = string.format("%d%%", percent)
        cellParam.num = ModuleRefer.EarthRevivalModule:GetAttrStr(attrAddonConfigInfo:Addon(i))
        if self.progressNum < percent then
            cellParam.state = CommonTipsInfoDefine.ContentCellState.Lock
        elseif self.progressNum == percent then
            cellParam.state = CommonTipsInfoDefine.ContentCellState.Now
        else
            if self.progressNum > percent and self.progressNum < attrAddonConfigInfo:Percents(i + 1)  then
                cellParam.state = CommonTipsInfoDefine.ContentCellState.Now
            else
                cellParam.state = CommonTipsInfoDefine.ContentCellState.Unlock
            end
        end
        table.insert(param.contentList, cellParam)
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonTipsInfoMediator, param)
end

function EarthRevivalMapComponent:OnClickShowContribution()
    local configInfo = ModuleRefer.WorldTrendModule:GetCurSeasonConfigInfo()
    if not configInfo then
        return
    end
    ---@type CommonLeaderboardPopupMediatorParam
    local data = {}
    data.leaderboardDatas = {
        {
            cfgIds = { configInfo:PlayerLeaderboardReward(), configInfo:AllianceLeaderboardReward() },
        },
    }
    data.leaderboardTitles = { 'worldstage_geren', 'worldstage_lianmeng' }
    data.rewardsTitles = { 'worldstage_geren', 'worldstage_lianmeng' }
    data.rewardsTitleHint = I18N.Get('worldstage_phfj')
    data.title = "worldstage_jfph"
    data.style = CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_BOARD |
    CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_REWARD |
    CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_CONTRIBUTION
    g_Game.UIManager:Open(UIMediatorNames.CommonLeaderboardPopupMediator, data)
end

function EarthRevivalMapComponent:OnClickMap(param,eventData)
    local uiPos = UIHelper.ScreenPos2UIPos(eventData.position)
    if self.maxMapMode then
        uiPos.x = uiPos.x + self.mapOffsetX
        uiPos.y = uiPos.y + self.mapOffsetY
    end
    local coordX = self:CalcMapCoordX(uiPos.x)
    local coordY = self:CalcMapCoordY(uiPos.y)
    if coordX >= 0 and coordY >= 0 then
        local districtID = ModuleRefer.TerritoryModule:GetDistrictAt(math.floor(coordX), math.floor(coordY))
        if districtID > 0 then
            local ringID = ModuleRefer.EarthRevivalModule:GetMapRingID(districtID)
            self:OnSelectMapRing(ringID)
        end
    end
end

function EarthRevivalMapComponent:OnClick1x()
    if not self.maxMapMode then
        return
    end
    self.mapOffsetX = 0
    self.mapOffsetY = 0
    self.rectNodeMap.localPosition = Vector3.zero
    self.rectNodeMap.localScale = Vector3.one
    self.rectDetailMap.localPosition = Vector3.zero
    self.rectDetailMap.localScale = Vector3.one
    self.goSelect1x:SetActive(true)
    self.goSelect2x:SetActive(false)
    self.maxMapMode = false
end

function EarthRevivalMapComponent:OnClick2x()
    if self.maxMapMode then
        return
    end
    local districtId = ModuleRefer.PlayerModule:GetBornDistrictId()
    local myDistrictCenterCoord = ModuleRefer.TerritoryModule:GetDistrictCenter(districtId)
    self.mapOffsetX = self:CalcMapLocalPosX(myDistrictCenterCoord.X)
    self.mapOffsetY = self:CalcMapLocalPosY(myDistrictCenterCoord.Y)
    local localPos = self.rectNodeMap.localPosition
    self.rectNodeMap.localPosition = Vector3((localPos.x - self.mapOffsetX) * MAX_MAP_MODE_SCALE, (localPos.y - self.mapOffsetY) * MAX_MAP_MODE_SCALE, 0)
    self.rectNodeMap.localScale = Vector3(MAX_MAP_MODE_SCALE, MAX_MAP_MODE_SCALE, MAX_MAP_MODE_SCALE)
    self.rectDetailMap.localPosition = Vector3((localPos.x - self.mapOffsetX) * MAX_MAP_MODE_SCALE, (localPos.y - self.mapOffsetY) * MAX_MAP_MODE_SCALE, 0)
    self.rectDetailMap.localScale = Vector3(MAX_MAP_MODE_SCALE, MAX_MAP_MODE_SCALE, MAX_MAP_MODE_SCALE)
    self.goSelect1x:SetActive(false)
    self.goSelect2x:SetActive(true)
    self.maxMapMode = true
end

function EarthRevivalMapComponent:OnClick3x()
    --TODO
end

function EarthRevivalMapComponent:OnClickWorldTrendDetail()
    ---@type TextToastMediatorParameter
    local param = {}
    param.clickTransform = self.btnWorldTrendDetail:GetComponent(typeof(CS.UnityEngine.RectTransform))
    param.content = I18N.Get("WorldStage_zoushism")
    ModuleRefer.ToastModule:ShowTextToast(param)
end

function EarthRevivalMapComponent:OnClickAnswer_1()
    ---@type TextToastMediatorParameter
    local param = {}
    param.clickTransform = self.btnAnswer_1:GetComponent(typeof(CS.UnityEngine.RectTransform))
    param.content = ModuleRefer.WorldTrendModule:GetKingdomTaskScheduleContent(self.branchTaskID_1)
    ModuleRefer.ToastModule:ShowTextToast(param)
end

function EarthRevivalMapComponent:OnClickAnswer_2()
    ---@type TextToastMediatorParameter
    local param = {}
    param.clickTransform = self.btnAnswer_2:GetComponent(typeof(CS.UnityEngine.RectTransform))
    param.content = ModuleRefer.WorldTrendModule:GetKingdomTaskScheduleContent(self.branchTaskID_2)
    ModuleRefer.ToastModule:ShowTextToast(param)
end

function EarthRevivalMapComponent:OnClickRewardIcon_1()
    ---@type TextToastMediatorParameter
    local param = {}
    param.clickTransform = self.btnReward_1:GetComponent(typeof(CS.UnityEngine.RectTransform))
    param.content = self.rewardTips_1
    ModuleRefer.ToastModule:ShowTextToast(param)
end

function EarthRevivalMapComponent:OnClickRewardIcon_2()
    ---@type TextToastMediatorParameter
    local param = {}
    param.clickTransform = self.btnReward_2:GetComponent(typeof(CS.UnityEngine.RectTransform))
    param.content = self.rewardTips_2
    ModuleRefer.ToastModule:ShowTextToast(param)
end

function EarthRevivalMapComponent:TickSecond()
    self:UpdateStageRemainTime()
end

function EarthRevivalMapComponent:CalcMapCoordX(posX)
    --将uiposX转换为改根节点下的localposX
    local localPosX = posX - self.rectMapRoot.localPosition.x
    local mapWidth = self.rectNodeMap.rect.width
    --大地图左下角为(0, 0)点
    local zeroCoordLocalPosX = -mapWidth / 2
    local mapSystem = KingdomMapUtils.GetMapSystem()
    if mapSystem == nil then
        return -1
    end
    local maxCoordX = mapSystem.StaticMapData.TilesPerMapX
    return (localPosX - zeroCoordLocalPosX) / mapWidth * maxCoordX
end

function EarthRevivalMapComponent:CalcMapLocalPosX(coordX)
    local mapWidth = self.rectNodeMap.rect.width
    local mapSystem = KingdomMapUtils.GetMapSystem()
    if mapSystem == nil then
        return -1
    end
    local maxCoordX = mapSystem.StaticMapData.TilesPerMapX
    local zeroCoordLocalPosX = -mapWidth / 2
    return coordX / maxCoordX * mapWidth + zeroCoordLocalPosX
end

function EarthRevivalMapComponent:CalcMapCoordY(posY)
    local localPosY = posY - self.rectMapRoot.localPosition.y
    local mapHeight = self.rectNodeMap.rect.height
    local zeroCoordLocalPosY = -mapHeight / 2
    local mapSystem = KingdomMapUtils.GetMapSystem()
    if mapSystem == nil then
        return -1
    end
    local maxCoordY = mapSystem.StaticMapData.TilesPerMapZ
    return (localPosY - zeroCoordLocalPosY) / mapHeight * maxCoordY
end

function EarthRevivalMapComponent:CalcMapLocalPosY(coordY)
    local mapHeight = self.rectNodeMap.rect.height
    local mapSystem = KingdomMapUtils.GetMapSystem()
    if mapSystem == nil then
        return -1
    end
    local maxCoordY = mapSystem.StaticMapData.TilesPerMapZ
    local zeroCoordLocalPosY = -mapHeight / 2
    return coordY / maxCoordY * mapHeight + zeroCoordLocalPosY
end

function EarthRevivalMapComponent:OnSelectMapRing(ringID)
    local mapGroupOpen = false
    for k, v in pairs(self.nodeDetailList) do
        if k == ringID then
            v:SetVisible(true)
            self.goMapGroup:SetActive(true)
            self.luagoMapGroup:FeedData(ringID)
            mapGroupOpen = true
        else
            v:SetVisible(false)
        end
    end
    if not mapGroupOpen then
        self.goMapGroup:SetActive(false)
        self:ResetMaterial()
    else
        self:UpdateMaterial(ringID)
    end
end

function EarthRevivalMapComponent:UpdateMaterial(ringID)
    for k, v in pairs(self.nodeMapList) do
        local material = v.material
        if not material then
            goto continue
        end
        if k == ringID then
            material:SetFloat("_choose_toggle", 1)
            material:EnableKeyword("_CHOOSE")
        else
            material:SetFloat("_choose_toggle", 0)
            material:DisableKeyword("_CHOOSE")
        end
        ::continue::
    end

    for k, v in pairs(self.nodeDetailList) do
        local material = v.material
        if not material then
            goto continue
        end
        if k == ringID then
            material:SetFloat("_breath_toggle", 1)
            material:EnableKeyword("_BREATH")
        else
            material:SetFloat("_breath_toggle", 0)
            material:DisableKeyword("_BREATH")
        end
        ::continue::
    end
end

function EarthRevivalMapComponent:ResetMaterial()
    for k, v in pairs(self.nodeMapList) do
        local material = v.material
        if not material then
            goto continue
        end
        material:SetFloat("_choose_toggle", 0)
        material:DisableKeyword("_CHOOSE")
        ::continue::
    end

    for k, v in pairs(self.nodeDetailList) do
        v:SetVisible(false)
        local material = v.material
        if not material then
            goto continue
        end
        material:SetFloat("_breath_toggle", 0)
        material:DisableKeyword("_BREATH")
        ::continue::
    end
    self.goMapGroup:SetActive(false)
end

return EarthRevivalMapComponent