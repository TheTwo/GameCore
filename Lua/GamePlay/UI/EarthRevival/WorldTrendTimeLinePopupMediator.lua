local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local TimerUtility = require('TimerUtility')

---@class WorldTrendTimeLinePopupMediator : BaseUIMediator
local WorldTrendTimeLinePopupMediator = class('WorldTrendTimeLinePopupMediator', BaseUIMediator)

function WorldTrendTimeLinePopupMediator:OnCreate()
    self.imgWorld_1 = self:Image('p_img_world_1')
    -- self.imgWorld_2 = self:Image('p_img_world_2')
    self.textStory = self:Text('p_text_story')
    self.pageviewcontrollerScroll = self:BindComponent('p_scroll', typeof(CS.PageViewController))
end

function WorldTrendTimeLinePopupMediator:OnOpened(stageID)
    if not stageID then
        return
    end
    self.stageID = stageID
    local stageConfig = ConfigRefer.WorldStage:Find(stageID)
    if not stageConfig then
        return
    end
    if stageConfig:StageBackgroundLength() > 0 then
        g_Game.SpriteManager:LoadSprite(stageConfig:StageBackground(1), self.imgWorld_1)
        -- if stageConfig:StageBackgroundLength() > 1 then
        --     g_Game.SpriteManager:LoadSprite(stageConfig:StageBackground(2), self.imgWorld_2)
        -- end
    end
    self.textStory.text = I18N.Get(stageConfig:StageDesc())
    -- self.pageScrollTimer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.AutoScrollPage), 4, -1)
end

function WorldTrendTimeLinePopupMediator:OnClose()
    if self.pageScrollTimer then
        TimerUtility.StopAndRecycle(self.pageScrollTimer)
        self.pageScrollTimer = nil
    end
end

function WorldTrendTimeLinePopupMediator:AutoScrollPage()
    local page = self.curPageIndex
    local pageCount = 2
    local newPage = (page + 1) % pageCount
    self.pageviewcontrollerScroll:ScrollToPage(newPage)
    self:OnPageChanged(nil, newPage)
end

function WorldTrendTimeLinePopupMediator:OnPageChanged(_, newPageIndex)
    self.curPageIndex = newPageIndex
end

return WorldTrendTimeLinePopupMediator