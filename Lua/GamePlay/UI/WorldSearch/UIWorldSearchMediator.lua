local BaseUIMediator = require ('BaseUIMediator')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')

local KingdomMapUtils = require("KingdomMapUtils")
local Delegate = require('Delegate')
local HUDConst = require('HUDConst')
local EventConst = require('EventConst')
local GuideFingerUtil = require('GuideFingerUtil')
local SearchEntityType = require('SearchEntityType')
local HUDMediatorPartDefine = require('HUDMediatorPartDefine')
local AudioConsts = require("AudioConsts")
local KingdomConstant = require("KingdomConstant")
local UIMediatorNames = require("UIMediatorNames")
local MapBuildingType = require("MapBuildingType")
local SearchCategory = require("SearchCategory")
local OutputResourceType = require("OutputResourceType")

local MapUtils = CS.Grid.MapUtils

local SearchEntityParameter = require('SearchEntityParameter')



---@class UIWorldSearchMediator : BaseUIMediator
---@field super BaseUIMediator
---@field compChildSetBar CommonNumberSlider
---@field petStatus number
---@field currentState UIWorldSearchState
---@field states table<number, UIWorldSearchState>
---@field searchTypeMap table<number, number>
---@field searchCategoryMap table<number, number>
---@field resourceOutputMap table<number, number>
local UIWorldSearchMediator = class('UIWorldSearchMediator', BaseUIMediator)

---@class UIWorldSearchMediatorParam
---@field selectType number
---@field searchLv number

function UIWorldSearchMediator:OnCreate()
    self.btnBase = self:Button('p_base', Delegate.GetOrCreate(self, self.OnClickClose))
    self.goContent = self:GameObject('p_content')
    self.textSelectLevel = self:Text('p_text_select_level', I18N.Get("searchentity_tips_selectlv"))
    self.textInputQuantity = self:Text('p_text_input_quantity')
    self.compChildSetBar = self:LuaObject('child_set_bar')
    self.p_text_tips = self:Text('p_text_tips')
    self.p_btn_search = self:LuaObject('p_btn_search')
    self.p_table_type = self:TableViewPro('p_table_type')

    self.p_reward = self:GameObject("p_reward")
    self.p_text_reward = self:Text('p_text_reward', I18N.Get("searchentity_info_possible_reward"))
    self.p_table_reward = self:TableViewPro('p_table_reward')

    self.p_search_pet = self:GameObject("p_search_pet")
    self.p_text_pet = self:Text("p_text_pet", I18N.Get("searchentity_info_searchable"))
    self.p_table_pet = self:TableViewPro('p_table_pet')
    self.p_btn_detail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnPetDetailClicked))

    self.p_search_resources = self:GameObject("p_search_resources")
    self.p_text_resources = self:Text("p_text_resources", I18N.Get("searchentity_info_searchable"))
    self.p_table_resources = self:TableViewPro('p_table_resources')

    self.p_search_egg = self:GameObject("p_search_egg")
    self.p_text_egg = self:Text("p_text_egg", I18N.Get("mining_info_may_hatch"))
    self.p_text_egg_collect = self:Text("p_text_egg_collect", I18N.Get("mining_info_may_hatch"))
    self.p_text_egg_collect_quantity = self:Text("p_text_egg_collect_quantity")
    self.p_table_egg = self:TableViewPro('p_table_egg')

    self.states = {}
    self.searchTypeMap =
    {
        [SearchEntityType.NormalMob] = SearchCategory.Monster,
        [SearchEntityType.EliteMob] = SearchCategory.Pet,
        [SearchEntityType.ResourceField] = nil,
        [SearchEntityType.Pet] = SearchCategory.ResourcePetEgg,
    }
    self.searchCategoryMap =
    {
        [SearchCategory.Monster] = SearchEntityType.NormalMob,
        [SearchCategory.Pet] = SearchEntityType.EliteMob,
        [SearchCategory.ResourcePetEgg] = SearchEntityType.ResourceField,
        [SearchCategory.ResourceWood] = SearchEntityType.ResourceField,
        [SearchCategory.ResourceStone] = SearchEntityType.ResourceField,
        [SearchCategory.ResourceFood] = SearchEntityType.ResourceField,
    }
    self.resourceOutputMap =
    {
        [OutputResourceType.PetEgg] = SearchCategory.ResourcePetEgg,
        --[OutputResourceType.LoggingCamp] = SearchCategory.ResourceWood,
        --[OutputResourceType.StoneCamp] = SearchCategory.ResourceStone,
        --[OutputResourceType.Farm] = SearchCategory.ResourceFood,
    }
end

function UIWorldSearchMediator:OnOpened(param)
    g_Game.UIManager:CloseAllExceptByType({
        g_Game.UIManager.CSUIMediatorType.Hud,
        g_Game.UIManager.CSUIMediatorType.Dialog,
        g_Game.UIManager.CSUIMediatorType.SystemMsg,
    })
    
    g_Game.EventManager:AddListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self,self.OnLodChanged))
    g_Game.EventManager:AddListener(EventConst.HUD_STATE_CHANGED, Delegate.GetOrCreate(self,self.OnCityStateChanged))
    g_Game.EventManager:AddListener(EventConst.WORLD_SEARCH_TYPE, Delegate.GetOrCreate(self,self.OnChangeSelectType))
    g_Game.ServiceManager:AddResponseCallback(SearchEntityParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetSearchResults))

    g_Game.EventManager:TriggerEvent(EventConst.CHANG_SEARCH_PANEL_STATE, true)
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allBottom, false)
    
    ---@type BistateButtonSmallParam
    local upButton = {}
    upButton.buttonText = I18N.Get("searchentity_btn_search")
    upButton.onClick = Delegate.GetOrCreate(self, self.OnClickSearchBtn)
    self.p_btn_search:FeedData(upButton)
    
    self:InitializeStates()
    self:RefreshTypeList()

    local searchCategory
    local searchType
    local searchLv
    if param and param.selectType then
        searchCategory = self:GetSearchCategoryByType(param.selectType)
        searchType = param.selectType
        searchLv = param.searchLv
    else
        searchCategory = ModuleRefer.WorldSearchModule:GetSearchCategory()
    end
    self.p_table_type:SetToggleSelectIndex(searchCategory - 1)
    self:OnChangeSelectType(searchCategory, searchType, searchLv)
end

function UIWorldSearchMediator:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self,self.OnLodChanged))
    g_Game.EventManager:RemoveListener(EventConst.HUD_STATE_CHANGED, Delegate.GetOrCreate(self,self.OnCityStateChanged))
    g_Game.EventManager:RemoveListener(EventConst.WORLD_SEARCH_TYPE, Delegate.GetOrCreate(self,self.OnChangeSelectType))
    g_Game.ServiceManager:RemoveResponseCallback(SearchEntityParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetSearchResults))

    g_Game.EventManager:TriggerEvent(EventConst.CHANG_SEARCH_PANEL_STATE, false)
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allBottom, true)
    
    self:ReleaseStates()
    self.currentState = nil
end

function UIWorldSearchMediator:RefreshTypeList()
    ---@type WorldSearchCellData[]
    local dataList = {}
    for _, config in ConfigRefer.SearchType:ipairs() do
        local type = config:Type()
        local category = self:GetSearchCategoryByType(type)
        if category then
            ---@type WorldSearchCellData
            local single = {}
            single.icon = config:Icon()
            single.category = category
            single.type = type
            single.name = config:ShowName()
            table.insert(dataList, single)
        end
    end

    local petEggSearchTypeConfig = ModuleRefer.WorldSearchModule:GetSearchTypeConfig(SearchEntityType.ResourceField)
    local petEggIcon = petEggSearchTypeConfig:Icon()

    local resourceConfigList = ModuleRefer.WorldSearchModule:GetSearchResourceFieldsConfigs()
    for _, config in ipairs(resourceConfigList) do
        local outputType = config:OutputType()
        local category = self:GetSearchCategoryByOutput(outputType)
        if category then
            ---@type WorldSearchCellData
            local single = {}
            single.icon = petEggIcon
            single.category = category
            single.type = SearchEntityType.ResourceField
            single.name = config:Name()
            table.insert(dataList, single)
        end
    end
    table.sort(dataList, function(a, b) 
        return a.category < b.category
    end)

    self.p_table_type:Clear()
    for _, data in ipairs(dataList) do
        self.p_table_type:AppendData(data)
    end
    self.p_table_type:RefreshAllShownItem()
end

function UIWorldSearchMediator:InitializeStates()
    self.states[SearchCategory.Monster] = require("UIWorldSearchStateMonster").new()
    self.states[SearchCategory.Pet] = require("UIWorldSearchStatePet").new()
    self.states[SearchCategory.ResourcePetEgg] = require("UIWorldSearchStatePetEgg").new()
    self.states[SearchCategory.ResourceWood] = require("UIWorldSearchStateResourceField").new()
    self.states[SearchCategory.ResourceStone] = require("UIWorldSearchStateResourceField").new()
    self.states[SearchCategory.ResourceFood] = require("UIWorldSearchStateResourceField").new()
end

function UIWorldSearchMediator:ReleaseStates()
    for _, state in pairs(self.states) do
        state:Unselect()
    end
    table.clear(self.states)
end

function UIWorldSearchMediator:SetState(searchCategory)
    if self.currentState and self.currentState:GetSearchCategory() == searchCategory then
        return
    end

    if self.currentState then
        self.currentState:Unselect()
    end
    
    local state = self.states[searchCategory]
    local data = self:CreateStateData(searchCategory)
    if state and data then
        state:Select(self, data)
        self.currentState = state
    end
end

function UIWorldSearchMediator:SetLevel(searchLevel)
    if self.currentState then
        self.currentState:SetLevel(searchLevel)
    end
end

function UIWorldSearchMediator:CreateStateData(category)
    if category == SearchCategory.Monster then
        local monsterConfigs = ModuleRefer.WorldSearchModule:GetSearchMonsterConfigs()
        return monsterConfigs
    elseif category == SearchCategory.ResourcePetEgg then
        ---@type UIWorldSearchStateResourceFieldParameter
        local param = {}
        param.category = SearchCategory.ResourcePetEgg
        param.outputType = OutputResourceType.LoggingCamp
        param.resourceFieldConfigList = ModuleRefer.KingdomConstructionModule:GetFixedBuildingConfigsByType(MapBuildingType.Resource)
        return param
    elseif category == SearchCategory.ResourceWood then
        ---@type UIWorldSearchStateResourceFieldParameter
        local param = {}
        param.category = SearchCategory.ResourceWood
        param.outputType = OutputResourceType.LoggingCamp
        param.resourceFieldConfigList = ModuleRefer.KingdomConstructionModule:GetFixedBuildingConfigsByType(MapBuildingType.Resource)
        return param
    elseif category == SearchCategory.ResourceStone then
        ---@type UIWorldSearchStateResourceFieldParameter
        local param = {}
        param.category = SearchCategory.ResourceStone
        param.outputType = OutputResourceType.StoneCamp
        param.resourceFieldConfigList = ModuleRefer.KingdomConstructionModule:GetFixedBuildingConfigsByType(MapBuildingType.Resource)
        return param
    elseif category == SearchCategory.ResourceFood then
        ---@type UIWorldSearchStateResourceFieldParameter
        local param = {}
        param.category = SearchCategory.ResourceFood
        param.outputType = OutputResourceType.Farm
        param.resourceFieldConfigList = ModuleRefer.KingdomConstructionModule:GetFixedBuildingConfigsByType(MapBuildingType.Resource)
        return param
    elseif category == SearchCategory.Pet then
        local petConfigs = ModuleRefer.WorldSearchModule:GetSearchPetMonsterConfigs()
        return petConfigs
    end
end

function UIWorldSearchMediator:OnChangeSelectType(searchCategory, searchType, searchLevel)
    ModuleRefer.WorldSearchModule:RecordSearchCategory(searchCategory)
    
    self.p_table_type:SetToggleSelectIndex(searchCategory - 1)
    local cell = self.p_table_type:GetCell(searchCategory - 1)
    local infoPosition = self.goContent.transform.position
    infoPosition = CS.UnityEngine.Vector3(cell.transform.position.x, infoPosition.y, infoPosition.z)
    self.goContent.transform.position = infoPosition
    
    if searchLevel then
        ModuleRefer.WorldSearchModule:RecordSearchLevel(ModuleRefer.WorldSearchModule:GetSearchCategory(), searchLevel)
    else
        searchLevel = ModuleRefer.WorldSearchModule:GetSearchLevel(searchCategory)
    end

    self:SetState(searchCategory)
    self:SetLevel(searchLevel)

    local maxAttackLevel, maxLevel = self.currentState:GetMaxLevels()
    if maxLevel < 0 then
        return
    end
    
    ---@type CommonNumberSliderData
    local setBarData = {}
    setBarData.minNum = 1
    setBarData.maxNum = math.min(maxAttackLevel, maxLevel)
    setBarData.oneStepNum = 1
    setBarData.curNum = searchLevel
    setBarData.callBack = Delegate.GetOrCreate(self, self.OnValueChange)
    self.compChildSetBar:FeedData(setBarData)
    self:OnValueChange(searchLevel)
end

function UIWorldSearchMediator:OnValueChange(inputText)
    local level = tonumber(inputText)
    self:SetLevel(level)
    ModuleRefer.WorldSearchModule:RecordSearchLevel(ModuleRefer.WorldSearchModule:GetSearchCategory(), level)
end

function UIWorldSearchMediator:GetSelectedLevel()
    if not self.currentState then
        return nil
    end
    local maxAttackLevel, maxLevel = self.currentState:GetMaxLevels()
    local curNum = self.compChildSetBar.curNum
    return math.clamp(curNum, 1, maxAttackLevel)
end

--function UIWorldSearchMediator:OnReachMaxAttackLevel()
--    if self.currentState then
--        local hintText = self.currentState:GetReachMaxAttackLevelTip()
--        ModuleRefer.ToastModule:AddSimpleToast(hintText)
--    end
--end

function UIWorldSearchMediator:OnClickSearchBtn()
    local searchCategory = ModuleRefer.WorldSearchModule:GetSearchCategory()
    local searchType = self:GetSearchType(searchCategory)
    local searchID = self.currentState and self.currentState:GetSelectedID()
    local searchLevel = self:GetSelectedLevel()

    if not searchID or not searchLevel then
        return
    end
    
    local position
    local searchDistance = ConfigRefer.ConstMain:SearchMobRadius() * KingdomMapUtils.GetStaticMapData().UnitsPerTileX
    if searchType == SearchEntityType.NormalMob then
        local mobCtrl = ModuleRefer.SlgModule.troopManager:FindLvMobCtrl(searchLevel, false, searchDistance)
        if mobCtrl then
            position = mobCtrl:GetPosition()
        end
    elseif searchType == SearchEntityType.Pet then
        local mobCtrl = ModuleRefer.SlgModule.troopManager:FindLvMobCtrl(searchLevel, true, searchDistance)
        if mobCtrl then
            position = mobCtrl:GetPosition()
        end
    end
    
    if position then
        self:FocusOnTarget(position)
        self:CloseSelf()
        return
    end
    
    local param = SearchEntityParameter.new()
    param.args.Param.SearchType = searchType
    param.args.Param.Level = searchLevel
    param.args.Param.MonsterClassType = searchID
    param:Send()
end

---@param isSuccess boolean
---@param reply wrpc.SearchEntityReply
---@param cmd wrpc.SearchEntityRequest
function UIWorldSearchMediator:OnGetSearchResults(isSuccess, reply, cmd)
    if not isSuccess then
        return
    end

    local result = reply.Result
    local entityId = result.EntityId
    local landCfgCell = ConfigRefer.Land:Find(result.TargetLandformId)
    if entityId == 0 then
        if landCfgCell then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("bw_toast_higher_circle", cmd.request.Param.Level, I18N.Get(landCfgCell:Name())))
            return
        end
        return
    end

    local x, y = KingdomMapUtils.ParseBuildingPos(result.Pos)
    local worldPos = MapUtils.CalculateCoordToTerrainPosition(x, y, KingdomMapUtils.GetMapSystem())
    self:FocusOnTarget(worldPos)

    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_se_world_monsterborn)

    self:CloseSelf()
end

function UIWorldSearchMediator:FocusOnTarget(worldPos)
    local camera = g_Game.SceneManager.current.basicCamera
    local curSize = camera:GetSize()
    local targetSize = KingdomMapUtils.GetCameraLodData().mapCameraEnterSize
    if curSize > targetSize then
        camera:LookAt(worldPos, 0.2, function() camera:ZoomTo(targetSize, 0.2, function() GuideFingerUtil.ShowGuideFingerByWorldPos(worldPos) end)  end)
    else
        camera:LookAt(worldPos, 0.2, function()  GuideFingerUtil.ShowGuideFingerByWorldPos(worldPos) end)
    end
end

function UIWorldSearchMediator:OnPetDetailClicked()
    g_Game.UIManager:Open(UIMediatorNames.LandformIntroUIMediator)
end

function UIWorldSearchMediator:OnLodChanged(oldLod, newLod)
    if newLod > KingdomConstant.LowLod then
        self:CloseSelf()
    end
end

function UIWorldSearchMediator:OnCityStateChanged(hudState)
    if hudState == HUDConst.HUD_STATE.CITY then
        self:CloseSelf()
    end
end

function UIWorldSearchMediator:OnClickClose()
    self:CloseSelf()
end

function UIWorldSearchMediator:GetSearchCategoryByType(searchType)
    local category = self.searchTypeMap[searchType]
    return category
end

function UIWorldSearchMediator:GetSearchCategoryByOutput(OutputResourceType)
    local category = self.resourceOutputMap[OutputResourceType]
    --if not category then
    --    g_Logger.Error(("invalid output type: %s"):format(OutputResourceType))
    --end
    return category
end

function UIWorldSearchMediator:GetSearchType(searchCategory)
    local type = self.searchCategoryMap[searchCategory]
    if not type then
        g_Logger.Error(("invalid search category: %s"):format(searchCategory))
    end
    return type
end

return UIWorldSearchMediator