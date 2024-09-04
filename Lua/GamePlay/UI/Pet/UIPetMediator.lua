local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local I18N = require('I18N')
local UIMediatorNames = require("UIMediatorNames")
local CommonDropDown = require("CommonDropDown")
local ConfigRefer = require("ConfigRefer")
local TimerUtility = require("TimerUtility")
local Utils = require("Utils")
local HeroUIUtilities = require("HeroUIUtilities")
local SetPetIsLockParameter = require("SetPetIsLockParameter")
local EventConst = require("EventConst")
local UIHelper = require("UIHelper")
local AttrValueType = require("AttrValueType")
local UI3DViewConst = require("UI3DViewConst")
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local ArtResourceUtils = require('ArtResourceUtils')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local NotificationType = require('NotificationType')
local AudioConsts = require('AudioConsts')
local DBEntityPath = require("DBEntityPath")
---@class UIPetMediator : BaseUIMediator
local UIPetMediator = class('UIPetMediator', BaseUIMediator)

---@class UIPetMediatorParam
---@field petId number @宠物ID
---@field selectedType number @选中类型, 只在不传宠物ID时生效

local PET_SORT_MODE_RARITY = 1
local PET_SORT_MODE_LEVEL = 2
local PET_SORT_MODE_RANK = 3
local ATTR_DISP_ID_POWER = 100

local FILTER_STYLE = {Rarity = 1, Rank = 2, Style = 3}
function UIPetMediator:ctor()
    self._selectedId = 0
    self._petSortMode = PET_SORT_MODE_RARITY
    self._closing = false
    self._bgAnimOpened = false
    self._levelUpExpItemCfgId = -1
    self._levelUpExpItemCfg = nil
    self._levelUpExpItemNeededCount = 0
    self._petSortData = {}
    ---@type table<number, UIPetIconData>
    self._petData = {}
    self._petTypeData = {}
    ---@type SystemEntryConfigCell
    self._petUpgradeEntryCfg = nil
end

function UIPetMediator:OnCreate()
    self:InitObjects()
    self:PreloadUI3DView()
end

function UIPetMediator:InitObjects()
    ---@type CommonBackButtonComponent
    self.backButton = self:LuaObject("child_common_btn_back")
    self.petSortModeDropDown = self:LuaObject("child_dropdown")
    self.petListNode = self:GameObject("p_pet_list")
    self.tablePetList = self:TableViewPro("p_table_pet")
    self.emptyListNode = self:GameObject("p_pet_empty")
    self.textEmpty = self:Text("p_text_empty", "pet_memo4")
    self.textCarried = self:Text("p_text_carried", "hero_pet_carried")

    self.bindHeroButton = self:Button("p_btn_hero", Delegate.GetOrCreate(self, self.OnBindHeroButtonClick))
    ---@type HeroInfoItemComponent
    self.bindHeroInfo = self:LuaObject("child_card_hero_s_ex")
    self.p_btn_upgrade = self:Button("p_btn_upgrade", Delegate.GetOrCreate(self, self.OnBtnLevelUpClicked))

    self.p_group_hint = self:GameObject("p_group_hint")
    self.p_text_hint = self:Text("p_text_hint")
    self.p_btn_hint_goto = self:Button("p_btn_hint_goto", Delegate.GetOrCreate(self, self.OnBtnGotoClick))

    ---@type CommonPairsQuantity
    self.buttonUpgrade = self:LuaObject("child_common_quantity")
    -- 模型旋转
    self:DragEvent("p_btn_empty", nil, Delegate.GetOrCreate(self, self.OnModelDrag))
    self:PointerClick("p_btn_empty", Delegate.GetOrCreate(self, self.OnClickPet))

    self.imgBaseQuality = self:Image('p_base_quality')
    self.textName = self:Text('p_text_name')
    self.textPower = self:Text('p_text_power')
    self.textLv = self:Text('p_text_lv', I18N.Get("pet_param_label_lv"))
    self.textLvNumber = self:Text('p_text_lv_number')

    self.btnInfo = self:Button('p_btn_info', Delegate.GetOrCreate(self, self.OnBtnInfoClicked))
    self.storyButton = self:Button("p_btn_story", Delegate.GetOrCreate(self, self.OnSkillButtonClick))
    self.lockButton = self:Button("p_btn_lock", Delegate.GetOrCreate(self, self.OnLockButtonClick))
    self.goIconLock = self:GameObject('p_icon_lock')
    self.goIconUnlock = self:GameObject('p_icon_unlock')
    self.petBookBtn = self:Button("p_btn_pet_book", Delegate.GetOrCreate(self, self.GotoPetBook))

    self.p_btn_compound = self:Button('p_btn_compound', Delegate.GetOrCreate(self, self.OnClickPetFusion))
    self.p_btn_change_name = self:Button("p_btn_change_name", Delegate.GetOrCreate(self, self.OnClickChangePetName))

    ---@type UIPetWorkTypeComp
    self.p_type_main = self:LuaBaseComponent('p_type_main')
    self.p_layout_type_main = self:Transform('p_layout_type_main')
    self.pool_type_info_main = LuaReusedComponentPool.new(self.p_type_main, self.p_layout_type_main)

    -- 属性标签
    self.child_icon_style_main = self:LuaObject('child_icon_style_main')

    -- 筛选
    self.p_text_all_lv = self:Text('p_text_all_lv', "backpack_type_all")
    self.p_text_all_quality = self:Text('p_text_all_quality', "backpack_type_all")
    self.p_text_all_style = self:Text('p_text_all_style', "backpack_type_all")
    self.p_btn_all_style = self:Button('p_btn_all_style', Delegate.GetOrCreate(self, self.OnClickFilterStyle))
    self.p_btn_all_lv = self:Button('p_btn_all_lv', Delegate.GetOrCreate(self, self.OnClickFilterLevel))
    self.p_btn_all_quality = self:Button('p_btn_all_quality', Delegate.GetOrCreate(self, self.OnClickFilterQuality))
    self.p_btn_all_style_Status = self:StatusRecordParent('p_btn_all_style')
    self.p_btn_all_lv_Status = self:StatusRecordParent('p_btn_all_lv')
    self.p_btn_all_quality_Status = self:StatusRecordParent('p_btn_all_quality')
    self.p_btn_style = self:LuaBaseComponent('p_btn_style')
    self.p_btn_lv = self:LuaBaseComponent('p_btn_lv')
    self.p_btn_quality = self:LuaBaseComponent('p_btn_quality')
    self.p_style_layout = self:Transform('p_style_layout')
    self.p_lv_layout = self:Transform('p_lv_layout')
    self.p_quality_layout = self:Transform('p_quality_layout')
    self.pool_filter_style = LuaReusedComponentPool.new(self.p_btn_style, self.p_style_layout)
    self.pool_filter_level = LuaReusedComponentPool.new(self.p_btn_lv, self.p_lv_layout)
    self.pool_filter_quality = LuaReusedComponentPool.new(self.p_btn_quality, self.p_quality_layout)
    self.p_btn_open = self:Button('p_btn_open', Delegate.GetOrCreate(self, self.OnClickFilter))
    self.p_btn_close = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnClickFilter))
    self.child_pet_dna = self:LuaObject('child_pet_dna')
    self.p_text_pet_book = self:Text('p_text_pet_book')

    -- 新增Filter
    self.p_group_filter = self:GameObject('p_group_filter')
    -- self.p_text_filter_1 = self:Text('p_text_filter_1', '#按XX排序')
    -- self.p_text_filter_2 = self:Text('p_text_filter_2', '#按XX排序')

    ---@type BaseSkillIcon
    self.skill1 = self:LuaObject('child_item_skill_1')
    self.skill2 = self:LuaObject('child_item_skill_2')
    self.skill3 = self:LuaObject('child_item_skill_3')

    ---@type PetStarLevelComponent
    self.group_star = self:LuaBaseComponent('group_star')
    self.p_btn_level = self:Button('p_btn_level', Delegate.GetOrCreate(self, self.OnClickDetail))
    self.p_text_skill_book = self:Text("p_text_skill_book", "hero_card")

    self.p_text_resonated = self:Text('p_text_resonated', 'pet_level_sync_name')

    self.p_text_upgrade = self:Text('p_text_upgrade', 'Work_lvup_farm3_lv1_Name')
    self.bindHeroButton.gameObject:SetVisible(false)

    -- 红点
    self.notifyNode = self:LuaObject('child_reddot_default_petbook')
    self.child_reddot_default_skill = self:LuaObject('child_reddot_default_skill')

    -- 技能红点
    self.child_reddot_default_2 = self:LuaObject("child_reddot_default_2")
    self.child_reddot_default_3 = self:LuaObject("child_reddot_default_3")
    self.skillRedDots = {self.child_reddot_default_2, self.child_reddot_default_3}
    self.child_reddot_default_upgrade = self:LuaObject('child_reddot_default_upgrade')

    self.p_lv_layout:SetVisible(false)
    self.p_quality_layout:SetVisible(false)

    self.p_group_lock_1 = self:GameObject('p_group_lock_1')
    self.p_group_lock_2 = self:GameObject('p_group_lock_2')

    self.p_pet_list_status = self:StatusRecordParent('p_pet_list')
    self.p_btn_unfold = self:Button('p_btn_unfold', Delegate.GetOrCreate(self, self.OnClickFold))

    -- 战斗宠物
    ---@type PetTagComponent
    self.p_group_feature = self:LuaBaseComponent('p_group_feature')

    self.p_title_level = self:Text('p_title_level', 'hero_btn_level')
    self.p_title_skill = self:Text('p_title_skill', 'hero_card')
    self.p_text_dna = self:Text('p_text_dna', "pet_gene_name")
    self.child_icon_style_main:SetVisible(true)
    self.p_btn_goto_dna = self:Button('p_btn_goto_dna', Delegate.GetOrCreate(self, self.OnClickGene))
end

function UIPetMediator:PreloadUI3DView()
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

function UIPetMediator:OnBtnLevelUpClicked()
    if self.clickedLevelUp then
        return
    end

    self.clickedLevelUp = true
    local pet = ModuleRefer.PetModule:GetPetByID(self._selectedId)
    if (not pet) then
        return
    end
    local isSatisfyFurniture = ModuleRefer.PetModule:IsSatisfyFurnitureLevel(self._selectedId)
    if not isSatisfyFurniture then
        return
    end
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_pet_upgrade)

    local petLevel, exp = ModuleRefer.PetModule:GetPetResonateLevel()
    local _, exp, expNext = ModuleRefer.PetModule:GetExpPercent(pet.ConfigId, petLevel, pet.Exp)
    local lvupItemCfgId = ConfigRefer.PetConsts:PetLevelUpCost()
    local itemCfg = ConfigRefer.Item:Find(lvupItemCfgId)
    if (itemCfg) then
        local has = ModuleRefer.InventoryModule:GetAmountByConfigId(lvupItemCfgId)
        local need = math.max(1, expNext - exp)
        if (has < need) then
            ModuleRefer.InventoryModule:OpenExchangePanel({{id = lvupItemCfgId, num = need - has}})
            return
        end
    end

    ModuleRefer.PetModule:PetAddExp(self._selectedId, self._levelUpExpItemNeededCount, Delegate.GetOrCreate(self, self.OnPetLevelUp))
end

function UIPetMediator:OnBtnGotoClick()
    g_Game.UIManager:CloseAllByName(UIMediatorNames.CommonConfirmPopupMediator)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.UIPetMediator)
    local city = ModuleRefer.CityModule.myCity
    local furnitureTypeId = ConfigRefer.CityConfig:HotSpringFurniture()
    city:LookAtTargetFurnitureByTypeCfgId(furnitureTypeId, 0.8, nil, true)
end

function UIPetMediator:OnBtnInfoClicked(args)
    local level, pets = ModuleRefer.PetModule:GetHighestLevelPets()

    ---@type TextToastMediatorParameter
    local toastParameter = {}
    toastParameter.clickTransform = self.btnInfo.transform
    toastParameter.content = I18N.GetWithParams("animal_work_fur_desc_03", level, ModuleRefer.PetModule:GetPetName(pets[3]))
    ModuleRefer.ToastModule:ShowTextToast(toastParameter)
end

function UIPetMediator:OnShow(param)
    self.clickedLevelUp = false
    self:RefreshRedPoint()
    self.isFold = true
    g_Game.EventManager:TriggerEvent(EventConst.UNIT_MARKER_CANVAS_SHOW_HIDE_FOR_3D_UI, false)
end

function UIPetMediator:OnHide(param)
    g_Game.EventManager:TriggerEvent(EventConst.UNIT_MARKER_CANVAS_SHOW_HIDE_FOR_3D_UI, true)
end

function UIPetMediator:OnOpened(param)
    g_Game.EventManager:AddListener(EventConst.PET_RENAME, Delegate.GetOrCreate(self, self.RefreshSelectedPet))
    g_Game.EventManager:AddListener(EventConst.PET_EQUIP_SKILL, Delegate.GetOrCreate(self, self.OnEquipSkill))
    g_Game.EventManager:AddListener(EventConst.PET_UNEQUIP_SKILL, Delegate.GetOrCreate(self, self.OnUnEquipSkill))
    g_Game.EventManager:AddListener(EventConst.PET_UPGRADE_SKILL, Delegate.GetOrCreate(self, self.OnUpgradeSkill))
    g_Game.EventManager:AddListener(EventConst.PET_UI_MAIN_REFRESH, Delegate.GetOrCreate(self, self.TryRefresh))
    g_Game.EventManager:AddListener(EventConst.PET_UI_MAIN_REFRESH_MODEL, Delegate.GetOrCreate(self, self.RefreshModel))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPet.PetInfos.MsgPath, Delegate.GetOrCreate(self, self.GetNewPet))

    self.forceClose = false

    if param and param.petId then
        self._selectedId = param.petId
    end
    local total = ConfigRefer.PetConsts:PetMaxCount()
    local cur = ModuleRefer.PetModule:GetPetCount()
    self.p_text_pet_book.text = I18N.GetWithParams(cur .. "/" .. total)
    -- g_Game.UIManager:SetZBlurVisible(false)
    g_Game.EventManager:TriggerEvent(EventConst.OPEN_3D_SHOW_UI)
    self:InitData(param)
    self:RefreshPetList(self._selectedId == 0)

    if self.forceClose then
        return
    end
    self:OnPetSelected(self._petData[self._selectedId], true)
    self:InitFilter()
    self:RefreshPetSkill()
    if self.ui3dModel then
        if param and param.petId then
            self.ui3dModel:EnableVirtualCamera(2)
        else
            self.ui3dModel:EnableVirtualCamera(1)
        end
    end
end

function UIPetMediator:GotoPet(petId)
    self._selectedId = petId
    self:RefreshPetList()
    self:RefreshSelectedPet()
    self:RefreshStars()
end

function UIPetMediator:OnClose(param)
    self._closing = true
    -- self.detailPageController.onPageChanged = nil
    self:ClearEffectTimer()
    if self.aniTimer then
        TimerUtility.StopAndRecycle(self.aniTimer)
        self.aniTimer = nil
    end
    if self.clickAniTimer then
        TimerUtility.StopAndRecycle(self.clickAniTimer)
        self.clickAniTimer = nil
    end
    g_Game.UIManager:CloseUI3DView(self:GetRuntimeId())
    g_Game.EventManager:TriggerEvent(EventConst.CLOSE_3D_SHOW_UI)
    g_Game.EventManager:RemoveListener(EventConst.PET_RENAME, Delegate.GetOrCreate(self, self.RefreshSelectedPet))
    g_Game.EventManager:RemoveListener(EventConst.PET_EQUIP_SKILL, Delegate.GetOrCreate(self, self.OnEquipSkill))
    g_Game.EventManager:RemoveListener(EventConst.PET_UNEQUIP_SKILL, Delegate.GetOrCreate(self, self.OnUnEquipSkill))
    g_Game.EventManager:RemoveListener(EventConst.PET_UPGRADE_SKILL, Delegate.GetOrCreate(self, self.OnUpgradeSkill))
    g_Game.EventManager:RemoveListener(EventConst.PET_UI_MAIN_REFRESH, Delegate.GetOrCreate(self, self.TryRefresh))
    g_Game.EventManager:RemoveListener(EventConst.PET_UI_MAIN_REFRESH_MODEL, Delegate.GetOrCreate(self, self.RefreshModel))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPet.PetInfos.MsgPath, Delegate.GetOrCreate(self, self.GetNewPet))
end

function UIPetMediator:OnUnEquipSkill(param)
    self.tablePetList:SetToggleSelect(self._petData[self._selectedId])
    self:RefreshPetSkill()
    self:RefreshStars()
end

function UIPetMediator:OnUpgradeSkill(skillId)
    if self.skillLevels then
        for k, v in pairs(self.skillLevels) do
            if skillId == v.skillId then
                v.playEquipVfx = true
                v.level = v.level + 1
                self.playVfx = true
                break
            end
        end
    end
end

function UIPetMediator:OnEquipSkill(param)
    if self.skillLevels then
        self.playVfx = true
        local skillId = param.skillId
        local level = ModuleRefer.PetModule:GetSkillLevel(self._selectedId, false, skillId)
        local quality = ConfigRefer.PetLearnableSkill:Find(skillId):Quality()
        table.insert(self.skillLevels, {quality = quality, level = level, playEquipVfx = true})
        table.sort(self.skillLevels, function(a, b)
            return a.quality > b.quality
        end)
    end
end

function UIPetMediator:TryRefresh()
    self:RefreshPetList()

    if self.playVfx == true then
        self.playVfx = false
        self.group_star:FeedData({skillLevels = self.skillLevels})
        self:RefreshPetSkill()
        self.tablePetList:SetToggleSelect(self._petData[self._selectedId])
    else
        self.tablePetList:SetToggleSelect(self._petData[self._selectedId])
        self:RefreshPetSkill()
        self:RefreshStars()
    end
end

--- 初始化数据
---@param self UIPetMediator
---@param param UIPetMediatorParam
function UIPetMediator:InitData(param)
    if (not self.backButton) then
        return
    end
    self._filterStyle = 0
    self.filterRank = 0
    self._filterQuality = 0
    self.backButton:FeedData({title = I18N.Get("pet_title0"), onClose = Delegate.GetOrCreate(self, self.OnBackButtonClick)})

    local sortDropDownData = {}
    sortDropDownData.items = CommonDropDown.CreateData("", I18N.Get("pet_filter_condition0"), "", I18N.Get("pet_sort_by_main_skill_name"), "", I18N.Get("pet_sort_star_desc"))
    sortDropDownData.defaultId = self._petSortMode
    sortDropDownData.onSelect = Delegate.GetOrCreate(self, self.OnDropDownSelect)
    self.petSortModeDropDown:FeedData(sortDropDownData)
    self._levelUpExpItemCfgId = ConfigRefer.PetConsts:PetLevelUpCost()
    self._levelUpExpItemCfg = ConfigRefer.Item:Find(self._levelUpExpItemCfgId)
    self.typeCfgList = ModuleRefer.PetModule:GetTypeCfgList()

    ---@type CommonPairsQuantityParameter
    local parameter = {}
    parameter.itemId = self._levelUpExpItemCfgId
    parameter.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
    parameter.num1 = 0
    parameter.num2 = 0
    self.buttonUpgrade:FeedData(parameter)
end

--- 刷新伙伴列表
---@param self PetModule
---@param resetSelected boolean 重置选中的条目
function UIPetMediator:RefreshPetList(resetSelected)
    local pets = ModuleRefer.PetModule:GetPetList()
    local count = 0
    for k, v in pairs(pets) do
        count = count + 1
    end

    self.lockButton.gameObject:SetVisible(true)
    self.emptyListNode:SetVisible(false)
    self.petListNode:SetVisible(true)

    if (resetSelected) then
        self._selectedId = 0
    end

    self._petData = {}
    self._petSortData = {}

    for id, pet in pairs(pets) do
        local petTypeCfg = ModuleRefer.PetModule:GetTypeCfg(pet.Type)
        local petTagId = petTypeCfg:PetTagDisplay()

        local rank = ModuleRefer.PetModule:GetStarLevel(id)
        ---@type UIPetIconData
        local data = {
            id = id,
            cfgId = pet.ConfigId,
            onClick = Delegate.GetOrCreate(self, self.OnPetSelected),
            selected = self._selectedId == id,
            level = pet.Level,
            rank = rank,
            templateIds = pet.TemplateIds,
            isBattle = petTagId > 0,
        }
        self._petData[id] = data
        local bindHeroId = ModuleRefer.PetModule:GetPetLinkHero(id)
        local cfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
        local fixedSkillLevel = ModuleRefer.PetModule:GetSkillLevel(id, true)

        table.insert(self._petSortData, {
            fixedSkillLevel = fixedSkillLevel,
            style = cfg:AssociatedTagInfo(),
            id = id,
            cfgId = pet.ConfigId,
            rarity = cfg:Quality(),
            level = pet.Level,
            rank = rank,
            templateIds = pet.TemplateIds,
            heroBind = bindHeroId and bindHeroId > 0,
            isInTroop = ModuleRefer.TroopModule:GetPetBelongedTroopIndex(id) ~= 0.,
        })
    end
    if #self._petSortData == 0 then
        self.forceClose = true
        g_Logger.Error("1个宠物都没有吧")
        -- self:CloseSelf()
        return
    end
    self:SortPetData()
    if (self._selectedId == 0) then
        self._selectedId = self._petSortData[1].id
        if (self._petData[self._selectedId]) then
            self._petData[self._selectedId].selected = true
        end
    end
    self.tablePetList:Clear()
    for _, item in ipairs(self._petSortData) do
        self.tablePetList:AppendData(self._petData[item.id])
    end

    -- self.p_table_pets:Clear()
    -- local hasAllPet = true
    -- for k, cfg in pairs(self.typeCfgList) do
    --     local typeCfgId = cfg:Id()
    --     local pets = ModuleRefer.PetModule:GetPetsByType(typeCfgId)
    --     -- 增加未获得的宠物
    --     if pets == nil then
    --         ---@type UIPetIconData
    --         local cfgId = cfg:SamplePetCfg()
    --         local data = {onClick = Delegate.GetOrCreate(self, self.OnUnOwnPetSelected), id = -cfgId, cfgId = cfgId}
    --         self.p_table_pets:AppendData(data)
    --         hasAllPet = false
    --     end
    -- end
    -- self.p_table_pets:RefreshAllShownItem()
end

--- 刷新选中的伙伴属性
---@param self UIPetMediator
function UIPetMediator:RefreshSelectedPet()
    local pet = ModuleRefer.PetModule:GetPetByID(self._selectedId)
    if (not pet) then
        g_Logger.ErrorChannel("Pet", "未找到宠物, id: %s", self._selectedId)
        return
    end

    local pet = ModuleRefer.PetModule:GetPetByID(self._selectedId)
    local petCfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
    g_Game.SpriteManager:LoadSprite(ModuleRefer.PetModule:GetPetMainQualityFrame(petCfg:Quality()), self.imgBaseQuality)
    self.textName.text = ModuleRefer.PetModule:GetPetName(self._selectedId)

    -- 等级
    self:RefreshPetLevelInfo()

    -- 工作能力
    self.pool_type_info_main:HideAll()
    for i = 1, petCfg:PetWorksLength() do
        local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
        local workType = petWorkCfg:Type()
        local level = petWorkCfg:Level()
        local param = {level = level, name = ModuleRefer.PetModule:GetPetWorkTypeStr(workType), icon = ModuleRefer.PetModule:GetPetWorkTypeIcon(workType)}
        local itemMain = self.pool_type_info_main:GetItem().Lua
        itemMain:FeedData(param)
    end

    -- 属性标签
    local tagId = petCfg:AssociatedTagInfo()
    if tagId > 0 then
        self.child_icon_style_main:FeedData({tagId = tagId})
    end

    -- 战斗标签
    local petTypeCfg = ModuleRefer.PetModule:GetTypeCfg(pet.Type)
    local petTagId = petTypeCfg:PetTagDisplay()
    if petTagId and petTagId > 0 then
        self.p_group_feature:SetVisible(true)
        self.p_group_feature:FeedData(petTagId)
    else
        self.p_group_feature:SetVisible(false)
    end

    -- 基因
    self.child_pet_dna:FeedData(pet)

    -- 是否锁定
    self:RefreshLockState(self._selectedId)

    -- 技能
    self:RefreshPetSkill()

    -- 升级红点
    local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("pet_level_up_", NotificationType.PET_LEVEL_UP)
    if (node) then
        self.child_reddot_default_upgrade:SetVisible(true)
        ModuleRefer.NotificationModule:AttachToGameObject(node, self.child_reddot_default_upgrade.go, self.child_reddot_default_upgrade.redDot)
    else
        self.child_reddot_default_upgrade:SetVisible(false)
    end
    -- 英雄绑定
    -- local bindHeroId = ModuleRefer.PetModule:GetPetLinkHero(pet.ID)
    -- if (bindHeroId and bindHeroId > 0) then
    --     self.bindHeroButton.gameObject:SetVisible(true)
    --     self.bindHeroInfo:FeedData({heroData = ModuleRefer.HeroModule:GetHeroByCfgId(bindHeroId), hideLv = true, hideStrengthen = true})
    -- else
    --     self.bindHeroButton.gameObject:SetVisible(false)
    -- end

    -- local equipNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PetSkillEquip_" .. self._selectedId, NotificationType.PET_SKILL_EQUIP)
    -- ModuleRefer.NotificationModule:AttachToGameObject(equipNode, self.child_reddot_default_equip.go, self.child_reddot_default_equip.redDot)

    local petCfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
    self:Show3DModel(petCfg)
end

function UIPetMediator:RefreshModel()
    local pet = ModuleRefer.PetModule:GetPetByID(self._selectedId)
    local petCfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
    self:Show3DModel(petCfg)
end

-- 星级
function UIPetMediator:RefreshStars()
    local starLevel, skillLevels = ModuleRefer.PetModule:GetSkillLevelQuality(self._selectedId)
    self.skillLevels = skillLevels
    self.group_star:FeedData({skillLevels = skillLevels})
end

function UIPetMediator:RefreshPetLevelInfo()
    local pet = ModuleRefer.PetModule:GetPetByID(self._selectedId)
    -- 等级
    if not pet then
        return
    end
    self._petData[self._selectedId].level = pet.Level
    local maxLevel = ModuleRefer.PetModule:GetMaxLevel()
    local limitedLevel = ModuleRefer.PetModule:GetLimitedMaxLevel()
    local has = ModuleRefer.InventoryModule:GetAmountByConfigId(self._levelUpExpItemCfgId)
    local need = ModuleRefer.PetModule:GetPetLevelUpRequiredItemCount(self._selectedId)
    self._levelUpExpItemNeededCount = need
    if (pet.Level >= maxLevel) then
        self.p_group_hint:SetVisible(true)
        self.p_btn_hint_goto:SetVisible(false)
        self.p_btn_upgrade:SetVisible(false)
        self.p_text_hint.text = I18N.Get("pet_all_max_level_name")
    else
        if (pet.Level >= limitedLevel) then
            self.p_group_hint:SetVisible(true)
            self.p_btn_hint_goto:SetVisible(true)
            self.p_btn_upgrade:SetVisible(false)
            self.p_text_hint.text = I18N.Get("mentor_tips01")
        else
            self.p_group_hint:SetVisible(false)
            self.buttonUpgrade:SetVisible(true)
            self.p_btn_upgrade:SetVisible(true)
            self.buttonUpgrade:ChangeNum(has, need)
        end
    end
    -- Power
    local power = ModuleRefer.PetModule:GetPetAttrDisplayValue(self._selectedId, ATTR_DISP_ID_POWER)
    self.textPower.text = CS.System.String.Format("{0:#,0}", power)
    self.textLvNumber.text = pet.Level
    -- local maxLevel = ModuleRefer.PetModule:GetMaxLevel()
    -- self.textLvNumberTop.text = "/" .. maxLevel
end

--- 伙伴数据排序
---@param self UIPetMediator
function UIPetMediator:SortPetData()
    -- Filter
    if self._filterStyle ~= 0 or self.filterRank ~= 0 or self._filterQuality ~= 0 then
        local filterData = {}
        for k, v in pairs(self._petSortData) do
            filterData[k] = v
        end

        for i = #self._petSortData, 1, -1 do
            local v = self._petSortData[i]
            if (self._filterQuality ~= 0 and v.rarity ~= self._filterQuality) or (self.filterRank ~= 0 and v.rank ~= self.filterRank) or (self._filterStyle ~= 0 and v.style ~= self._filterStyle) then
                table.remove(filterData, i)
            end
        end
        self._petSortData = filterData
    end

    -- Sort
    if (self._petSortMode == PET_SORT_MODE_RARITY) then
        table.sort(self._petSortData, UIPetMediator.SortPetDataByRarity)
    elseif (self._petSortMode == PET_SORT_MODE_LEVEL) then
        table.sort(self._petSortData, UIPetMediator.SortPetDataByLevel)
    elseif (self._petSortMode == PET_SORT_MODE_RANK) then
        table.sort(self._petSortData, UIPetMediator.SortPetDataByRank)
    end
end

function UIPetMediator:OnDropDownSelect(id)
    self._petSortMode = id
    self:RefreshPetList()
end

function UIPetMediator:OnPetSelected(data, force)
    if (not data) then
        return
    end
    if (self._selectedId ~= data.id or force) then
        self._selectedId = data.id
        self.tablePetList:SetToggleSelect(self._petData[self._selectedId])
        self:RefreshSelectedPet()
        self:RefreshStars()
    end
end

function UIPetMediator:OnUnOwnPetSelected(petCfgId)
    ModuleRefer.PetModule:ShowPetPreview(petCfgId, "sss")
end

--- 展示3D模型
---@param self UIPetMediator
---@param petCfg PetConfigCell
function UIPetMediator:Show3DModel(petCfg)
    if (petCfg) then
        local artConf = ConfigRefer.ArtResource:Find(petCfg:ShowModel())
        -- g_Game.UIManager:CloseUI3DModelView()
        ModuleRefer.HeroModule:SkipTimeline()
        g_Game.UIManager:SetupUI3DModelView(self:GetRuntimeId(), artConf:Path(), ConfigRefer.ArtResource:Find(petCfg:ShowBackground()):Path(), nil, function(viewer)
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
            self:Play3DModelBgAnim()
            local showTimeline = petCfg:ShowAnimationVFX()
            if showTimeline and showTimeline ~= "" then
                if self.ui3dModel then
                    self.ui3dModel.curModelGo:SetVisible(false)
                end
                local callback = function()
                    if self.ui3dModel then
                        self.ui3dModel.curModelGo:SetVisible(true)
                        self.ui3dModel:ChangeRigBuilderState(true)
                    end
                    self.ui3dModel:InitVirtualCameraSetting(self:Get3DCameraSettings())
                end
                ModuleRefer.HeroModule:LoadTimeline(petCfg:ShowAnimationVFX(), self.ui3dModel.moduleRoot, callback)
            else
                if petCfg:ShowAnimationLength() >= 1 then
                    local maxNum = petCfg:ShowAnimationLength()
                    local index = math.random(1, maxNum)
                    self.aniName = petCfg:ShowAnimation(index)
                    self.ui3dModel:PlayAnim(self.aniName)
                    self.isPlayAni = true
                    self.aniTimer = TimerUtility.IntervalRepeat(function()
                        self:CheckIsCompleteShow()
                    end, 0.2, -1)
                end
            end
        end)
    end
end

function UIPetMediator:CheckIsCompleteShow()
    if self.ui3dModel and Utils.IsNotNull(self.ui3dModel.modelAnim) then
        local animState = self.ui3dModel.modelAnim:GetCurrentAnimatorStateInfo(0)
        if animState and self.aniName and animState:IsName(self.aniName) and animState.normalizedTime > 0.95 then
            if self.aniTimer then
                TimerUtility.StopAndRecycle(self.aniTimer)
                self.aniTimer = nil
            end
            self.isPlayAni = false
        end
    end
end

function UIPetMediator:OnClickPet()
    if self.ui3dModel and Utils.IsNotNull(self.ui3dModel.modelAnim) then
        if self.isPlayAni then
            return
        end
        local pet = ModuleRefer.PetModule:GetPetByID(self._selectedId)
        local petCfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
        if petCfg:RandomAnimationLength() >= 1 then
            local maxNum = petCfg:RandomAnimationLength()
            local index = math.random(1, maxNum)
            self.clickAnimName = petCfg:RandomAnimation(index)
            self.ui3dModel:CrossFade(self.clickAnimName)
            self.isPlayAni = true
            self.clickAniTimer = TimerUtility.IntervalRepeat(function()
                self:CheckClickAniIsCompleteShow()
            end, 0.2, -1)
        end
    end
end

function UIPetMediator:CheckClickAniIsCompleteShow()
    if self.ui3dModel and Utils.IsNotNull(self.ui3dModel.modelAnim) then
        local animState = self.ui3dModel.modelAnim:GetCurrentAnimatorStateInfo(0)
        if self.clickAnimName and animState:IsName(self.clickAnimName) then
            if animState and animState.normalizedTime > 0.95 then
                if self.clickAniTimer then
                    TimerUtility.StopAndRecycle(self.clickAniTimer)
                    self.clickAniTimer = nil
                end
                self.isPlayAni = false
            end
        end
    end
end

function UIPetMediator:Play3DModelBgAnim()
    if (not self.ui3dModel) then
        return
    end
    local anim = self.ui3dModel.curEnvGo.transform:Find("vx_w_hero_main/all/vx_ui_hero_main"):GetComponent(typeof(CS.UnityEngine.Animation))
    if (anim) then
        if (not self._bgAnimOpened) then
            anim:Play("anim_vx_w_hero_main_open")
            self._bgAnimOpened = true
        else
            anim:Play("anim_vx_w_hero_main_loop")
        end
    end
end

--- 获取3D相机参数
---@param self UIPetMediator
function UIPetMediator:Get3DCameraSettings()
    local cameraSetting = {}
    for i = 1, 2 do
        local setting = {}
        setting.fov = 3
        setting.nearCp = 40
        setting.farCp = 48
        if i == 1 then
            setting.localPos = CS.UnityEngine.Vector3(-0.3, 3.65, -43.87342)
        else
            setting.localPos = CS.UnityEngine.Vector3(0.5, 3.65, -43.87342)
        end
        cameraSetting[i] = setting
    end
    return cameraSetting
end

function UIPetMediator.SortPetDataByRarity(a, b)
    if (a.isInTroop ~= b.isInTroop) then
        return a.isInTroop
    elseif (a.rarity ~= b.rarity) then
        return a.rarity > b.rarity
    elseif (a.level ~= b.level) then
        return a.level > b.level
    elseif (a.rank ~= b.rank) then
        return a.rank > b.rank
    else
        return a.cfgId < b.cfgId
    end
end

function UIPetMediator.SortPetDataByLevel(a, b)
    if (a.isInTroop ~= b.isInTroop) then
        return a.isInTroop
    elseif (a.fixedSkillLevel ~= b.fixedSkillLevel) then
        return a.fixedSkillLevel > b.fixedSkillLevel
    elseif (a.rarity ~= b.rarity) then
        return a.rarity > b.rarity
    elseif (a.rank ~= b.rank) then
        return a.rank > b.rank
    else
        return a.cfgId < b.cfgId
    end
end

function UIPetMediator.SortPetDataByRank(a, b)
    if (a.isInTroop ~= b.isInTroop) then
        return a.isInTroop
    elseif (a.rank ~= b.rank) then
        return a.rank > b.rank
    elseif (a.rarity ~= b.rarity) then
        return a.rarity > b.rarity
    elseif (a.level ~= b.level) then
        return a.level > b.level
    else
        return a.cfgId < b.cfgId
    end
end

function UIPetMediator:OnModelDrag(go, eventData)
    if (self.ui3dModel) then
        self.ui3dModel:RotateModelY(eventData.delta.x * -0.5)
    end
end

function UIPetMediator:OnBackButtonClick()
    g_Game.UIManager:CloseUI3DView(self:GetRuntimeId())
    TimerUtility.DelayExecute(function()
        self:BackToPrevious()
    end, 0.1)
end

function UIPetMediator:ClearEffectTimer()
    if self.levelEffectTime1 then
        TimerUtility.StopAndRecycle(self.levelEffectTime1)
        self.levelEffectTime1 = nil
    end
    if self.levelEffectTime2 then
        TimerUtility.StopAndRecycle(self.levelEffectTime2)
        self.levelEffectTime2 = nil
    end
    if self.levelEffectTime3 then
        TimerUtility.StopAndRecycle(self.levelEffectTime3)
        self.levelEffectTime3 = nil
    end
    if self.levelEffectTime4 then
        TimerUtility.StopAndRecycle(self.levelEffectTime4)
        self.levelEffectTime4 = nil
    end
end

function UIPetMediator:OnPetLevelUp()
    if self.ui3dModel then
        if self.ui3dModel.curVfxPath[1] ~= "vfx_level_hero_shengji" then
            self.ui3dModel:SetupVfx("vfx_level_hero_shengji")
        else
            local vfx = self.ui3dModel.curVfxGo[1]
            if vfx then
                vfx:SetVisible(false)
                vfx:SetVisible(true)
            end
        end
        -- self.ui3dModel:ChangeRenderMaterial("EnhanceHalfTone", "mat_beijing_s_new3")
        -- self.ui3dModel:ChangeRenderMaterial("EnhanceOutline", "mat_level_hero_shengji_fresnel_01")
        self.ui3dModel:ChangeCameraOpaqueState(true)
        self.levelEffectTime1 = TimerUtility.DelayExecute(function()
            self.ui3dModel:ChangeCameraRenderer2HalfTone()
            -- self.ui3dModel:ChangeRenderMaterial("EnhanceHalfTone", "mat_beijing_s_new1")
            -- self.ui3dModel:ChangeRenderMaterial("EnhanceOutline", "mat_level_hero_shengji_fresnel_01")
        end, 0.35)
        self.levelEffectTime2 = TimerUtility.DelayExecute(function()
            -- self.ui3dModel:ChangeRenderMaterial("EnhanceHalfTone", "mat_beijing_s_new2")
            -- self.ui3dModel:ChangeRenderMaterial("EnhanceOutline", "mat_level_hero_shengji_fresnel_02")
            self.ui3dModel:PlayCameraShake(CS.UnityEngine.Vector3.up, 2, 0.5)
        end, 0.55)
        self.levelEffectTime3 = TimerUtility.DelayExecute(function()
            -- self.ui3dModel:ChangeRenderMaterial("EnhanceHalfTone", "mat_beijing_s_new3")
            -- self.ui3dModel:ChangeRenderMaterial("EnhanceOutline", "mat_level_hero_shengji_fresnel_01")
        end, 0.68)
        self.levelEffectTime4 = TimerUtility.DelayExecute(function()
            self.ui3dModel:ChangeCameraRenderer2Normal()
            self.ui3dModel:ChangeCameraOpaqueState(false)
            self.ui3dModel:ClearMaterial()
        end, 0.75)
    end
    self:RefreshPetLevelInfo()
    self:RefreshPetList()
    self.tablePetList:SetToggleSelect(self._petData[self._selectedId])

    local unlockSkillLevel1 = ConfigRefer.PetConsts:PetExtraSkillUnlockLevel(1)
    local unlockSkillLevel2 = ConfigRefer.PetConsts:PetExtraSkillUnlockLevel(2)
    if self._petData[self._selectedId].level == unlockSkillLevel1 or self._petData[self._selectedId].level == unlockSkillLevel2 then
        self:RefreshPetSkill()
    end

    self.clickedLevelUp = false
end

function UIPetMediator:OnBindHeroButtonClick()
    local pet = ModuleRefer.PetModule:GetPetByID(self._selectedId)
    if (pet and pet.BindHeroId and pet.BindHeroId > 0) then
        local heroCfg = ConfigRefer.Heroes:Find(pet.BindHeroId)
        if (heroCfg) then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("pet_already_bound_des", I18N.Get(heroCfg:Name())))
        end
    end
end

function UIPetMediator:OnClickChangePetName()
    ModuleRefer.PetModule:RenamePet(self._selectedId)
end

function UIPetMediator:OnClickPetFusion()

end

function UIPetMediator:OnClickFold()
    self.isFold = not self.isFold
    self.p_pet_list_status:SetState(self.isFold and 0 or 1)
end

function UIPetMediator:OnClickGene()
    local pet = ModuleRefer.PetModule:GetPetByID(self._selectedId)
    if #pet.PetGeneInfo == 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('pet_gene_none_tips'))
        return
    end
    g_Game.UIManager:Open(UIMediatorNames.PetGeneMediator, pet)
end

function UIPetMediator:OnClickDetail()
    g_Game.UIManager:Open(UIMediatorNames.UIPetMainPopupMediator, {petId = self._selectedId})
end

function UIPetMediator:OnSkillButtonClick()
    g_Game.UIManager:Open(UIMediatorNames.UIPetSkillMediator, {isLearnPanel = true})
end

function UIPetMediator:OnLockButtonClick()
    local params = SetPetIsLockParameter.new()
    local petId = self._selectedId
    params.args.PetCompId = petId
    params.args.Value = not ModuleRefer.PetModule:IsPetLocked(petId)
    params:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, resp)
        if (suc) then
            self:RefreshLockState(petId)
            g_Game.EventManager:TriggerEvent(EventConst.PET_REFRESH_UNLOCK_STATE, petId)
        end
    end)
end

function UIPetMediator:RefreshLockState(petId)
    local isLocked = ModuleRefer.PetModule:IsPetLocked(petId)
    self.goIconLock:SetVisible(isLocked)
    self.goIconUnlock:SetVisible(not isLocked)
end

function UIPetMediator:GotoPetBook()
    g_Game.UIManager:CloseUI3DView(self:GetRuntimeId())
    g_Game.UIManager:Open(UIMediatorNames.PetBookMediator)
    ModuleRefer.FPXSDKModule:TrackCustomBILog("pet_book_mediator")
    -- g_Game.UIManager:CloseByName("UIPetMediator")
end

function UIPetMediator:RefreshRedPoint()
    ModuleRefer.PetModule:RefreshLevelUpRedDots(true)
    ModuleRefer.PetModule:RefreshSkillRedDots(true)
    local unlock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(ConfigRefer.PetConsts:PetHandbookUnlock())
    self.petBookBtn:SetVisible(unlock)
    if unlock then
        self.notifyNode.redDot:SetVisible(ModuleRefer.PetCollectionModule:GetStoryRedPoint())
        -- self.notifyNode.redNew:SetVisible(ModuleRefer.PetCollectionModule:GetStoryRedPoint())
    end

    local receiveNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PetSkillReceive", NotificationType.PET_SKILL_RECEIVE)
    ModuleRefer.NotificationModule:AttachToGameObject(receiveNode, self.child_reddot_default_skill.go, self.child_reddot_default_skill.redNew)
end

-- 筛选
function UIPetMediator:InitFilter()
    self.isOpenFilter = false
    self.pool_filter_style:HideAll()
    self.pool_filter_quality:HideAll()
    self.pool_filter_level:HideAll()

    self.filterQuality = {}
    self.filterLevel = {}
    self.filterStyle = {}

    self.filterQualityIndex = 0
    self.filterLevelIndex = 0
    self.filterStyleIndex = 0

    self.p_btn_all_quality_Status:SetState(1)
    self.p_btn_all_lv_Status:SetState(1)
    self.p_btn_all_style_Status:SetState(1)

    -- TODO: 筛选先写死
    -- 3品质
    for i = 1, 3 do
        local param = {}
        param.index = i
        param.icon = "sp_item_frame_circle_s_" .. i + 2
        param.onClick = Delegate.GetOrCreate(self, self.OnClickFilterQuality)
        param.filterStyle = FILTER_STYLE.Rarity
        local item = self.pool_filter_quality:GetItem().Lua
        item:FeedData(param)
        self.filterQuality[i] = item
    end

    -- 6星星
    for i = 1, 6 do
        local param = {}
        param.index = i
        param.icon = "sp_comp_icon_star"
        param.text = i
        param.onClick = Delegate.GetOrCreate(self, self.OnClickFilterLevel)
        param.filterStyle = FILTER_STYLE.Rank
        local item = self.pool_filter_level:GetItem().Lua
        item:FeedData(param)
        self.filterLevel[i] = item
    end

    -- 5风格
    local styleCfg = ConfigRefer.AssociatedTag
    for i = 1, styleCfg.length do
        local param = {}
        param.index = i
        param.icon = ArtResourceUtils.GetUIItem(styleCfg:Find(i):Icon())
        param.onClick = Delegate.GetOrCreate(self, self.OnClickFilterStyle)
        param.filterStyle = FILTER_STYLE.Style
        local item = self.pool_filter_style:GetItem().Lua
        item:FeedData(param)
        self.filterStyle[i] = item
    end

    self:RefreshFilter()
end

function UIPetMediator:RefreshFilter()
    -- self.p_btn_open:SetVisible(not self.isOpenFilter)
    -- self.p_btn_close:SetVisible(self.isOpenFilter)
    -- self.p_lv_layout:SetVisible(self.isOpenFilter)

    self.p_btn_open:SetVisible(false)
    self.p_btn_close:SetVisible(false)
end

function UIPetMediator:OnClickFilter()
    self.isOpenFilter = not self.isOpenFilter
    self:RefreshFilter()
end

function UIPetMediator:OnClickFilterQuality(index)
    if index == nil then
        index = 0
        self.p_btn_all_quality_Status:SetState(1)
    else
        self.p_btn_all_quality_Status:SetState(0)
    end
    self._filterQuality = index
    for k, v in pairs(self.filterQuality) do
        if v.index ~= index then
            v:IsSelect(false)
        else
            v:IsSelect(true)
        end
    end
    self:RefreshPetList()
end

function UIPetMediator:OnClickFilterLevel(index)
    if index == nil then
        index = 0
        self.p_btn_all_lv_Status:SetState(1)
    else
        self.p_btn_all_lv_Status:SetState(0)
    end
    self.filterRank = index
    for k, v in pairs(self.filterLevel) do
        if v.index ~= index then
            v:IsSelect(false)
        else
            v:IsSelect(true)
        end
    end
    self:RefreshPetList()
end
function UIPetMediator:OnClickFilterStyle(index)
    if index == nil then
        index = 0
        self.p_btn_all_style_Status:SetState(1)
    else
        self.p_btn_all_style_Status:SetState(0)
    end
    self._filterStyle = index

    for k, v in pairs(self.filterStyle) do
        if v.index ~= index then
            v:IsSelect(false)
        else
            v:IsSelect(true)
        end
    end
    self:RefreshPetList()
end

function UIPetMediator:RefreshPetSkill()
    local pet = ModuleRefer.PetModule:GetPetByID(self._selectedId)
    if not pet then
        return
    end

    local petCfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
    self.skills = {}
    -- 第一固有技能 读SLGSkillID(2)
    local skillId = petCfg:SLGSkillID(2)
    if (skillId and skillId > 0) then
        local slgSkillCell = ConfigRefer.SlgSkillInfo:Find(skillId)
        local data = {
            index = skillId,
            skillId = slgSkillCell:SkillId(),
            skillLevel = pet.SkillLevels[1],
            isPetFix = true,
            isLock = false,
            quality = petCfg:Quality(),
            clickCallBack = function()
                g_Game.UIManager:Open(UIMediatorNames.UICommonPopupCardDetailMediator, {isPetFix = true, type = 2, cfgId = slgSkillCell:SkillId(), level = pet.SkillLevels[1]})
            end,
        }
        self.skill1:FeedData(data)
        table.insert(self.skills, skillId)
    end

    -- 第二三技能找数据
    local skills = pet.PetInfoWrapper.LearnedSkill
    for i = 1, 2 do
        local unlockLevel = ConfigRefer.PetConsts:PetExtraSkillUnlockLevel(i)
        local skillId = skills and skills[i] or nil
        local level = ModuleRefer.PetModule:GetSkillLevel(self._selectedId, false, skills[i])
        local cellIndex = i
        local isLock = pet.Level < unlockLevel
        local data = {
            petId = self._selectedId,
            index = skillId,
            skillId = skillId,
            unlockLevel = unlockLevel,
            cellIndex = cellIndex,
            skillLevel = level,
            isPet = true,
            isAdd = (skillId == nil or skillId == 0) and not isLock,
            isLock = isLock,
            quality = petCfg:Quality(),
            clickCallBack = Delegate.GetOrCreate(self, self.OnSkillClick),
        }
        if i == 1 then
            self.skill2:FeedData(data)
            self.p_group_lock_1:SetVisible(isLock)
        elseif i == 2 then
            self.skill3:FeedData(data)
            self.p_group_lock_2:SetVisible(isLock)
        end
        table.insert(self.skills, skillId)

        local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PetSkill_" .. self._selectedId .. "_" .. i, NotificationType.PET_SKILL_CELL)
        ModuleRefer.NotificationModule:AttachToGameObject(node, self.skillRedDots[i].go, self.skillRedDots[i].redDot)
    end

    local isInTroop = ModuleRefer.TroopModule:GetPetBelongedTroopIndex(pet.ID) ~= 0
    self.skill2:PlaySkillAddVfx(isInTroop)
    self.skill3:PlaySkillAddVfx(isInTroop)
end

function UIPetMediator:OnSkillClick(param)
    if param == nil then
        return
    end

    if param.isAdd then
        local pet = ModuleRefer.PetModule:GetPetByID(self._selectedId)
        local data = {}
        data.isEquip = true
        data.pet = pet
        data.cellIndex = param.cellIndex
        g_Game.UIManager:Open(UIMediatorNames.UIPetSkillMediator, data)
    elseif param.isLock then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("pet_skill_slot_unlock_tips", param.unlockLevel))
    else
        g_Game.UIManager:Open(UIMediatorNames.UICommonPopupCardDetailMediator, {petId = param.petId, type = 6, cfgId = param.skillId, skillLevel = param.skillLevel, cellIndex = param.cellIndex})
    end
end

-- 失去宠物时，刷新
function UIPetMediator:GetNewPet(entity, changedTable)
    if changedTable and changedTable.Remove then
        self:RefreshPetList(true)
        self.tablePetList:SetToggleSelect(self._petData[self._selectedId])
        self:RefreshSelectedPet()
        self:RefreshStars()

        local total = ConfigRefer.PetConsts:PetMaxCount()
        local cur = ModuleRefer.PetModule:GetPetCount()
        self.p_text_pet_book.text = I18N.GetWithParams(cur .. "/" .. total)
        return
    end
end

return UIPetMediator
