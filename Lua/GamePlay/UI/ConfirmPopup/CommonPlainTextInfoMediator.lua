---scene: scene_activity_popup_rule
local BaseUIMediator = require("BaseUIMediator")
local I18N = require('I18N')
local Delegate = require('Delegate')
local UIHelper = require('UIHelper')
local LuaReusedComponentPool = require('LuaReusedComponentPool')
local GetTopListParameter = require('GetTopListParameter')
local ModuleRefer = require('ModuleRefer')

---@class CommonPlainTextInfoMediator:BaseUIMediator
---@field tab number
local CommonPlainTextInfoMediator = class("CommonPlainTextInfoMediator", BaseUIMediator)

---@class CommonPlainTextContent
---@field selectedIndex number
---@field list CommonPlainTextContentCell[]

---@class CommonPlainTextContentCell
---@field title string
---@field rule string
---@field hint string
---@field reward ItemIconData[]
---@field isSelected boolean


---@class CommonPlainTextInfoParam
---@field title string
---@field tabs table
---@field contents table
---@field leaderboardId number
---@field leaderboardActivityID number @LeaderboardActivity
---@field startTab number
---@field onClose fun()

function CommonPlainTextInfoMediator:OnCreate()
    self.textContent = self:Text("p_text_rule")
    self.luaBackGround = self:LuaObject("child_popup_base_m")
    self.ui_common_content = self:GameObject('ui_common_content')
    self.p_group_rank_board = self:GameObject('p_group_rank_board')
    -- 父节点
    self.p_rule_root = self:Transform('p_rule_root')
    self.mask_tab = self:Transform('mask_tab')

    -- tab
    ---@type CommonInfoTab
    self.p_tab = self:LuaBaseComponent('p_tab')

    -- 组件
    ---@type CommonInfoTitle
    self.p_title = self:LuaBaseComponent('p_title')
    ---@type CommonInfoRule
    self.p_item_text = self:LuaBaseComponent('p_item_text') -- 白色文本
    ---@type CommonInfoHint
    self.p_text_hint = self:LuaBaseComponent('p_text_hint') -- 红色文本
    ---@type CommonInfoReward
    self.p_reward = self:LuaBaseComponent('p_reward')
    ---@see LeaderboardTopListPage
    self.p_group_rank_board = self:LuaBaseComponent('p_group_rank_board') -- 排行榜
    ---@type CS.UnityEngine.UI.ScrollRect
    self.p_scroll_rect = self:ScrollRect("scroll_content")
    self.p_scroll_rect:CalculateLayoutInputVertical()

    self.p_group_rule = self:GameObject('p_group_rule')
    self.p_reward_now = self:GameObject('p_reward_now')
    self.p_text_reward = self:Text('p_text_reward', 'alliance_activity_big17')
    self.p_text_score = self:Text('p_text_score')
    self.p_table_reward_now = self:TableViewPro('p_table_reward_now')
    self.p_text_reward_hint = self:Text('p_text_reward_hint', 'alliance_activity_big19')

    -- Transform
    self.p_group_tabs = self:Transform('p_group_tabs')

    -- 对象池
    self.pool_tabs = LuaReusedComponentPool.new(self.p_tab, self.p_group_tabs)

    self.p_title:SetVisible(false)
    self.p_item_text:SetVisible(false)
    self.p_text_hint:SetVisible(false)
    self.p_reward:SetVisible(false)
    self.p_tab:SetVisible(false)

    self.tabHolder = {}
    self.contentComps = {}
end

---@param param CommonPlainTextInfoParam
function CommonPlainTextInfoMediator:OnOpened(param)
    ---@type CommonBackButtonData
    local backgroundData = {}
    backgroundData.title = param.title
    backgroundData.onClose = param.onClose
    self.luaBackGround:FeedData(backgroundData)

    self.pool_tabs:HideAll()
    self.param = param
    for i = 1, #param.tabs do
        local data = {}
        data.selected = false
        data.icon = param.tabs[i]
        data.onClick = Delegate.GetOrCreate(self, function()
            self:SwitchTab(i)
        end)
        local item = self.pool_tabs:GetItem().Lua
        item:FeedData(data)
        table.insert(self.tabHolder, item)
    end

    self:SwitchTab(param.startTab or 1)
end

function CommonPlainTextInfoMediator:OnShow()
    g_Game.ServiceManager:AddResponseCallback(GetTopListParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnGetTopListResponse))
end

function CommonPlainTextInfoMediator:OnHide()
    g_Game.ServiceManager:RemoveResponseCallback(GetTopListParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnGetTopListResponse))
end

function CommonPlainTextInfoMediator:SwitchTab(tab)
    self.tab = tab
    for i = 1, #self.tabHolder do
        if i == tab then
            self.tabHolder[i]:ChangeSelectTab(true)
        else
            self.tabHolder[i]:ChangeSelectTab(false)
        end
    end

    self:ClearContents()
    local content = self.param.contents[tab]
    if content.leaderboardId then
        self:ShowRankBoard(content)
    else
        self:ShowContents(content)
    end
end

function CommonPlainTextInfoMediator:ShowRankBoard(content)
    local leaderboardId = content.leaderboardId
    self.p_group_rule:SetActive(false)
    ModuleRefer.LeaderboardModule:SendGetTopList(leaderboardId, 1, 100)
end

---@param content CommonPlainTextContent
function CommonPlainTextInfoMediator:ShowContents(content)
    self.p_group_rank_board:SetVisible(false)
    self.p_group_rule:SetActive(true)
    
    local myReward, myRule, noRank
    for i = 1, #content.list do
        local cell = content.list[i]
        if not cell then
            goto continue
        end
        
        local comp
        if cell.title then
            comp = UIHelper.DuplicateUIComponent(self.p_title, self.p_rule_root)
            comp:FeedData(cell.title)
            comp:SetVisible(true)
        elseif cell.rule then
            if cell.isSelected then
                myRule = cell.rule
            end
            comp = UIHelper.DuplicateUIComponent(self.p_item_text, self.p_rule_root)
            comp:FeedData(cell)
            comp:SetVisible(true)
        elseif cell.hint then
            comp = UIHelper.DuplicateUIComponent(self.p_text_hint, self.p_rule_root)
            comp:FeedData(cell.hint)
            comp:SetVisible(true)
        elseif cell.reward then
            if cell.isSelected then
                myReward = cell.reward
            end
            comp = UIHelper.DuplicateUIComponent(self.p_reward, self.p_rule_root)
            comp:FeedData(cell)
            comp:SetVisible(true)
        end
        table.insert(self.contentComps, comp)
        ::continue::
    end

    if content.selectedIndex then
        self.p_reward_now:SetActive(true)
        self:RefreshMyRewardInfo(myRule, myReward)
    else
        self.p_reward_now:SetActive(false)
    end
end

function CommonPlainTextInfoMediator:ClearContents()
    for k, v in pairs(self.contentComps) do
        UIHelper.DeleteUIComponent(v)
    end
    self.contentComps = {}
end

---@param isSuccess boolean
---@param reply wrpc.GetTopListReply
---@param req AbstractRpc
function CommonPlainTextInfoMediator:OnGetTopListResponse(isSuccess, reply, req)
    if not isSuccess then return end

    -- local rapidjson = require('rapidjson')
    -- g_Logger.Error(rapidjson.encode(reply))

    self.p_group_rank_board:SetVisible(true)

    local content = self.param.contents[self.tab]

    ---@type LeaderboardTopListPageData
    local data = {}
    data.reply = reply
    data.req = req.request
    data.leaderboardActivityID = self.param.leaderboardActivityID
    data.title = content.title
    data.tip = content.tip
    self.p_group_rank_board:FeedData(data)
end

---@param myRule string
---@param myReward ItemIconData[]
function CommonPlainTextInfoMediator:RefreshMyRewardInfo(myRule, myReward)
    local hasRank = myRule and myReward and true or false
    self.p_table_reward_now:SetVisible(hasRank)
    self.p_text_score:SetVisible(hasRank)
    self.p_text_reward_hint:SetVisible(not hasRank)
    
    if hasRank then
        self.p_table_reward_now:Clear()
        for k, v in ipairs(myReward) do
            ---@type ItemIconData
            local iconData = {}
            iconData.configCell = v.configCell
            if not v.count or v.count == 0 then
                iconData.showCount = false
            else
                iconData.count = v.count
            end
            self.p_table_reward_now:AppendData(iconData)
        end
        self.p_text_score.text = myRule
    end
end

return CommonPlainTextInfoMediator
