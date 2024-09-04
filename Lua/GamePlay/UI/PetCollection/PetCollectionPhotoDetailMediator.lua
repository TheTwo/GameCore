local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local TimerUtility = require('TimerUtility')
local I18N = require('I18N')
local GuideUtils = require('GuideUtils')
local ClientDataKeys = require('ClientDataKeys')
local Vector3 = CS.UnityEngine.Vector3
local UIMediatorNames = require("UIMediatorNames")
local PetCollectionEnum = require("PetCollectionEnum")
local TimeFormatter = require("TimeFormatter")
local Color = CS.UnityEngine.Color
local UIHelper = require('UIHelper')
local LuaReusedComponentPool = require('LuaReusedComponentPool')

local PetCollectionPhotoDetailMediator = class('PetCollectionPhotoDetailMediator', BaseUIMediator)
function PetCollectionPhotoDetailMediator:ctor()
end

function PetCollectionPhotoDetailMediator:OnCreate()
    self.tabs = self:TableViewPro('p_tab_table')

    -- Info Tag
    self.infoNode = self:GameObject('p_info')
    self.p_text_pet_name = self:Text('p_text_pet_name')
    self.infoNormalNode = self:GameObject('p_norm_info')

    -- self.p_text_tag_title = self:Text('p_text_tag_title')
    self.p_text_habitat_title = self:Text('p_text_habitat_title')
    self.p_text_habitat_info = self:Text('p_text_habitat_info')
    self.p_text_title_info = self:Text('p_text_title_info')

    self.infoEmptyNode = self:GameObject('p_empty')
    self.p_text_empty = self:Text('p_text_empty')
    self.btnBuy = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnClickGoto))
    self.p_text = self:Text('p_text')

    -- 掉落技能
    ---@type BaseSkillIcon
    self.emptySlgSkill1 = self:LuaObject("child_item_skill_1")
    ---@type BaseSkillIcon
    self.emptySlgSkill2 = self:LuaObject("child_item_skill_2")

    -- Study Tag
    self.studyNode = self:GameObject('p_study')
    self.p_text_study_level = self:Text('p_text_study_level')
    self.p_btn_detail = self:Button('p_btn_detail')
    self.researchSlider = self:Slider('p_pb_level')
    self.p_text_pb = self:Text('p_text_pb')
    self.p_list_table = self:TableViewPro('p_list_table')
    self.p_buff = self:Button('p_buff', Delegate.GetOrCreate(self, self.OnClickBuff))
    self.p_complete = self:GameObject('p_complete')
    -- Story Tag
    self.storyNode = self:GameObject('p_story')
    self.p_text_title_story = self:Text('p_text_title_story')
    self.p_text_story_content = self:Text('p_text_story_content')
    self.storyContents = self:TableViewPro('p_table_story')

    self.petIcon = self:Image('p_icon_pet')
    self.petOutline = self:Image('p_icon_pet_outline')
    self.p_text_num = self:Text('p_text_num')
    self.p_tag_special = self:GameObject('p_tag_special')
    self.p_btn_sign = self:Button('p_btn_sign', Delegate.GetOrCreate(self, self.OnSign))
    self.p_text_player_name = self:Text('p_text_player_name')
    self.p_text_date = self:Text('p_text_date')
    self.p_text_sign = self:Text('p_text_sign')
    -- Bottom
    self.p_btn_left = self:Button('p_btn_left', Delegate.GetOrCreate(self, self.OnClickLeft))
    self.p_btn_right = self:Button('p_btn_right', Delegate.GetOrCreate(self, self.OnClickRight))
    self.p_text_page_num = self:Text('p_text_page_num')
    self.p_btn_close = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnClickClose))

    self.p_base_n = self:GameObject('p_base_n')
    self.p_base_gold = self:GameObject('p_base_gold')
    self.p_light_n = self:GameObject('p_light_n')
    self.p_light_gold = self:GameObject('p_light_gold')
    self.p_name = self:GameObject('p_name')

    self.backButton = self:LuaObject('child_common_btn_back')
    self.vx_trigger = self:BindComponent("trigger", typeof(CS.FpAnimation.FpAnimationCommonTrigger))

    -- 优化
    self.p_text_habitat_title_new = self:Text('p_text_habitat_title_new', I18N.Get('pet_research_habitat_name'))
    self.p_table_habitat = self:TableViewPro('p_table_habitat')
    ---@type UIHeroAssociateIconComponent
    self.child_icon_style = self:LuaObject('child_icon_style')

    ---@type UIPetWorkTypeComp
    self.p_type_main = self:LuaBaseComponent('p_type_main')
    self.p_layout_type_main = self:Transform('p_layout_type_main')
    self.pool_type_info_main = LuaReusedComponentPool.new(self.p_type_main, self.p_layout_type_main)

    -- 固定技能
    ---@type BaseSkillIcon
    self.child_item_skill = self:LuaObject("child_item_skill")
    -- 品质色
    self.p_base_quality = self:Image('p_base_quality')
end

function PetCollectionPhotoDetailMediator:OnShow(param)
    self.backButton:FeedData({title = I18N.Get("pet_handbook_name")})

    g_Game.EventManager:AddListener(EventConst.PET_COLLECTION_DETAIL_TAB, Delegate.GetOrCreate(self, self.SwitchTab))
    self:Refresh(param)
end

function PetCollectionPhotoDetailMediator:OnOpened(param)
end

function PetCollectionPhotoDetailMediator:OnClose(param)
end

function PetCollectionPhotoDetailMediator:Refresh(data, noTabAnim)
    self.areaIndex = data.areaIndex
    self.pageIndex = data.pageIndex
    self.detailTabIndex = data.detailTabIndex

    local param = ModuleRefer.PetCollectionModule:GetDetailInfo(data.pageIndex, data.areaIndex)
    self.param = param
    local icon = ConfigRefer.ArtResourceUI:Find(param:ShowPortrait()):Path()
    g_Game.SpriteManager:LoadSprite(icon, self.petIcon)
    g_Game.SpriteManager:LoadSprite(icon, self.petOutline)
    self.petIndex = param:Id()
    self.p_tag_special:SetVisible(false or param:IsVip())
    self.maxPage = ModuleRefer.PetCollectionModule:GetPetNumByArea(param.areaIndex)
    self.p_text_num.text = "NO." .. param:Id()
    self.p_text_page_num.text = param.pageIndex .. "/" .. self.maxPage
    local lock = false

    self.p_base_n:SetVisible(not param:IsVip())
    self.p_light_n:SetVisible(not param:IsVip())
    self.p_base_gold:SetVisible(param:IsVip())
    self.p_light_gold:SetVisible(param:IsVip())

    local status = ModuleRefer.PetCollectionModule:GetPetStatus(param)
    self.gotoStatus = status

    if status == PetCollectionEnum.PhotoStatusEnum.Own then
        self.p_text_pet_name.text = I18N.Get(ConfigRefer.Pet:Find(param:SamplePetCfg()):Name())
        self.btnBuy:SetVisible(false)
        self.infoNormalNode:SetVisible(true)
        self.infoEmptyNode:SetVisible(false)
        self.child_item_skill:SetVisible(true)
        self.petIcon:SetVisible(true)
        self.petOutline:SetVisible(false)
    elseif status == PetCollectionEnum.PhotoStatusEnum.Hide then
        self.p_text_pet_name.text = "???"
        self.p_text_empty.text = I18N.Get('pet_memo5')
        self.btnBuy:SetVisible(false)
        lock = true
        self.detailTabIndex = 1
        self.infoNormalNode:SetVisible(false)
        self.infoEmptyNode:SetVisible(true)
        self.child_item_skill:SetVisible(false)
        self.petIcon:SetVisible(false)
        self.petOutline:SetVisible(true)
        self.petOutline.color = Color(0, 0, 0, 1)

    elseif status == PetCollectionEnum.PhotoStatusEnum.CanBuy then
        self.p_text_pet_name.text = I18N.Get(ConfigRefer.Pet:Find(param:SamplePetCfg()):Name())
        self.p_text_empty.text = I18N.Get('pet_memo5')
        self.p_text.text = I18N.Get('skincollection_obtain')
        self.btnBuy:SetVisible(true)
        lock = true
        self.detailTabIndex = 1
        self.infoNormalNode:SetVisible(false)
        self.infoEmptyNode:SetVisible(true)
        self.child_item_skill:SetVisible(false)
        self.petIcon:SetVisible(true)
        self.petOutline:SetVisible(true)
        self.petOutline.color = Color(0, 0, 0, 0.8)
    end

    self:SwitchTab({detailTabIndex = self.detailTabIndex, lock = lock}, noTabAnim)
end

function PetCollectionPhotoDetailMediator:SwitchTab(param, noTabAnim)
    self.detailTabIndex = param.detailTabIndex
    local researchData = ModuleRefer.PetCollectionModule:GetResearchData(self.param:Id())
    local isSign = false
    local isFullLevel = false
    local level = 1
    local exp = 0
    if researchData then
        isSign = researchData.IsSignName
        level = researchData.Level
        exp = researchData.Exp
        isFullLevel = researchData.IsFullLevel
    end
    -- 三个Tab页面
    self.storyContents:Clear()
    self.p_list_table:Clear()
    self.tabs:Clear()
    -- Info
    if (self.detailTabIndex == PetCollectionEnum.TabType.Details) then
        self.infoNode:SetVisible(true)
        self.studyNode:SetVisible(false)
        self.storyNode:SetVisible(false)

        -- 宠物技能
        local petTypeCfg = ModuleRefer.PetModule:GetTypeCfg(self.petIndex)
        local samplePetCfg = ModuleRefer.PetModule:GetPetCfg(petTypeCfg:SamplePetCfg())

        self.petTypeCfg = petTypeCfg

        -- 战斗标签
        local tagId = samplePetCfg:AssociatedTagInfo()
        if tagId > 0 then
            self.child_icon_style:FeedData({tagId = tagId})
        end

        -- 工作能力
        self.pool_type_info_main:HideAll()
        for i = 1, samplePetCfg:PetWorksLength() do
            local petWorkCfg = ConfigRefer.PetWork:Find(samplePetCfg:PetWorks(i))
            local workType = petWorkCfg:Type()
            local level = petWorkCfg:Level()
            local param = {level = level, name = ModuleRefer.PetModule:GetPetWorkTypeStr(workType), icon = ModuleRefer.PetModule:GetPetWorkTypeIcon(workType)}
            local itemMain = self.pool_type_info_main:GetItem().Lua
            itemMain:FeedData(param)
        end

        self.p_text_habitat_title.text = I18N.Get("pet_research_habitat_name")
        self.p_text_habitat_info.text = I18N.Get(petTypeCfg:Story())
        self.p_text_title_info.text = I18N.Get("hero_card")

        -- 掉落技能
        local dropSkill = ConfigRefer.PetSkillBase:Find(samplePetCfg:RefSkillTemplate()):DropSkill()
        local slgSkillId = ConfigRefer.PetLearnableSkill:Find(dropSkill):SlgSkill()
        local slgSkillCell = ConfigRefer.SlgSkillInfo:Find(slgSkillId)
        self.emptySlgSkill1:FeedData({index = dropSkill, skillLevel = 1, quality = samplePetCfg:Quality(), isPet = true, clickCallBack = Delegate.GetOrCreate(self, self.OnSlgSkillClick)})

        -- 固定技能
        local skillId = samplePetCfg:SLGSkillID(2)
        slgSkillCell = ConfigRefer.SlgSkillInfo:Find(skillId)
        self.child_item_skill:FeedData({
            skillId = slgSkillCell:SkillId(),
            index = slgSkillCell:SkillId(),
            skillLevel = 1,
            isPetFix = true,
            quality = samplePetCfg:Quality(),
            clickCallBack = Delegate.GetOrCreate(self, self.OnSlgSkillClick),
        })

        -- 品质色
        g_Game.SpriteManager:LoadSprite(ModuleRefer.PetModule:GetPetQualityFrame(samplePetCfg:Quality()), self.p_base_quality)

        -- 栖息地图标
        self.p_table_habitat:Clear()
        for i = 1, petTypeCfg:HandbooksLength() do
            local cfg = ConfigRefer.PetHandbook:Find(petTypeCfg:Handbooks(i))
            local land = cfg:TargetLand()
            if land ~= 0 then
                self.p_table_habitat:AppendData({index = cfg.areaIndex, land = land, icon = cfg:Icon()})
            end
        end
        -- 研究
    elseif (self.detailTabIndex == PetCollectionEnum.TabType.Research) then
        self.infoNode:SetVisible(false)
        self.studyNode:SetVisible(true)
        self.storyNode:SetVisible(false)
        local cfg = ModuleRefer.PetCollectionModule:GetResearchConfig(self.petIndex)

        if researchData then
            level = researchData.Level
            exp = researchData.Exp
            isFullLevel = researchData.IsFullLevel
        end
        local maxExp = ModuleRefer.PetCollectionModule:GetMaxExp(cfg, level)
        local percent = exp / maxExp

        self.p_text_study_level.text = I18N.Get(ConfigRefer.PetConsts:PetHandbookResearchLevelName()) .. string.format(" <b>%s</b>", level)
        self.researchSlider.value = percent
        self.p_text_pb.text = string.format("<color=#000000><b>%s</b></color>", exp) .. "/" .. string.format("<color=#242630>%s</color>", maxExp)

        for i = 1, cfg:TopicsLength() do
            local topic = ConfigRefer.PetResearchTopic:Find(cfg:Topics(i))
            topic.ResearchProcess = researchData and researchData.ResearchProcess[i - 1] or nil
            topic.ResearchValue = researchData and researchData.ResearchValue[i - 1] or 0
            topic.studyIndex = i
            topic.desc = cfg:TopicNames(i)
            self.p_list_table:AppendData(topic)
        end

        -- 故事
    elseif (self.detailTabIndex == PetCollectionEnum.TabType.Story) then
        local curResearchLevel = researchData and researchData.Level or 0
        local story = researchData and researchData.StoryUnlock or {}
        local cfg = ConfigRefer.PetStory:Find(self.param:PetStoryId())

        self.p_text_title_story.text = I18N.Get(cfg:Name())
        self.p_text_story_content.text = I18N.Get(cfg:Desc())

        if cfg then
            for i = 1, cfg:UnlockInfoLength() do
                local info = cfg:UnlockInfo(i)
                local storyId = info:PetStoryItemId(i)
                local level = info:NeedLevel(i)
                self.storyContents:AppendData({
                    areaIndex = self.areaIndex,
                    petIndex = self.petIndex,
                    index = i,
                    unlock = story[i],
                    storyId = storyId,
                    level = level,
                    reward = info:Reward(i),
                    curResearchLevel = curResearchLevel,
                })
            end
        end
        self.infoNode:SetVisible(false)
        self.studyNode:SetVisible(false)
        self.storyNode:SetVisible(true)
    end

    -- 签名相关
    if isFullLevel then
        self.p_text_pb.text = I18N.Get("hero_level_full")
    end
    UIHelper.SetGray(self.p_buff.gameObject, not isFullLevel)
    self.researchSlider:SetVisible(not isFullLevel)
    self.p_complete:SetVisible(isFullLevel)
    self.p_btn_sign:SetVisible(isFullLevel and not isSign)
    self.p_text_sign.text = I18N.Get("pet_handbook_sign_name")
    if isSign then
        self.p_text_player_name.text = ModuleRefer.PlayerModule:GetPlayer().Basics.Name
        self.p_text_date.text = TimeFormatter.TimeToDateTimeStringUseFormat(researchData.SignTime.Seconds, "yyyy/MM/dd HH:mm:ss")
    end
    self.p_name:SetVisible(isSign)
    self.p_text_player_name:SetVisible(isSign)
    self.p_text_date:SetVisible(isSign)
    -- Tab状态刷新
    self.tabs:Clear()
    for i = 1, 3 do
        local data = {tabIndex = i, petIndex = self.petIndex, curTabIndex = self.detailTabIndex, noTabAnim = noTabAnim}
        self.tabs:AppendData(data)
    end
    self.tabs:RefreshAllShownItem()

    g_Game.EventManager:TriggerEvent(EventConst.PET_COLLECTION_DETAIL_LOCK_TAB, {lock = param.lock})
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.p_text_story_content.transform)
end

function PetCollectionPhotoDetailMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.PET_COLLECTION_DETAIL_TAB, Delegate.GetOrCreate(self, self.SwitchTab))
end

function PetCollectionPhotoDetailMediator:OnClickLeft()
    if (self.pageIndex == 1) then
        return
    end
    local res = {pageIndex = self.pageIndex - 1, areaIndex = self.areaIndex, detailTabIndex = self.detailTabIndex}
    self:Refresh(res, true)
    self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

function PetCollectionPhotoDetailMediator:OnClickRight()
    if (self.pageIndex == self.maxPage) then
        return
    end
    local res = {pageIndex = self.pageIndex + 1, areaIndex = self.areaIndex, detailTabIndex = self.detailTabIndex}
    self:Refresh(res, true)
    self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

function PetCollectionPhotoDetailMediator:OnClickClose()
    g_Game.UIManager:CloseByName(UIMediatorNames.PetCollectionPhotoDetailMediator)
end

function PetCollectionPhotoDetailMediator:OnSlgSkillClick(param)
    g_Game.UIManager:Open(UIMediatorNames.UICommonPopupCardDetailMediator, {type = 2, cfgId = param.index, level = 1})
end

function PetCollectionPhotoDetailMediator:OnClickGoto()
    if self.gotoStatus == PetCollectionEnum.PhotoStatusEnum.CanBuy then
        GuideUtils.GotoByGuide(self.petTypeCfg:AcquireGoto(), false)
    end
end

function PetCollectionPhotoDetailMediator:OnClickBuff()
    ModuleRefer.ToastModule:ShowTextToast({clickTransform = self.p_buff.transform, content = I18N.Get("pet_quality_buff_des")})
end

function PetCollectionPhotoDetailMediator:OnSign()
    ModuleRefer.PetCollectionModule:Sign({self.petIndex}, function()
        g_Game.UIManager:Open(UIMediatorNames.PetCollectionSignatureMediator, self.param)

        local researchData = ModuleRefer.PetCollectionModule:GetResearchData(self.param:Id())
        self.p_text_player_name.text = ModuleRefer.PlayerModule:GetPlayer().Basics.Name
        self.p_text_date.text = TimeFormatter.TimeToDateTimeStringUseFormat(researchData.SignTime.Seconds, "yyyy/MM/dd HH:mm:ss")

        self.p_text_player_name:SetVisible(true)
        self.p_text_date:SetVisible(true)
        self.p_btn_sign:SetVisible(false)
        self.p_name:SetVisible(true)
    end)
end

return PetCollectionPhotoDetailMediator
