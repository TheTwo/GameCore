---@class CityFurnitureOverviewUIParameter
---@field new fun(city, showPage, showToggle, pageDataMap):CityFurnitureOverviewUIParameter
---@field showPage number
---@field showToggle number @Flags
---@field pageDataMap table<number, any> @每个页的参数
local CityFurnitureOverviewUIParameter = class("CityFurnitureOverviewUIParameter")
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local I18N = require("I18N")
local PageStatus = {Overview = 1, CitizenManage = 2}
local ToggleStatus = {
    AllHide = 0,
    Overview = 1 << 0,
    CitizenManage = 1 << 1
}
ToggleStatus.AllShow = table.sumValues(ToggleStatus)

CityFurnitureOverviewUIParameter.PageStatus = PageStatus
CityFurnitureOverviewUIParameter.ToggleStatus = ToggleStatus

function CityFurnitureOverviewUIParameter:ctor(city, showPage, showToggle, pageDataMap)
    self.city = city
    if showPage == nil then
        self.showPage = PageStatus.Overview
    else
        self.showPage = self:CheckPageParam(showPage)
    end

    if showToggle == nil then
        self.showToggle = ToggleStatus.AllShow
    else
        self.showToggle = self:CheckToggleParam(showToggle)
    end

    if pageDataMap == nil then
        self.pageDataMap = self:GenerateDefaultPageDataMap()
    else
        self.pageDataMap = pageDataMap
    end
end

function CityFurnitureOverviewUIParameter:CheckPageParam(showPage)
    for _, v in pairs(PageStatus) do
        if showPage == v then
            return showPage
        end
    end
    return PageStatus.Overview
end

function CityFurnitureOverviewUIParameter:CheckToggleParam(showToggle)
    local toggleCount = 0
    for _, v in pairs(ToggleStatus) do
        if v == ToggleStatus.AllHide or v == ToggleStatus.AllShow then
            goto continue
        end

        if (showToggle & v) ~= 0 then
            toggleCount = toggleCount + 1
        end
        ::continue::
    end

    if toggleCount <= 1 then
        return ToggleStatus.AllHide
    end
    return showToggle
end

function CityFurnitureOverviewUIParameter:GenerateDefaultPageDataMap()
    local CityFurnitureOverviewDataGroup_LevelUp = require("CityFurnitureOverviewDataGroup_LevelUp")
    -- local CityFurnitureOverviewDataGroup_Process = require("CityFurnitureOverviewDataGroup_Process")
    -- local CityFurnitureOverviewDataGroup_ResCollect = require("CityFurnitureOverviewDataGroup_ResCollect")
    -- local CityFurnitureOverviewDataGroup_Produce = require("CityFurnitureOverviewDataGroup_Produce")
    -- local CityFurnitureOverviewDataGroup_MilitiaTrain = require("CityFurnitureOverviewDataGroup_MilitiaTrain")
    -- local CityFurnitureOverviewDataGroup_Gamble = require("CityFurnitureOverviewDataGroup_Gamble")
    local CityFurnitureOverviewDataGroup_CityWork = require("CityFurnitureOverviewDataGroup_CityWork")
    local CityFurnitureOverviewDataGroup_FurnitureMaker = require("CityFurnitureOverviewDataGroup_FurnitureMaker")
    local CityCitizenNewManageUIParameter = require("CityCitizenNewManageUIParameter")
    local CityWorkType = require("CityWorkType")
    local pageDataMap = {}

    local upgrade = CityFurnitureOverviewDataGroup_LevelUp.new(self.city)
    -- local process = CityFurnitureOverviewDataGroup_Process.new(self.city)
    -- local collect = CityFurnitureOverviewDataGroup_ResCollect.new(self.city)
    -- local produce = CityFurnitureOverviewDataGroup_Produce.new(self.city)
    -- local militia = CityFurnitureOverviewDataGroup_MilitiaTrain.new(self.city)
    -- local gamble = CityFurnitureOverviewDataGroup_Gamble.new(self.city)
    local work = CityFurnitureOverviewDataGroup_CityWork.new(self.city)
    local furMaking = CityFurnitureOverviewDataGroup_FurnitureMaker.new(self.city)

    pageDataMap[PageStatus.Overview] = {
        DataList = {
            upgrade,
            work,
            furMaking,
        },
        city = self.city
    }
    pageDataMap[PageStatus.CitizenManage] = CityCitizenNewManageUIParameter.new(self.city):SetShowMask(false):SetShowWorkingCiziten(true)
    return pageDataMap
end

function CityFurnitureOverviewUIParameter:GetPageContentStatus(page)
    if page == PageStatus.Overview then return 0 end
    if page == PageStatus.CitizenManage then
        ---@type CityCitizenNewManageUIParameter
        local param = self.pageDataMap[page]
        if param and param.needShowWorkingAbout then
            return 2 
        else
            return 1
        end
    end
end

function CityFurnitureOverviewUIParameter:GetPageTitleText(page)
    if page == PageStatus.Overview then
        return I18N.Get(FurnitureOverview_I18N.OverviewUI_PageTitleOverview)
    end
    if page == PageStatus.CitizenManage then
        ---@type CityCitizenNewManageUIParameter
        local param = self.pageDataMap[page]
        if param and param.needShowWorkingAbout then
            return I18N.Get(FurnitureOverview_I18N.OverviewUI_PageTitleSelectCitizen)
        else
            return I18N.Get(FurnitureOverview_I18N.OverviewUI_PageTitleCitizen)
        end
    end
end

return CityFurnitureOverviewUIParameter