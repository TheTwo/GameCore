local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local EarthRevivalDefine = require('EarthRevivalDefine')

---@class EarthRevivalPopupMediator : BaseUIMediator
local EarthRevivalPopupMediator = class('EarthRevivalPopupMediator', BaseUIMediator)

function EarthRevivalPopupMediator:OnCreate()
    self.imgBackground = self:Image('p_img')
    self.luagoPage = self:LuaObject('p_page_1')

    self.textNewsTitle = self:Text('p_text_title_1', "worldstage_toutiao")
    self.textNewsContent = self:Text('p_text_news_title')

    self.imgHead = self:Image('img')
    self.textTitle = self:Text('p_text_title_news', "worldstage_sudi")
    self.textName = self:Text('p_text_name', "worldstage_Egirl")
    self.textTime = self:Text('p_text_time')

    self.reddot = self:LuaObject('child_reddot_default')

    self.textGoto = self:Text('p_text_goto', "worldstage_xwsl")
    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnClickGoto))

    self.goNoNews = self:GameObject('p_no_news')
    self.textNoNews = self:Text('p_text_blank', "worldstage_zwxw")
end

function EarthRevivalPopupMediator:OnOpened(Params)
    if Params and Params.popIds then
        self.popIds = Params.popIds
    end

    -- ---@type EarthRevivalNewsParam
    local newsData = ModuleRefer.EarthRevivalModule:GetNewsData()
    if not newsData then
        return
    end
    if newsData.pageCount < 1 then
        self.goNoNews:SetActive(true)
        return
    end
    self.goNoNews:SetActive(false)
    local pageNews = newsData.pageNewsList[1]
    self.luagoPage:FeedData(pageNews)
    self.textNewsContent.text = pageNews.newsContent
    self:UpdateNewsTime()

    self.reddot:SetVisible(not ModuleRefer.EarthRevivalModule:NewsDailyRewardClaimed())
end

function EarthRevivalPopupMediator:OnClose()
    if self.popIds then
        ModuleRefer.LoginPopupModule:OnPopupShown(self.popIds)
    end
end

function EarthRevivalPopupMediator:UpdateNewsTime()
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

function EarthRevivalPopupMediator:OnClickGoto()
    ModuleRefer.EarthRevivalModule:OpenEarthRevivalMediator({tabIndex = EarthRevivalDefine.EarthRevivalTabType.News})
end

return EarthRevivalPopupMediator