local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local PetCollectionEnum = require('PetCollectionEnum')
local UI3DViewConst = require("UI3DViewConst")
local LuaReusedComponentPool = require('LuaReusedComponentPool')
local PetGotoType = require('PetGotoType')
local KingdomMapUtils = require("KingdomMapUtils")
local HeroUIUtilities = require('HeroUIUtilities')
local ActivityTimerHolder = require("ActivityTimerHolder")
local ArtResourceUtils = require("ArtResourceUtils")
local Vector2 = CS.UnityEngine.Vector2
local Vector3 = CS.UnityEngine.Vector3
local Vector2Short = CS.DragonReborn.Vector2Short
local NativeArrayVector3 = CS.Unity.Collections.NativeArray(CS.UnityEngine.Vector3)
local DBEntityPath = require("DBEntityPath")

local PetBookMediator = class('PetBookMediator', BaseUIMediator)
function PetBookMediator:ctor()
    self._rewardList = {}
end

function PetBookMediator:OnCreate()
    self.p_table_pet = self:TableViewPro('p_table_pet')
    self.right_info = self:StatusRecordParent('right_info')
    self.p_text_research_progress = self:Text('p_text_research_progress')
    -- 未解锁
    self.p_text_lock = self:Text('p_text_lock')
    self.p_btn_goto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnClickGoto))
    self.p_text_hint = self:Text('p_text_hint')
    self.img_city = self:Image('img_city')

    -- 未获得
    self.child_card_pet_s = self:LuaObject('child_card_pet_s')
    self.p_text_find = self:Text('p_text_find')
    self.p_text_pet_name_info = self:Text('p_text_pet_name_info')
    self.p_text_pet_collect = self:Text('p_text_pet_collect')
    self.p_table_pet_collect = self:TableViewPro('p_table_pet_collect')
    self.p_text_position = self:Text('p_text_position')
    -- 已获得
    self.p_text_pet_name = self:Text('p_text_pet_name')
    self.p_text_num_buy = self:Text('p_text_num_buy')
    ---@type PetTagComponent
    self.p_group_feature = self:LuaObject('p_group_feature')
    ---@type UIHeroAssociateIconComponent
    self.child_icon_style = self:LuaObject('child_icon_style')
    ---@type UIPetWorkTypeComp
    self.p_type = self:LuaBaseComponent('p_type')
    self.p_layout_type = self:Transform('p_layout_type')
    self.pool_type_info = LuaReusedComponentPool.new(self.p_type, self.p_layout_type)
    self.p_btn_get = self:Button('p_btn_get', Delegate.GetOrCreate(self, self.ShowGetMorePanel))
    self.p_btn_report = self:Button('p_btn_report', Delegate.GetOrCreate(self, self.OnClickReport))

    self.p_text_level = self:Text('p_text_level')
    self.p_text_research_level = self:Text('p_text_research_level')
    self.p_progress_research = self:Slider('p_progress_research')
    self.p_text_research_num = self:Text('p_text_research_num', '230/230')
    ---@type BaseSkillIcon
    self.child_item_skill = self:LuaObject('child_item_skill')
    self.p_btn_detail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnClickDetail))
    self.p_text_reward = self:Text('p_text_reward')
    self.p_table_item_reward = self:TableViewPro('p_table_item_reward')
    self.p_table_task = self:TableViewPro('p_table_task')
    self.p_text_get = self:Text('p_text_get', 'btn_goto_get_animal')
    self.p_text_report = self:Text('p_text_report')
    self.p_text_type = self:Text('p_text_type')
    self.p_text_amount = self:Text('p_text_amount')
    self.child_common_btn_back = self:LuaObject('child_common_btn_back')
    self.p_battle_position = self:GameObject("p_battle_position")
    self.p_icon_position = self:Image('p_icon_position')
    -- GOTO
    self.gotoStatus = self:StatusRecordParent('p_status_way')
    self.p_btn_radar = self:Button('p_btn_radar', Delegate.GetOrCreate(self, self.OnClickGotoGetMore))
    self.p_btn_buy = self:Button('p_btn_buy', Delegate.GetOrCreate(self, self.OnClickGotoGetMore))
    self.p_btn_shop = self:Button('p_btn_shop', Delegate.GetOrCreate(self, self.OnClickGotoGetMore))
    self.p_btn_map_assembly = self:Button('p_btn_map_assembly', Delegate.GetOrCreate(self, self.OnClickGotoGetMore))
    self.p_btn_activity = self:Button('p_btn_activity', Delegate.GetOrCreate(self, self.OnClickGotoGetMore))
    self.p_text_time_activity = self:Text('p_text_time_activity')
    -- self.p_btn_map = self:Button('p_btn_map', Delegate.GetOrCreate(self, self.OnClickGotoGetMore))

    self.p_text_landform = self:Text('p_text_landform', "petguide_way_to_get01")
    self.p_text_hint_collect = self:Text('p_text_hint_collect')
    self.p_text_radar = self:Text('p_text_radar', "goto")

    self.p_text_name_gift = self:Text('p_text_name_gift', "petguide_way_to_get03")
    self.p_text_buy = self:Text('p_text_buy', "goto")
    ---@type CommonDiscountTag
    self.child_shop_discount_tag = self:LuaObject("child_shop_discount_tag")
    self.p_text_radar = self:Text('p_text_radar', "goto")

    self.p_text_shop_search = self:Text('p_text_shop_search', "petguide_way_to_get02")
    self.p_text_shop = self:Text('p_text_shop', "goto")

    self.p_text_map_assembly_search = self:Text('p_text_map_assembly_search', "petguide_way_to_get04")
    self.p_text_map_assembly = self:Text('p_text_map_assembly', "goto")
    self.p_text_activity_name = self:Text('p_text_activity_name', "petguide_way_to_get05")
    self.p_text_activity = self:Text('p_text_activity', "goto")

    self.p_img_base = self:GameObject("p_img_base")

    ---@type LandformMap
    self.child_landform_map = self:LuaObject('child_landform_map')
    self.rectLand = self:RectTransform("child_landform_map")
    self.vx_line_end = self:Transform('vx_line_end')
    self.p_line_start = self:Transform('p_line_start')

    self.p_group_reward = self:GameObject("p_group_reward")
    self:PreloadUI3DView()

    self.vx_trigger_reward = self:BindComponent("vx_trigger_reward", typeof(CS.FpAnimation.FpAnimationCommonTrigger))
    self.p_img_pet = self:Image("p_img_pet")
    self.p_img_activity = self:Image("p_img_activity")
end

function PetBookMediator:PreloadUI3DView()
    self:SetAsyncLoadFlag()
    ---@type UI3DViewerParam
    local data = {}
    data.envPath = "mdl_ui3d_background1"
    local cameraSettings = self:Get3DCameraSettings()
    g_Game.UIManager.ui3DViewManager:InitCameraTransform(cameraSettings[1])
    data.callback = function(viewer)
        self:RemoveAsyncLoadFlag()
    end
    g_Game.UIManager:SetupUI3DView(self:GetRuntimeId(), UI3DViewConst.ViewType.ModelViewer, data)
end
--- 获取3D相机参数
---@param self UIPetMediator
function PetBookMediator:Get3DCameraSettings()
    local cameraSetting = {}
    local setting = {}
    setting.fov = 3
    setting.nearCp = 25.62
    setting.farCp = 154.3
    setting.localPos = CS.UnityEngine.Vector3(-0.1, 0.57, -42)
    setting.rotation = CS.UnityEngine.Vector3(1, 0, 0)

    cameraSetting[1] = setting
    return cameraSetting
end

--- 展示3D模型
function PetBookMediator:Show3DModel(petCfg)
    if (petCfg) then
        local artConf = ConfigRefer.ArtResource:Find(petCfg:ShowModel())
        local background = ConfigRefer.ArtResource:Find(ConfigRefer.PetType:Find(self.selected):PetGuideBackground())
        if background == nil then
            g_Logger.Log("PetType.csv PetGuideBackground = nil")
            return
        end
        g_Game.UIManager:SetupUI3DModelView(self:GetRuntimeId(), artConf:Path(), background:Path(), nil, function(viewer)
            if not viewer then
                return
            end
            self.ui3dModel = viewer
            local scale = artConf:ModelScale()
            if (not scale or scale <= 0) then
                scale = 1
            end
            self.ui3dModel:SetModelScale(CS.UnityEngine.Vector3.one * scale)
            self.ui3dModel:SetLitAngle(CS.UnityEngine.Vector3(30, 322.46, 0))
            self.ui3dModel:SetModelPosition(CS.UnityEngine.Vector3(artConf:ModelPosition(1), artConf:ModelPosition(2), artConf:ModelPosition(3)))
            self.ui3dModel:InitVirtualCameraSetting(self:Get3DCameraSettings())
            self.ui3dModel:SetModelAngles(CS.UnityEngine.Vector3(artConf:ModelRotation(1), artConf:ModelRotation(2), artConf:ModelRotation(3)))
            self.ui3dModel:RefreshEnv()
        end)
    end
end

function PetBookMediator:OnOpened()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPet.PetInfos.MsgPath, Delegate.GetOrCreate(self, self.GetNewPet))

    KingdomMapUtils.SetGlobalCityMapParamsId(false)
    self:InitContent()
end

function PetBookMediator:OnClose()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPet.PetInfos.MsgPath, Delegate.GetOrCreate(self, self.GetNewPet))

    self:ReleaseTimer()
    g_Game.UIManager:CloseUI3DView(self:GetRuntimeId())
    g_Game.EventManager:TriggerEvent(EventConst.PET_UI_MAIN_REFRESH_MODEL)
    KingdomMapUtils.SetGlobalCityMapParamsId(KingdomMapUtils.IsMapState())
end
function PetBookMediator:OnShow(param)

end

function PetBookMediator:OnHide(param)
end

function PetBookMediator:InitContent()
    local curPlayerProgress = ModuleRefer.PetCollectionModule:GetCollectionRewardCurrentProgress()
    local sumProgress = ModuleRefer.PetModule:GetResearchSum()
    self.p_text_research_progress.text = I18N.Get('petguide_research_total_pt') .. curPlayerProgress .. "/" .. sumProgress
    self.child_common_btn_back:FeedData({title = I18N.Get("petguide")})
    local max = ModuleRefer.PetCollectionModule:GetPetNumByArea(1)
    local cur = ModuleRefer.PetCollectionModule:GetCurPetNumByArea(1)
    self.p_text_type.text = I18N.Get("petguide_research_total_type") .. cur .. "/" .. max
    self.p_text_amount.text = I18N.Get("petguide_research_total_num") .. ModuleRefer.PetModule:GetPetCount()
    self._petData = {}
    local pets = ModuleRefer.PetCollectionModule:GetPetsByArea(1)
    self.p_table_pet:Clear()
    for k, v in pairs(pets) do
        local data = v
        data.id = v:Id()
        data.onClick = Delegate.GetOrCreate(self, self.OnSelectPet)
        self._petData[data.id] = data
        self.p_table_pet:AppendData(v)
    end

    self:OnSelectPet(self._petData[1], true)
end

function PetBookMediator:OnSelectPet(data, isInit)
    if (not data) then
        return
    end
    if (self.selected ~= data.id or isInit) then
        self.selected = data.id
        self.p_table_pet:SetToggleSelect(self._petData[self.selected])
        self:RefreshSelectedPet(isInit)
    end
end

function PetBookMediator:RefreshSelectedPet(isInit)
    local status = ModuleRefer.PetCollectionModule:GetPetStatus(self._petData[self.selected])
    local petTypeCfg = ModuleRefer.PetModule:GetTypeCfg(self.selected)
    local petCfgId = self._petData[self.selected]:SamplePetCfg()
    local petCfg = ConfigRefer.Pet:Find(petCfgId)
    local level = ConfigRefer.PetResearch:Find(petTypeCfg:PetResearchId()):UnlockCondMainCityLevel()
    self.castleLevel = level
    local researchData = ModuleRefer.PetCollectionModule:GetResearchData(self.selected)
    local getMore = ConfigRefer.GetMore:Find(petTypeCfg:GetMoreConfig())
    local gotoType = petTypeCfg:PetGotoType()
    self.getMore = getMore
    self.gotoType = gotoType
    self.getMoreItem = petCfg:SourceItems(1)
    local petName = I18N.Get(petCfg:Name())
    local petStoryId = petTypeCfg:PetStoryId()
    local petStory = ConfigRefer.PetStory:Find(petStoryId)

    if status == PetCollectionEnum.PetStatus.Own then
        self.p_img_base:SetVisible(false)
        self.right_info:SetState(2)
        self.p_text_pet_name.text = I18N.Get(ConfigRefer.Pet:Find(petCfgId):Name())
        self.p_text_num_buy.text = ModuleRefer.PetCollectionModule:GetPetBookId(petTypeCfg:PetBookId())

        -- 战斗标签
        local petTagId = petTypeCfg:PetTagDisplay()
        if petTagId and petTagId > 0 then
            self.p_group_feature:SetVisible(true)
            self.p_group_feature:FeedData(petTagId)
        else
            self.p_group_feature:SetVisible(false)
        end

        local labelIcon = HeroUIUtilities.GetHeroBattleTypeTextureName(petCfg:BattleType())
        g_Game.SpriteManager:LoadSprite(labelIcon, self.p_icon_position)

        -- 属性标签
        local tagId = petCfg:AssociatedTagInfo()
        if tagId > 0 then
            self.child_icon_style:FeedData({tagId = tagId})
        end

        -- 工作能力
        self.pool_type_info:HideAll()
        for i = 1, petCfg:PetWorksLength() do
            local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
            local workType = petWorkCfg:Type()
            local level = petWorkCfg:Level()
            local param = {level = level, name = ModuleRefer.PetModule:GetPetWorkTypeStr(workType), icon = ModuleRefer.PetModule:GetPetWorkTypeIcon(workType)}
            local itemMain = self.pool_type_info:GetItem().Lua
            itemMain:FeedData(param)
        end

        -- 技能等级
        local dropSkill = ConfigRefer.PetSkillBase:Find(petCfg:RefSkillTemplate()):DropSkill()
        local slgSkillId = ConfigRefer.PetLearnableSkill:Find(dropSkill):SlgSkill()
        self.child_item_skill:FeedData({
            index = dropSkill,
            skillLevel = 1,
            quality = petCfg:Quality(),
            isPet = true,
            clickCallBack = function()
                g_Game.UIManager:Open(UIMediatorNames.UICommonPopupCardDetailMediator, {type = 6, cfgId = dropSkill})
            end,
        })

        -- 宠物研究
        local cfg = ModuleRefer.PetCollectionModule:GetResearchConfig(self.selected)
        local isFullLevel = false
        local level = 1
        local exp = 0
        if researchData then
            level = researchData.Level
            exp = researchData.Exp
            isFullLevel = researchData.IsFullLevel
        end
        local maxExp = ModuleRefer.PetCollectionModule:GetMaxExp(cfg, level)

        self.p_text_research_level.text = I18N.Get("petguide_research")
        self.p_text_research_num.text = exp .. "/" .. maxExp
        self.p_progress_research.value = exp / maxExp
        self.p_text_level.text = level
        self.p_table_task:Clear()
        for i = 1, cfg:TopicsLength() do
            local topic = ConfigRefer.PetResearchTopic:Find(cfg:Topics(i))
            topic.ResearchProcess = researchData and researchData.ResearchProcess[i - 1] or nil
            topic.ResearchValue = researchData and researchData.ResearchValue[i - 1] or 0
            topic.studyIndex = i
            topic.unlock = level >= topic:UnlockLevel()
            topic.unlockLevel = topic:UnlockLevel()
            topic.desc = cfg:TopicNames(i)
            topic.petCfgId = self.selected
            topic.onClick = function()
                self:ShowGetMorePanel()
            end
            self.p_table_task:AppendData(topic)
        end
        if isInit then
            self.p_table_task:SetVisible(false)
            self.p_table_task:SetVisible(true)
        end
        -- 研究奖励
        local petStoryId = petTypeCfg:PetStoryId()
        local petStory = ConfigRefer.PetStory:Find(petStoryId)
        -- local needLevel = petStory:UnlockInfo(level):NeedLevel()
        local curResearchLevel = researchData and researchData.Level or 0
        local index = 1
        for k, v in pairs(researchData.StoryUnlock) do
            if v then
                index = index + 1
            end
        end
        if index > petStory:UnlockInfoLength() then
            index = petStory:UnlockInfoLength()
            self.p_group_reward:SetVisible(false)
        else
            self.p_group_reward:SetVisible(true)
        end
        self.storyUnlockIndex = index
        local reward = petStory:UnlockInfo(self.storyUnlockIndex):Reward()
        local itemGroup = ConfigRefer.ItemGroup:Find(reward)
        self.rewards = {}

        -- 零级奖励为获得宠物奖励
        if self.storyUnlockIndex == 1 then
            self.p_text_reward.text = I18N.GetWithParams("petguide_task_desc01", petName)
        else
            self.p_text_reward.text = I18N.GetWithParams("petguide_research_claimreward_preview", self.storyUnlockIndex - 1)
        end
        self.p_table_item_reward:Clear()
        local canClaim = false
        for j = 1, itemGroup:ItemGroupInfoListLength() do
            local itemGroupInfo = itemGroup:ItemGroupInfoList(j)
            ---@type ItemIconData
            local iconData = {configCell = ConfigRefer.Item:Find(itemGroupInfo:Items()), showCount = true, count = itemGroupInfo:Nums()}

            if curResearchLevel >= self.storyUnlockIndex then
                canClaim = true
                iconData.claimable = true
                iconData.onClick = Delegate.GetOrCreate(self, self.OnClickClaimReward)
            end

            table.insert(self.rewards, {id = iconData.configCell:Id(), count = iconData.count})
            self.p_table_item_reward:AppendData(iconData)
        end

        if canClaim then
            self.vx_trigger_reward:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        else
            self.vx_trigger_reward:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
        end

        -- 报告数量
        local storyMax = petStory:UnlockInfoLength() - 1
        self.p_text_report.text = I18N.Get("petguide_btn_report") .. (curResearchLevel - 1) .. "/" .. storyMax
        -- I18N.GetWithParams("#报告 {1}", curResearchLevel .. "/" .. storyMax)

        self:Show3DModel(petCfg)
        self:HideLineRenderer()
    elseif status == PetCollectionEnum.PetStatus.NotOwn then
        self.p_img_base:SetVisible(true)
        self.right_info:SetState(1)
        g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(petTypeCfg:ShowPortrait()), self.p_img_pet)
        g_Game.UIManager:CloseUI3DView(self:GetRuntimeId())

        self.child_card_pet_s:FeedData({cfgId = petCfgId})
        self.p_text_pet_name_info.text = petName
        self.p_text_find.text = I18N.Get("petguide_new_discover")
        -- self.p_text_find.text = I18N.Get("petguide_discover", petName)
        self.p_text_pet_collect.text = I18N.GetWithParams('petguide_task_desc01', petName)

        local petStoryId = petTypeCfg:PetStoryId()
        local petStory = ConfigRefer.PetStory:Find(petStoryId)
        local reward = petStory:UnlockInfo(1):Reward()
        local itemGroup = ConfigRefer.ItemGroup:Find(reward)
        -- local itemGroupInfo = itemGroup:ItemGroupInfoList(1)
        ---@type ItemIconData
        -- local iconData = {configCell = ConfigRefer.Item:Find(itemGroupInfo:Items()), showCount = true, count = itemGroupInfo:Nums()}
        self.p_table_pet_collect:Clear()
        for j = 1, itemGroup:ItemGroupInfoListLength() do
            local itemGroupInfo = itemGroup:ItemGroupInfoList(j)
            ---@type ItemIconData
            local iconData = {configCell = ConfigRefer.Item:Find(itemGroupInfo:Items()), showCount = true, count = itemGroupInfo:Nums()}
            self.p_table_pet_collect:AppendData(iconData)
        end

        if gotoType == PetGotoType.Land then
            self.gotoStatus:SetState(0)
            local landId = petCfg:PetTrackLandId()
            self.landId = landId
            g_Logger.Error("self.landId , " .. landId)

            local lastUnlockLandId = ModuleRefer.LandformModule:GetLastPlayerUnlockLandFormId()

            if landId > 0 then
                self.p_text_position.text = I18N.Get(ConfigRefer.Land:Find(landId):Name())
                local isLandUnlocked, tips = ModuleRefer.LandformModule:GetLandformOpenHint(landId, true)
                if isLandUnlocked then
                    self.p_text_hint_collect:SetVisible(false)
                else
                    self.p_text_hint_collect:SetVisible(true)
                    self.p_text_hint_collect.text = I18N.GetWithParams("petguide_time_tip", tips)
                end
                self:RefreshRadiusMap(lastUnlockLandId)
            else
                self:HideLineRenderer()
                self.p_text_position.text = I18N.Get("unknown_zone")
                self.p_text_hint_collect:SetVisible(false)
            end

        elseif gotoType == PetGotoType.Pay then
            self.gotoStatus:SetState(1)
            self.getMoreId = getMore:RefPayGoods(1)
            if self.getMoreId == 0 then
                g_Logger.Error("getMore:RefPayGoods(1) = 0")
            end
            local price, priceType = ModuleRefer.ActivityShopModule:GetGoodsPrice(self.getMoreId)
            self.p_text_buy.text = string.format('%s %.2f', priceType, price)
            self.child_shop_discount_tag:FeedData(ModuleRefer.ActivityShopModule:GetDiscountTagParamByGoodId(self.getMoreId))
        elseif gotoType == PetGotoType.Shop then
            self.gotoStatus:SetState(2)

        elseif gotoType == PetGotoType.Search then
            self.gotoStatus:SetState(3)

        elseif gotoType == PetGotoType.Activity then
            self.gotoStatus:SetState(4)
            local tabId, isOpen = ModuleRefer.ActivityCenterModule:GetTabIdFromGetMoreCfg(getMore, 1)
            local tabCfg = ConfigRefer.ActivityCenterTabs:Find(tabId)
            if tabCfg then
                local icon = tabCfg:Icon()
                g_Game.SpriteManager:LoadSprite(icon, self.p_img_activity)
            end
            if isOpen then
                self:ReleaseTimer()
                local startTime, endTime = ModuleRefer.ActivityCenterModule:GetActivityTabStartEndTime(tabId)
                self.previewTimerHolder = ActivityTimerHolder.new(self.p_text_time_activity)
                self.previewTimerHolder:SetDisplayMode(ActivityTimerHolder.DisplayMode.Single)
                self.previewTimerHolder:Setup()
                self.previewTimerHolder:StartTick(endTime.Seconds)
                self.previewTimerHolder:OnTick()
            else
                self.p_text_time_activity.text = I18N.Get("alliance_behemoth_challenge_state1")
            end

        end
    elseif status == PetCollectionEnum.PetStatus.Lock then
        self.p_img_base:SetVisible(true)
        self.right_info:SetState(0)
        g_Game.UIManager:CloseUI3DView(self:GetRuntimeId())
        local furniture = ConfigRefer.CityFurnitureTypes:Find(ConfigRefer.CityConfig:MainFurnitureType())
        local name = I18N.Get(furniture:Name())
        local icon = I18N.Get(furniture:Image())
        g_Game.SpriteManager:LoadSprite(icon, self.img_city)
        self.p_text_lock.text = I18N.GetWithParams("petguide_unlock_tip01", name, level)
        self.p_text_hint.text = I18N.GetWithParams("petguide_unlock_tip02", name)
        self:HideLineRenderer()
    end
end

function PetBookMediator:ReleaseTimer()
    if self.previewTimerHolder then
        self.previewTimerHolder:Release()
        self.previewTimerHolder = nil
    end
end

function PetBookMediator:OnClickClaimReward()
    ModuleRefer.PetCollectionModule:UnlockStory(self.selected, self.storyUnlockIndex, function()
        if self.storyUnlockIndex == 1 then
            g_Game.UIManager:Open(UIMediatorNames.UIRewardMediator, {itemInfo = self.rewards})
        else
            g_Game.UIManager:Open(UIMediatorNames.PetBookStageRewardMediator, {itemInfo = self.rewards, petCfgId = self.selected, level = self.storyUnlockIndex})
        end
        self:RefreshSelectedPet()
    end)
end

function PetBookMediator:OnClickGoto()
    local scene = g_Game.SceneManager.current
    if scene:IsInCity() then
        self:CloseSelf()
        ModuleRefer.GuideModule:CallGuide(1001)
    else
        self:CloseSelf()
        scene:ReturnMyCity(function()
            ModuleRefer.GuideModule:CallGuide(1001)
        end)
    end
end

function PetBookMediator:OnClickGotoGetMore()
    local gotoType = self.gotoType
    if gotoType == PetGotoType.Land then
        ModuleRefer.FPXSDKModule:TrackCustomBILog("go_to_pet_radar")
        g_Game.UIManager:Open(UIMediatorNames.RadarMediator, {tracePetId = self.selected})
        return
    elseif gotoType == PetGotoType.Pay then
        if self.getMoreId == nil then
            g_Logger.Error("getMore:RefPayGoods()没配")
            return
        else
            local packId = ModuleRefer.ActivityShopModule:GetFirstAvaliableGoodInGroup(self.getMoreId)
            if packId == nil then
                g_Logger.Error("packId null")
                return
            end
            ModuleRefer.FPXSDKModule:TrackCustomBILog("pet_research_pay")
            ModuleRefer.ActivityShopModule:PurchaseGoods(packId, nil, true, false)
            return
        end
    elseif gotoType == PetGotoType.Activity then
        local tabId, isOpen = ModuleRefer.ActivityCenterModule:GetTabIdFromGetMoreCfg(self.getMore, 1)
        if isOpen then
            ModuleRefer.ActivityCenterModule:GotoActivity(tabId)
        else
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("worldstage_systementry_unlock"))
        end
        return
    end
    local guideCall = self.getMore:Goto(1):Goto()
    self.guideCall = guideCall

    g_Logger.Error("执行guideCall:" .. self.guideCall)
    ModuleRefer.GuideModule:CallGuide(self.guideCall)
end

function PetBookMediator:OnClickReport()
    g_Game.UIManager:Open(UIMediatorNames.PetStoryMediator, {cfgId = self.selected})
end

function PetBookMediator:ShowGetMorePanel()
    local petCfgId = self._petData[self.selected]:SamplePetCfg()
    local petCfg = ConfigRefer.Pet:Find(petCfgId)
    local workTypeCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(1))
    local workType = workTypeCfg:Type()
    ModuleRefer.InventoryModule:OpenExchangePanel({{isPet = true, id = self.getMoreItem, num = 1, petWorkType = workType, petWorkTypeLevel = workTypeCfg:Level()}})
end

function PetBookMediator:OnClickDetail()
    g_Game.UIManager:Open(UIMediatorNames.PetBookRewardDetailMediator, {cfgId = self.selected})
end

function PetBookMediator:RefreshRadiusMap(landformConfigID)
    local castle = ModuleRefer.PlayerModule:GetCastle()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local castleX, castleZ = KingdomMapUtils.ParseBuildingPos(castle.MapBasics.Position)
    local xMin, yMin, xMax, yMax, landformUVPosList = self:CalculateLandformOuterSquareAndPositions(castleX, castleZ, landformConfigID)

    ---@type LandformMapParameter
    local landMapParam = {startSelectLandformConfigID = self.landId, showMyCastle = true, rectXMin = xMin, rectYMin = yMin, rectXMax = xMax, rectYMax = yMax}
    self.child_landform_map:FeedData(landMapParam)
    -- landformUVPosList 连线
    local uiCamera = g_Game.UIManager:GetUICamera()

    local layerNum = ConfigRefer.Land:Find(self.landId):LayerNum()
    local uvPos = landformUVPosList[layerNum]

    local rect = self.rectLand.rect
    -- 正方形
    local ScaleX = self.rectLand.localScale.x
    local ScaleY = self.rectLand.localScale.y
    local width = rect.width * ScaleX
    local height = rect.height * ScaleY

    local rectOffset = uiCamera:WorldToScreenPoint(Vector3(self.rectLand.position.x, self.rectLand.position.y, 0))
    -- local rectPos = Vector2(rectOffset.x + uvPos.x * width - width / 2, rectOffset.y + uvPos.y * height - height / 2)
    local rectPos = Vector2(rectOffset.x - width / 2, rectOffset.y - height / 2)
    local uvOffset = Vector2(uvPos.x * width, uvPos.y * height)
    -- local uvOffset = Vector2(uvPos.y * width, uvPos.x * height)

    rectPos = rectPos + uvOffset
    -- Vector2(rectOffset.x - width / 2 * ScaleX, rectOffset.y - height / 2 * ScaleY)
    local endPos = uiCamera:ScreenToWorldPoint(Vector3(rectPos.x, rectPos.y, -1))
    local lines = {}
    lines[1] = Vector3(self.vx_line_end.transform.position.x, self.vx_line_end.transform.position.y, -1)
    lines[2] = endPos
    self.p_line_start.position = endPos
    self:SetLineRendererData(lines)
end

---@param maxLandformID number
---@return number, number, number, number, CS.UnityEngine.Vector2[]
function PetBookMediator:CalculateLandformOuterSquareAndPositions(castleX, castleZ, maxLandformID)
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local mapCenterX = staticMapData.TilesPerMapX / 2
    local mapCenterZ = staticMapData.TilesPerMapZ / 2
    local radius = staticMapData.TilesPerMapX / 2

    -- for test
    local offset
    if ModuleRefer.LandformModule.TestLandformEnable then
        offset = tonumber(ModuleRefer.LandformModule.TestOffset)
        maxLandformID = tonumber(ModuleRefer.LandformModule.TestLandformID)
        castleX = tonumber(ModuleRefer.LandformModule.TestCastleX)
        castleZ = tonumber(ModuleRefer.LandformModule.TestCastleZ)
    else
        offset = -0.05
    end

    -- 从地图中心往玩家的方向发射线，射线长度是半个地图size，穿过各个圈层
    ---@type CS.DragonReborn.Vector3Short[]
    local distinctLandforms = {}
    local castleDir = Vector2(castleX - mapCenterX, castleZ - mapCenterZ).normalized
    local endCoord = Vector2Short(mapCenterX, mapCenterZ)
    local startPos = Vector2(mapCenterX, mapCenterZ) + castleDir * radius
    local startCoord = Vector2Short(math.round(startPos.x), math.round(startPos.y))
    ModuleRefer.TerritoryModule:GetDistinctLandforms(startCoord, endCoord, distinctLandforms)
    local innerLandformLayer = ConfigRefer.Land:Find(maxLandformID):LayerNum()
    local innerLandformX = mapCenterX
    local innerLandformZ = mapCenterZ
    for _, landform in ipairs(distinctLandforms) do
        if landform.Z == innerLandformLayer then
            innerLandformX = landform.X
            innerLandformZ = landform.Y
            break
        end
    end

    local radian = math.atan(castleZ - mapCenterZ, castleX - mapCenterX)
    local sin = math.sin(radian)
    local cos = math.cos(radian)
    local x = castleX - mapCenterX
    local z = castleZ - mapCenterZ

    -- 中心射线与正方形的交点连线，偏移量要根据方向变化
    local outerRadius = radius
    -- up and down
    if z >= x and z >= -x or z <= x and z <= -x then
        outerRadius = outerRadius / math.abs(sin)
        offset = offset * math.abs(sin)
    elseif z < x and z > -x or z > x and z < -x then
        outerRadius = outerRadius / math.abs(cos)
        offset = offset * math.abs(cos)
    end
    innerLandformX = innerLandformX * (1 + offset * cos)
    innerLandformZ = innerLandformZ * (1 + offset * sin)

    -- 外圈交点和内圈交点，连接得到的直径形成一个圆。这个圆的外接正方形，就是缩放区域。
    local outerLandformX = outerRadius * cos + mapCenterX
    local outerLandformZ = outerRadius * sin + mapCenterZ
    g_Logger.Log(("outer pos:(%s, %s), inner pos:(%s, %s), offset:%s"):format(outerLandformX, outerLandformZ, innerLandformX, innerLandformZ, offset))
    local distX = outerLandformX - innerLandformX
    local distZ = outerLandformZ - innerLandformZ
    local extent = math.sqrt(distX * distX + distZ * distZ) * 0.5
    local centerX = (innerLandformX + outerLandformX) * 0.5
    local centerZ = (innerLandformZ + outerLandformZ) * 0.5
    local xMin = centerX - extent
    local yMin = centerZ - extent
    local xMax = centerX + extent
    local yMax = centerZ + extent

    -- 计算一个相对坐标列表。代表每个圈层的指示点。使用时要映射到地图贴图的坐标。例如(xMax - xMin) * u
    ---@type CS.UnityEngine.Vector2[]
    local landformUVPosList = {}
    for i = 1, #distinctLandforms - 1 do
        local landform = distinctLandforms[i]
        local nextLandform = distinctLandforms[i + 1]
        local x = landform.X - xMin
        local y = landform.Y - yMin
        local nextX = nextLandform.X - xMin
        local nextY = nextLandform.Y - yMin
        local position = Vector2(nextX + x, nextY + y) * 0.5 / (extent * 2)
        table.insert(landformUVPosList, position)
    end

    return xMin, yMin, xMax, yMax, landformUVPosList
end
function PetBookMediator:SetLineRendererData(linePosArray)
    self._lineRenderer = self.vx_line_end:GetComponentInChildren(typeof(CS.UnityEngine.LineRenderer))
    local c = #linePosArray
    local array = NativeArrayVector3(c, CS.Unity.Collections.Allocator.Temp)
    for i, v in pairs(linePosArray) do
        array[i - 1] = v
    end
    self._lineRenderer.positionCount = c
    self._lineRenderer:SetPositions(array)
    self._lineRenderer.startWidth = 0.05
    self._lineRenderer.endWidth = 0.05
    array:Dispose()
end

function PetBookMediator:HideLineRenderer()
    if self._lineRenderer then
        self._lineRenderer.positionCount = 0
    end
end

-- 获得新宠物时，刷新图鉴
function PetBookMediator:GetNewPet(entity, changedTable)
    if changedTable and changedTable.Add then
        self:InitContent()
        self:RefreshSelectedPet()
        return
    end
end

return PetBookMediator
