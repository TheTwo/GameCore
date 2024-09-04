local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local TimerUtility = require('TimerUtility')
local UIHelper = require('UIHelper')
local EarthRevivalDefine = require('EarthRevivalDefine')
local LikeWorldStageNewsParameter = require('LikeWorldStageNewsParameter')
local ReceiveNewsDailyRewardParameter = require('ReceiveNewsDailyRewardParameter')
local TimeFormatter = require('TimeFormatter')
local Utils = require('Utils')
local GameObjectCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper

---@class EarthRevivalNewsParam
---@field pageCount number
---@field pageNewsList EarthRevivalNewsData[]
---@field latestNewsList EarthRevivalNewsData[]

---@class EarthRevivalNewsData
---@field newsId number
---@field newsConfigId number
---@field newsContent string
---@field newsIcon string
---@field likeNum number
---@field isLiked boolean
---@field extraInfo wds.WorldStageNewsExtraInfo

---@class EarthRevivalNewsComponent : BaseUIComponent
local EarthRevivalNewsComponent = class('EarthRevivalNewsComponent', BaseUIComponent)

local RUN_SPEED = 5

function EarthRevivalNewsComponent:OnCreate()
    -- groupleft
    self.imgHead = self:Image('img')
    self.textTitle = self:Text('p_text_title', "worldstage_sudi")
    self.textName = self:Text('p_text_name', "worldstage_Egirl")
    self.textTime = self:Text('p_text_time')
    self.textSubscription = self:Text('p_text_subscription', "worldstage_dingyue")
    self.btnShare = self:Button('p_btn_share', Delegate.GetOrCreate(self, self.OnClickShare))
    self.btnLike = self:Button('p_btn_like', Delegate.GetOrCreate(self, self.OnClickLike))
    self.statusLike = self:StatusRecordParent('p_btn_like')
    self.textLike = self:Text('p_text_like')

    self.pageviewcontrollerScroll = self:BindComponent('p_scroll', typeof(CS.PageViewController))
    self:DragEvent('p_scroll', Delegate.GetOrCreate(self, self.OnBeginDrag), nil, Delegate.GetOrCreate(self, self.OnEndDrag))
    self.pageTemplate = self:LuaBaseComponent('p_page')
    self.scrollDotTemplate = self:LuaBaseComponent('p_dot')
    self.textNewsTitle = self:Text('p_text_news_title')
    self.imgWeather = self:Image('p_icon_time')
    self.textNewsTime = self:Text('p_text_time_news')
    self.rectMaskRun = self:RectTransform('mask_run')
    self.rectTextRun = self:RectTransform('p_text_run')
    self.textRunContent = self:Text('p_text_run')
    self.textBreaking = self:Text('p_text_breaking', "worldstage_toutiao")
    self.imgSpine = self:Image('p_spine')
    self.goSpineParent = self:GameObject('p_go_spine')

    -- groupreward
    self.luagoGiftDaily = self:LuaObject('child_gift_daily')
    self.textGiftDaily = self:Text('p_text_claimed_1')
    self.animRewarded = self:AnimTrigger('vx_trigger_open')

    self.textLatestNews = self:Text('p_text_gift', "worldstage_ciji")
    -- self.tableviewProLatestNews = self:TableViewPro('p_table_news')

    self.statusCenter = self:StatusRecordParent('group_center')
    self.textNoNews = self:Text('p_text_no_news', "worldstage_zwxw")

    self.goHelper = GameObjectCreateHelper.Create()
end

function EarthRevivalNewsComponent:OnShow()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.TickSecond))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.TickFrame))
end

function EarthRevivalNewsComponent:OnHide()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TickSecond))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.TickFrame))
end

function EarthRevivalNewsComponent:OnClose()
    if self._target then
        GameObjectCreateHelper.DestroyGameObject(self._target)
        self._target = nil
    end
    if self.pageScrollTimer then
        TimerUtility.StopAndRecycle(self.pageScrollTimer)
        self.pageScrollTimer = nil
    end
    self.pageviewcontrollerScroll.onPageChanged = nil
    self.pageviewcontrollerScroll.onPageChanging = nil
end

---@param param EarthRevivalNewsParam
function EarthRevivalNewsComponent:OnFeedData(param)
    if not param then
        return
    end
    self.pageviewcontrollerScroll.onPageChanged = nil
    self.pageviewcontrollerScroll.onPageChanging = nil
    self:ClearNewsPage()

    self.param = param
    self.pageCount = param.pageCount or 1
    self.pageviewcontrollerScroll.pageCount = self.pageCount
    self.statusCenter:ApplyStatusRecord(param.pageCount == 0 and 1 or 0)

    --NewsPage
    self.newsPage = {}
    self.scrollDots = {}
    self.curPageIndex = 0
    self.pageTemplate:SetVisible(false)
    self.scrollDotTemplate:SetVisible(false)
    for i = 1, self.pageCount do
        self.newsPage[i] = UIHelper.DuplicateUIComponent(self.pageTemplate)
        self.newsPage[i].Lua:OnFeedData(param.pageNewsList[i])
        self.newsPage[i].gameObject:SetActive(true)
        self.scrollDots[i] = UIHelper.DuplicateUIComponent(self.scrollDotTemplate)
        self.scrollDots[i].gameObject:SetActive(true)
        self.scrollDots[i].Lua:SetDotVisible(i == 1)
    end
    self.pageviewcontrollerScroll.onPageChanged = Delegate.GetOrCreate(self, self.OnPageChanged)
    self.pageviewcontrollerScroll.onPageChanging = Delegate.GetOrCreate(self, self.OnPageChanged)
    self:UpdatePageNewsContent(self.curPageIndex + 1)
    if not self.pageScrollTimer then
        self.pageScrollTimer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.AutoScrollPage), 4, -1)
    end
    self.pageviewcontrollerScroll:ScrollToPage(0)
    self:OnPageChanged(nil, 0)
    self:UpdateTime()

    local weatherSprite = EarthRevivalDefine.EarthRevivalNews_WeatherIcon[ModuleRefer.EarthRevivalModule:GetRandomWeatherIndex()]
    if not string.IsNullOrEmpty(weatherSprite) then
        g_Game.SpriteManager:LoadSprite(weatherSprite, self.imgWeather)
    end

    self.btnShare:SetVisible(false)
    self.isLiked = ModuleRefer.EarthRevivalModule:GetNewsLiked(0)
    self.statusLike:ApplyStatusRecord(self.isLiked and 1 or 0)
    self:UpdateLikeNum()
    self:UpdateNewsTime()

    self:InitRunNews()

    self:InitSpine()

    --DailyReward
    self:InitDailyReward()

    --LatestNews
    -- self.tableviewProLatestNews:Clear()
    -- for i = 1, #param.latestNewsList do
    --     self.tableviewProLatestNews:AppendData(param.latestNewsList[i])
    -- end
end

function EarthRevivalNewsComponent:ClearNewsPage()
    if not self.pageCount then
        return
    end
    for i = 1, self.pageCount do
        UIHelper.DeleteUIComponent(self.newsPage[i])
        UIHelper.DeleteUIComponent(self.scrollDots[i])
    end
end

function EarthRevivalNewsComponent:AutoScrollPage()
    local page = self.curPageIndex
    local pageCount = self.pageCount
    if pageCount == 0 then
        pageCount = 1
    end
    local newPage = (page + 1) % pageCount
    self.pageviewcontrollerScroll:ScrollToPage(newPage)
    self:OnPageChanged(nil, newPage)
end

function EarthRevivalNewsComponent:OnPageChanged(_, newPageIndex)
    if self.pageCount == 0 then
        return
    end
    if newPageIndex >= self.pageCount then
        newPageIndex = newPageIndex % self.pageCount
    end
    self.curPageIndex = newPageIndex

    self:SetScrollDotsShow(newPageIndex + 1)
    self:UpdatePageNewsContent(newPageIndex + 1)
end

function EarthRevivalNewsComponent:SetScrollDotsShow(showDotsIndex)
    for i = 1, self.pageCount do
        self.scrollDots[i].Lua:SetDotVisible(i == showDotsIndex)
    end
end

function EarthRevivalNewsComponent:UpdatePageNewsContent(pageIndex)
    local pageNews = self.param.pageNewsList[pageIndex]
    if not pageNews then
        return
    end
    self.textNewsTitle.text = pageNews.newsContent
end

function EarthRevivalNewsComponent:OnClickShare()
    --TODO
end

function EarthRevivalNewsComponent:OnClickLike()
    if self.isLiked then
        return
    end
    local param = LikeWorldStageNewsParameter.new()
    param.args.NewsId = 0
    param:SendWithFullScreenLockAndOnceCallback(nil, true, function(cmd, isSuccess, rsp)
        if isSuccess then
            self.statusLike:ApplyStatusRecord(1)
            self.likeNum = self.likeNum + 1
            self.textLike.text = tostring(self.likeNum)
            self.isLiked = true
        end
    end)
end

function EarthRevivalNewsComponent:UpdateLikeNum()
    local curNewsInfo = ModuleRefer.EarthRevivalModule:GetCurNewsInfo()
    if not curNewsInfo then
        self.textLike.text = 0
        return
    end
    self.likeNum = curNewsInfo.Likes
    if self.likeNum > 1000 then
        local num = math.floor(self.likeNum / 1000)
        self.textLike.text = string.format("%dK", num)
    else
        self.textLike.text = tostring(self.likeNum)
    end
end

function EarthRevivalNewsComponent:OnBeginDrag()
    -- self.pageScrollTimer:Reset(Delegate.GetOrCreate(self, self.AutoScrollPage), 4, -1)
end

function EarthRevivalNewsComponent:OnEndDrag()
    -- self.pageScrollTimer:Start()
end

function EarthRevivalNewsComponent:InitRunNews()
    self.runNewsList = ModuleRefer.EarthRevivalModule:GetRunNewsList()
    if #self.runNewsList < 1 then
       return
    end
    self.maskWidth = self.rectMaskRun.rect.width
    self.textWidth = self.rectTextRun.rect.width
    self.textRunContent.transform.localPosition = CS.UnityEngine.Vector3(self.maskWidth / 2, 0, 0)
    self.originX = self.textRunContent.transform.localPosition.x
    self.runNewsIndex = 0
    local content = I18N.Get(self.runNewsList[self.runNewsIndex + 1])
    self.textRunContent.text = content
    local settings = self.textRunContent:GetGenerationSettings(CS.UnityEngine.Vector2(0, self.textRunContent:GetPixelAdjustedRect().size.y))
    local width = self.textRunContent.cachedTextGeneratorForLayout:GetPreferredWidth(content, settings) / self.textRunContent.pixelsPerUnit
    self.targetX = self.originX - width - self.maskWidth
    self.startRun = true
end

function EarthRevivalNewsComponent:InitSpine()
    if self._target then
        return
    end
    
    local pageNewsList = {}
    for i = 1, self.pageCount do
        pageNewsList[i] = self.param.pageNewsList[i].newsId
    end
    local spineConfig = ModuleRefer.EarthRevivalModule:GetNewsSpineConfig(pageNewsList)
    if not spineConfig then
        return
    end
    local cell = ConfigRefer.ArtResourceUI:Find(spineConfig:Spine())
    -- local cell = ConfigRefer.ArtResourceUI:Find(10291)
    
    local asset = cell and cell:Path() or string.Empty
    if not string.IsNullOrEmpty(asset) then
        self.goHelper:Create(asset, self.goSpineParent.transform, function(go)
            self._target = go
            self._spineGraphic = nil
            if Utils.IsNotNull(self._target) then
                ---@type CS.UnityEngine.RectTransform
                local rectTrans = self._target:GetComponent(typeof(CS.UnityEngine.RectTransform))
                if Utils.IsNotNull(rectTrans) then
                    if not self._pivot then
                        if cell:SpinePivotLength() > 1 then
                            self._pivot = CS.UnityEngine.Vector2(cell:SpinePivot(1), cell:SpinePivot(2))
                        else
                            self._pivot = CS.UnityEngine.Vector2(0.5, 0.5)
                        end
                    end
                    rectTrans.pivot = self._pivot
                    if not self._localScale then
                        self._localScale = CS.UnityEngine.Vector3.one
                    end
                    rectTrans.localScale = self._localScale
                else
                    local trans = self._target.transform
                    trans.localScale = self._localScale
                end
                ---@type CS.Spine.Unity.SkeletonGraphic
                local spineGraphic = self._target:GetComponentInChildren(typeof(CS.Spine.Unity.SkeletonGraphic))
                if Utils.IsNotNull(spineGraphic) then
                    if spineGraphic.initialFlipX ~= self._useFlipX then
                        spineGraphic.initialFlipX = self._useFlipX
                        spineGraphic:Initialize(true)
                    end
                end
                self._spineGraphic = self._target:GetComponentInChildren(typeof(CS.UnityEngine.UI.MaskableGraphic))
                if self._color then
                    self._spineGraphic.color = self._color
                end
            end
        end)
    end

    -- local audioConfig = ConfigRefer.AudioConfig:Find(spineConfig:Sound())
    -- if not audioConfig then
    --     return
    -- end
    g_Game.SoundManager:PlayAudio(spineConfig:Sound())
end

function EarthRevivalNewsComponent:InitDailyReward()
    self.textGiftDaily.gameObject:SetActive(false)
    ---@type CommonDailyGiftData
    local data = {}
    data.itemGroupId = ModuleRefer.LeaderboardModule:GetDailyRewardItemGroupId()
    data.state = ModuleRefer.EarthRevivalModule:GetDailyRewardState()
    data.customCloseIcon = EarthRevivalDefine.EarthRevivalNews_CanClaimRewardIcon
    data.customCloseText = I18N.Get("worldstage_meiri")
    data.customOpenIcon = EarthRevivalDefine.EarthRevivalNews_HasClaimRewardIcon
    data.customOpenText = I18N.Get("worldstage_yilingqu")
    data.onClickWhenClosed = Delegate.GetOrCreate(self, self.OnDailyRewardClick)
    self.luagoGiftDaily:FeedData(data)

    -- 设置红点
    ModuleRefer.EarthRevivalModule:AttachToGroupNewsRedDot(self.luagoGiftDaily:GetReddotNode())
    ModuleRefer.EarthRevivalModule:RefreshNewsRedDot()
end

function EarthRevivalNewsComponent:OnDailyGiftRewarded()
    local CommonDailyGiftState = require('CommonDailyGiftState')
    self.luagoGiftDaily:ChangeState(CommonDailyGiftState.HasCliamed)
    self.animRewarded:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    ModuleRefer.EarthRevivalModule:RefreshNewsRedDot()
    g_Game.EventManager:TriggerEvent(EventConst.ON_DAILY_REWARD_CLAIMED)
end

function EarthRevivalNewsComponent:OnDailyRewardClick()
    local curStage = ModuleRefer.WorldTrendModule:GetCurStage()
    if curStage.Stage == 0 then
        return
    end
    local param = ReceiveNewsDailyRewardParameter.new()
    param:SendWithFullScreenLockAndOnceCallback(nil, true, function(cmd, isSuccess, rsp)
        if isSuccess then
            self:OnDailyGiftRewarded()
        end
    end)
end

function EarthRevivalNewsComponent:TickSecond()
    self:UpdateTime()
end

function EarthRevivalNewsComponent:TickFrame()
    if not self.startRun then
        return
    end
    if not self.runNewsList then
        return
    end
    if #self.runNewsList < 1 then
        return
    end
    self.textRunContent.transform.localPosition = CS.UnityEngine.Vector3(self.textRunContent.transform.localPosition.x - RUN_SPEED, 0, 0)
    if self.textRunContent.transform.localPosition.x < self.targetX then
        self.runNewsIndex = (self.runNewsIndex + 1) % #self.runNewsList
        self.textRunContent.transform.localPosition = CS.UnityEngine.Vector3(self.originX, 0, 0)
        local content = I18N.Get(self.runNewsList[self.runNewsIndex + 1])
        self.textRunContent.text = content
        local settings = self.textRunContent:GetGenerationSettings(CS.UnityEngine.Vector2(0, self.textRunContent:GetPixelAdjustedRect().size.y))
        local width = self.textRunContent.cachedTextGeneratorForLayout:GetPreferredWidth(content, settings) / self.textRunContent.pixelsPerUnit
        self.targetX = self.originX - width - self.maskWidth
    end
end

function EarthRevivalNewsComponent:UpdateTime()
    local curTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local timeTable = TimeFormatter.GetTimeTableInDHMS(curTime)
    self.textNewsTime.text = string.format("%02d:%02d", timeTable.hour, timeTable.minute)
end

function EarthRevivalNewsComponent:UpdateNewsTime()
    local curNewsInfo = ModuleRefer.EarthRevivalModule:GetCurNewsInfo()
    if not curNewsInfo then
        return
    end
    local lastRefreshTime = curNewsInfo.NextRefreshTime.Seconds - 86400
    local curTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local time = curTime - lastRefreshTime
    if time < 0 then
        time = 0
    end
    self.textTime.text = I18N.GetWithParams("worldstage_xiaoshiqian", math.floor(time / 3600))
end

return EarthRevivalNewsComponent