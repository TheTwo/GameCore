local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local KingdomMapUtils = require('KingdomMapUtils')
local UIMediatorNames = require('UIMediatorNames')
local KingdomTouchInfoFactory = require('KingdomTouchInfoFactory')
local KingdomTouchInfoCompHelper = require('KingdomTouchInfoCompHelper')
local KingdomTouchInfoHelper = require('KingdomTouchInfoHelper')
local ConfigRefer = require('ConfigRefer')
local TouchMenuBasicInfoDatum = require('TouchMenuBasicInfoDatum')
local I18N = require('I18N')
local TouchMenuCellPairDatum = require('TouchMenuCellPairDatum')
local NumberFormatter = require('NumberFormatter')
local CityConst = require('CityConst')
local TouchMenuHelper = require('TouchMenuHelper')
local EventConst = require('EventConst')
local TouchMenuButtonTipsData = require("TouchMenuButtonTipsData")
local TMCellSeMonsterDatum = require("TMCellSeMonsterDatum")
local TouchMenuCellSeMonsterDatum = require("TouchMenuCellSeMonsterDatum")
local TouchMenuMainBtnDatum = require("TouchMenuMainBtnDatum")
local ArtResourceUtils = require('ArtResourceUtils')
local TouchMenuBasicInfoDatumSe = require('TouchMenuBasicInfoDatumSe')
local KingdomInteractionDefine = require("KingdomInteractionDefine")
local TileHighLightMap = require("TileHighLightMap")
local ObjectType = require("ObjectType")
local TimerUtility = require("TimerUtility")
local SlgTouchMenuInfoFactory = require('SlgTouchMenuInfoFactory')
local TouchMenuUIMediator = require("TouchMenuUIMediator")
---@class PvETileAsseRadarBubbleBehavior
local PvETileAsseRadarBubbleBehavior = class("PvETileAsseRadarBubbleBehavior")

local QualityBubbleSprites = {"sp_city_bubble_base_green", "sp_city_bubble_base_blue", "sp_city_bubble_base_purple", "sp_city_bubble_base_orange"}

local QualityFrameSprites = {"sp_city_bubble_base_green", "sp_city_bubble_base_blue", "sp_city_bubble_base_purple", "sp_city_bubble_base_orange"}

local QualityLightSprites = {"sp_radar_img_light_01", "sp_radar_img_light_02", "sp_radar_img_light_03", "sp_radar_img_light_04"}

function PvETileAsseRadarBubbleBehavior:Awake()

end

function PvETileAsseRadarBubbleBehavior:OnEnable()
    if self.facingCamera then
        self.facingCamera.FacingCamera = KingdomMapUtils.GetBasicCamera().mainCamera
        self.vxTrigger = self.facingCamera.transform:Find("Trigger"):GetComponent(typeof(CS.FpAnimation.FpAnimationCommonTrigger))
    end
    local kingdomInteraction = ModuleRefer.KingdomInteractionModule
    if kingdomInteraction then
        kingdomInteraction:AddOnClick(Delegate.GetOrCreate(self, self.DoOnClick), KingdomInteractionDefine.InteractionPriority.RadarBubble)
    end
end

function PvETileAsseRadarBubbleBehavior:OnDisable()
    local kingdomInteraction = ModuleRefer.KingdomInteractionModule
    if kingdomInteraction then
        kingdomInteraction:RemoveOnClick(Delegate.GetOrCreate(self, self.DoOnClick))
    end
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

function PvETileAsseRadarBubbleBehavior:InitEvent(bubbleType, customData)
    self.bubbleType = bubbleType
    self.customData = customData
    -- if self.customData and self.customData.lv then
    --     self:SetLvText(self.customData.lv)
    -- end
    -- if self.customData and self.customData.isMainCity then
    --     self.goFrame:SetActive(false)
    -- else
    --     self.goFrame:SetActive(true)
    -- end
    if self.vxTrigger then
        self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
end

function PvETileAsseRadarBubbleBehavior:SetLvText(lv)
    self.goLv:SetActive(true)
    self.lvText.text = lv
end

function PvETileAsseRadarBubbleBehavior:SetRemainTime(time)
    if not self.goTime.activeSelf then
        self.goTime:SetActive(true)
    end
    self.timeText.text = time
end

function PvETileAsseRadarBubbleBehavior:ShowBubble(isShow)
    self.goBubble:SetActive(isShow)
end

function PvETileAsseRadarBubbleBehavior:ShowLodIcon(isShow)
    self.goLodIcon:SetActive(isShow)
end

function PvETileAsseRadarBubbleBehavior:SetBubbleBase(spriteName)
    if not string.IsNullOrEmpty(spriteName) then
        g_Game.SpriteManager:LoadSpriteAsync(spriteName, self.imgBaseBubble)
    end
end

function PvETileAsseRadarBubbleBehavior:SetBubbleFrameCyst(spriteName)
    if not string.IsNullOrEmpty(spriteName) then
        g_Game.SpriteManager:LoadSpriteAsync(spriteName, self.imgFrameCystBubble)
    else
        self.imgFrameCystBubble:SetVisible(false)
    end
end

function PvETileAsseRadarBubbleBehavior:SetBubbleIcon(spriteName)
    if not string.IsNullOrEmpty(spriteName) then
        g_Game.SpriteManager:LoadSpriteAsync(spriteName, self.imgIconBubble)
    end
end

function PvETileAsseRadarBubbleBehavior:SetFrameActive(active)
    self.imgBaseBubble:SetVisible(active)
    self.imgFrameCystBubble:SetVisible(false)
end

function PvETileAsseRadarBubbleBehavior:SetLodFrameActive(active)
    self.imgFrameLodIcon:SetVisible(active)
end

function PvETileAsseRadarBubbleBehavior:SetLodFrame(spriteName)
    if not string.IsNullOrEmpty(spriteName) then
        g_Game.SpriteManager:LoadSpriteAsync(spriteName, self.imgFrameLodIcon)
    end
end

function PvETileAsseRadarBubbleBehavior:SetLodIcon(spriteName)
    if not string.IsNullOrEmpty(spriteName) then
        g_Game.SpriteManager:LoadSpriteAsync(spriteName, self.imgIconLodIcon)
    end
end

function PvETileAsseRadarBubbleBehavior:SetPetRewardActive(active)
    self.goGroupPetReward:SetActive(active)
end

function PvETileAsseRadarBubbleBehavior:SetPetRewardIcon(spriteName)
    if not string.IsNullOrEmpty(spriteName) then
        g_Game.SpriteManager:LoadSpriteAsync(spriteName, self.imgGroupPetReward)
    end
end

function PvETileAsseRadarBubbleBehavior:SetCitizenTaskActive(active)
    self.imgCitizenTaskIcon:SetVisible(active)
end

function PvETileAsseRadarBubbleBehavior:SetCitizenTaskIcon(spriteName)
    if not string.IsNullOrEmpty(spriteName) then
        g_Game.SpriteManager:LoadSpriteAsync(spriteName, self.imgCitizenTaskIcon)
    end
end

function PvETileAsseRadarBubbleBehavior:SetYOffset(offset)
    if self.facingCamera then
        self.facingCamera.yOffset = offset
    end
end

function PvETileAsseRadarBubbleBehavior:SetQuality(quality)
    if quality then
        self.imgFrameCystBubble:SetVisible(false)
        quality = math.clamp(quality, 0, #QualityLightSprites - 1)

        -- local lightSprite = QualityLightSprites[quality + 1]
        -- if not string.IsNullOrEmpty(lightSprite) then
        --     g_Game.SpriteManager:LoadSprite(lightSprite, self.imgFrameCystBubble)
        -- else
        --     self.imgFrameCystBubble:SetVisible(false)
        -- end

        local bubbleSprite = QualityBubbleSprites[quality + 1]
        if not string.IsNullOrEmpty(bubbleSprite) then
            g_Game.SpriteManager:LoadSpriteAsync(bubbleSprite, self.imgBaseBubble)
        end

        local frameSprite = QualityFrameSprites[quality + 1]
        if not string.IsNullOrEmpty(frameSprite) then
            g_Game.SpriteManager:LoadSpriteAsync(frameSprite, self.imgFrameLodIcon)
        end
    else
        self.imgFrameCystBubble:SetVisible(false)
    end
end

function PvETileAsseRadarBubbleBehavior:RefreshAll()
    self.imgIconBubble:UpdateImmediate()
    self.imgIconLodIcon:UpdateImmediate()
    self.imgFrameLodIcon:UpdateImmediate()
    self.imgBaseBubble:UpdateImmediate()
    self.imgFrameCystBubble:UpdateImmediate()
end

function PvETileAsseRadarBubbleBehavior:GetFacingCamera()
    if self.facingCamera then
        return self.facingCamera.FacingCamera
    end
    return nil
end

function PvETileAsseRadarBubbleBehavior:DoOnClick(trans)
    if trans and #trans > 0 then
        for _, t in ipairs(trans) do
            if t == self.colliderTrans then
                if self.customData and self.customData.isMainCity then
                    local castle = ModuleRefer.PlayerModule:GetCastle()
                    local name = castle.Owner.PlayerName.String
                    local level = ModuleRefer.PlayerModule:StrongholdLevel()
                    local x = castle.MapBasics.BuildingPos.X
                    local y = castle.MapBasics.BuildingPos.Y
                    local touchData = KingdomTouchInfoFactory.CreateEntityHighLod(x, y, name, level)
                    local callback = function()
                        g_Game.EventManager:TriggerEvent(EventConst.RADAR_HIDE_CLOSE_CAMERA)
                        g_Game.UIManager:CloseAllByName(UIMediatorNames.RadarMediator)
                        KingdomMapUtils.FocusCamera(self.customData.worldPos, true)
                    end
                    touchData.pages[1].buttonGroupData[1].data[1]:SetOnClick(callback)
                    ModuleRefer.KingdomTouchInfoModule:Hide()
                    ModuleRefer.KingdomTouchInfoModule:Show(touchData)
                    return true
                end
                if self.customData and self.customData.isRadarTaskBubble then
                    if self.customData.type == ObjectType.SeEnter then
                        local scene = KingdomMapUtils.GetKingdomScene()
                        local tile = KingdomMapUtils.RetrieveMap(self.customData.X, self.customData.Y)
                        KingdomTouchInfoFactory.CreateDataFromKingdom(tile, scene:GetLod())

                        TileHighLightMap.ShowTileHighlight(tile)
                        g_Game.EventManager:TriggerEvent(EventConst.MAP_SELECT_BUILDING, tile.entity)
                    elseif self.customData.type == ObjectType.SlgInteractor then
                        local scene = KingdomMapUtils.GetKingdomScene()
                        local tile = KingdomMapUtils.RetrieveMap(self.customData.X, self.customData.Y)
                        KingdomTouchInfoFactory.CreateDataFromKingdom(tile, scene:GetLod())

                        TileHighLightMap.ShowTileHighlight(tile)
                        g_Game.EventManager:TriggerEvent(EventConst.MAP_SELECT_BUILDING, tile.entity)
                    elseif self.customData.type == ObjectType.SlgCatchPet then
                        local objectData = self.customData.objectData
                        if objectData then
                            ModuleRefer.PetModule:TryOpenCatchMenu(objectData)
                        end
                    elseif self.customData.type == ObjectType.SlgMob then
                        local ctrl = ModuleRefer.SlgModule:GetTroopCtrl(self.customData.ctrl)
                        if ctrl then
                            ctrl._module:SelectAndOpenTroopMenu(ctrl)
                        end
                    elseif self.customData.type == ObjectType.SlgRtBox then
                        local data = self.customData.data
                        if data then
                            ModuleRefer.WorldRewardInteractorModule:ShowMenu(data)
                        end
                    elseif self.customData.type == ObjectType.SlgCreepTumor then
                        local data = self.customData.data
                        if data then
                            ModuleRefer.MapCreepModule:StartSweepClean(data)
                        end
                    elseif self.customData.type == ObjectType.SlgVillage then
                        local scene = KingdomMapUtils.GetKingdomScene()
                        local tile = KingdomMapUtils.RetrieveMap(self.customData.X, self.customData.Y)
                        KingdomTouchInfoFactory.CreateVillage(tile, scene:GetLod())
                    elseif self.customData.type == ObjectType.BehemothCage then
                        local mob = ModuleRefer.SlgModule:GetBehemothMobByCage(self.customData.entity.ID)
                        local ctrl = ModuleRefer.SlgModule:GetTroopCtrl(mob.ID)
                        ctrl._data = mob
                        local menuParam = SlgTouchMenuInfoFactory.CreateBehemothTouchMenuParam(ctrl, ModuleRefer.SlgModule.troopManager:CalcTroopRadius(ctrl._data))
                        TouchMenuUIMediator.OpenSingleton(menuParam)
                    end

                    self:CheckInMist()
                    return true
                end
                local camerMoveCallBack
                if self.customData and self.customData.tile then
                    camerMoveCallBack = function()
                        if KingdomMapUtils.IsMapState() and self.customData.tile then
                            local tile = self.customData.tile
                            local size = ConfigRefer.ConstMain:ChooseCameraDistance()
                            local lod = KingdomMapUtils.GetCameraLodData():CalculateLod(size)
                            g_Game.EventManager:TriggerEvent(EventConst.WAIT_AND_SHOW_UNIT, tile.X, tile.Z, lod)
                        end
                    end
                else
                    camerMoveCallBack = function()
                    end
                end
                local callBack = function()
                    g_Game.EventManager:TriggerEvent(EventConst.RADAR_HIDE_CLOSE_CAMERA)
                    g_Game.UIManager:CloseAllByName(UIMediatorNames.RadarMediator)
                    self.basicCamera = KingdomMapUtils.GetBasicCamera()
                    local size = ConfigRefer.ConstMain:ChooseCameraDistance()
                    if self.customData and self.customData.worldPos then
                        if self.customData.inCity then
                            self.basicCamera:ZoomToWithFocus(CityConst.CITY_NEAR_CAMERA_SIZE, CS.UnityEngine.Vector3(0.5, 0.5), self.customData.worldPos, CityConst.CITY_UI_CAMERA_FOCUS_TIME)
                        else
                            self.basicCamera:ZoomToWithFocus(size, CS.UnityEngine.Vector3(0.5, 0.5), self.customData.worldPos, 0.3, camerMoveCallBack)
                        end
                    else
                        self.basicCamera:ZoomTo(size, 0.2)
                    end
                end
                local scene = KingdomMapUtils.GetKingdomScene()
                local lod = scene:GetLod()
                if self.bubbleType == wrpc.RadarEntityType.RadarEntityType_Creep then
                    local singleInfo = self.customData.singleInfo
                    local tile = KingdomMapUtils.RetrieveMap(singleInfo.X, singleInfo.Y)
                    KingdomTouchInfoFactory.CreateDataFromKingdom(tile, lod)
                    return true
                elseif self.bubbleType == wrpc.RadarEntityType.RadarEntityType_ResourceField then
                    local singleInfo = self.customData.singleInfo
                    local cfg = ConfigRefer.FixedMapBuilding:Find(singleInfo.CfgId)
                    local name = I18N.Get(cfg:Name())
                    local level = cfg:Level()
                    local coord = KingdomMapUtils.CoordToXYString(singleInfo.X, singleInfo.Y)
                    local mainWindow = TouchMenuBasicInfoDatum.new(name, nil, coord, level)
                    local outputItem = ConfigRefer.Item:Find(cfg:OutputResourceItem())
                    local ret = {}
                    local outputPair = TouchMenuCellPairDatum.new(I18N.Get("ziyuandi_chanliang"), ("+%d/h"):format(cfg:OutputResourceCount() * 3600 / cfg:OutputResourceInterval()), outputItem:Icon())
                    table.insert(ret, outputPair)
                    local recommendPower = 0
                    for i = 1, cfg:InitTroopsLength() do
                        local monsterId = cfg:InitTroops(i)
                        local monsterCfg = ConfigRefer.KmonsterData:Find(monsterId)
                        recommendPower = recommendPower + monsterCfg:RecommendPower()
                    end
                    table.insert(ret, TouchMenuCellPairDatum.new(I18N.Get("world_tjbl"), NumberFormatter.Normal(recommendPower), "sp_comp_icon_help_build"))
                    local buttons = {}
                    table.insert(buttons, KingdomTouchInfoCompHelper.GenerateButtonCompData(callBack, nil, KingdomTouchInfoFactory.ButtonIcons.IconStrength, I18N.Get("setips_btn_go"),
                                                                                            KingdomTouchInfoFactory.ButtonBacks.NegativeBack))
                    local position = KingdomTouchInfoHelper.GetWorldPosition(singleInfo.X, singleInfo.Y)
                    local data = TouchMenuHelper.GetSinglePageUIDatum(mainWindow, ret, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons)):SetPos(position):SetClickEmptyClose(true)
                    ModuleRefer.KingdomTouchInfoModule:Show(data)
                    return true
                elseif self.bubbleType == wrpc.RadarEntityType.RadarEntityType_Pet then
                    local petWildId = self.customData.data.ConfigId
                    local tid = ModuleRefer.PetModule:GetSeMapIdByPetWildId(petWildId)
                    local mapCfg = ConfigRefer.MapInstance:Find(tid)
                    local basicInfo = TouchMenuBasicInfoDatumSe.new()
                    basicInfo:SetImage(ArtResourceUtils.GetUIItem(mapCfg:HeadPic()))
                    basicInfo:SetName(I18N.Get(mapCfg:Name()))
                    basicInfo:SetDesc(I18N.Get(mapCfg:Desc()))
                    basicInfo:SetDetailClick(function()
                        g_Game.EventManager:TriggerEvent(EventConst.TOUCH_MENU_SHOW_OVERLAP_DETAIL_PAENL, I18N.Get(mapCfg:Desc()))
                    end)
                    local uiPages = {}
                    local monsterInfoPage = TouchMenuCellSeMonsterDatum.new()
                    monsterInfoPage:SetTitle(I18N.Get("setips_title_monster"))
                    for i = 1, mapCfg:SeNpcConfLength() do
                        local seNpcCfg = ConfigRefer.SeNpc:Find(mapCfg:SeNpcConf(i))
                        if (seNpcCfg) then
                            local monsterData = TMCellSeMonsterDatum.new()
                            monsterData:SetIconId(seNpcCfg:MonsterInfoIcon())
                            monsterInfoPage:AppendMonsterDatum(monsterData)
                        end
                    end
                    monsterInfoPage:SetInfoClick(function()

                    end)
                    table.insert(uiPages, monsterInfoPage)
                    local buttonTip = TouchMenuButtonTipsData.new()
                    buttonTip:SetIcon(nil)
                    buttonTip:SetContent(I18N.GetWithParams("setips_title_ce", CS.System.String.Format("{0:#,0}", mapCfg:Power())))
                    local btn = TouchMenuMainBtnDatum.new()
                    btn.onClick = callBack
                    btn.label = I18N.Get("setips_btn_go")
                    local btnGroup = TouchMenuHelper.GetRecommendButtonGroupDataArray({btn})
                    local uiDatum = TouchMenuHelper.GetSinglePageUIDatum(basicInfo, uiPages, btnGroup, buttonTip):SetPos(self.customData.worldPos):SetClickEmptyClose(true)
                    g_Game.UIManager:Open(UIMediatorNames.TouchMenuUIMediator, uiDatum)
                    return true
                elseif self.bubbleType == ModuleRefer.RadarModule.CITY_FILTER_BUBBLE_TYPE.SE_BATTLE then
                    if self:CheckInMist() then
                        return true
                    end
                    callBack()
                    return true
                elseif self.bubbleType == ModuleRefer.RadarModule.CITY_FILTER_BUBBLE_TYPE.SE_PET then
                    if self:CheckInMist() then
                        return true
                    end
                    callBack()
                    return true
                else
                    callBack()
                    return true
                end
            end
        end
    end
end

function PvETileAsseRadarBubbleBehavior:CheckInMist()
    local isInMist = not ModuleRefer.MapFogModule:IsFogUnlocked(self.customData.X, self.customData.Y)
    if isInMist then
        self.timer = TimerUtility.DelayExecute(function()
            g_Game.EventManager:TriggerEvent(EventConst.BUBBLE_IN_MIST,self.customData)
        end, 0.2)
        return true
    end
    return false
end

return PvETileAsseRadarBubbleBehavior
