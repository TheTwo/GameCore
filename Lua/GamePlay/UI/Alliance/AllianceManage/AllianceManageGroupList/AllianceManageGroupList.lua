local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceManageGroupList:BaseUIComponent
---@field new fun():AllianceManageGroupList
---@field super BaseUIComponent
local AllianceManageGroupList = class('AllianceManageGroupList', BaseUIComponent)

---@class AllianceManageGroupListParam
---@field targetAllianceName string

function AllianceManageGroupList:ctor()
    BaseUIComponent.ctor(self)
    ---@type AllianceJoinAllianceCellData[]
    self._recommendList = {}
    ---@type AllianceJoinAllianceCellData[]
    self._searchResult = {}
    self._searchAbort = false
    self._getRecommendAbort = false
    self._inSearchMode = false
end

function AllianceManageGroupList:OnCreate(param)
    self._p_input = self:InputField("p_input", nil, nil, Delegate.GetOrCreate(self, self.OnInputSubmit))
    self._p_btn_delect = self:Button("p_btn_delect", Delegate.GetOrCreate(self, self.OnClickSearchClear))
    
    self._p_status_nofound = self:GameObject("p_status_nofound")
    self._p_text_no = self:Text("p_text_no", "not_found")
    
    self._p_table_league = self:TableViewPro("p_table_league")
    self._p_table_league:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnSelectedAllianceChanged))

    self._p_status_n = self:GameObject("p_status_n")
    ---@type AllianceManageGroupListInfoPanel
    self._p_right_panel = self:LuaObject("p_right_panel")
end

---@param param AllianceManageGroupListParam
function AllianceManageGroupList:OnShow(param)
    self._p_right_panel:AddEvents()
    self._getRecommendAbort = false
    self._searchAbort = false
    if param and param.targetAllianceName then
        self._p_input.text = param.targetAllianceName
        self:BeginChangeMode(true)
    else
        self:BeginChangeMode(false)
    end
end

function AllianceManageGroupList:OnHide(param)
    self._p_right_panel:RemoveEvents()
    self._p_table_league:Clear()
    self._getRecommendAbort = true
    self._searchAbort = true
end

function AllianceManageGroupList:OnClose(param)
    self._p_table_league:SetSelectedDataChanged(nil)
end

function AllianceManageGroupList:BeginChangeMode(isSearch)
    self._p_table_league:UnSelectAll()
    self._p_right_panel:FeedData(nil)
    if isSearch then
        self._p_input.interactable = false
        self._p_btn_delect:SetVisible(true)
        if not self._inSearchMode then
            self._p_table_league:Clear()
        end
        ModuleRefer.AllianceModule:FindAlliances(self._p_input.text, Delegate.GetOrCreate(self, self.OnGetSearchData))
    else
        self._p_input.text = string.Empty
        self._p_input.interactable = false
        self._p_btn_delect:SetVisible(false)
        if self._inSearchMode then
            self._p_table_league:Clear()
        end
        ModuleRefer.AllianceModule:GetRecommendedAlliances(1, Delegate.GetOrCreate(self, self.OnGetRecommendData))
    end
end

---@param isSearch boolean
function AllianceManageGroupList:EndChangeMode(isSearch)
    self._inSearchMode = isSearch
    self._p_table_league:Clear()
    if isSearch then
        for _, v in ipairs(self._searchResult) do
            self._p_table_league:AppendData(v)
        end
        if #self._searchResult > 0 then
            self._p_status_nofound:SetVisible(false)
            self._p_table_league:SetVisible(true)
            self._p_table_league:SetToggleSelectIndex(0)
        else
            self._p_table_league:SetVisible(false)
            self._p_status_nofound:SetVisible(true)
            self._p_right_panel:FeedData(nil)
        end
    else
        self._p_status_nofound:SetVisible(false)
        for _, v in ipairs(self._recommendList) do
            self._p_table_league:AppendData(v)
        end
        if #self._recommendList > 0 then
            self._p_table_league:SetVisible(true)
            self._p_table_league:SetToggleSelectIndex(0)
        else
            self._p_table_league:SetVisible(false)
            self._p_right_panel:FeedData(nil)
        end
    end
    self._p_table_league:Play(true)
end

function AllianceManageGroupList:OnInputSubmit(text)
    if string.IsNullOrEmpty(self._p_input.text) then
        return
    end
    self:BeginChangeMode(true)
end

function AllianceManageGroupList:OnClickSearchClear()
    self:BeginChangeMode(false)
end

---@param cmd GetRecommendedAlliancesParameter
---@param isSuccess boolean
---@param rsp wrpc.GetRecommendedAlliancesReply
function AllianceManageGroupList:OnGetRecommendData(cmd, isSuccess, rsp)
    self._p_input.interactable = true
    if self._getRecommendAbort then
        return
    end
    table.clear(self._recommendList)
    if isSuccess then
        for _, v in ipairs(rsp.Infos) do
            if v.ID ~= ModuleRefer.AllianceModule:GetAllianceId() then
                ---@type AllianceJoinAllianceCellData
                local data = {
                    info = v,
                    isApplied = false
                }
                table.insert(self._recommendList, data)
            end
        end
    end
    self:EndChangeMode(false)
end

---@param cmd FindAlliancesParameter
---@param isSuccess boolean
---@param rsp wrpc.FindAlliancesReply
function AllianceManageGroupList:OnGetSearchData(cmd, isSuccess, rsp)
    self._p_input.interactable = true
    if self._searchAbort then
        return
    end
    table.clear(self._searchResult)
    if isSuccess then
        for _, v in ipairs(rsp.Infos) do
            if v.ID ~= ModuleRefer.AllianceModule:GetAllianceId() then
                ---@type AllianceJoinAllianceCellData
                local data = {
                    info = v,
                    isApplied = false
                }
                table.insert(self._searchResult, data)
            end
        end
    end
    self:EndChangeMode(true)
end

---@param selected AllianceJoinAllianceCellData
function AllianceManageGroupList:OnSelectedAllianceChanged(last, selected)
    self._p_right_panel:FeedData(selected and selected.info or nil)
end

return AllianceManageGroupList