local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local EventConst = require('EventConst')
local UIMediatorNames = require("UIMediatorNames")
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local DBEntityPath = require("DBEntityPath")
local SEClimbTowerDailyRewardState = require('SEClimbTowerDailyRewardState')

local BaseUIMediator = require("BaseUIMediator")

---@class SEClimbTowerMainMediatorParameter
---@field sectionId number 关卡编号

---@class SEClimbTowerMainMediator:BaseUIMediator
---@field new fun():SEClimbTowerMainMediator
---@field super BaseUIMediator
local SEClimbTowerMainMediator = class('SEClimbTowerMainMediator', BaseUIMediator)

local PAGE_CHAPTER = 1001
local PAGE_SECTION = 1002

function SEClimbTowerMainMediator:OnCreate(param)
    ---@type CommonBackButtonComponent
    self.commonBackComp = self:LuaObject("child_common_btn_back")

    self.btnShop = self:Button('p_btn_shop', Delegate.GetOrCreate(self, self.OnShopClicked))
    self.txtShop = self:Text('p_text_shop', 'setower_systemname_shop')

    self.btnTroop = self:Button('p_btn_troop', Delegate.GetOrCreate(self, self.OnTroopClicked))
    self.txtTroop = self:Text('p_text_troop', 'setower_systemname_troop')

    self.btnClosedGift = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnGiftClicked))
    self.btnOpenedGift = self:Button('p_btn_open', Delegate.GetOrCreate(self, self.OnGiftClicked))
    self.txtClosedGift = self:Text('p_text_gift', 'setower_dayreward_on')
    self.txtOpenedGift = self:Text('p_text_claimed', 'setower_dayreward_off')

    ---@type SEClimbTowerChapterPage
    self.pageChapter = self:LuaObject('p_content_chapter')

    ---@type SEClimbTowerSectionPage
    self.pageSection = self:LuaObject('p_content_section')
end

---@param data SEClimbTowerMainMediatorParameter
function SEClimbTowerMainMediator:OnOpened(data)
    self.curPage = PAGE_CHAPTER
    if data and data.sectionId then
        self.selectSectionId = data.sectionId
        self.selectChapterId = ConfigRefer.ClimbTowerSection:Find(data.sectionId):ChapterId()
        self.curPage = PAGE_SECTION
    end

    g_Game.EventManager:AddListener(EventConst.SE_CLIMB_TOWER_CHAPTER_CLICK, Delegate.GetOrCreate(self, self.OnChapterClickRecieved))
    g_Game.EventManager:AddListener(EventConst.SE_CLIMB_TOWER_RETURN_TO_CHAPTER, Delegate.GetOrCreate(self, self.OnReturnToChapterClick))

    ---@type CommonBackButtonData
    local commonBackButtonData = {}
    commonBackButtonData.title = I18N.Get('setower_systemname_endlesschallenge')
    commonBackButtonData.onClose = Delegate.GetOrCreate(self, self.OnClickBtnClose)
    self.commonBackComp:FeedData(commonBackButtonData)

    self:UpdateCurrentPage()
    self:UpdateDailyReward()
end

function SEClimbTowerMainMediator:OnClose(data)
    g_Game.EventManager:RemoveListener(EventConst.SE_CLIMB_TOWER_CHAPTER_CLICK, Delegate.GetOrCreate(self, self.OnChapterClickRecieved))
    g_Game.EventManager:RemoveListener(EventConst.SE_CLIMB_TOWER_RETURN_TO_CHAPTER, Delegate.GetOrCreate(self, self.OnReturnToChapterClick))
end

function SEClimbTowerMainMediator:OnShow(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.ClimbTower.IsDailyReward.MsgPath, Delegate.GetOrCreate(self, self.OnDailyRewardChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.SystemEntry.OpenSystems.MsgPath, Delegate.GetOrCreate(self, self.OnSystemEntryChanged))
end

function SEClimbTowerMainMediator:OnHide(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.ClimbTower.IsDailyReward.MsgPath, Delegate.GetOrCreate(self, self.OnDailyRewardChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.SystemEntry.OpenSystems.MsgPath, Delegate.GetOrCreate(self, self.OnSystemEntryChanged))
end

function SEClimbTowerMainMediator:OnSystemEntryChanged()
    self:UpdateDailyReward()
end

function SEClimbTowerMainMediator:OnDailyRewardChanged()
    self:UpdateDailyReward()
end

function SEClimbTowerMainMediator:UpdateDailyReward()
    local state = ModuleRefer.SEClimbTowerModule:GetDailyRewardState()
    self.btnClosedGift:SetVisible(state == SEClimbTowerDailyRewardState.CanCliam)
    self.btnOpenedGift:SetVisible(state == SEClimbTowerDailyRewardState.HasCliamed)
end

function SEClimbTowerMainMediator:UpdateCurrentPage()
    self.pageChapter:SetVisible(self.curPage == PAGE_CHAPTER)
    self.pageSection:SetVisible(self.curPage == PAGE_SECTION)

    if self.curPage == PAGE_CHAPTER then
        self.pageChapter:FeedData()
    else
        ---@type SEClimbTowerSectionPageData
        local sectionPageData = {}
        sectionPageData.chapterId = self.selectChapterId
        sectionPageData.sectionId = self.selectSectionId
        self.pageSection:HideSectionTips()
        self.pageSection:HideStarRewardTips()
        self.pageSection:FeedData(sectionPageData)
    end
end

function SEClimbTowerMainMediator:OnChapterClickRecieved(chapterId)
    self.curPage = PAGE_SECTION
    self.selectChapterId = chapterId
    self.selectSectionId = -1
    self:UpdateCurrentPage()
end

function SEClimbTowerMainMediator:OnReturnToChapterClick()
    self.curPage = PAGE_CHAPTER
    self:UpdateCurrentPage()
end

function SEClimbTowerMainMediator:OnClickBtnClose()
    self:CloseSelf()
end

function SEClimbTowerMainMediator:OnShopClicked()
	local climbTowerShopId = ConfigRefer.ClimbTowerConst.ClimbTowerShopID and ConfigRefer.ClimbTowerConst:ClimbTowerShopID() or 100
	g_Game.UIManager:Open(UIMediatorNames.UIShopMeidator, {tabIndex = climbTowerShopId})
end

function SEClimbTowerMainMediator:OnTroopClicked()
	g_Game.UIManager:Open(UIMediatorNames.SEClimbTowerTroopMediator)
end

function SEClimbTowerMainMediator:OnGiftClicked()
    local state = ModuleRefer.SEClimbTowerModule:GetDailyRewardState()
    if state == SEClimbTowerDailyRewardState.Hide then
        return
    end

    if state == SEClimbTowerDailyRewardState.HasCliamed then
        local itemGroupId = ModuleRefer.SEClimbTowerModule:GetDailyRewardItemGroup()
        ModuleRefer.SEClimbTowerModule:ShowRewardTips('setower_dayreward_tips', itemGroupId, self.btnOpenedGift.transform)
        return
    end

    local cliamDailyReward = require('DailyRewardClimbTowerParameter').new()
    cliamDailyReward:Send()
end

return SEClimbTowerMainMediator
