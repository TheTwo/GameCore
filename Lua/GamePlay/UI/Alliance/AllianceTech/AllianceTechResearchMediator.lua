--- scene:scene_league_research
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local AllianceTechResearchTechColumnHelper = require("AllianceTechResearchTechColumnHelper")
local AllianceTechResearchHostProvider = require("AllianceTechResearchHostProvider")
local AllianceTechnologyType = require("AllianceTechnologyType")
local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")
local DBEntityPath = require("DBEntityPath")
local UIHelper = require("UIHelper")
local NumberFormatter = require("NumberFormatter")
local AllianceCurrencyType = require("AllianceCurrencyType")
local Utils = require("Utils")
local AllianceModuleDefine = require("AllianceModuleDefine")
local NotificationType = require("NotificationType")
local UIMediatorNames = require('UIMediatorNames')
local BaseUIMediator = require("BaseUIMediator")
local CommonLeaderboardPopupDefine = require('CommonLeaderboardPopupDefine')

---@class AllianceTechResearchMediatorParameter
---@field enterFocusOnGroup number|nil
---@field enterFocusSelect boolean
---@field backNoAni boolean

---@class AllianceTechResearchMediator:BaseUIMediator
---@field new fun():AllianceTechResearchMediator
---@field super BaseUIMediator
local AllianceTechResearchMediator = class('AllianceTechResearchMediator', BaseUIMediator)

function AllianceTechResearchMediator:ctor()
    BaseUIMediator.ctor(self)
    self._currentTab = nil

    ---@type table<number, {prefabIdx:number, data:AllianceTechResearchLinkerColumnParameter|AllianceTechResearchTechColumnParameter}[]>
    self._cells_Tab = {}

    ---@type table<number, CommonResourceBtn>
    self._currencyResMap = {}

    self._backNoAni = false
    self._onShowFocusGroup = nil
    self._onShowFocusGroupAutoSelect = nil
end

function AllianceTechResearchMediator:OnCreate(param)
    ---@type CommonChildTabLeftBtn
    self._p_btn_side_tab_1 = self:LuaObject("p_btn_side_tab_1")
    ---@type CommonChildTabLeftBtn
    self._p_btn_side_tab_2 = self:LuaObject("p_btn_side_tab_2")
    ---@type CommonChildTabLeftBtn
    self._p_btn_side_tab_3 = self:LuaObject("p_btn_side_tab_3")

    self._p_group_resource = self:Transform("p_group_resource")
    ---@see CommonResourceBtn
    self._child_resource = self:LuaBaseComponent("child_resource")
    self._child_resource:SetVisible(false)
    self._p_btn_help = self:Button("p_btn_help", Delegate.GetOrCreate(self, self.OnClickHelpTip))
    self._p_text_daily = self:Text("p_text_daily")
    self.p_text_daily_num = self:Text("p_text_daily_num")
    self._p_text_times = self:Text("p_text_times", "alliance_tec_jihui")
    self._p_tabel_mask = self:Button("p_tabel_mask", Delegate.GetOrCreate(self, self.OnClickTableEmpty))
    self._p_tabel_mask_rect = self:RectTransform("p_tabel_mask")
    self._p_table_cell = self:TableViewPro("p_table_cell")
    self._p_table_cell.OnShownCellChanged = Delegate.GetOrCreate(self, self.OnShownCellChanged)
    self._p_table_cell_rect = self:RectTransform("p_table_cell")
    self._p_table_cell_btn = self:Button("p_table_cell", Delegate.GetOrCreate(self, self.OnClickTableEmpty))
    ---@see AllianceTechResearchTechNodeDetailBoard
    self._p_popup_detail = self:LuaBaseComponent('p_popup_detail')
    ---@type CS.UnityEngine.RectTransform
    self._p_popup_detail_rect = self._p_popup_detail.transform:GetComponent(typeof(CS.UnityEngine.RectTransform))
    ---@see CommonBackButtonComponent
    self._child_common_btn_back = self:LuaBaseComponent("child_common_btn_back")
    self.p_btn_rank = self:Button("p_btn_rank", Delegate.GetOrCreate(self, self.OnClickBtnRank))
    self.p_text_rank = self:Text('p_text_rank')

    self._p_btn_side_tab_2:SetVisible(false)
end

---@param param AllianceTechResearchMediatorParameter|nil
function AllianceTechResearchMediator:OnOpened(param)

    self._p_table_cell_rect.anchorMin = CS.UnityEngine.Vector2.zero
    self._p_table_cell_rect.anchorMax = CS.UnityEngine.Vector2.one
    self._p_table_cell_rect.offsetMin = CS.UnityEngine.Vector2.zero
    self._p_table_cell_rect.offsetMax = CS.UnityEngine.Vector2.zero
    self._p_table_cell_rect.anchoredPosition = CS.UnityEngine.Vector2.zero

    ---@type CommonChildTabLeftBtnParameter
    local tabData = {}
    tabData.btnName = I18N.Get("alliance_tec_lianmeng")
    tabData.index = AllianceTechnologyType.Alliance
    tabData.onClick = Delegate.GetOrCreate(self, self.OnChangeTab)
    self._p_btn_side_tab_1:FeedData(tabData)
    tabData = {}
    tabData.btnName = I18N.Get("alliance_tec_shengchan")
    tabData.index = AllianceTechnologyType.Production
    tabData.onClick = Delegate.GetOrCreate(self, self.OnChangeTab)
    self._p_btn_side_tab_2:FeedData(tabData)
    tabData = {}
    tabData.btnName = I18N.Get("alliance_tec_zhandou")
    tabData.index = AllianceTechnologyType.Fight
    tabData.onClick = Delegate.GetOrCreate(self, self.OnChangeTab)
    self._p_btn_side_tab_3:FeedData(tabData)

    ---@type CommonBackButtonData
    local backBtnData = {}
    backBtnData.title = I18N.Get("alliance_tec_keji")
    backBtnData.onClose = Delegate.GetOrCreate(self, self.OnClickBackBtn)
    self._child_common_btn_back:FeedData(backBtnData)

    self:SetupAllianceCurrency()
    self:OnChangeTab(AllianceTechnologyType.Alliance)
    self:RefreshDailyDonate()
    self:RefreshTimes(g_Game.ServerTime:GetServerTimestampInSecondsNoFloor())
    self._backNoAni = false
    local setFocusOnGroup = false
    if param and type(param) == 'table' then
        if param.enterFocusOnGroup then
            self._onShowFocusGroup = param.enterFocusOnGroup
            self._onShowFocusGroupAutoSelect = param.enterFocusSelect
            -- self:FocusOnGroup(param.enterFocusOnGroup, param.enterFocusSelect)
            setFocusOnGroup = true
        end
        self._backNoAni = param.backNoAni or false
    elseif param and type(param) == 'string' then
        local groupId = tonumber(param)
        if groupId then
            self._onShowFocusGroup = groupId
            self._onShowFocusGroupAutoSelect = true
            -- self:FocusOnGroup(groupId, true)
            setFocusOnGroup = true
        end
    end
    if not setFocusOnGroup then
        if ModuleRefer.PlayerModule:GetPlayer().Owner.AllianceRank < AllianceModuleDefine.LeaderRank then
            local recommend = ModuleRefer.AllianceTechModule:GetRecommendTech()
            if recommend ~= 0 then
                self._onShowFocusGroup = recommend
                self._onShowFocusGroupAutoSelect = true
                -- self:FocusOnGroup(recommend, true)
            end
        end
    end

    local node = self._p_btn_side_tab_1:GetNotificationNode()
    node:SetVisible(true)
    node = self._p_btn_side_tab_2:GetNotificationNode()
    node:SetVisible(true)
    node = self._p_btn_side_tab_3:GetNotificationNode()
    node:SetVisible(true)

    -- 刚打开时 打开推荐页签
    local markGroup = ModuleRefer.AllianceTechModule:GetRecommendTech()
    if markGroup then
        local groupTab = ModuleRefer.AllianceTechModule:GetTechTypeByGroupId(markGroup)
        self:OnChangeTab(groupTab)
    end
end

function AllianceTechResearchMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.UI_ALLIANCE_TECH_GROUP_SELECTED, Delegate.GetOrCreate(self, self.OnGroupNodeSelected))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerAlliance.LastRecoverNormalDonateTime.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerAllianceDonateTimesRefresh))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerAlliance.NormalDonateTimes.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerAllianceDonateTimesRefresh))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerAlliance.TodayDonateTechPoints.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerDonatePointChanged))
    g_Game.EventManager:AddListener(EventConst.UI_ALLIANCE_TECH_FOCUS_ON_GROUP, Delegate.GetOrCreate(self, self.FocusOnGroup))
    -- g_Game.EventManager:AddListener(EventConst.ALLIANCE_CURRENCY_UPDATED_IDS, Delegate.GetOrCreate(self, self.OnAllianceCurrencyChanged))
    g_Game.EventManager:AddListener(EventConst.UI_ALLIANCE_TECH_CURRENCY_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceCurrencyChanged))

    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.TickSec))
    self:SetupNotifyTrack(true)
    ModuleRefer.AllianceTechModule:SetDonateRank()
    self:UpdateRank()
    if self._onShowFocusGroup then
        local groupId = self._onShowFocusGroup
        local selectOnFocus = self._onShowFocusGroupAutoSelect
        self._onShowFocusGroup = nil
        self._onShowFocusGroupAutoSelect = nil
        self:FocusOnGroup(groupId, selectOnFocus or false)
    end
end

function AllianceTechResearchMediator:UpdateRank()
    local rank = ModuleRefer.AllianceTechModule.myWeekRank
    if rank == 0 then
        self.p_text_rank.text = I18N.GetWithParams("alliance_technology_rank1", I18N.Get("alliance_worldevent_rank_empty"))
    else
        self.p_text_rank.text = I18N.GetWithParams("alliance_technology_rank1", rank)
    end
end

function AllianceTechResearchMediator:OnHide(param)
    AllianceTechResearchHostProvider.Instance():SetSelectedGroup(nil)
    g_Game.EventManager:RemoveListener(EventConst.UI_ALLIANCE_TECH_GROUP_SELECTED, Delegate.GetOrCreate(self, self.OnGroupNodeSelected))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerAlliance.LastRecoverNormalDonateTime.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerAllianceDonateTimesRefresh))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerAlliance.NormalDonateTimes.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerAllianceDonateTimesRefresh))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerAlliance.TodayDonateTechPoints.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerDonatePointChanged))
    g_Game.EventManager:RemoveListener(EventConst.UI_ALLIANCE_TECH_FOCUS_ON_GROUP, Delegate.GetOrCreate(self, self.FocusOnGroup))
    -- g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_CURRENCY_UPDATED_IDS, Delegate.GetOrCreate(self, self.OnAllianceCurrencyChanged))
    g_Game.EventManager:RemoveListener(EventConst.UI_ALLIANCE_TECH_CURRENCY_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceCurrencyChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TickSec))
    self:SetupNotifyTrack(false)
end

function AllianceTechResearchMediator:OnClickBtnHelp()

end

-- 联盟资源部分改成显示个人联盟货币
-- function AllianceTechResearchMediator:SetupAllianceCurrency()
--     self._child_resource:SetVisible(true)

--     local allianceCurrency = ConfigRefer.AllianceCurrency
--     for id, v in allianceCurrency:ipairs() do
--         local comp = UIHelper.DuplicateUIComponent(self._child_resource, self._p_group_resource)
--         ---@type CommonResourceBtnData
--         local data = {}
--         data.iconName = v:Icon()
--         data.isShowPlus = false
--         data.content = string.Empty
--         comp:FeedData(data)
--         self._currencyResMap[id] = comp.Lua
--     end
--     self._child_resource:SetVisible(false)
--     self:OnAllianceCurrencyChanged(self._currencyResMap)
-- end

function AllianceTechResearchMediator:SetupAllianceCurrency()
    self._child_resource:SetVisible(true)
    local config = ConfigRefer.Item
    local allianceCoin = config:Find(AllianceModuleDefine.AllianceCurrencyItemId)
    local id = allianceCoin:Id()
    local icon = allianceCoin:Icon()
    -- for id, v in allianceCurrency:ipairs() do
    local comp = UIHelper.DuplicateUIComponent(self._child_resource, self._p_group_resource)
    ---@type CommonResourceBtnData
    local data = {}
    data.iconName = icon
    data.isShowPlus = false
    data.content = string.Empty
    data.itemId = id
    data.onClick = Delegate.GetOrCreate(self, self.OnClickAllianceCoin)
    comp:FeedData(data)
    self._currencyResMap[id] = comp.Lua
    -- end
    self._child_resource:SetVisible(false)
    self:OnAllianceCurrencyChanged(self._currencyResMap)
end

function AllianceTechResearchMediator:OnClickAllianceCoin()
    ---@type CommonItemDetailsParameter
    local param = {}
    -- param.clickTransform = self._currencyResMap[AllianceModuleDefine.AllianceCurrencyItemId].CSComponent.transform
    param.itemId = AllianceModuleDefine.AllianceCurrencyItemId
    param.itemType = require("CommonItemDetailsDefine").ITEM_TYPE.ITEM
    g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
end

function AllianceTechResearchMediator:GetAllianceCurrencyItemPos()
    return self._currencyResMap[AllianceModuleDefine.AllianceCurrencyItemId].imgIconCapsule.transform.position
end

---@param chains AllianceTechGroupChain[]
---@return {prefabIdx:number, data:AllianceTechResearchTechColumnParameter}
function AllianceTechResearchMediator.BuildTechNodeColumn(chains)
    ---@type {prefabIdx:number, data:AllianceTechResearchTechColumnParameter}
    local ret = {}
    ret.prefabIdx = 0
    ---@type AllianceTechResearchTechColumnParameter
    ret.data = {}
    ret.data.nodes = chains
    ret.data.nodePos = {}
    local nodeCount = #chains
    for i = 1, nodeCount do
        ret.data.nodePos[i] = AllianceTechResearchTechColumnHelper.CalculateCellEvenOddPos(i, nodeCount)
    end
    return ret
end

---@param last AllianceTechResearchTechColumnParameter
---@param current AllianceTechResearchTechColumnParameter
---@return {prefabIdx:number, data:AllianceTechResearchLinkerColumnParameter}
function AllianceTechResearchMediator.BuildLinkParameter(last, current)
    ---@type {prefabIdx:number, data:AllianceTechResearchLinkerColumnParameter}
    local ret = {}
    ret.prefabIdx = 1
    ---@type AllianceTechResearchLinkerColumnParameter
    ret.data = {}
    ret.data.linkMap = {}
    ret.data.leftPos2Group = {}
    ret.data.rightPos2Group = {}
    for i, v in ipairs(last.nodes) do
        for _, nextChain in pairs(v.next) do
            for j, w in ipairs(current.nodes) do
                if nextChain.id == w.id then
                    local leftPos = last.nodePos[i]
                    local rightPos = current.nodePos[j]
                    ret.data.leftPos2Group[leftPos] = v.id
                    ret.data.rightPos2Group[rightPos] = w.id
                    local posSet = ret.data.linkMap[leftPos]
                    if not posSet then
                        posSet = {}
                        ret.data.linkMap[leftPos] = posSet
                    end
                    posSet[rightPos] = true
                end
            end
        end
    end
    return ret
end

function AllianceTechResearchMediator:GenerateTableCell()
    AllianceTechResearchHostProvider.Instance():SetSelectedGroup(nil)
    self._p_table_cell:Clear()
    local cellsData = self._cells_Tab[self._currentTab]
    if not cellsData then
        cellsData = {}
        self._cells_Tab[self._currentTab] = cellsData
        local chainLvNodes = ModuleRefer.AllianceTechModule:GetTechChainByType(self._currentTab)
        if chainLvNodes then
            ---@type {d:number,v:AllianceTechGroupChain[]}[]
            local tmp = {}
            for i, v in pairs(chainLvNodes) do
                table.insert(tmp, {d = i, v = v})
            end
            table.sort(tmp, function(a, b)
                return a.d < b.d
            end)
            local lastColumn = AllianceTechResearchMediator.BuildTechNodeColumn(tmp[1].v)
            table.insert(cellsData, lastColumn)
            for i = 2, #tmp do
                local currentColumn = AllianceTechResearchMediator.BuildTechNodeColumn(tmp[i].v)
                local linkColumn = AllianceTechResearchMediator.BuildLinkParameter(lastColumn.data, currentColumn.data)
                table.insert(cellsData, linkColumn)
                table.insert(cellsData, currentColumn)
                lastColumn = currentColumn
            end
        end
    end

    for _, v in ipairs(cellsData) do
        self._p_table_cell:AppendData(v.data, v.prefabIdx)
    end
end

function AllianceTechResearchMediator:OnChangeTab(tab)
    if tab == nil or self._currentTab == tab then
        return
    end

    self._p_table_cell_rect.anchoredPosition = CS.UnityEngine.Vector2.zero
    self._currentTab = tab
    self._p_popup_detail:SetVisible(false)
    self._p_btn_side_tab_1:SetStatus(tab == self._p_btn_side_tab_1._index and 0 or 1)
    self._p_btn_side_tab_2:SetStatus(tab == self._p_btn_side_tab_2._index and 0 or 1)
    self._p_btn_side_tab_3:SetStatus(tab == self._p_btn_side_tab_3._index and 0 or 1)
    self:GenerateTableCell()
end

---@param maxPos CS.UnityEngine.Vector3
function AllianceTechResearchMediator:OnGroupNodeSelected(groupId, maxPos)
    self._p_table_cell_rect:DOKill(false)
    if not groupId then
        self._p_table_cell_rect.anchoredPosition = CS.UnityEngine.Vector2.zero
        self._p_popup_detail:SetVisible(false)
    else
        self._p_popup_detail:SetVisible(true)
        if maxPos then
            local checkRect = self._p_popup_detail_rect.rect
            local min = checkRect.min
            local worldPos = self._p_popup_detail_rect:TransformPoint(min.x, min.y, 0)
            if worldPos.x < maxPos.x then
                local offset = worldPos.x - maxPos.x
                local w = self._p_table_cell_rect.position
                w.x = w.x + offset
                local offsetLocal = self._p_table_cell_rect:InverseTransformPoint(w)
                if math.abs(offsetLocal.x) > 1 then
                    self._p_table_cell_rect:DOAnchorPosMoveX(offsetLocal.x, 0.1)
                end
            end
        end
        self._p_popup_detail:FeedData(groupId)
    end
end

function AllianceTechResearchMediator:SetupNotifyTrack(add)
    local notificationModule = ModuleRefer.NotificationModule

    local allianceTabNode = self._p_btn_side_tab_1:GetNotificationNode()
    local productionTabNode = self._p_btn_side_tab_2:GetNotificationNode()
    local fightTabNode = self._p_btn_side_tab_3:GetNotificationNode()
    if add then
        local techNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.TechTabAlliance, NotificationType.ALLIANCE_TECH_MAIN_TAB_ALLIANCE)
        notificationModule:AttachToGameObject(techNode, allianceTabNode.go, allianceTabNode.redRecommend)
        techNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.TechTabProduction, NotificationType.ALLIANCE_TECH_MAIN_TAB_PRODUCTION)
        notificationModule:AttachToGameObject(techNode, productionTabNode.go, productionTabNode.redRecommend)
        techNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.TechTabFight, NotificationType.ALLIANCE_TECH_MAIN_TAB_FIGHT)
        notificationModule:AttachToGameObject(techNode, fightTabNode.go, fightTabNode.redRecommend)
    else
        notificationModule:RemoveFromGameObject(allianceTabNode.go, false)
        notificationModule:RemoveFromGameObject(productionTabNode.go, false)
        notificationModule:RemoveFromGameObject(fightTabNode.go, false)
    end
end

function AllianceTechResearchMediator:RefreshDailyDonate()
    local playerAlliance = ModuleRefer.PlayerModule:GetPlayer().PlayerAlliance
    local allianceDonateTimes = playerAlliance and playerAlliance.TodayDonateTechPoints
    self._p_text_daily.text = I18N.GetWithParams("alliance_tec_jinrijuanxian", "")
    self.p_text_daily_num.text = I18N.Get(allianceDonateTimes)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._p_btn_help.transform)
end

function AllianceTechResearchMediator:TickSec(dt)
    if not self._needTick then
        return
    end
    self:RefreshTimes(g_Game.ServerTime:GetServerTimestampInSecondsNoFloor())
end

---@param entity wds.Player
function AllianceTechResearchMediator:OnPlayerDonatePointChanged(entity, changedData)
    if entity.ID ~= ModuleRefer.PlayerModule:GetPlayerId() then
        return
    end
    self:RefreshDailyDonate()
end

---@param entity wds.Player
function AllianceTechResearchMediator:OnPlayerAllianceDonateTimesRefresh(entity, changedData)
    if entity.ID ~= ModuleRefer.PlayerModule:GetPlayerId() then
        return
    end
    self:RefreshTimes(g_Game.ServerTime:GetServerTimestampInSecondsNoFloor())
end

function AllianceTechResearchMediator:RefreshTimes(nowTime)
    local playerAlliance = ModuleRefer.PlayerModule:GetPlayer().PlayerAlliance
    local times = playerAlliance and playerAlliance.NormalDonateTimes or 0
    local limitTime = ConfigRefer.AllianceConsts:AllianceItemDonateLimit()
    local leftTimes = math.max(0, limitTime - times)
    self._needTick = times > 0 and (playerAlliance and playerAlliance.LastRecoverNormalDonateTime.Seconds + ConfigRefer.AllianceConsts:AllianceItemDonateRecoverTime() >= nowTime)
    local recoverTimeStr = string.Empty
    if self._needTick then
        recoverTimeStr = (" (%s)"):format(TimeFormatter.SimpleFormatTime(playerAlliance.LastRecoverNormalDonateTime.Seconds + ConfigRefer.AllianceConsts:AllianceItemDonateRecoverTime() - nowTime))
    end
    self._p_text_times.text = I18N.GetWithParams("alliance_tec_jihui2", tostring(leftTimes), tostring(limitTime), recoverTimeStr)
end

function AllianceTechResearchMediator:OnClickTableEmpty()
    AllianceTechResearchHostProvider.Instance():SetSelectedGroup(nil)
end

function AllianceTechResearchMediator:OnClickHelpTip()
    ---@type TextToastMediatorParameter
    local param = {}
    param.content = I18N.Get(ConfigRefer.AllianceConsts:AllianceTechDonatePointTip())
    param.clickTransform = self._p_btn_help:GetComponent(typeof(CS.UnityEngine.RectTransform))
    ModuleRefer.ToastModule:ShowTextToast(param)
end

function AllianceTechResearchMediator:FocusOnGroup(groupId, autoSelect)
    if not groupId then
        return
    end
    local type = ModuleRefer.AllianceTechModule:GetTechTypeByGroupId(groupId)
    if not type then
        return
    end
    self:OnGroupNodeSelected(nil, nil)
    self:OnChangeTab(type)
    AllianceTechResearchHostProvider.Instance():SetSelectedGroup(nil)
    local typeCellsData = self._cells_Tab[type]
    if not typeCellsData then
        return
    end
    local matchCellData = nil
    local matchIndex
    for i, v in ipairs(typeCellsData) do
        if v.prefabIdx == 0 and v.data and v.data.nodes then
            for _, node in ipairs(v.data.nodes) do
                if node.id == groupId then
                    matchCellData = v.data
                    matchIndex = i
                    break
                end
            end
            if matchIndex then
                break
            end
        end
    end
    if not matchIndex then
        return
    end
    local focusIndex = matchIndex - 1
    if autoSelect then
        self._p_table_cell:SetDataFocus(focusIndex, 0, CS.TableViewPro.MoveSpeed.Fast, function()
            ---@type CS.DragonReborn.UI.LuaTableViewProCell
            local csCell = self._p_table_cell:GetCellLua(function(cellData, _)
                return cellData == matchCellData
            end)
            if Utils.IsNotNull(csCell) then
                ---@type AllianceTechResearchTechColumn
                local cell = csCell.Lua
                if cell then
                    local node = cell:GetNode(groupId)
                    if node then
                        node:DoSetSelectedSelf()
                        return
                    end
                end
            end
            AllianceTechResearchHostProvider.Instance():SetSelectedGroup(groupId)
        end)
    else
        self._p_table_cell:SetDataFocus(focusIndex, 0, CS.TableViewPro.MoveSpeed.Fast)
    end
end

-- function AllianceTechResearchMediator:OnAllianceCurrencyChanged(idMap)
--     for id, _ in pairs(idMap) do
--         if self._currencyResMap[id] then
--             local btn = self._currencyResMap[id]
--             local currentNum = ModuleRefer.AllianceModule:GetAllianceCurrencyById(id)
--             local type = ModuleRefer.AllianceModule:GetAllianceCurrencyTypeById(id)
--             if type == AllianceCurrencyType.Fund then
--                 btn:SetupContent( NumberFormatter.NumberAbbr(currentNum))
--             else
--                 local maxCount = ModuleRefer.AllianceModule:GetAllianceCurrencyMaxCountById(id)
--                 btn:SetupContent(NumberFormatter.NumberAbbr(math.floor(currentNum), true) .. '/' .. NumberFormatter.NumberAbbr(math.floor(maxCount), true))
--             end
--         end
--     end
-- end

function AllianceTechResearchMediator:OnAllianceCurrencyChanged(idMap)
    for id, _ in pairs(idMap) do
        if self._currencyResMap[id] then
            local btn = self._currencyResMap[id]
            local count = ModuleRefer.InventoryModule:GetAmountByConfigId(id)
            btn:SetupContent(count)
        end
    end
end

function AllianceTechResearchMediator:OnLeaveAlliance()
    self:CloseSelf()
end

function AllianceTechResearchMediator:OnClickBackBtn()
    self:BackToPrevious(nil, self._backNoAni, self._backNoAni)
end

function AllianceTechResearchMediator:OnClickBtnRank()
    g_Game.UIManager:Open(UIMediatorNames.AllianceTechRankMediator)
end

function AllianceTechResearchMediator:OnShownCellChanged()
    self._p_popup_detail:SetVisible(false)
    AllianceTechResearchHostProvider.Instance():SetSelectedGroup(nil)
end

return AllianceTechResearchMediator
