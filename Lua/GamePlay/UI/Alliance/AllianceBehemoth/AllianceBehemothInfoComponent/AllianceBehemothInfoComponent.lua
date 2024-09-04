local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local AllianceBehemothInfoComponentOperationProvider = require("AllianceBehemothInfoComponentOperationProvider")
local SlgTouchMenuHelper = require("SlgTouchMenuHelper")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local UIHelper = require("UIHelper")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local ArtResourceUtils = require("ArtResourceUtils")
local AllianceModuleDefine = require("AllianceModuleDefine")
local KingdomMapUtils = require("KingdomMapUtils")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceBehemothInfoComponentData
---@field behemothInfo AllianceBehemoth
---@field operationProvider AllianceBehemothInfoComponentOperationProvider

---@class AllianceBehemothInfoComponent:BaseUIComponent
---@field new fun():AllianceBehemothInfoComponent
---@field super BaseUIComponent
local AllianceBehemothInfoComponent = class('AllianceBehemothInfoComponent', BaseUIComponent)

AllianceBehemothInfoComponent.DefaultProvider = AllianceBehemothInfoComponentOperationProvider.new()

function AllianceBehemothInfoComponent:ctor()
    AllianceBehemothInfoComponent.super.ctor(self)
    self._eventsAdd = false
    ---@type AllianceBehemothInfoComponentOperationProvider
    self._operationProvider = nil
    ---@type CS.DragonReborn.UI.LuaBaseComponent[]
    self._nestSkills = {}
    ---@type CS.DragonReborn.UI.LuaBaseComponent[]
    self._mapSkills = {}
    ---@type AllianceBehemothInfoComponentData
    self._data = nil
    ---@type AllianceBehemothInfoComponentAttrCellData[]
    self._attrCellData = {}
end

function AllianceBehemothInfoComponent:OnCreate(param)
    self._p_base_turtle = self:GameObject("p_base_turtle")
    self._p_base_lion = self:GameObject("p_base_lion")

    self._p_btn_rewards = self:Button("p_btn_rewards", Delegate.GetOrCreate(self, self.OnClickBtnReward))
    self._p_text_behemoth_name = self:Text("p_text_behemoth_name")
    self._p_text_behemoth_lv = self:Text("p_text_behemoth_lv")
    self._p_arrow = self:GameObject("p_arrow")
    self._p_text_behemoth_lv_1 = self:Text("p_text_behemoth_lv_1")
    self._p_detail = self:GameObject("p_detail")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickDetailTip))

    self._p_icon_tag = self:Image("p_icon_tag")
    self._p_text_skill = self:Text("p_text_skill")
    
    self._p_text_site = self:Text("p_text_site")
    self._p_site_click = self:Button("p_btn_site", Delegate.GetOrCreate(self, self.OnClickSite))
    self._p_group_skill = self:GameObject("p_group_skill")
    self._p_skill_nest = self:Transform("p_skill_nest")
    ---@see BaseSkillIcon
    self._child_item_skill_template = self:LuaBaseComponent("child_item_skill_template")
    self._child_item_skill_template:SetVisible(false)
    self._p_text_skill_nest = self:Text("p_text_skill_nest", "alliance_behemoth_skill_title")
    self._p_text_skill_map = self:Text("p_text_skill_map", "alliance_behemoth_title_battlefield")
    self._p_skill_map = self:Transform("p_skill_map")
    ---@type BaseSkillIcon
    self._child_item_skill_map_template = self:LuaBaseComponent("child_item_skill_map_template")
    self._child_item_skill_map_template:SetVisible(false)
    
    self._p_btn_challenge = self:Button("p_btn_challenge", Delegate.GetOrCreate(self, self.OnClickChallenge))
    self._p_text_challenge = self:Text("p_text_challenge", "alliance_behemoth_button_challenge")
    self._p_number_cl = self:GameObject("p_number_cl")
    self._p_icon_item_cl = self:Image("p_icon_item_cl")
    self._p_text_num_green_cl = self:Text("p_text_num_green_cl")
    self._p_text_num_red_cl = self:Text("p_text_num_red_cl")
    self._p_text_num_wilth_cl = self:Text("p_text_num_wilth_cl")

    self._p_r5_btn_group = self:GameObject("p_r5_btn_group")
    self._p_btn_challenge_r5_holder = self:GameObject("p_btn_challenge_r5_holder")
    self._p_btn_call_r5_holder = self:GameObject("p_btn_call_r5_holder")
    self._p_btn_challenge_r5 = self:Button("p_btn_challenge_r5", Delegate.GetOrCreate(self, self.OnClickChallengeR5))
    self._p_text_challenge_r5 = self:Text("p_text_challenge_r5", "alliance_behemoth_button_challenge")
    self._p_btn_call_r5 = self:Button("p_btn_call_r5", Delegate.GetOrCreate(self, self.OnClickCallR5))
    self._p_text_call_r5 = self:Text("p_text_call_r5", "alliance_behemoth_button_summon")

    self._p_btn_change_behemoth = self:Button("p_btn_change_behemoth", Delegate.GetOrCreate(self, self.OnClickChangeBehemoth))
    self._p_text_change_behemoth = self:Text("p_text_change_behemoth", "alliance_behemoth_button_attend")
    self._p_text_r5 = self:Text("p_text_r5", "alliance_behemoth_summon_tip2")
    self._p_text_civilian = self:Text("p_text_civilian", "alliance_behemoth_summon_tip1")
    self._p_now_control = self:GameObject("p_now_control")
    self._p_text_now_control = self:Text("p_text_now_control", "alliance_behemoth_attend_tip1")
    self._p_not_obtained = self:GameObject("p_not_obtained")
    self._p_text_not_obtained = self:Text("p_text_not_obtained", "alliance_behemoth_system_none")
    self._p_in_challenge = self:Text("p_in_challenge")
    self._p_table_basics = self:TableViewPro("p_table_basics")
end

---@param data AllianceBehemothInfoComponentData
function AllianceBehemothInfoComponent:OnFeedData(data)
    self._data = data
    local lastProvider = self._operationProvider
    if lastProvider ~= data.operationProvider then
        if lastProvider then lastProvider:OnHide() end
        self._operationProvider = data.operationProvider
        if self._operationProvider then
            self._operationProvider:OnShow()
            self._operationProvider:SetHost(self)
        end
    end
    self:RefreshBehemoth()
    self:RefreshOperation()
end

function AllianceBehemothInfoComponent:RefreshBehemoth()
    local behemoth = self._data.behemothInfo
    local isturtle = behemoth:GetBehemothGroupId() == 1000
    self._p_base_turtle:SetVisible(isturtle)
    self._p_base_lion:SetVisible(not isturtle)
    local currentInUsing = ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth() == behemoth
    local currentDeviceLv = ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceLevel()
    local currentDeviceLvMax = ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceLevelMax()
    local monsterConfig = behemoth:GetRefKMonsterDataConfig((behemoth:IsFake() and 1) or currentDeviceLv)
    local summonMonsterConfig = behemoth:GetSummonRefKMonsterDataConfig(((behemoth:IsFake() or not currentInUsing) and 1) or currentDeviceLv)
    local name, _, _ = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(monsterConfig)
    self._p_text_behemoth_name.text = name
    local nextLvKmonsterConfig = nil
    if currentInUsing then
        self._p_text_behemoth_lv:SetVisible(true)
        self._p_text_behemoth_lv.text = ("Lv.%d"):format(currentDeviceLv)
        if currentDeviceLvMax > currentDeviceLv then
            self._p_text_behemoth_lv_1:SetVisible(true)
            self._p_text_behemoth_lv_1.text = ("Lv.%d"):format(currentDeviceLv + 1)
            self._p_arrow:SetVisible(true)
        else
            self._p_arrow:SetVisible(false)
            self._p_text_behemoth_lv_1:SetVisible(false)
        end
        nextLvKmonsterConfig = behemoth:GetRefKMonsterDataConfig(math.min(currentDeviceLv + 1, currentDeviceLvMax))
    elseif currentDeviceLv
        and ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceBuildingStatus() == wds.BuildingStatus.BuildingStatus_Constructed
        and not behemoth:IsFake()
    then
        self._p_text_behemoth_lv:SetVisible(true)
        self._p_text_behemoth_lv.text = ("Lv.%d"):format(currentDeviceLv)
        self._p_arrow:SetVisible(false)
        self._p_text_behemoth_lv_1:SetVisible(false)
    else
        self._p_text_behemoth_lv:SetVisible(true)
        self._p_text_behemoth_lv.text = ("Lv.%d"):format(1)
        self._p_arrow:SetVisible(false)
        self._p_text_behemoth_lv_1:SetVisible(false)
    end
    if not behemoth:IsFake() then
        self._p_text_site.transform.parent:SetVisible(true)
        local x,y = behemoth:GetMapLocation()
        self._p_text_site.text = ("X:%d,Y:%d"):format(math.floor(x + 0.5), math.floor(y + 0.5))
    else
        self._p_text_site.transform.parent:SetVisible(false)
    end
    self:RefreshAttrCell(monsterConfig, nextLvKmonsterConfig)
    self:RefreshSkills(monsterConfig, self._nestSkills, self._child_item_skill_template, self._p_skill_nest)
    self:RefreshSkills(summonMonsterConfig, self._mapSkills, self._child_item_skill_map_template, self._p_skill_map)
end

---@param monsterConfig KmonsterDataConfigCell
---@param nextLvMonsterConfig KmonsterDataConfigCell
function AllianceBehemothInfoComponent:RefreshAttrCell(monsterConfig, nextLvMonsterConfig)
    self._p_table_basics:Clear()
    table.clear(self._attrCellData)
    local behemothAttrDisplay = ModuleRefer.AllianceModule.Behemoth.BehemothAttrDisplay
    ---@type AssociatedTagConfigCell
    local tagInfo = nil
    local heroInfo = monsterConfig:Hero(1)
    local heroNpcConfig = ConfigRefer.HeroNpc:Find(heroInfo:HeroConf())
    local heroesConfig = ConfigRefer.Heroes:Find(heroNpcConfig:HeroConfigId())
    local petNpcConfig = ConfigRefer.PetNpc:Find(heroInfo:PetConf())
    local petConfig = nil
    local petLevel = 0
    if not tagInfo then
        tagInfo = ConfigRefer.AssociatedTag:Find(heroesConfig:AssociatedTagInfo())
    end
    if petNpcConfig then
        petConfig = ConfigRefer.Pet:Find(petNpcConfig:PetId())
        petLevel = petNpcConfig:Level()
    end
    local level = heroNpcConfig:HeroLevel()
    local nextLevel
    local heroesConfigNext
    local petConfigNext
    local petLevelNext = 0
    if nextLvMonsterConfig then
        local nextHeroInfo = nextLvMonsterConfig:Hero(1)
        local heroNpcConfigNext = ConfigRefer.HeroNpc:Find(nextHeroInfo:HeroConf())
        nextLevel = heroNpcConfigNext:HeroLevel()
        heroesConfigNext = ConfigRefer.Heroes:Find(heroNpcConfigNext:HeroConfigId())
        local petNpcConfigNext = ConfigRefer.PetNpc:Find(nextHeroInfo:PetConf())
        if petNpcConfigNext then
            petConfigNext = ConfigRefer.Pet:Find(petNpcConfigNext:PetId())
            petLevelNext = petNpcConfigNext:Level()
        end
    end
    local blackbg = false
    for _, displayAttr in ipairs(behemothAttrDisplay) do
        local value, langKey, formattedStr,isShow, icon  = ModuleRefer.HeroModule:GetHeroAttrDisplayValueConfigOnly(heroesConfig, level, petConfig, petLevel, displayAttr)
        local nextValue, formattedStrNext
        if heroesConfigNext and nextLevel then
            nextValue, _, formattedStrNext = ModuleRefer.HeroModule:GetHeroAttrDisplayValueConfigOnly(heroesConfigNext, nextLevel, petConfigNext, petLevelNext, displayAttr)
        end
        if ((value and value ~= 0) or ((nextValue and nextValue ~= 0))) and isShow then
            ---@type AllianceBehemothInfoComponentAttrCellData
            local cellData = {}
            cellData.name = I18N.Get(langKey)
            cellData.icon = icon
            cellData.numStr = formattedStr
            cellData.numStrNext = formattedStrNext
            cellData.blackBg = blackbg
            blackbg = not blackbg
            table.insert(self._attrCellData, cellData)
        end
    end
    if tagInfo then
        self._p_icon_tag.transform.parent:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(tagInfo:Icon()), self._p_icon_tag)
        self._p_text_skill.text = I18N.Get(tagInfo:Name())
    else
        self._p_icon_tag.transform.parent:SetVisible(false)
    end
    for _, v in ipairs(self._attrCellData) do
        self._p_table_basics:AppendData(v)
    end
end

---@param index BaseSkillIconData
---@param skillLevel number
---@param clickTrans CS.UnityEngine.RectTransform
function AllianceBehemothInfoComponent:OnClickSkillCell(index, skillLevel, clickTrans)
    if not index then return end
    if index.isSlg then
        ---@type UISkillCommonTipMediatorParameter
        local param = {}
        param.ShowSlgSkillTips = { slgSkillId = index.skillId, skillLevel = skillLevel }
        param.clickTrans = clickTrans
        g_Game.UIManager:Open(UIMediatorNames.UISkillCommonTipMediator, param)
    elseif index.isSoc then
        ---@type UISkillCommonTipMediatorParameter
        local param = {}
        param.ShowSocSkillTips = { socSkillId = index.skillId, skillLevel = skillLevel }
        param.clickTrans = clickTrans
        g_Game.UIManager:Open(UIMediatorNames.UISkillCommonTipMediator, param)
    end
end

---@param monsterConfig KmonsterDataConfigCell
---@param skillCells CS.DragonReborn.UI.LuaBaseComponent[]
---@param template CS.DragonReborn.UI.LuaBaseComponent
---@param parent CS.UnityEngine.Transform
function AllianceBehemothInfoComponent:RefreshSkills(monsterConfig, skillCells, template, parent)
    ---@type table<number, BaseSkillIconData>
    local skillsMap = {}
    ---@type BaseSkillIconData[]
    local skillsData = {}
    local monsterHeroLength = monsterConfig and monsterConfig:HeroLength() or 0
    for i = 1, monsterHeroLength do
        local heroInfo = monsterConfig:Hero(i)
        local heroNpc = ConfigRefer.HeroNpc:Find(heroInfo:HeroConf())
        local hero = ConfigRefer.Heroes:Find(heroNpc:HeroConfigId())
        if hero then
            for j = 1, hero:SlgSkillDisplayLength() do
                local skillInfoId = hero:SlgSkillDisplay(j)
                local skillInfo = ConfigRefer.SlgSkillInfo:Find(skillInfoId)
                local skillLogic = ConfigRefer.KheroSkillLogical:Find(skillInfo:SkillId())
                if skillLogic and not skillsMap[skillLogic:Id()] then
                    skillsMap[skillLogic:Id()] = true
                    ---@type BaseSkillIconData
                    local data = {}
                    data.skillId = skillLogic:Id()
                    data.skillLevel = 1
                    data.isSlg = true
                    data.index = data
                    data.clickCallBack = Delegate.GetOrCreate(self, self.OnClickSkillCell)
                    table.insert(skillsData, data)
                end
            end
        end
    end
    local existsCount = #skillCells
    local dataCount = #skillsData
    for i = dataCount + 1, existsCount do
        skillCells[i]:SetVisible(false)
    end
    for i = existsCount + 1, dataCount do
        local cell = UIHelper.DuplicateUIComponent(template, parent)
        skillCells[i] = cell
    end
    for i = 1, dataCount do
        skillCells[i]:SetVisible(true)
        skillCells[i]:FeedData(skillsData[i])
    end
end

function AllianceBehemothInfoComponent:RefreshOperation()
    local provider = self:GetProvider()
    provider:SetCurrentContext(self._data.behemothInfo)
    self._p_btn_rewards:SetVisible(provider:ShowReward())
    self._p_detail:SetVisible(provider:ShowDetailTip())
    self._p_btn_challenge:SetVisible(provider:ShowChallenge())
    self._p_text_challenge.text = provider:ChallengeText()
    self._p_btn_challenge_r5_holder:SetVisible(provider:ShowChallengeR5())
    self._p_text_challenge_r5.text = provider:ChallengeTextR5()
    self._p_btn_call_r5_holder:SetVisible(provider:ShowCall())
    self._p_text_call_r5.text = provider:CallText()
    self._p_btn_change_behemoth:SetVisible(provider:ShowChange())
    self._p_text_change_behemoth.text = provider:ChangeText()
    self._p_now_control:SetVisible(provider:ShowNowControl())
    self._p_not_obtained:SetVisible(provider:ShowNotHave())
    self._p_text_civilian:SetVisible(provider:ShowCivilianText())
    self._p_text_civilian.text = provider:CivilianText()
    self._p_text_r5:SetVisible(provider:ShowR5Text())
    self._p_text_r5.text = provider:R5Text()
    local needTick = provider:NeedTickNowControl()
    self:SetupTickControl(needTick)
    if needTick then
        self:TickNowControl(0)
    end
    needTick = provider:ShowInChallengeText()
    self:SetupTickInChallenge(needTick)
    self._p_in_challenge:SetVisible(needTick)
    if needTick then
        self:TickInChallenge(0)
        self._p_text_civilian:SetVisible(false)
    end
end

function AllianceBehemothInfoComponent:OnShow(param)
    self:SetupEvents(true)
end

function AllianceBehemothInfoComponent:OnHide(param)
    self:SetupEvents(false)
end

function AllianceBehemothInfoComponent:OnClose(param)
    self:SetupEvents(false)
end

---@return AllianceBehemothInfoComponentOperationProvider
function AllianceBehemothInfoComponent:GetProvider()
    return self._operationProvider or AllianceBehemothInfoComponent.DefaultProvider
end

function AllianceBehemothInfoComponent:SetupEvents(add)
    if not self._eventsAdd and add then
        self._eventsAdd = true
        if self._operationProvider then
            self._operationProvider:OnShow()
        end
    elseif self._eventsAdd and not add then
        self._eventsAdd = false
        self:SetupTickControl(false)
        self:SetupTickInChallenge(false)
        if self._operationProvider then
            self._operationProvider:OnHide()
        end
    end
end

function AllianceBehemothInfoComponent:OnClickBtnReward()
    self:GetProvider():OnClickReward(self._p_btn_rewards.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform)))
end

function AllianceBehemothInfoComponent:OnClickDetailTip()
    self:GetProvider():OnClickDetailTip(self._p_btn_detail.transform)
end

function AllianceBehemothInfoComponent:OnClickSite()
    local behemoth = self._data.behemothInfo
    local x,y = behemoth:GetMapLocation()
    if x and y then
        self:GetParentBaseUIMediator():CloseSelf()
        if behemoth:IsFromCage() then
            local size = KingdomMapUtils.GetCameraLodData().mapCameraEnterSize
            AllianceWarTabHelper.GoToCoord(x, y, nil, nil, nil, nil, nil, size, 0)
        else
            AllianceWarTabHelper.GoToCoord(x, y)
        end
        
    end
end

function AllianceBehemothInfoComponent:OnClickChallenge()
    self:GetProvider():OnClickChallenge()
end

function AllianceBehemothInfoComponent:OnClickChallengeR5()
    self:GetProvider():OnClickChallengeR5()
end

function AllianceBehemothInfoComponent:OnClickCallR5()
    if self:GetProvider():OnClickCall() then
        self:GetParentBaseUIMediator():CloseSelf()
    end
end

function AllianceBehemothInfoComponent:OnClickChangeBehemoth()
    self:GetProvider():OnClickChange(self._p_btn_change_behemoth.transform)
end

function AllianceBehemothInfoComponent:SetupTickControl(add)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TickNowControl))
    if not add then return end
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.TickNowControl))
end

function AllianceBehemothInfoComponent:SetupTickInChallenge(add)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TickInChallenge))
    if not add then return end
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.TickInChallenge))
end

function AllianceBehemothInfoComponent:TickNowControl(dt)
    local needTick, text = self:GetProvider():TickNowControl(dt)
    if not needTick then
        self._p_text_now_control.text = I18N.Get("alliance_behemoth_attend_tip1")
        self:SetupTickControl(false)
    else
        self._p_text_now_control.text = text
    end
end

function AllianceBehemothInfoComponent:TickInChallenge(dt)
    local needTick, text = self:GetProvider():TickInChallengeText(dt)
    if not needTick then
        self._p_in_challenge:SetVisible(false)
        self:SetupTickInChallenge(false)
    else
        self._p_in_challenge.text = text
    end
end

return AllianceBehemothInfoComponent