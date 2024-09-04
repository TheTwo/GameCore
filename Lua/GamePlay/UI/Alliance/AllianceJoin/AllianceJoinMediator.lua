--- scene:scene_league_join

local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")
local GetAllianceBasicInfoParameter = require("GetAllianceBasicInfoParameter")
local BaseUIMediator = require("BaseUIMediator")

---@class AllianceJoinMediator:BaseUIMediator
---@field new fun():AllianceJoinMediator
---@field super BaseUIMediator
local AllianceJoinMediator = class('AllianceJoinMediator', BaseUIMediator)

---@class AllianceJoinMediatorData
---@field targetAllianceName string

function AllianceJoinMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type AllianceJoinAllianceCellData[]
    self._recommendList = {}
    ---@type AllianceJoinAllianceCellData[]
    self._searchResult = {}
    self._searchAbort = false
    self._getRecommendAbort = false
    self._inSearchMode = false
end

function AllianceJoinMediator:OnCreate(param)
    ---@type CommonBackButtonComponent
    self._child_common_btn_back = self:LuaObject("child_common_btn_back")
    self._p_input = self:InputField("p_input", Delegate.GetOrCreate(self, self.OnInputChanged), Delegate.GetOrCreate(self, self.OnInputEnd))
    self._p_btn_delect = self:Button("p_btn_delect", Delegate.GetOrCreate(self, self.OnClickSearchClear))
    self._p_btn_search = self:Button("p_btn_search", Delegate.GetOrCreate(self, self.OnClickSearch))
    self._p_text_search = self:Text("p_text_search", "confirm")
    self._p_text_Placeholder = self:Text("p_text_Placeholder", "search_input")
    self._p_status_nofound = self:GameObject("p_status_nofound")
    self._p_text_no = self:Text("p_text_no", "not_found")
    self._p_table_league = self:TableViewPro("p_table_league")
    self._p_table_league:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnSelectedAllianceChanged))
    
    self._p_status_noleague = self:GameObject("p_status_noleague")
    self._p_p_text_noleague = self:Text("p_text_noleague", I18N.Temp().hint_no_alliance)
    
    self._p_status_n = self:GameObject("p_status_n")
    
    ---@type AllianceJoinSelectedDetailComponent
    self._p_selected_alliance_detail = self:LuaObject("p_selected_alliance_detail")
    
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickGoToCreate))
    self._p_text_btn_goto = self:Text("p_text_btn_goto", "create_league")
    self._getRecommendAbort = false
    self._searchAbort = false

    self.p_group_tab = self:GameObject("p_group_tab")
    ---@type CommonButtonTab
    self.p_tab_btn_league = self:LuaObject("p_tab_btn_league")
    ---@type CommonButtonTab
    self.p_tab_btn_invitation = self:LuaObject("p_tab_btn_invitation")
end

---@param param AllianceJoinMediatorData
function AllianceJoinMediator:OnShow(param)
    self:FeedSubPart() 
    self:AddEvents() 
    if param and param.targetAllianceName then
        self:ToTargetAlliance(param.targetAllianceName)
    else
        self:BeginChangeMode(false)
    end
    self:InitTab()
end

function AllianceJoinMediator:OnHide(param)
    self:RemoveEvents()
end

function AllianceJoinMediator:OnClose(data)
    self._getRecommendAbort = true
    self._searchAbort = true
    self.super.OnClose(self)
end

function AllianceJoinMediator:ToTargetAlliance(allianceName)
    self._p_input.text = allianceName
    self:BeginChangeMode(true)
end

function AllianceJoinMediator:BeginChangeMode(isSearch)
    self._p_table_league:UnSelectAll()
    self._p_selected_alliance_detail:SetVisible(false)
    if isSearch then
        self._p_btn_search:SetVisible(false)
        self._p_btn_delect:SetVisible(true)
        if not self._inSearchMode then
            self._p_table_league:Clear()
        end
        ModuleRefer.AllianceModule:FindAlliances(self._p_input.text, Delegate.GetOrCreate(self, self.OnGetSearchData))
    else
        self._p_input.text = string.Empty
        self._p_btn_search:SetVisible(true)
        self._p_btn_delect:SetVisible(false)
        if self._inSearchMode then
            self._p_table_league:Clear()
        end
        ModuleRefer.AllianceModule:GetRecommendedAlliances(1, Delegate.GetOrCreate(self, self.OnGetRecommendData))
    end
end

---@param isSearch boolean
function AllianceJoinMediator:EndChangeMode(isSearch)
    self._inSearchMode = isSearch
    self._p_table_league:Clear()
    if isSearch then
        self._p_status_noleague:SetVisible(false)
        for _, v in ipairs(self._searchResult) do
            self._p_table_league:AppendData(v)
        end
        if #self._searchResult > 0 then
            self._p_status_nofound:SetVisible(false)
            self._p_status_n:SetVisible(true)
            self._p_table_league:SetToggleSelectIndex(0)
        else
            self._p_status_n:SetVisible(false)
            self._p_status_nofound:SetVisible(true)
        end
    else
        self._p_status_nofound:SetVisible(false)
        for _, v in ipairs(self._recommendList) do
            self._p_table_league:AppendData(v)
        end
        if #self._recommendList > 0 then
            self._p_status_noleague:SetVisible(false)
            self._p_status_n:SetVisible(true)
            self._p_table_league:SetToggleSelectIndex(0)
        else
            self._p_status_noleague:SetVisible(true)
            self._p_status_n:SetVisible(false)
        end
    end
end

---@param selected AllianceJoinAllianceCellData
function AllianceJoinMediator:OnSelectedAllianceChanged(last, selected)
    self._p_selected_alliance_detail:FeedData(selected and selected.info or nil)
end

function AllianceJoinMediator:OnClickGoToCreate()
    self:CloseSelf(nil, true)
    g_Game.UIManager:Open(UIMediatorNames.AllianceCreationMediator)
end

function AllianceJoinMediator:OnInputChanged(text)
    self._p_btn_search.interactable = false
end

function AllianceJoinMediator:OnInputEnd(text)
    self._p_btn_search.interactable = true
end

function AllianceJoinMediator:OnClickSearchClear()
    self:BeginChangeMode(false)
end

function AllianceJoinMediator:OnClickSearch()
    if string.IsNullOrEmpty(self._p_input.text) then
        return
    end
    self:BeginChangeMode(true)
end

function AllianceJoinMediator:FeedSubPart()
    ---@type CommonBackButtonData
    local btnData = {
        title = I18N.Get("join_league")
    }
    self._child_common_btn_back:FeedData(btnData)
end

function AllianceJoinMediator:AddEvents()
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_JOINED_WITH_DATA_READY, Delegate.GetOrCreate(self, self.OnJoinAlliance))
    self._p_selected_alliance_detail:AddEvents()
end

function AllianceJoinMediator:RemoveEvents()
    self._p_selected_alliance_detail:RemoveEvents()
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_JOINED_WITH_DATA_READY, Delegate.GetOrCreate(self, self.OnJoinAlliance))
end

---@param cmd GetRecommendedAlliancesParameter
---@param isSuccess boolean
---@param rsp wrpc.GetRecommendedAlliancesReply
function AllianceJoinMediator:OnGetRecommendData(cmd, isSuccess, rsp)
    if self._getRecommendAbort then
        return
    end
    table.clear(self._recommendList)
    if isSuccess then
        local appliedAllianceMap
        local playerAlliance = ModuleRefer.PlayerModule:GetPlayer().PlayerAlliance
        appliedAllianceMap = playerAlliance and playerAlliance.AppliedAllianceIDs or {}
        for _, v in ipairs(rsp.Infos) do
            ---@type AllianceJoinAllianceCellData
            local data = {
                info = v,
                isApplied = appliedAllianceMap[v.ID] and true or false
            }
            table.insert(self._recommendList, data)
        end
    end
    self:EndChangeMode(false)
end

---@param cmd FindAlliancesParameter
---@param isSuccess boolean
---@param rsp wrpc.FindAlliancesReply
function AllianceJoinMediator:OnGetSearchData(cmd, isSuccess, rsp)
    if self._searchAbort then
        return
    end
    table.clear(self._searchResult)
    if isSuccess then
        local appliedAllianceMap
        local playerAlliance = ModuleRefer.PlayerModule:GetPlayer().PlayerAlliance
        appliedAllianceMap = playerAlliance and playerAlliance.AppliedAllianceIDs or {}
        for _, v in ipairs(rsp.Infos) do
            ---@type AllianceJoinAllianceCellData
            local data = {
                info = v,
                isApplied = appliedAllianceMap[v.ID] and true or false
            }
            table.insert(self._searchResult, data)
        end
    end
    self:EndChangeMode(true)
end

---@param current wrpc.AllianceBriefInfo
function AllianceJoinMediator:OnSelectionChanged(last, current)
    self._p_selected_alliance_detail:FeedData(current)
end

function AllianceJoinMediator:OnJoinAlliance()
    self:CloseSelf(nil, true)
    ---@type AllianceMainMediatorParameter
    local openParameter = {
        showJoinAni = true
    }
    g_Game.UIManager:Open(UIMediatorNames.AllianceMainMediator, openParameter)
end

function AllianceJoinMediator:InitTab()
    local alliances = ModuleRefer.AllianceModule:GetRecuirtAllianceInfo()
    self.p_group_tab:SetVisible(#alliances > 0)
    ---@type CommonButtonTab
    local tabRuleParam = {}
    tabRuleParam.text = I18N.Get('#联盟列表')
    tabRuleParam.callback = Delegate.GetOrCreate(self, self.OnListTabClicked)
    self.p_tab_btn_league:FeedData(tabRuleParam)

    ---@type CommonButtonTab
    local tabRuleParam = {}
    tabRuleParam.text = I18N.Get('#入盟邀请')
    tabRuleParam.callback = Delegate.GetOrCreate(self, self.OnInviteTabClicked)
    self.p_tab_btn_invitation:FeedData(tabRuleParam)
end

function AllianceJoinMediator:OnListTabClicked()
    self.p_tab_btn_league:ChangeSelectTab(true)
    self.p_tab_btn_invitation:ChangeSelectTab(false)
    self:BeginChangeMode(false)
    self._p_selected_alliance_detail:SetIsInvited(false)
end

function AllianceJoinMediator:OnInviteTabClicked()
    self.p_tab_btn_league:ChangeSelectTab(false)
    self.p_tab_btn_invitation:ChangeSelectTab(true)

    local alliances = ModuleRefer.AllianceModule:GetRecuirtAllianceInfo()
    local sendCmd = GetAllianceBasicInfoParameter.new()
    sendCmd.args.AllianceIDs:AddRange(alliances)
    sendCmd:SendOnceCallback(false,nil,true,function(cmd, isSuccess, rsp)
        if isSuccess then
            self._p_table_league:Clear()
            self._p_status_noleague:SetVisible(false)
            for _, v in ipairs(rsp.Infos) do
                self._p_table_league:AppendData({info = v})
            end
            self._p_table_league:SetToggleSelectIndex(0)
            self._p_selected_alliance_detail:SetIsInvited(true)
        end
    end)
end

return AllianceJoinMediator