local BaseUIComponent = require('BaseUIComponent')
local UIHelper = require('UIHelper')
local Delegate = require('Delegate')
local GetTopListParameter = require('GetTopListParameter')
local ModuleRefer = require("ModuleRefer")
---@class CommonLeaderboardPopupBoard : BaseUIComponent
local CommonLeaderboardPopupBoard = class('CommonLeaderboardPopupBoard', BaseUIComponent)

---@class CommonLeaderboardPopupBoardParam
---@field stageNames string[]
---@field leaderboardIds table<number, number[]>
---@field topListDatas table<number, number[]>
---@field leaderboardTitles table<number, string[]>
---@field curStage number

function CommonLeaderboardPopupBoard:OnCreate()
    self.goPaginator = self:GameObject('p_time')
    self.btnPaginatorLeft = self:Button('p_btn_left', Delegate.GetOrCreate(self, self.OnBtnPaginatorLeftClick))
    self.btnPaginatorRight = self:Button('p_btn_right', Delegate.GetOrCreate(self, self.OnBtnPaginatorRightClick))
    self.textPaginator = self:Text('p_text_hint_reward')
    ---@type CommonLeaderboardPopupBoardTab
    self.tabTemplate = self:LuaBaseComponent('p_btn_tab')
    ---@type CommonLeaderboardPopupBoardTopList
    self.luaTopList = self:LuaObject('p_top_list')
end

function CommonLeaderboardPopupBoard:OnShow()
    g_Game.ServiceManager:AddResponseCallback(GetTopListParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnGetTopListResponse))
end

function CommonLeaderboardPopupBoard:OnHide()
    g_Game.ServiceManager:RemoveResponseCallback(GetTopListParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnGetTopListResponse))
end

---@param param CommonLeaderboardPopupBoardParam
function CommonLeaderboardPopupBoard:OnFeedData(param)
    self.leaderboardIds = param.leaderboardIds
    self.titles = param.leaderboardTitles
    self.stageNames = param.stageNames
    -- self.topListDatas = param.topListDatas
    self.curStage = param.curStage
    self:ReleaseTabs()
    self:InitTabs()
    self:OnTabClicked(1)
    if #self.stageNames <= 1 then
        self.goPaginator:SetActive(false)
    else
        self.goPaginator:SetActive(true)
        self.textPaginator.text = self.stageNames[self.curStage]
    end
end

function CommonLeaderboardPopupBoard:InitTabs()
    self.tabs = {}
    self.tabTemplate:SetVisible(true)
    for index = 1, #(self.leaderboardIds[self.curStage] or {}) do
        local tab = UIHelper.DuplicateUIComponent(self.tabTemplate)
        tab:FeedData({
            title = self.titles[index],
            isSelcted = index == 1,
            onClick = function()
                self:OnTabClicked(index)
            end,
        })
        table.insert(self.tabs, tab)
    end
    self.tabTemplate:SetVisible(false)
end

function CommonLeaderboardPopupBoard:ReleaseTabs()
    if not self.tabs then self.tabs = {} end
    for _, tab in ipairs(self.tabs) do
        UIHelper.DeleteUIComponent(tab)
    end
    self.tabs = {}
end

function CommonLeaderboardPopupBoard:OnTabClicked(index)
    for i = 1, #self.tabs do
        if i == index then
            self.tabs[i].Lua:Select()
        else
            self.tabs[i].Lua:Unselect()
        end
    end
    if not self.leaderboardIds[self.curStage] or not self.leaderboardIds[self.curStage][index] then
        return
    end
    self.selectIndex = index
    local leaderBoardId = self.leaderboardIds[self.curStage][index]
    ModuleRefer.LeaderboardModule:SendGetTopList(leaderBoardId, 1, 100)
end

function CommonLeaderboardPopupBoard:OnBtnPaginatorLeftClick()
    self.curStage = (self.curStage - 2) % (#self.stageNames) + 1
    self:ReleaseTabs()
    self:InitTabs()
    self:OnTabClicked(self.selectIndex)
    self.textPaginator.text = self.stageNames[self.curStage]
end

function CommonLeaderboardPopupBoard:OnBtnPaginatorRightClick()
    self.curStage = (self.curStage) % (#self.stageNames) + 1
    self:ReleaseTabs()
    self:InitTabs()
    self:OnTabClicked(self.selectIndex)
    self.textPaginator.text = self.stageNames[self.curStage]
end

function CommonLeaderboardPopupBoard:OnGetTopListResponse(isSuccess, reply, req)
    if not isSuccess then
        return
    end
    ---@type LeaderboardTopListPageData
    local data = {}
    data.reply = reply
    data.req = req.request
    self.luaTopList:FeedData(data)
end

return CommonLeaderboardPopupBoard