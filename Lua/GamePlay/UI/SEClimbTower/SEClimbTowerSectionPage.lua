local BaseUIComponent = require('BaseUIComponent')
local Delegate = require("Delegate")
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')

local Vector2 = CS.UnityEngine.Vector2

---@class SEClimbTowerSectionPageData
---@field chapterId number
---@field sectionId number

---@class SEClimbTowerSectionPage:BaseUIComponent
---@field new fun():SEClimbTowerSectionPage
---@field super BaseUIComponent
local SEClimbTowerSectionPage = class('SEClimbTowerSectionPage', BaseUIComponent)

function SEClimbTowerSectionPage:OnCreate()
    self.btnStars = self:Button('p_btn_star', Delegate.GetOrCreate(self, self.OnStarsClicked))
    self.txtStars = self:Text('p_text_star', 'setower_btn_starreward')

    self.btnBackChapter = self:Button('p_btn_return_chapter', Delegate.GetOrCreate(self, self.OnReturnToChapterClicked))
    self.txtBackChapter = self:Text('p_txt_return_chapter', 'setower_btn_chapter')

    self.btnCloseTip = self:Button('p_btn_empty_tips', Delegate.GetOrCreate(self, self.OnCloseTipClicked))
    self.imgBg = self:Image('p_base_content')

    ---@type SEClimbTowerSectionTips
    self.sectionTips = self:LuaObject('p_section_tips')

    ---@type SEClimbTowerStarRewardTips
    self.starTips = self:LuaObject('p_tips_star')

    self.scrollRect = self:ScrollRect('p_scroll')

    self.point1 = self:LuaObject('p_practice_01')
    self.point2 = self:LuaObject('p_practice_02')
    self.point3 = self:LuaObject('p_practice_03')
    self.point4 = self:LuaObject('p_practice_04')
    self.point5 = self:LuaObject('p_practice_05')
    self.point6 = self:LuaObject('p_practice_06')
    self.point7 = self:LuaObject('p_practice_07')
    self.point8 = self:LuaObject('p_practice_08')
    self.point9 = self:LuaObject('p_practice_09')
    self.point10 = self:LuaObject('p_practice_10')

    ---@type table <number, SEClimbTowerSectionPoint>
    self.allPoint = {}
    table.insert(self.allPoint, self.point1)
    table.insert(self.allPoint, self.point2)
    table.insert(self.allPoint, self.point3)
    table.insert(self.allPoint, self.point4)
    table.insert(self.allPoint, self.point5)
    table.insert(self.allPoint, self.point6)
    table.insert(self.allPoint, self.point7)
    table.insert(self.allPoint, self.point8)
    table.insert(self.allPoint, self.point9)
    table.insert(self.allPoint, self.point10)

    self.lineFinish01 = self:GameObject('p_line_finish_01')
    self.lineFinish02 = self:GameObject('p_line_finish_02')
    self.lineFinish03 = self:GameObject('p_line_finish_03')
    self.lineFinish04 = self:GameObject('p_line_finish_04')
    self.lineFinish05 = self:GameObject('p_line_finish_05')
    self.lineFinish06 = self:GameObject('p_line_finish_06')
    self.lineFinish07 = self:GameObject('p_line_finish_07')
    self.lineFinish08 = self:GameObject('p_line_finish_08')
    self.lineFinish09 = self:GameObject('p_line_finish_09')
    self.allFinishLines = {}
    table.insert(self.allFinishLines, self.lineFinish01)
    table.insert(self.allFinishLines, self.lineFinish02)
    table.insert(self.allFinishLines, self.lineFinish03)
    table.insert(self.allFinishLines, self.lineFinish04)
    table.insert(self.allFinishLines, self.lineFinish05)
    table.insert(self.allFinishLines, self.lineFinish06)
    table.insert(self.allFinishLines, self.lineFinish07)
    table.insert(self.allFinishLines, self.lineFinish08)
    table.insert(self.allFinishLines, self.lineFinish09)

    self.lastSelectIndex = -1
end

function SEClimbTowerSectionPage:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.SE_CLIMB_TOWER_SECTION_CLICK, Delegate.GetOrCreate(self, self.OnSectionPointClick))
end

function SEClimbTowerSectionPage:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.SE_CLIMB_TOWER_SECTION_CLICK, Delegate.GetOrCreate(self, self.OnSectionPointClick))
end

---@param data SEClimbTowerSectionPageData
function SEClimbTowerSectionPage:OnFeedData(data)
    self.chapterId = data.chapterId
    self.sectionId = data.sectionId
    self.chapterConfigCell = ConfigRefer.ClimbTowerChapter:Find(self.chapterId)
    self.lastSelectIndex = -1
    self.scrollRect.normalizedPosition = Vector2.zero
    
    self:UpdateUI()

    if self.sectionId > 0 then
        self.lastSelectIndex = ConfigRefer.ClimbTowerSection:Find(self.sectionId):Section()
        self:FocusOnPoint(self.allPoint[self.lastSelectIndex])
        for _, point in ipairs(self.allPoint) do
            point:SetSelect(false)
        end
        self.allPoint[self.lastSelectIndex]:SetSelect(true)
    end
end

function SEClimbTowerSectionPage:UpdateUI()
    for i, v in ipairs(self.allPoint) do
        ---@type SEClimbTowerSectionPoint
        local point = v

        ---@type SEClimbTowerSectionPointData
        local data = {}
        data.chapterId = self.chapterId
        data.index = i
        point:FeedData(data)
    end

    for i, v in ipairs(self.allFinishLines) do
        ---@type ClimbTowerSectionConfigCell
        local sectionConfigCell = ModuleRefer.SEClimbTowerModule:GetSectionConfigCell(self.chapterId, i)
        local isSectionHasStars = ModuleRefer.SEClimbTowerModule:IsSectionHasStars(sectionConfigCell:Id())
        ---@type CS.UnityEngine.GameObject
        local line = v
        line:SetVisible(isSectionHasStars)
    end

    self:LoadSprite(self.chapterConfigCell:Background(), self.imgBg)
end

-- 此方法生效的前提：ScrollRect的Content的AnchorMin和AnchorMax都是(0.5, 0.5)
---@param point SEClimbTowerSectionPoint
function SEClimbTowerSectionPage:FocusOnPoint(point)
    local contentRectTransform = self.scrollRect.content
    local width = contentRectTransform.rect.width
    local point3Pos = point.CSComponent.transform.localPosition
    local posX = point3Pos.x + width / 2
    local normalizedPosX = posX / width
    self.scrollRect.normalizedPosition = Vector2(normalizedPosX, 0)
end

function SEClimbTowerSectionPage:OnStarsClicked()
    self.starTips:SetVisible(true)
    ---@type SEClimbTowerStarRewardTipsData
    local data = {}
    data.chapterId = self.chapterId
    self.starTips:FeedData(data)
end

function SEClimbTowerSectionPage:OnReturnToChapterClicked()
    g_Game.EventManager:TriggerEvent(EventConst.SE_CLIMB_TOWER_RETURN_TO_CHAPTER)
end

function SEClimbTowerSectionPage:OnSectionPointClick(chapterId, index)
    ---@type SEClimbTowerSectionTipsData
    local data = {}
    data.chapterId = chapterId
    data.index = index
    self.sectionTips:SetVisible(true)
    self.sectionTips:HideRewardTips()
    self.sectionTips:FeedData(data)

    if self.lastSelectIndex > 0 and self.lastSelectIndex ~= index then
        self.allPoint[self.lastSelectIndex]:SetSelect(false)
    end
    
    self.lastSelectIndex = index
    self.allPoint[index]:SetSelect(true)
end

function SEClimbTowerSectionPage:HideStarRewardTips()
    self.starTips:SetVisible(false)
end

function SEClimbTowerSectionPage:HideSectionTips()
    self.sectionTips:SetVisible(false)
end

function SEClimbTowerSectionPage:OnCloseTipClicked()
    self.sectionTips:SetVisible(false)
end

return SEClimbTowerSectionPage