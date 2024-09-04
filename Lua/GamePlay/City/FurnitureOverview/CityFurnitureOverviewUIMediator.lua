---Scene Name : scene_construction_popup_manage
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local I18N = require("I18N")
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local CityFurnitureOverviewUIParameter = require("CityFurnitureOverviewUIParameter")

---@class CityFurnitureOverviewUIMediator:BaseUIMediator
local CityFurnitureOverviewUIMediator = class('CityFurnitureOverviewUIMediator', BaseUIMediator)

function CityFurnitureOverviewUIMediator:OnCreate()
    self._p_content_status = self:StatusRecordParent("p_content_status")
    self._p_text_title = self:Text("p_text_title")

    self._group_tab = self:GameObject("group_tab")              ----选项Toggle根节点

    self._child_btn_close = self:Button("child_btn_close", Delegate.GetOrCreate(self, self.BackToPrevious))
    self:Button("p_btn_city", Delegate.GetOrCreate(self, self.OnClickShowOverview))
    self._p_btn_city = self:StatusRecordParent("p_btn_city")
    self._p_text_city_n = self:Text("p_text_city_n", FurnitureOverview_I18N.OverviewUI_TagOverview)
    self._p_text_city_selected = self:Text("p_text_city_selected", FurnitureOverview_I18N.OverviewUI_TagOverview)

    self:Button("p_btn_citizen", Delegate.GetOrCreate(self, self.OnClickShowCitizen))
    self._p_btn_citizen = self:StatusRecordParent("p_btn_citizen")
    self._p_text_citizen_n = self:Text("p_text_citizen_n", FurnitureOverview_I18N.OverviewUI_TagCitizen)
    self._p_text_citizen_selected = self:Text("p_text_citizen_selected", FurnitureOverview_I18N.OverviewUI_TagCitizen)

    ---@type CityFurnitureOverviewUIPageOverview
    self._p_content_city = self:LuaObject("p_content_city")
    ---@type CityFurnitureOverviewUIPageCitizenManage
    self._p_content_citizen = self:LuaObject("p_content_citizen")
end

---@param param CityFurnitureOverviewUIParameter
function CityFurnitureOverviewUIMediator:OnOpened(param)
    self.param = param
    
    self:InitToggleVisible()
    self.statusRecords = {
        [CityFurnitureOverviewUIParameter.PageStatus.Overview] = self._p_btn_city,
        [CityFurnitureOverviewUIParameter.PageStatus.CitizenManage] = self._p_btn_citizen,
    }

    self.pages = {
        [CityFurnitureOverviewUIParameter.PageStatus.Overview] = self._p_content_city,
        [CityFurnitureOverviewUIParameter.PageStatus.CitizenManage] = self._p_content_citizen,
    }
    self:ShowPage(self.param.showPage)
end

function CityFurnitureOverviewUIMediator:OnClickShowOverview()
    self:ShowPage(CityFurnitureOverviewUIParameter.PageStatus.Overview)
end

function CityFurnitureOverviewUIMediator:OnClickShowCitizen()
    self:ShowPage(CityFurnitureOverviewUIParameter.PageStatus.CitizenManage)
end

function CityFurnitureOverviewUIMediator:InitToggleVisible()
    self._group_tab:SetActive(self.param.showToggle ~= CityFurnitureOverviewUIParameter.ToggleStatus.AllHide)
    self._p_btn_city:SetVisible((self.param.showToggle & CityFurnitureOverviewUIParameter.ToggleStatus.Overview) ~= 0)
    self._p_btn_citizen:SetVisible((self.param.showToggle & CityFurnitureOverviewUIParameter.ToggleStatus.CitizenManage) ~= 0)
end

function CityFurnitureOverviewUIMediator:ShowPage(page)
    if self.currentPage == page then return end

    self._p_text_title.text = self.param:GetPageTitleText(page)
    for k, v in pairs(self.pages) do
        v:SetVisible(page == k)
    end
    self._p_content_status:ApplyStatusRecord(self.param:GetPageContentStatus(page))

    for k, v in pairs(self.statusRecords) do
        v:ApplyStatusRecord(page == k and 1 or 0)
    end

    self.currentPage = page
    self.pages[page]:FeedData(self.param.pageDataMap[page])
end

function CityFurnitureOverviewUIMediator:HasToggle(toggle)
    return (self.param.showToggle & toggle) ~= 0
end

return CityFurnitureOverviewUIMediator