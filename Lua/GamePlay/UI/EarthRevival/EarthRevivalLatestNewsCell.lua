local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local LikeWorldStageNewsParameter = require('LikeWorldStageNewsParameter')
local EarthRevivalDefine = require('EarthRevivalDefine')
local ArtResourceUtils = require('ArtResourceUtils')
local WorldStageNewsContentType = require('WorldStageNewsContentType')


---@class EarthRevivalLatestNewsCell : BaseTableViewProCell
local EarthRevivalLatestNewsCell = class('EarthRevivalLatestNewsCell', BaseTableViewProCell)

function EarthRevivalLatestNewsCell:OnCreate()
    self.textNews = self:Text('p_text_news')
    self.imgNews = self:Image('p_icon_news')
    self.btnShare = self:Button('p_btn_share', Delegate.GetOrCreate(self, self.OnClickShare))
    self.btnLike = self:Button('p_btn_like', Delegate.GetOrCreate(self, self.OnClickLike))
    self.statusLike = self:StatusRecordParent('p_btn_like')
    self.textLike = self:Text('p_text_like')
end

---@param param EarthRevivalNewsData
function EarthRevivalLatestNewsCell:OnFeedData(param)
    if not param then
        return
    end
    self.param = param
    self.id = param.newsId
    _, self.contentType = ModuleRefer.EarthRevivalModule:GetNewsSubType(param.newsConfigId)
    if self.contentType == WorldStageNewsContentType.WSPNewsHaveGoldenPet then
        local petConfig = ConfigRefer.Pet:Find(param.extraInfo.ConfigId)
        if petConfig then
            self:LoadSprite(petConfig:Icon(), self.imgNews)
        end
    elseif self.contentType == WorldStageNewsContentType.WSPNewsHaveGoldenHero then
        local heroConfig = ConfigRefer.Heroes:Find(param.extraInfo.ConfigId)
        if heroConfig then
            local heroClientConfig = ConfigRefer.HeroClientRes:Find(heroConfig:ClientResCfg())
            if heroClientConfig then
                self:LoadSprite(heroClientConfig:HeadMini(), self.imgNews)
            end
        end
    else
        if not string.IsNullOrEmpty(param.newsIcon) then
            g_Game.SpriteManager:LoadSprite(param.newsIcon, self.imgNews)
        end
    end
    self.textNews.text = param.newsContent
    
    self.btnShare:SetVisible(false)
    self.isLiked = param.isLiked
    self.statusLike:ApplyStatusRecord(self.isLiked and 1 or 0)
    self:UpdateLikeNum()
end

function EarthRevivalLatestNewsCell:OnClickShare()
    --TODO
end

function EarthRevivalLatestNewsCell:OnClickLike()
    if self.isLiked then
        return
    end
    local param = LikeWorldStageNewsParameter.new()
    param.args.NewsId = self.id
    param:SendWithFullScreenLockAndOnceCallback(nil, true, function(cmd, isSuccess, rsp)
        if isSuccess then
            self.statusLike:ApplyStatusRecord(1)
            self.likeNum = self.likeNum + 1
            self.textLike.text = tostring(self.likeNum)
            self.isLiked = true
        end
    end)
end

function EarthRevivalLatestNewsCell:UpdateLikeNum()
    self.likeNum = self.param.likeNum
    if self.likeNum and self.likeNum > 1000 then
        local num = math.floor(self.likeNum / 1000)
        self.textLike.text = string.format("%dK", num)
    else
        self.textLike.text = tostring(self.likeNum)
    end
end

return EarthRevivalLatestNewsCell