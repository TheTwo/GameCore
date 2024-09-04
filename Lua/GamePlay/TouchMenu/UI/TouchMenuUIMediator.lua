---Scene Name : scene_common_touch_menu_detail
local BaseUIMediator = require ('BaseUIMediator')
local UIMediatorNames = require('UIMediatorNames')
local Delegate = require('Delegate')
local EventConst = require("EventConst")
local KingdomMapUtils = require("KingdomMapUtils")
local UIHelper = require("UIHelper")
local TileHighLightMap = require("TileHighLightMap")
local Utils = require("Utils")
local ChatShareType = require("ChatShareType")
local TouchMenuMainBtnDatum = require("TouchMenuMainBtnDatum")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local Vector3 = CS.UnityEngine.Vector3

---@class TouchMenuUIMediator:BaseUIMediator
local TouchMenuUIMediator = class('TouchMenuUIMediator', BaseUIMediator)

function TouchMenuUIMediator.OpenSingleton(uiData)
    if g_Game.UIManager:IsOpenedByName(UIMediatorNames.TouchMenuUIMediator) then
        g_Game.UIManager:CloseAllByName(UIMediatorNames.TouchMenuUIMediator)
    else
        g_Game.UIManager:Open(UIMediatorNames.TouchMenuUIMediator, uiData)
    end
end

function TouchMenuUIMediator.CloseSingleton()
    if g_Game.UIManager:IsOpenedByName(UIMediatorNames.TouchMenuUIMediator) then
        g_Game.UIManager:CloseAllByName(UIMediatorNames.TouchMenuUIMediator)
    end
end

---@param param TouchMenuUIDatum
function TouchMenuUIMediator:OnCreate(param)
    self._p_root = self:GameObject("p_root")

    --- Root
    self._p_city_info = self:RectTransform("p_city_info")
    self._p_background = self:GameObject("p_background")
    self:PointerClick("p_background", Delegate.GetOrCreate(self, self.CloseSelf))

    --- Arrows
    self._p_icon_arrow_n = self:GameObject("p_icon_arrow_n")
    self._p_icon_arrow_s = self:GameObject("p_icon_arrow_s")
    self._p_icon_arrow_e = self:GameObject("p_icon_arrow_e")
    self._p_icon_arrow_w = self:GameObject("p_icon_arrow_w")

    --- Header
    self._child_touch_menu_name = self:LuaBaseComponent("child_touch_menu_name")
    self._child_touch_menu_se = self:LuaBaseComponent("child_touch_menu_se")

    -- --- Templates
    -- self._p_pair = self:LuaBaseComponent("p_pair")
    -- self._p_pair_time = self:LuaBaseComponent("p_pair_time")
    -- self._p_pair_resource = self:LuaBaseComponent("p_pair_resource")
    -- self._p_text = self:LuaBaseComponent("p_text")
    -- self._p_task = self:LuaBaseComponent("p_task")
    -- self._p_progress = self:LuaBaseComponent("p_progress")
    -- self._p_reward = self:LuaBaseComponent("p_reward")
    -- self._p_se_monsters = self:LuaBaseComponent("p_se_monsters")
    -- self._p_league = self:LuaBaseComponent("p_league")
    -- self._p_buff = self:LuaBaseComponent("p_buff")
    -- self._p_reward_pair = self:LuaBaseComponent("p_reward_pair")
    -- self._p_pair_special = self:LuaBaseComponent("p_pair_special")
    -- self._p_mission = self:LuaBaseComponent('p_mission')
    -- self._p_behemoth_state = self:LuaBaseComponent('p_behemoth_state')
    -- self._p_behemoth_skill = self:LuaBaseComponent('p_behemoth_skill')
    -- self._p_behemoth_earnings = self:LuaBaseComponent('p_behemoth_earnings')
    -- self._p_behemoth_now = self:LuaBaseComponent('p_behemoth_now')

    ---@type table<number, {name:string, parent:string, onloaded:fun(go:CS.UnityEngine.GameObject)}>
    self._compLoadWrap = {
        [0] = {name = "child_touch_menu_pair", onloaded = Delegate.GetOrCreate(self, self._p_pair_loaded)},
        [1] = {name = "child_touch_menu_pair_time", onloaded = Delegate.GetOrCreate(self, self._p_pair_time_loaded)},
        [2] = {name = "child_touch_menu_pair_resource_root", onloaded = Delegate.GetOrCreate(self, self._p_pair_resource_loaded)},
        [3] = {name = "child_touch_circle_group_text_root", onloaded = Delegate.GetOrCreate(self, self._p_text_loaded)},
        [4] = {name = "child_touch_circle_group_task", onloaded = Delegate.GetOrCreate(self, self._p_task_loaded)},
        [5] = {name = "child_touch_menu_progress", onloaded = Delegate.GetOrCreate(self, self._p_progress_loaded)},
        [6] = {name = "child_touch_menu_reward", onloaded = Delegate.GetOrCreate(self, self._p_reward_loaded)},
        [7] = {name = "child_touch_menu_monsters", onloaded = Delegate.GetOrCreate(self, self._p_se_monsters_loaded)},
        [8] = {name = "child_touch_menu_league", onloaded = Delegate.GetOrCreate(self, self.p_league_loaded)},
        [9] = {name = "child_touch_menu_buff", onloaded = Delegate.GetOrCreate(self, self.p_buff_loaded)},
        [10] = {name = "child_touch_menu_reward_pair", onloaded = Delegate.GetOrCreate(self, self._p_reward_pair_loaded)},
        [11] = {name = "child_touch_menu_pair_special", onloaded = Delegate.GetOrCreate(self, self._p_pair_special_loaded)},
        [12] = {name = "child_touch_menu_mission", onloaded = Delegate.GetOrCreate(self, self._p_mission_loaded)},
        [13] = {name = "child_touch_menu_behemoth_state", onloaded = Delegate.GetOrCreate(self, self._p_behemoth_state_loaded)},
        [14] = {name = "child_touch_menu_behemoth_skill", onloaded = Delegate.GetOrCreate(self, self._p_behemoth_skill_loaded)},
        [15] = {name = "child_touch_menu_behemoth_earnings", onloaded = Delegate.GetOrCreate(self, self._p_behemoth_earnings_loaded)},
        [16] = {name = "child_touch_menu_behemoth_now", onloaded = Delegate.GetOrCreate(self, self._p_behemoth_now_loaded)},
        [17] = {name = "child_touch_menu_landform", onloaded = Delegate.GetOrCreate(self, self._p_landform_loaded)},
    }

    --- ComponentRoots
    self._p_components = self:Transform("p_components")

    --- Overlap Component Detail Panel
    self._p_group_detail = self:GameObject("p_group_detail")
    self._p_text_detail = self:Text("p_text_detail")
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnCloseOverlapDetailPanel))

    --- Button Top Tips
    self._p_group_tips = self:GameObject("p_group_tips")
    self._p_icon_tips = self:Image("p_icon_tips")
    self._p_text_tips = self:Text("p_text_tips")
    self._p_btn_tips_detail = self:Button("p_btn_detail_tips", Delegate.GetOrCreate(self, self.OnClickBtnTipsDetail))
    self._child_comp_btn_detail_tips = self:GameObject('child_comp_btn_detail_tips')
    
    -- Power
    self._p_power = self:GameObject("p_power")
    self._p_text_power = self:Text("p_text_power")
    self._p_icon_status = self:Image("p_icon_status")

    --- Buttons
    self._p_btn_group_1 = self:GameObject("p_btn_group_1")
    self._p_btn_group_2 = self:GameObject("p_btn_group_2")
    ---@type CS.UnityEngine.GameObject[]
    self._buttonGroup = {self._p_btn_group_1, self._p_btn_group_2}

    self._p_templates = self:GameObject("p_templates")
    self._p_templates:SetActive(false)
    ---@type TouchMenuMainBtn
    self._p_group_btn_pink = self:LuaBaseComponent("p_group_btn_pink")
    ---@type TouchMenuMainBtnBlack
    self._p_group_btn_black = self:LuaBaseComponent("p_group_btn_black")
    self._buttons = {}
    ---@type table<number, CS.DragonReborn.UI.LuaBaseComponent>
    self._buttonTemplates = {
        [TouchMenuMainBtnDatum.Style.Pink] = self._p_group_btn_pink,
        [TouchMenuMainBtnDatum.Style.Black] = self._p_group_btn_black,
    }

    --- Polluted
    self._p_polluted_hint = self:GameObject("p_polluted_hint")
    self._p_polluted_icon = self:Image("p_polluted_icon")
    self._p_polluted_text_hint = self:Text("p_polluted_text_hint")

    --- Share
    self._p_btn_share = self:Button("p_btn_share", Delegate.GetOrCreate(self, self.OnShareClick))

    --- Mark
    self._p_btn_mark = self:Button("p_btn_mark", Delegate.GetOrCreate(self, self.OnClickBtnMark))
    self._p_btn_mark_status = self:StatusRecordParent("p_btn_mark")

    self._p_btn_release = self:Button("p_btn_release", Delegate.GetOrCreate(self, self.OnClickBtnRelease))
    
    --- defuse
    self._p_btn_defuse = self:Button("p_btn_defuse", Delegate.GetOrCreate(self, self.OnClickBtnDefuse))

    --- delete
    self._p_btn_delete = self:Button("p_btn_delete", Delegate.GetOrCreate(self, self.OnClickBtnDelete))
    self._p_btn_player_info = self:Button("p_btn_player_info", Delegate.GetOrCreate(self, self.OnClickBtnPlayerInfo))

    --- Toggle
    self._p_group_tab = self:GameObject("p_group_tab")
    self._p_toggle_btn_1 = self:LuaObject("p_toggle_btn_1")
    self._p_toggle_btn_2 = self:LuaObject("p_toggle_btn_2")
    ---@type TouchMenuPageToggle[]
    self._toggles = {self._p_toggle_btn_1, self._p_toggle_btn_2}

    --- VX
    self._vx_trigger = self:AnimTrigger("vx_trigger")
    self._arrowOffset = 28
    self._screenWidth = CS.UnityEngine.Screen.width
    self._screenHeight = CS.UnityEngine.Screen.height
    self._p_city_info:SetVisible(false)

    self:CollectPageNeedComponents(param)
    self:StartManualCreate()
end

---@param param TouchMenuUIDatum
function TouchMenuUIMediator:CollectPageNeedComponents(param)
    self.basicNeed = {}
    self.compNeed = {}
    for i, v in ipairs(param.pages) do
        -- if v.basic then
        --     self:CollectBasicNeedComponents(v.basic)
        -- end
        if v.compsData then
            for _, comp in ipairs(v.compsData) do
                self:CollectCompNeedComponents(comp)
            end
        end
    end
end

---@param basic TouchMenuBasicInfoDatum
function TouchMenuUIMediator:CollectBasicNeedComponents(basic)
    local compName = basic:GetCompName()
    if self.basicNeed[compName] then return end

    self.basicNeed[compName] = true
end

---@param comp TouchMenuCellDatumBase
function TouchMenuUIMediator:CollectCompNeedComponents(comp)
    local prefabIndex = comp:GetPrefabIndex()
    if self.compNeed[prefabIndex] then return end

    self.compNeed[prefabIndex] = true
end

function TouchMenuUIMediator:StartManualCreate()
    self.asyncHolder = {}
    for name, flag in pairs(self.basicNeed) do
        self:SetAsyncLoadFlag()
    end

    for prefabIdx, flag in pairs(self.compNeed) do
        self:SetAsyncLoadFlag()
    end

    for name, flag in pairs(self.basicNeed) do
        if name == "_child_touch_menu_se" then
            local holder = CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, "child_touch_menu_se", "Contents", Delegate.GetOrCreate(self, self._child_touch_menu_se_loaded),false)
            table.insert(self.asyncHolder, holder)
        elseif name == "_child_touch_menu_name" then
            local holder = CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, "child_touch_menu_name", "Contents", Delegate.GetOrCreate(self, self._child_touch_menu_name_loaded),false)
            table.insert(self.asyncHolder, holder)
        else
            g_Logger.ErrorChannel("TouchMenuUIMediator", "unknown basic component name: " .. name)
        end
    end

    for prefabIdx, flag in pairs(self.compNeed) do
        local loadWrap = self._compLoadWrap[prefabIdx]
        if loadWrap then
            local holder = CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, loadWrap.name, "p_template_root", loadWrap.onloaded,false)
            table.insert(self.asyncHolder, holder)
        else
            g_Logger.ErrorChannel("TouchMenuUIMediator", "unknown component prefab index: " .. prefabIdx)
        end
    end
end

---@param param TouchMenuUIDatum
function TouchMenuUIMediator:OnOpened(param)
    self._components = {
        [0] = self._p_pair,
        [1] = self._p_pair_time,
        [2] = self._p_pair_resource,
        [3] = self._p_text,
        [4] = self._p_task,
        [5] = self._p_progress,
        [6] = self._p_reward,
        [7] = self._p_se_monsters,
        [8] = self._p_league,
        [9] = self._p_buff,
        [10] = self._p_reward_pair,
        [11] = self._p_pair_special,
        [12] = self._p_mission,
        [13] = self._p_behemoth_state,
        [14] = self._p_behemoth_skill,
        [15] = self._p_behemoth_earnings,
        [16] = self._p_behemoth_now,
        [17] = self._p_landform,
    }

    self._p_city_info:SetVisible(true)
    self.param = param
    self.type = param.type
    self.currentData = self.param.pages[self.param.startPage]
    self.showToggle = self.param.pageCount > 1
    self._p_group_tab:SetActive(self.showToggle)
    self._p_background:SetActive(self.param.emptyClose == true)
    self.datum2Cell = {}
    self:UpdatePanel()
    self:AdjustCameraPos()

    g_Game.EventManager:AddListener(EventConst.TOUCH_MENU_UPDATE_BASIC, Delegate.GetOrCreate(self, self.OnUpdateBasicData))
    g_Game.EventManager:AddListener(EventConst.TOUCH_MENU_UPDATE_TABLE_CELL, Delegate.GetOrCreate(self, self.OnUpdateTableCell))
    g_Game.EventManager:AddListener(EventConst.TOUCH_MENU_APPEND_TABLE_CELL, Delegate.GetOrCreate(self, self.OnAppendTableCell))
    g_Game.EventManager:AddListener(EventConst.TOUCH_MENU_REMOVE_TABLE_CELL, Delegate.GetOrCreate(self, self.OnRemoveTableCell))
    g_Game.EventManager:AddListener(EventConst.TOUCH_MENU_UDPATE_GROUP_BTN, Delegate.GetOrCreate(self, self.OnUpdateGroupButton))
    g_Game.EventManager:AddListener(EventConst.TOUCH_MENU_UDPATE_ALL_GROUP_BTN, Delegate.GetOrCreate(self, self.OnUpdateAllGroupButton))
    g_Game.EventManager:AddListener(EventConst.TOUCH_MENU_SHOW_OVERLAP_DETAIL_PAENL, Delegate.GetOrCreate(self, self.OnShowOverlapDetailPanel))
    g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_START, Delegate.GetOrCreate(self, self.OnTimelineStartHideSelf))
    g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_STOP, Delegate.GetOrCreate(self, self.OnTimelineEndResumeSelf))
    g_Game.EventManager:AddListener(EventConst.BUBBLE_IN_MIST, Delegate.GetOrCreate(self, self.ShowMistUnlockTips))

    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdate))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function TouchMenuUIMediator:OnHide(param)
    BaseUIMediator.OnHide(self, param)
    if self.param and self.param.onHideCallBack then
        local c = self.param.onHideCallBack
        self.param.onHideCallBack = nil
        c()
    end
end

function TouchMenuUIMediator:OnClose(param)
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdate))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))

    g_Game.EventManager:RemoveListener(EventConst.TOUCH_MENU_UPDATE_BASIC, Delegate.GetOrCreate(self, self.OnUpdateBasicData))
    g_Game.EventManager:RemoveListener(EventConst.TOUCH_MENU_UPDATE_TABLE_CELL, Delegate.GetOrCreate(self, self.OnUpdateTableCell))
    g_Game.EventManager:RemoveListener(EventConst.TOUCH_MENU_APPEND_TABLE_CELL, Delegate.GetOrCreate(self, self.OnAppendTableCell))
    g_Game.EventManager:RemoveListener(EventConst.TOUCH_MENU_REMOVE_TABLE_CELL, Delegate.GetOrCreate(self, self.OnRemoveTableCell))
    g_Game.EventManager:RemoveListener(EventConst.TOUCH_MENU_UDPATE_GROUP_BTN, Delegate.GetOrCreate(self, self.OnUpdateGroupButton))
    g_Game.EventManager:RemoveListener(EventConst.TOUCH_MENU_UDPATE_ALL_GROUP_BTN, Delegate.GetOrCreate(self, self.OnUpdateAllGroupButton))
    g_Game.EventManager:RemoveListener(EventConst.TOUCH_MENU_SHOW_OVERLAP_DETAIL_PAENL, Delegate.GetOrCreate(self, self.OnShowOverlapDetailPanel))
    g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_START, Delegate.GetOrCreate(self, self.OnTimelineStartHideSelf))
    g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_STOP, Delegate.GetOrCreate(self, self.OnTimelineEndResumeSelf))
    g_Game.EventManager:RemoveListener(EventConst.BUBBLE_IN_MIST, Delegate.GetOrCreate(self, self.ShowMistUnlockTips))

    g_Game.EventManager:TriggerEvent(EventConst.TOUCH_INFO_UI_CLOSE)
    self:ReleaseAllAsyncHolders()
    TileHighLightMap.HideTileHighlight(self.tile)
end

function TouchMenuUIMediator:ReleaseAllAsyncHolders()
    if not self.asyncHolder then return end

    for i, v in ipairs(self.asyncHolder) do
        v:AbortAndCleanup()
    end
    self.asyncHolder = nil
end

---@param toggleData TouchMenuPageToggleDatum
function TouchMenuUIMediator:ClickToggle(toggleData)
    if self.currentData == toggleData.pageData then return end
    self.currentData = toggleData.pageData
    self:UpdatePanel()
end

function TouchMenuUIMediator:UpdatePanel()
    self:ChangePageContent()

    if not self.showToggle then return end
    for _, v in ipairs(self._toggles) do
        local selected = v.data.pageData == self.currentData
        v:OnSelected(selected)
    end
end

function TouchMenuUIMediator:ChangePageContent()
    local showBasic = self.currentData.basic ~= nil
    if self._child_touch_menu_se then
        self._child_touch_menu_se:SetVisible(showBasic and self.currentData.basic:GetCompName() == "_child_touch_menu_se")
    end
    if self._child_touch_menu_name then
        self._child_touch_menu_name:SetVisible(showBasic and self.currentData.basic:GetCompName() == "_child_touch_menu_name")
    end
    if showBasic then
        self[self.currentData.basic:GetCompName()]:FeedData(self.currentData.basic)
    end
    self:RefreshMarkBtn()
    self:RefreshDefuseBtn()
    self:RefreshDeleteBtn()
    self:RefreshPlayerInfoBtn()
    self:RefreshReleaseBtn()

    ---@type {datum:TouchMenuCellDatumBase, comp:BaseUIComponent}[]
    local flexibleData = {}
    local showTable = self.currentData.compsData ~= nil
    self._p_components:SetVisible(showTable)
    if showTable then
        self:ClearComponents()
        for _, v in ipairs(self.currentData.compsData) do
            local prefabIndex = v:GetPrefabIndex()
            local comp = UIHelper.DuplicateUIComponent(self._components[prefabIndex], self._p_components)
            comp:FeedData(v)
            comp:SetVisible(true)
            self.datum2Cell[v] = comp

            if v:IsFlexibleHeight() then
                table.insert(flexibleData, {datum = v, comp = comp})
            end
        end
    end

    local showButtonTips = self.currentData.buttonTipsData ~= nil
    self._p_group_tips:SetActive(showButtonTips)
    if showButtonTips then
        local showTipsIcon = self.currentData.buttonTipsData:ShowIcon()
        self._p_icon_tips:SetVisible(showTipsIcon)
        if showTipsIcon then
            if self.currentData.buttonTipsData.dynamicIcon then
                g_Game.SpriteManager:LoadSprite(self.currentData.buttonTipsData.icon(), self._p_icon_tips)
            else
                g_Game.SpriteManager:LoadSprite(self.currentData.buttonTipsData.icon, self._p_icon_tips)
            end

            if self.currentData.buttonTipsData.iconColor then
                self._p_icon_tips.color = self.currentData.buttonTipsData.iconColor
            end
        end

        if self.currentData.buttonTipsData.dynamicContent then
            self._p_text_tips.text = self.currentData.buttonTipsData.content()
        else
            self._p_text_tips.text = self.currentData.buttonTipsData.content
        end

        local showTipsDetailBtn = self.currentData.buttonTipsData.dynamicTips or (not string.IsNullOrEmpty(self.currentData.buttonTipsData.tips))
        self._child_comp_btn_detail_tips:SetVisible(showTipsDetailBtn)
    end
    
    local showPower = self.currentData.powerData ~= nil
    self._p_power:SetVisible(showPower)
    if showPower then
        self._p_text_power.text = self.currentData.powerData.powerText
        if string.IsNullOrEmpty(self.currentData.powerData.powerIcon) then
            self._p_icon_status:SetVisible(false)
        else
            self._p_icon_status:SetVisible(true)
            g_Game.SpriteManager:LoadSprite(self.currentData.powerData.powerIcon, self._p_icon_status)
        end
    end

    for _, v in ipairs(self._buttons) do
        UIHelper.DeleteUIComponent(v)
    end
    self._button = {}

    for groupIdx, v in ipairs(self._buttonGroup) do
        local groupData = self.currentData.buttonGroupData[groupIdx]
        local showButtonGroup = groupData ~= nil
        v:SetVisible(showButtonGroup)

        if showButtonGroup then
            for _, datum in ipairs(groupData.data) do
                local template = self._buttonTemplates[datum.style or TouchMenuMainBtnDatum.Style.Pink]
                if Utils.IsNotNull(template) then
                    local inst = UIHelper.DuplicateUIComponent(template, v.transform)
                    inst:FeedData(datum)
                end
            end
        end
    end

    -- local showShare = type(self.currentData.shareClick) == "function"
    local showShare = self:IsCanShowShare()
    self._p_btn_share:SetVisible(showShare)

    local showPolluted = self.currentData.pollutedData ~= nil
    self._p_polluted_hint:SetActive(showPolluted)
    if showPolluted then
        g_Game.SpriteManager:LoadSprite(self.currentData.pollutedData.icon, self._p_polluted_icon)
        self._p_polluted_text_hint.text = self.currentData.pollutedData.content
    end

    if #flexibleData <= 1 then
        for i, v in ipairs(flexibleData) do
            v.comp.Lua:UsePreferHeight()
        end
    else
        g_Logger.Error("TODO:暂未设计多个动态高度的组件如何分配高度")
    end

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._p_city_info)
end

function TouchMenuUIMediator:ClearComponents()
    local childCount = self._p_components.childCount
    for i = childCount - 1, 0, -1 do
        local child = self._p_components:GetChild(i)
        local comp = child:GetComponent(typeof(CS.DragonReborn.UI.LuaBaseComponent))
        UIHelper.DeleteUIComponent(comp)
    end
    table.clear(self.datum2Cell)
end

local ArrowSide = {Left = 1, Right = 2, Top = 3, Bottom = 4}
local BottomLeftOffset = {
    [ArrowSide.Left] = {x = 0, y = -0.5},
    [ArrowSide.Right] = {x = -1, y = -0.5},
    [ArrowSide.Top] = {x = -0.5, y = -1},
    [ArrowSide.Bottom] = {x = -0.5, y = 0},
}
local BottomRightOffset = {
    [ArrowSide.Left] = {x = 1, y = -0.5},
    [ArrowSide.Right] = {x = 0, y = -0.5},
    [ArrowSide.Top] = {x = 0.5, y = -1},
    [ArrowSide.Bottom] = {x = 0.5, y = 0},
}
local TopLeftOffset = {
    [ArrowSide.Left] = {x = 0, y = 0.5},
    [ArrowSide.Right] = {x = -1, y = 0.5},
    [ArrowSide.Top] = {x = -0.5, y = 0},
    [ArrowSide.Bottom] = {x = -0.5, y = 1},
}
local TopRightOffset = {
    [ArrowSide.Left] = {x = 1, y = 0.5},
    [ArrowSide.Right] = {x = 0, y = 0.5},
    [ArrowSide.Top] = {x = 0.5, y = 0},
    [ArrowSide.Bottom] = {x = 0.5, y = 1},
}
local Forward = CS.UnityEngine.Vector3.forward
local Right = CS.UnityEngine.Vector3.right
local Zero = CS.UnityEngine.Vector3.zero

---@param camTrans CS.UnityEngine.Transform
---@param followTrans CS.UnityEngine.Transform
function TouchMenuUIMediator:CalcOffset(offset, type, camTrans, followTrans)
    if not offset or offset < 0.01 or not camTrans or not followTrans then
        return Zero
    end
    local screenOffsetDir
    if type == ArrowSide.Left then
        screenOffsetDir = CS.UnityEngine.Vector3.right
    elseif type == ArrowSide.Right then
        screenOffsetDir = CS.UnityEngine.Vector3.left
    elseif type == ArrowSide.Top then
        screenOffsetDir = CS.UnityEngine.Vector3.down
    else
        screenOffsetDir = CS.UnityEngine.Vector3.up
    end
    local screenOffsetVector = camTrans:TransformDirection(screenOffsetDir)
    local localOffset = screenOffsetVector * offset

    return localOffset;
end
function TouchMenuUIMediator:AdjustCameraPos(forceArrowSide)
    local camera = KingdomMapUtils.GetBasicCamera()
    if camera == nil then return end

    local uiCamera = g_Game.UIManager:GetUICamera()
    if uiCamera == nil then return end

    --- 记录矩形宽高
    local rect = self._p_city_info.rect
    self.width, self.height = rect.width, rect.height
    local wbl, wtl, wtr, wbr = self._p_city_info:GetWorldCorners()
    local vbl = uiCamera:WorldToViewportPoint(wbl)
    local vtl = uiCamera:WorldToViewportPoint(wtl)
    local vtr = uiCamera:WorldToViewportPoint(wtr)
    local vbr = uiCamera:WorldToViewportPoint(wbr)
    local vheight = vtl.y - vbl.y
    local vwidth = vbr.x - vbl.x

    --- 确认锚定的世界坐标
    local followTrans = self.param.followTrans
    local worldPos = nil
    if followTrans then
        worldPos = followTrans.position
    else
        worldPos = self.param.worldPos
    end

    if worldPos == nil then
        worldPos = camera:GetLookAtPosition()
    end

    --- 根据世界坐标的视口位置，找一个合适的UI边界锚定位置
    local viewport = camera.mainCamera:WorldToViewportPoint(worldPos)
    local x, y = viewport.x, viewport.y
    if forceArrowSide == nil then
        self.arrowSide = self:GetSuitableSide(worldPos, vwidth, vheight, camera.mainCamera, followTrans)
        if self.arrowSide == nil then
            if self:OutOfScreen(x, y) then
                self.arrowSide = self:GetOutOfScreenSide(x, y)
            else
                self.arrowSide = ArrowSide.Right
            end
        end
    else
        self.arrowSide = forceArrowSide
    end

    local worldPosOffset = self.param.followOffset == 0 and Zero or self:CalcOffset(self.param.followOffset,self.arrowSide,camera.mainCamera.transform,followTrans)
    local marginOffset = (self.param.marginX == 0 and self.param.marginZ == 0 ) and Zero or self:GetMarginOffset(self.arrowSide)
    local marginViewport = camera.mainCamera:WorldToViewportPoint(worldPos + worldPosOffset + marginOffset)

    --- 根据UI边界锚定位置的枚举，找到锚定后的UI视口坐标
    vbl = marginViewport + Vector3(BottomLeftOffset[self.arrowSide].x * vwidth, BottomLeftOffset[self.arrowSide].y * vheight)
    vtl = marginViewport + Vector3(TopLeftOffset[self.arrowSide].x * vwidth, TopLeftOffset[self.arrowSide].y * vheight)
    vtr = marginViewport + Vector3(TopRightOffset[self.arrowSide].x * vwidth, TopRightOffset[self.arrowSide].y * vheight)
    vbr = marginViewport + Vector3(BottomRightOffset[self.arrowSide].x * vwidth, BottomRightOffset[self.arrowSide].y * vheight)

    vbl, vtl, vtr, vbr = self:AdjustArrowSide(vbl, vtl, vtr, vbr)

    --- 如果溢出了屏幕，那么需要校正它
    local flag, viewOffset = self:EnsureInScreen(vbl, vtl, vtr, vbr)
    wbl = uiCamera:ViewportToWorldPoint({x = vbl.x, y = vbl.y, z = 0})
    if flag then
        vbl = vbl + viewOffset
        vtl = vtl + viewOffset
        vtr = vtr + viewOffset
        vbr = vbr + viewOffset
    end

    local uiPos = uiCamera:ViewportToWorldPoint({x = (vbl.x + vtr.x) / 2, y = (vbl.y + vtr.y) / 2, z = 0})
    local followOffset = uiCamera:ViewportToWorldPoint({x = marginViewport.x, y = marginViewport.y, z = 0}) - uiPos
    self._p_city_info.position = uiPos
    self._followTrans = followTrans
    self._followWorldPosOffset = worldPosOffset + marginOffset
    self._followOffset = followOffset
    self._worldPos = worldPos

    self._p_icon_arrow_n:SetActive(self.arrowSide == ArrowSide.Top)
    self._p_icon_arrow_s:SetActive(self.arrowSide == ArrowSide.Bottom)
    self._p_icon_arrow_e:SetActive(self.arrowSide == ArrowSide.Right)
    self._p_icon_arrow_w:SetActive(self.arrowSide == ArrowSide.Left)

    --- 校正箭头偏移
    if flag then
        local wbln = uiCamera:ViewportToWorldPoint({x = vbl.x, y = vbl.y, z = 0})
        local arrowOffset = wbl - wbln
        self:LimitOnEdge(self._p_icon_arrow_n.transform, ArrowSide.Top, arrowOffset)
        self:LimitOnEdge(self._p_icon_arrow_s.transform, ArrowSide.Bottom, arrowOffset)
        self:LimitOnEdge(self._p_icon_arrow_e.transform, ArrowSide.Right, arrowOffset)
        self:LimitOnEdge(self._p_icon_arrow_w.transform, ArrowSide.Left, arrowOffset)
        --self._p_icon_arrow_n.transform.position = self._p_icon_arrow_n.transform.position + arrowOffset
        --self._p_icon_arrow_s.transform.position = self._p_icon_arrow_s.transform.position + arrowOffset
        --self._p_icon_arrow_e.transform.position = self._p_icon_arrow_e.transform.position + arrowOffset
        --self._p_icon_arrow_w.transform.position = self._p_icon_arrow_w.transform.position + arrowOffset
    end
end

---@param trans CS.UnityEngine.Transform
---@param side number @ArrowSide
---@param offset CS.UnityEngine.Vector3
function TouchMenuUIMediator:LimitOnEdge(trans, side, offset)
    local targetWorldPos = trans.position + offset
    local originLocalPos = trans.parent:InverseTransformPoint(trans.position)
    local localPos = trans.parent:InverseTransformPoint(targetWorldPos)
    if side == ArrowSide.Top or side == ArrowSide.Bottom then
        localPos.y = originLocalPos.y
    elseif side == ArrowSide.Right or side == ArrowSide.Left then
        localPos.x = originLocalPos.x
    end
    trans.position = trans.parent:TransformPoint(localPos)
end

function TouchMenuUIMediator:GetCurrentPanelHeight()
    return self._p_city_info.rect.height
end

function TouchMenuUIMediator:OutOfScreen(x, y)
    return x < 0 or x > 1 or y < 0 or y > 1
end

function TouchMenuUIMediator:GetOutOfScreenSide(x, y)
    if x < 0 then
        return ArrowSide.Left
    elseif x > 1 then
        return ArrowSide.Right
    elseif y < 0 then
        return ArrowSide.Bottom
    elseif y > 0 then
        return ArrowSide.Top
    end
end

local SideOffset = {
    [ArrowSide.Left] = {top = 0.5, bottom = -0.5, left = 0, right = 1},
    [ArrowSide.Right] = {top = 0.5, bottom = -0.5, left = -1, right = 0},
    [ArrowSide.Top] = {top = 0, bottom = 1, left = -0.5, right = 0.5},
    [ArrowSide.Bottom] = {top = 1, bottom = 0, left = -0.5, right = 0.5},
}

local ArrowOffset = {
    [ArrowSide.Left] = {top = 0, bottom = 0, left = 1, right = 1},
    [ArrowSide.Right] = {top = 0, bottom = 0, left = -1, right = -1},
    [ArrowSide.Top] = {top = -1, bottom = -1, left = 0, right = 0},
    [ArrowSide.Bottom] = {top = 1, bottom = 1, left = 0, right = 0},
}

---@param camera CS.UnityEngine.Camera
function TouchMenuUIMediator:GetSuitableSide(worldPos, width, height, camera, followTrans)
    if self:IsSideSuitable(ArrowSide.Left, worldPos, width, height, camera, followTrans) then
        return ArrowSide.Left
    elseif self:IsSideSuitable(ArrowSide.Right, worldPos, width, height, camera, followTrans) then
        return ArrowSide.Right
    elseif self:IsSideSuitable(ArrowSide.Top, worldPos, width, height, camera, followTrans) then
        return ArrowSide.Top
    elseif self:IsSideSuitable(ArrowSide.Bottom, worldPos, width, height, camera, followTrans) then
        return ArrowSide.Bottom
    end
end

function TouchMenuUIMediator:IsSideSuitable(arrow, worldPos, width, height, camera, followTrans)
    local camTrans = camera.transform
    local marginOffset = self:GetMarginOffset(arrow)
    local worldPosOffset = self:CalcOffset(self.param.followOffset, arrow, camTrans, followTrans)
    local viewport = camera:WorldToViewportPoint(worldPos + worldPosOffset + marginOffset)
    local x, y = viewport.x, viewport.y
    local arrowViewOffset = self._arrowOffset / (self:IsHorizontal(arrow) and self._screenWidth or self._screenHeight)

    --- 水平情况下的上下视口
    local top = y + height * SideOffset[arrow].top + arrowViewOffset * ArrowOffset[arrow].top
    local bottom = y + height * SideOffset[arrow].bottom + arrowViewOffset * ArrowOffset[arrow].bottom
    local left = x + width * SideOffset[arrow].left + arrowViewOffset * ArrowOffset[arrow].left
    local right = x + width * SideOffset[arrow].right + arrowViewOffset * ArrowOffset[arrow].right
    return top <= 1 and bottom >= 0 and left >= 0 and right <= 1
end

function TouchMenuUIMediator:IsHorizontal(arrow)
    return arrow == ArrowSide.Left or ArrowSide.Right
end

function TouchMenuUIMediator:GetMarginOffset(arrow)
    if arrow == ArrowSide.Left then
        return Right * self.param.marginX
    elseif arrow == ArrowSide.Right then
        return Forward * self.param.marginZ
    elseif arrow == ArrowSide.Top then
        return Zero
    elseif arrow == ArrowSide.Bottom then
        return (Right * self.param.marginX) + (Forward * self.param.marginZ)
    end
    return Zero
end

function TouchMenuUIMediator:AdjustArrowSide(vbl, vtl, vtr, vbr)
    local arrowViewOffset = self._arrowOffset / (self:IsHorizontal(self.arrowSide) and self._screenWidth or self._screenHeight)
    vbl = vbl + Vector3(ArrowOffset[self.arrowSide].left, ArrowOffset[self.arrowSide].bottom, 0) * arrowViewOffset
    vtl = vtl + Vector3(ArrowOffset[self.arrowSide].left, ArrowOffset[self.arrowSide].top, 0) * arrowViewOffset
    vtr = vtr + Vector3(ArrowOffset[self.arrowSide].right, ArrowOffset[self.arrowSide].top, 0) * arrowViewOffset
    vbr = vbr + Vector3(ArrowOffset[self.arrowSide].right, ArrowOffset[self.arrowSide].bottom, 0) * arrowViewOffset
    return vbl, vtl, vtr, vbr
end

function TouchMenuUIMediator:EnsureInScreen(bl, tl, tr, br)
    local ox, oy = 0, 0
    local leftMargin = 0 - bl.x
    local rightMargin = br.x - 1
    --- 当不是左右两边都溢出屏幕时
    if leftMargin <= 0 or rightMargin <= 0 then
        if leftMargin > 0 then
            ox = ox + leftMargin
        elseif rightMargin > 0 then
            ox = ox - rightMargin
        end
    end

    --- 当不是上下两边都溢出屏幕时
    local bottomMargin = 0 - bl.y
    local topMargin = tl.y - 1
    if bottomMargin <= 0 or topMargin <= 0 then
        if bottomMargin > 0 then
            oy = oy + bottomMargin
        elseif topMargin > 0 then
            oy = oy - topMargin
        end
    end

    local needMove = math.abs(ox) > 0 or math.abs(oy) > 0
    local offset = Vector3(ox, oy, 0)
    return needMove, offset
end

---@param basicData TouchMenuBasicInfoDatumBase
function TouchMenuUIMediator:OnUpdateBasicData(basicData)
    self.currentData.basic = basicData
    local showBasic = self.currentData.basic ~= nil
    self._child_touch_menu_se:SetVisible(showBasic and self.currentData.basic:GetCompName() == "_child_touch_menu_se")
    self._child_touch_menu_name:SetVisible(showBasic and self.currentData.basic:GetCompName() == "_child_touch_menu_name")
    if showBasic then
        self[self.currentData.basic:GetCompName()]:FeedData(self.currentData.basic)
    end
    self:RefreshMarkBtn()
    self:RefreshDefuseBtn()
    self:RefreshDeleteBtn()
    self:RefreshPlayerInfoBtn()
    self:RefreshReleaseBtn()
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._p_city_info)
end

function TouchMenuUIMediator:LateUpdate()
    if not self._worldPos and not self._followTrans then return end
    if not self.arrowSide then return end

    if self:RectChanged() then return end

    local camera = KingdomMapUtils.GetBasicCamera()
    if camera == nil then return end

    local uiCamera = g_Game.UIManager:GetUICamera()
    if uiCamera == nil then return end
    local worldPos = nil
    if self._followTrans then
        worldPos = self._followTrans.position
    else
        worldPos = self._worldPos
    end
    local marginViewport = camera.mainCamera:WorldToViewportPoint( worldPos + self._followWorldPosOffset )
    local x, y = marginViewport.x, marginViewport.y
    local target = uiCamera:ViewportToWorldPoint({x = x, y = y, z = 0}) - self._followOffset
    self._p_city_info.position = target
end

function TouchMenuUIMediator:RectChanged()
    local rect = self._p_city_info.rect
    if self.width ~= rect.width or self.height ~= rect.height then
        self:AdjustCameraPos(self.arrowSide)
        return true
    end
    return false
end

function TouchMenuUIMediator:OnSecondTick()
    if self.currentData.buttonTipsData then
        if self.currentData.buttonTipsData.dynamicIcon then
            g_Game.SpriteManager:LoadSprite(self.currentData.buttonTipsData.icon(), self._p_icon_tips)
        end

        if self.currentData.buttonTipsData.dynamicContent then
            self._p_text_tips.text = self.currentData.buttonTipsData.content()
        end
    end
end

function TouchMenuUIMediator:OnTick(dt)
    if not self.param or not self.param.closeOnTime then
        return
    end
    if self.param.closeOnTime < g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() then
        self:CloseSelf()
    end
end

---@param base TouchMenuCellDatumBase
function TouchMenuUIMediator:OnUpdateTableCell(base)
    if base == nil then return end
    if self.currentData.compsData == nil then return end

    for i, v in ipairs(self.currentData.compsData) do
        if v == base and self.datum2Cell[v] then
            self.datum2Cell[v]:FeedData(v)
            CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._p_city_info)
            break
        end
    end
end

---@param base TouchMenuCellDatumBase
---@param pos number
function TouchMenuUIMediator:OnAppendTableCell(base, pos)
    if base == nil then return end

    if self.currentData.compsData == nil then
        self.currentData.compsData = {}
        self._p_components:SetVisible(true)
    end

    if pos then
        local fixedPos = math.clamp(pos, 1, #self.currentData.compsData + 1)
        table.insert(self.currentData.compsData, fixedPos, base)
        local comp = UIHelper.DuplicateUIComponent(self._components[base:GetPrefabIndex()], self._p_components)
        comp:FeedData(base)
        comp:SetVisible(true)
        self.datum2Cell[base] = comp
        comp.transform:SetSiblingIndex(fixedPos - 1)
    else
        table.insert(self.currentData.compsData, base)
        local comp = UIHelper.DuplicateUIComponent(self._components[base:GetPrefabIndex()], self._p_components)
        comp:FeedData(base)
        comp:SetVisible(true)
        self.datum2Cell[base] = comp
    end
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._p_city_info)
end

---@param base TouchMenuCellDatumBase
function TouchMenuUIMediator:OnRemoveTableCell(base)
    if base == nil then return end
    if self.currentData.compsData == nil then return end

    for i, v in ipairs(self.currentData.compsData) do
        if v == base then
            UIHelper.DeleteUIComponent(self.datum2Cell[base])
            self.datum2Cell[base] = nil
            table.remove(self.currentData.compsData, i)
            if #self.currentData.compsData == 0 then
                self.currentData.compsData = nil
                self._p_components:SetVisible(false)
            end
            CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._p_city_info)
            break
        end
    end
end

---@param buttonGroupDatum TouchMenuMainBtnGroupData
---@param groupIdx number
function TouchMenuUIMediator:OnUpdateGroupButton(buttonGroupDatum, groupIdx)
    if buttonGroupDatum == nil then return end
    if self.currentData.buttonGroupData == nil then return end
    if #self.currentData.buttonGroupData < groupIdx or groupIdx <= 0 then return end

    self.currentData.buttonGroupData[groupIdx] = buttonGroupDatum
    local buttons = self._buttons[groupIdx]
    if buttons == nil then return end

    for i, button in ipairs(buttons) do
        local buttonShow = buttonGroupDatum.count >= i
        button:SetVisible(buttonShow)

        if buttonShow then
            button:FeedData(buttonGroupDatum.data[i])
        end
    end
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._p_city_info)
end

---@param buttonGroupData TouchMenuMainBtnGroupData[]
function TouchMenuUIMediator:OnUpdateAllGroupButton(buttonGroupData)
    self.currentData.buttonGroupData = buttonGroupData
    for groupIdx, v in ipairs(self._buttonGroup) do
        local groupData = self.currentData.buttonGroupData[groupIdx]
        local showButtonGroup = groupData ~= nil
        v:SetVisible(showButtonGroup)

        if showButtonGroup then
            ---@param button TouchMenuMainBtn
            for i, button in ipairs(self._buttons[groupIdx]) do
                local buttonShow = groupData.count >= i
                button:SetVisible(buttonShow)

                if buttonShow then
                    button:FeedData(groupData.data[i])
                end
            end
        end
    end
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._p_city_info)
end

function TouchMenuUIMediator:OnShowOverlapDetailPanel(desc)
    if string.IsNullOrEmpty(desc) then return end
    self._p_group_detail:SetActive(true)
    self._p_text_detail.text = desc
    self._vx_trigger:PlayAll("OverlapPanelEnter")
end

function TouchMenuUIMediator:OnCloseOverlapDetailPanel()
    self._p_group_detail:SetActive(false)
    g_Game.EventManager:TriggerEvent(EventConst.TOUCH_MENU_HIDE_OVERLAP_DETAIL_PAENL)
    self._vx_trigger:PlayAll("OverlapPanelExit")
end

function TouchMenuUIMediator:OnTimelineStartHideSelf()
    self._p_root:SetVisible(false)
end

function TouchMenuUIMediator:OnTimelineEndResumeSelf()
    self._p_root:SetVisible(true)
end

function TouchMenuUIMediator:IsCanShowShare()
    if not self.currentData.basic then
        return false
    end
    local dbType =  self.currentData.basic.dbType
    if not dbType then
        return false
    end
    if dbType == -1 or
     dbType == ChatShareType.WorldEvent or
     dbType == ChatShareType.ResourceField or
     dbType == ChatShareType.SlgMonster or
     dbType == ChatShareType.SlgBuilding then
        return true
    end
    return false
end

function TouchMenuUIMediator:OnShareClick()
    if not self.currentData.basic then
        return false
    end
    self:CloseSelf()
    local basic = self.currentData.basic
    ---@type ShareChannelChooseParam
    local param = {type = basic.dbType, configID = basic.configID}
    param.x, param.y = self:GetCoordByCoordStr()
    local UIMediatorNames = require("UIMediatorNames")
    g_Game.UIManager:Open(UIMediatorNames.ShareChannelChooseMediator, param)
end

function TouchMenuUIMediator:GetCoordByCoordStr()
    if not self.currentData.basic then
        return 0, 0
    end
    local basic = self.currentData.basic
    if basic.coord.x and basic.coord.y then
        return basic.coord.x, basic.coord.y
    end
    local x = 0
    local y = 0
    local xStr = string.match(basic.coord, "(X:%d+)")
    if xStr then
        x = string.match(xStr, "%d+")
    end
    local yStr = string.match(basic.coord, "(Y:%d+)")
    if yStr then
        y = string.match(yStr, "(%d+)")
    end
    return x, y
end

function TouchMenuUIMediator:ShowMistUnlockTips(customData)
    if customData and customData.entity then
        if ModuleRefer.RadarModule:GetScout(customData.entity) then
            self._p_text_tips.text = UIHelper.GetColoredText(I18N.Get("bw_radar_invest_mist_clear"), "#B8120E")
            return
        end
    end

    self._p_text_tips.text = UIHelper.GetColoredText(I18N.Get("creep_tips_clearmist"), "#B8120E")
end

function TouchMenuUIMediator:RefreshMarkBtn()
    local show = self:ShowMarkBtn()
    self._p_btn_mark:SetVisible(show)
    if show then
        self._p_btn_mark_status:SetState(self:GetMarkState())
    end
end

function TouchMenuUIMediator:ShowMarkBtn()
    return self.currentData
            and self.currentData.basic
            and self.currentData.basic:ShowMarkBtn() or false
end

function TouchMenuUIMediator:GetMarkState()
    return self.currentData
            and self.currentData.basic
            and self.currentData.basic:GetMarkState() or 0
end

function TouchMenuUIMediator:OnClickBtnMark()
    if self:ShowMarkBtn() then
        if not self.currentData.basic:OnClickBtnMark(self._p_btn_mark.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))) then
            self:CloseSelf()
        end
    end
end

function TouchMenuUIMediator:RefreshReleaseBtn()
    local show = self:ShowRelease()
    self._p_btn_release:SetVisible(show)
end

function TouchMenuUIMediator:ShowRelease()
    return self.currentData and self.currentData.basic and self.currentData.basic:ShowReleaseBtn() or false
end

function TouchMenuUIMediator:OnClickBtnRelease()
    if self:ShowRelease() then
        if not self.currentData.basic:OnClickReleaseBtn(self._p_btn_release.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))) then
            self:CloseSelf()
        end
    end
end

function TouchMenuUIMediator:RefreshDefuseBtn()
    local show = self:ShowDefuse()
    self._p_btn_defuse:SetVisible(show)
end

function TouchMenuUIMediator:ShowDefuse()
    return self.currentData
            and self.currentData.basic
            and self.currentData.basic:ShowDefuseBtn() or false
end

function TouchMenuUIMediator:OnClickBtnDefuse()
    if self:ShowDefuse() then
        if not self.currentData.basic:OnClickDefuseBtn(self._p_btn_defuse.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))) then
            self:CloseSelf()
        end
    end
end

function TouchMenuUIMediator:RefreshDeleteBtn()
    local show = self:ShowDelete()
    self._p_btn_delete:SetVisible(show)
end

function TouchMenuUIMediator:ShowDelete()
    return self.currentData
            and self.currentData.basic
            and self.currentData.basic:ShowDeleteBtn() or false
end

function TouchMenuUIMediator:OnClickBtnDelete()
    if self:ShowDelete() then
        if not self.currentData.basic:OnClickDeleteBtn(self._p_btn_delete.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))) then
            self:CloseSelf()
        end
    end
end

function TouchMenuUIMediator:RefreshPlayerInfoBtn()
    local show = self:ShowPlayerInfo()
    self._p_btn_player_info:SetVisible(show)
end

function TouchMenuUIMediator:ShowPlayerInfo()
    return self.currentData
            and self.currentData.basic
            and self.currentData.basic:ShowPlayerInfoBtn() or false
end

function TouchMenuUIMediator:OnClickBtnPlayerInfo()
    if self:ShowPlayerInfo() then
        if not self.currentData.basic:OnClickPlayerInfoBtn(self._p_btn_player_info.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))) then
            self:CloseSelf()
        end
    end
end

function TouchMenuUIMediator:OnClickBtnTipsDetail()
    if self.currentData.buttonTipsData.dynamicTips then
        self.currentData.buttonTipsData.tips()
    elseif not string.IsNullOrEmpty(self.currentData.buttonTipsData.tips) then
        ---@type TextToastMediatorParameter
        local toastParameter = {}
        toastParameter.clickTransform =  self._p_btn_tips_detail.transform
        toastParameter.title = ''
        toastParameter.content = self.currentData.buttonTipsData.tips
        ModuleRefer.ToastModule:ShowTextToast(toastParameter)
    end
end

----#region 异步按需加载相关增加代码
function TouchMenuUIMediator:_child_touch_menu_se_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_se failed")
        return
    end

    self._child_touch_menu_se = self:LuaBaseComponent("child_touch_menu_se")
    self._child_touch_menu_se:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end

function TouchMenuUIMediator:_child_touch_menu_name_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_name failed")
        return
    end

    self._child_touch_menu_name = self:LuaBaseComponent("child_touch_menu_name")
    self._child_touch_menu_name:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end

function TouchMenuUIMediator:_p_pair_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_pair failed")
        return
    end

    self._p_pair = self:LuaBaseComponent("p_pair")
    self._p_pair:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end

function TouchMenuUIMediator:_p_pair_time_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_pair_time failed")
        return
    end

    self._p_pair_time = self:LuaBaseComponent("p_pair_time")
    self._p_pair_time:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end

function TouchMenuUIMediator:_p_pair_resource_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_pair_resource_root failed")
        return
    end

    self._p_pair_resource = self:LuaBaseComponent("p_pair_resource")
    self._p_pair_resource:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end

function TouchMenuUIMediator:_p_text_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_circle_group_text_root failed")
        return
    end

    self._p_text = self:LuaBaseComponent("p_text")
    self._p_text:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end

function TouchMenuUIMediator:_p_task_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_circle_group_task failed")
        return
    end

    self._p_task = self:LuaBaseComponent("p_task")
    self._p_task:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end

function TouchMenuUIMediator:_p_progress_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_progress failed")
        return
    end

    self._p_progress = self:LuaBaseComponent("p_progress")
    self._p_progress:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end

function TouchMenuUIMediator:_p_reward_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_reward failed")
        return
    end

    self._p_reward = self:LuaBaseComponent("p_reward")
    self._p_reward:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end

function TouchMenuUIMediator:_p_se_monsters_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_monsters failed")
        return
    end

    self._p_se_monsters = self:LuaBaseComponent("p_se_monsters")
    self._p_se_monsters:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end
function TouchMenuUIMediator:p_league_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_league failed")
        return
    end

    self._p_league = self:LuaBaseComponent("p_league")
    self._p_league:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end
function TouchMenuUIMediator:p_buff_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_buff failed")
        return
    end

    self._p_buff = self:LuaBaseComponent("p_buff")
    self._p_buff:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end
function TouchMenuUIMediator:_p_reward_pair_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_reward_pair failed")
        return
    end

    self._p_reward_pair = self:LuaBaseComponent("p_reward_pair")
    self._p_reward_pair:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end
function TouchMenuUIMediator:_p_pair_special_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_pair_special failed")
        return
    end

    self._p_pair_special = self:LuaBaseComponent("p_pair_special")
    self._p_pair_special:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end
function TouchMenuUIMediator:_p_mission_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_mission failed")
        return
    end

    self._p_mission = self:LuaBaseComponent("p_mission")
    self._p_mission:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end
function TouchMenuUIMediator:_p_behemoth_state_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_behemoth_state failed")
        return
    end

    self._p_behemoth_state = self:LuaBaseComponent("p_behemoth_state")
    self._p_behemoth_state:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end
function TouchMenuUIMediator:_p_behemoth_skill_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_behemoth_skill failed")
        return
    end

    self._p_behemoth_skill = self:LuaBaseComponent("p_behemoth_skill")
    self._p_behemoth_skill:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end
function TouchMenuUIMediator:_p_behemoth_earnings_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_behemoth_earnings failed")
        return
    end

    self._p_behemoth_earnings = self:LuaBaseComponent("p_behemoth_earnings")
    self._p_behemoth_earnings:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end
function TouchMenuUIMediator:_p_behemoth_now_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_behemoth_now failed")
        return
    end

    self._p_behemoth_now = self:LuaBaseComponent("p_behemoth_now")
    self._p_behemoth_now:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end
function TouchMenuUIMediator:_p_landform_loaded(go)
    if Utils.IsNull(go) then
        self:RemoveAsyncLoadFlag()
        g_Logger.ErrorChannel("TouchMenuUIMediator", "load child_touch_menu_platform failed")
        return
    end

    self._p_landform = self:LuaBaseComponent("p_landform")
    self._p_landform:SetVisible(false)
    self:RemoveAsyncLoadFlag()
end
----#endregion

return TouchMenuUIMediator
