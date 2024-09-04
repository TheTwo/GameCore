---scene scene_world_trend_main
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local EarthRevivalDefine = require('EarthRevivalDefine')
local NotificationType = require('NotificationType')
local UIMediatorNames = require('UIMediatorNames')
local DBEntityPath = require('DBEntityPath')
local CommonLeaderboardPopupDefine = require('CommonLeaderboardPopupDefine')
local ActivityRewardType = require('ActivityRewardType')

---@class EarthRevivalMediator : BaseUIMediator
local EarthRevivalMediator = class('EarthRevivalMediator', BaseUIMediator)

---@class EarthRevivalUIParameter
---@field tabIndex number
---@field defaultStage number
---@field defaultActivityId number


function EarthRevivalMediator:OnCreate()
    self.compChildCommonBack = self:LuaObject('child_common_btn_back')

    --TOP
    self.btnTabNews = self:Button('p_btn_tab_news', Delegate.GetOrCreate(self, self.OnClickTabNews))
    self.statusNews = self:StatusRecordParent('p_btn_tab_news')
    self.textOnNews = self:Text('p_text_on_news', "worldstage_xinwen")
    self.textOffNews = self:Text('p_text_off_news', "worldstage_xinwen")
    self.reddotNews = self:LuaObject('p_reddot_news')

    self.btnTabMap = self:Button('p_btn_tab_map', Delegate.GetOrCreate(self, self.OnClickTabMap))
    self.statusMap = self:StatusRecordParent('p_btn_tab_map')
    self.textOnMap = self:Text('p_text_on_map', "worldstage_jushi")
    self.textOffMap = self:Text('p_text_off_map', "worldstage_jushi")
    self.reddotMap = self:LuaObject('p_reddot_map')

    self.btnTabTask = self:Button('p_btn_tab_task', Delegate.GetOrCreate(self, self.OnClickTabMask))
    self.statusTask = self:StatusRecordParent('p_btn_tab_task')
    self.textOnTask = self:Text('p_text_on_task', "worldstage_xingdong")
    self.textOffTask = self:Text('p_text_off_task', "worldstage_xingdong")
    self.reddotTask = self:LuaObject('p_reddot_task')

    self.btnShop = self:Button('p_btn_shop', Delegate.GetOrCreate(self, self.OnClickTabShop))
    self.statusShop = self:StatusRecordParent('p_btn_shop')
    self.textOnShop = self:Text('p_text_on_shop', "worldstage_tinder_store")
    self.textOffShop = self:Text('p_text_off_shop', "worldstage_tinder_store")
    self.reddotShop = self:LuaObject('p_reddot_shop')
    self.luagoResource = self:LuaObject('child_resource')

    self.btnRank = self:Button('p_btn_rank', Delegate.GetOrCreate(self, self.OnBtnRankClick))
    self.luaItem1 = self:LuaObject('child_item_standard_s_2')
    self.luaItem2 = self:LuaObject('child_item_standard_s_1')

    self.btnTimeline = self:Button('p_btn_timeline', Delegate.GetOrCreate(self, self.OnBtnTimelineClick))

    --Content
    self.goNews = self:GameObject('p_group_news')
    self.luagoNews = self:LuaObject('p_group_news')
    self.goMap = self:GameObject('p_group_map')
    self.luagoMap = self:LuaObject('p_group_map')
    self.goTask = self:GameObject('p_group_task')
    self.luagoTask = self:LuaObject('p_group_task')
    self.goShop = self:GameObject('p_group_shop')
    self.luagoShop = self:LuaObject('p_group_shop')

    self:GameObject('ani_news_in'):SetActive(true)
    self.btnTabTask.gameObject:SetActive(false)

    self.reddotShop:SetVisible(false)

    self.reddotTimeline = self:LuaObject('child_reddot_default')
end

---@param param EarthRevivalUIParameter | string
function EarthRevivalMediator:OnOpened(param)
    self.compChildCommonBack:FeedData({
        title = I18N.Get("worldstage_csjh")
    })

    if param and param.tabIndex then
        self:TabClicked(param.tabIndex, param.defaultStage, param.defaultActivityId)
    elseif type(param) == "string" then
        if param == "Shop" then
            self:TabClicked(EarthRevivalDefine.EarthRevivalTabType.Shop)
        else
            local id = tonumber(param)
            if id > 0 then
                self:TabClicked(EarthRevivalDefine.EarthRevivalTabType.News, nil, id)
            else
                local arId = ModuleRefer.ActivityCenterModule:GetCurOpeningAutoRewardId(ActivityRewardType.FirePlan)
                local tabId = 0
                for _, v in ConfigRefer.ActivityCenterTabs:pairs() do
                    if v:RefActivityReward() == arId then
                        tabId = v:Id()
                        break
                    end
                end
                self:TabClicked(EarthRevivalDefine.EarthRevivalTabType.News, nil, tabId)
            end
        end
    else
        self:TabClicked(ModuleRefer.EarthRevivalModule:GetOpenTabIndex())
    end

    self:UpdateResource()
    self:InitTopRewards()

    --Reddot
    self.reddotNews:SetVisible(true)
    local newsNode = ModuleRefer.NotificationModule:GetDynamicNode("EarthRevivalTabNewsNode", NotificationType.EARTHREVIVAL_TAB_NEWS)
    ModuleRefer.NotificationModule:AttachToGameObject(newsNode, self.reddotNews.go, self.reddotNews.redDot)

    self.reddotMap:SetVisible(false)
    ModuleRefer.EarthRevivalModule:AttachToTabMapRedDot(self.reddotMap.go)

    self.reddotTask:SetVisible(true)
    local taskNode = ModuleRefer.EarthRevivalModule.taskModule:GetReddotNode()
    ModuleRefer.NotificationModule:AttachToGameObject(taskNode, self.reddotTask.go, self.reddotTask.redDot)

    self.reddotTimeline:SetVisible(true)
    local timelineNode = ModuleRefer.EarthRevivalModule.timelineRedDot
    ModuleRefer.NotificationModule:AttachToGameObject(timelineNode, self.reddotTimeline.go, self.reddotTimeline.redDot)
end

function EarthRevivalMediator:OnShow()
    ModuleRefer.EarthRevivalModule:RefreshNewsRedDot()
    ModuleRefer.EarthRevivalModule.taskModule:UpdateReddot()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Currency.MsgPath,Delegate.GetOrCreate(self, self.OnResourceChanged))
    g_Game.EventManager:AddListener(EventConst.ON_FIRE_PLAN_BTN_SHOP_CLICK, Delegate.GetOrCreate(self, self.OnClickTabShop))
end

function EarthRevivalMediator:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ON_FIRE_PLAN_BTN_SHOP_CLICK, Delegate.GetOrCreate(self, self.OnClickTabShop))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Currency.MsgPath,Delegate.GetOrCreate(self, self.OnResourceChanged))
end

function EarthRevivalMediator:OnClose()
    ModuleRefer.EarthRevivalModule:RefreshRedDot()
end

function EarthRevivalMediator:UpdateResource()
    local curSeason = ModuleRefer.WorldTrendModule:GetCurSeason()
    local seasonConfig = ConfigRefer.WorldSeason:Find(curSeason)
    if seasonConfig then
        ---@type CommonResourceBtnSimplifiedData
        local param = {itemId = seasonConfig:StageScoreItem()}
        param.onClick = function ()
            ---@type CommonItemDetailsParameter
            local data = {}
            data.itemId = seasonConfig:StageScoreItem()
            data.itemType = require("CommonItemDetailsDefine").ITEM_TYPE.ITEM
            g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, data)
        end
        self.luagoResource:FeedData(param)
    end
end

function EarthRevivalMediator:InitTopRewards()
    local playerLeaderboardId, _ = ModuleRefer.EarthRevivalModule:GetCurOpeningLeaderboardId()
    if playerLeaderboardId == 0 then
        g_Logger.ErrorChannel("EarthRevivalMediator", "火种行动未开启或未配置排行榜")
        return
    end
    local cfg = ConfigRefer.LeaderboardActivity:Find(playerLeaderboardId)
    local topRewards = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(cfg:RewardItemGroup(1))
    if topRewards[1] then
        self.luaItem1:SetVisible(true)
        topRewards[1].showCount = false
        self.luaItem1:FeedData(topRewards[1])
    else
        self.luaItem1:SetVisible(false)
    end

    if topRewards[2] then
        self.luaItem2:SetVisible(true)
        topRewards[2].showCount = false
        self.luaItem2:FeedData(topRewards[2])
    else
        self.luaItem2:SetVisible(false)
    end
end

function EarthRevivalMediator:OnClickTabNews()
    self:TabClicked(EarthRevivalDefine.EarthRevivalTabType.News)
end

function EarthRevivalMediator:OnClickTabMap()
    self:TabClicked(EarthRevivalDefine.EarthRevivalTabType.Map)
end

function EarthRevivalMediator:OnClickTabMask()
    self:TabClicked(EarthRevivalDefine.EarthRevivalTabType.Task)
end

function EarthRevivalMediator:OnClickTabShop()
    self:TabClicked(EarthRevivalDefine.EarthRevivalTabType.Shop)
end

function EarthRevivalMediator:OnBtnRankClick()
    ---@type CommonLeaderboardPopupMediatorParam
    local data = {}
    data.leaderboardDatas = {}
    local playerLeaderboardId, allianceLeaderboardId = ModuleRefer.EarthRevivalModule:GetCurOpeningLeaderboardId()
    if playerLeaderboardId == 0 or allianceLeaderboardId == 0 then
        g_Logger.ErrorChannel("EarthRevivalMediator", "火种行动未开启或未配置排行榜")
        return
    end
    local leaderboardData = {
        cfgIds = {playerLeaderboardId, allianceLeaderboardId},
    }
    table.insert(data.leaderboardDatas, leaderboardData)
    data.leaderboardTitles = { 'worldstage_geren', 'worldstage_lianmeng' }
    data.rewardsTitles = { 'worldstage_geren', 'worldstage_lianmeng' }
    data.rewardsTitleHint = I18N.Get('worldstage_phfj')
    data.style = CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_BOARD | CommonLeaderboardPopupDefine.STYLE_MASK.SHOW_REWARD
    data.title = "worldstage_jfph"
    local lId = data.leaderboardDatas[1].cfgIds[1]
    local cfg = ConfigRefer.LeaderboardActivity:Find(lId)
    local _, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(cfg:ControlActivity())
    data.timerEndTime = endTime.Seconds
    g_Game.UIManager:Open(UIMediatorNames.CommonLeaderboardPopupMediator, data)
end

function EarthRevivalMediator:OnBtnTimelineClick()
    g_Game.UIManager:Open(UIMediatorNames.WorldTrendTimeLineMediator)
end

function EarthRevivalMediator:OnResourceChanged()
    self:UpdateResource()
end

function EarthRevivalMediator:TabClicked(index, defaultStage, defaultActivityId)
    ModuleRefer.ActivityCenterModule:InitRedDot()
    self.statusNews:ApplyStatusRecord(index == EarthRevivalDefine.EarthRevivalTabType.News and 0 or 1)
    self.statusShop:ApplyStatusRecord(index == EarthRevivalDefine.EarthRevivalTabType.Shop and 0 or 1)
    self.luagoNews:SetVisible(index == EarthRevivalDefine.EarthRevivalTabType.News)
    self.luagoMap:SetVisible(false)
    self.luagoTask:SetVisible(index == EarthRevivalDefine.EarthRevivalTabType.Task)
    self.luagoShop:SetVisible(index == EarthRevivalDefine.EarthRevivalTabType.Shop)
    if index == EarthRevivalDefine.EarthRevivalTabType.News then
        ---@type EarthRevivalNewsAndActivityParameter
        local data = {}
        data.tabId = defaultActivityId
        self.luagoNews:FeedData(data)
    elseif index == EarthRevivalDefine.EarthRevivalTabType.Task then
        self.luagoTask:FeedData()
    elseif index == EarthRevivalDefine.EarthRevivalTabType.Shop then
        ---@type EarthRevivalShopData
        local data = {}
        data.shopId = ModuleRefer.EarthRevivalModule:GetCurOpenEarthRevivalShopId()
        self.luagoShop:FeedData(data)
    end
end

function EarthRevivalMediator:GetItemPos()
    return self.luagoResource.CSComponent.transform.position
end

return EarthRevivalMediator