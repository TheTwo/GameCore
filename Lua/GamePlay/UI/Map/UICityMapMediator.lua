local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local Delegate = require('Delegate')
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local UIHelper = require('UIHelper')
local ArtResourceUtils = require("ArtResourceUtils")
local CastleUnlockTechnologyParameter = require("CastleUnlockTechnologyParameter")
local CastleCancelUnlockTechParameter = require("CastleCancelUnlockTechParameter")
local TimerUtility = require("TimerUtility")
local BuildingType = require("BuildingType")
local I18N = require('I18N')

local MIN_SCALE = 0.44
local MAX_SCALE = 1

---@class UICityMapMediator : BaseUIMediator
local UICityMapMediator = class('UICityMapMediator', BaseUIMediator)

function UICityMapMediator:OnCreate()
    self.goMap = self:GameObject('p_map')
    self.compGroupBuildling = self:LuaBaseComponent('p_group_buildling')
    self.compPosition = self:LuaBaseComponent('p_btn_position')
    self.compGroupPollution = self:LuaBaseComponent('p_group_pollution')
    self.compArea = self:LuaBaseComponent('p_btn_area')
    self.compGroupExpore = self:LuaBaseComponent('p_group_expore')
    self.compChildSetBar = self:LuaBaseComponent('child_set_bar')
    self.compChildCommonBack = self:LuaBaseComponent('child_common_btn_back')
    self.goEmpthArchor = self:GameObject("p_empty_archor")
    self.compGroupBuildling.gameObject:SetActive(false)
    self.compPosition.gameObject:SetActive(false)
    self.compGroupPollution.gameObject:SetActive(false)
    self.compArea.gameObject:SetActive(false)
    self.compGroupExpore.gameObject:SetActive(false)
end

function UICityMapMediator:OnOpened()
    self.scale = MIN_SCALE
    self.originSizeX = self.goMap.transform.sizeDelta.x
    self.halfScreenHight = CS.UnityEngine.Screen.height / 2
    self.halfScreenWidth = CS.UnityEngine.Screen.width / 2
    self.limitX = 0
    self.limitY = 0
    self.compChildCommonBack:FeedData({title = I18N.Temp().title_in_city_map})
    local setBarData = {}
    setBarData.minNum = 0
    setBarData.maxNum = (MAX_SCALE - MIN_SCALE) * 100
    setBarData.oneStepNum = 1
    setBarData.curNum = self.minNum
    setBarData.callBack = function(value)
        self:OnValueChange(value)
    end
    self.compChildSetBar:FeedData(setBarData)
    self:DragEvent("p_empty", nil, Delegate.GetOrCreate(self, self.OnDragBase), nil, false)
    self:PointerClick("p_empty", Delegate.GetOrCreate(self, self.OnClickMap))
    self:ZoomEvent("p_empty", Delegate.GetOrCreate(self, self.OnZoomMap))
    self.tickTimer = TimerUtility.IntervalRepeat(function() self:RefreshDetailsTick() end, 0.1, -1)
    self.buildingItems = {}
    self:RefreshBuilding()
    self:RefreshCreep()
end

function UICityMapMediator:OnValueChange(value)
    self.scale = value / 100 + MIN_SCALE
    self:RefreshMapScale(self.scale)
end

function UICityMapMediator:RefreshMapScale(scale)
    self.goMap.transform.localScale = CS.UnityEngine.Vector3(scale, scale, 1)
    local curSize = (scale * self.originSizeX) / 2
    if curSize - self.halfScreenWidth > 0 then
        self.limitX = curSize - self.halfScreenWidth
    else
        self.limitX = 0
    end
    if curSize - self.halfScreenHight > 0 then
        self.limitY = curSize - self.halfScreenHight
    else
        self.limitX = 0
    end
    local goMapPos = self.goMap.transform.localPosition
    local x = math.clamp(goMapPos.x, - self.limitX, self.limitX)
    local y = math.clamp(goMapPos.y, - self.limitY, self.limitY)
    self.goMap.transform.localPosition = CS.UnityEngine.Vector3(x, y, 0)
    self:RefreshBuilding()
end

function UICityMapMediator:OnDragBase(_, eventData)
    local goMapPos = self.goMap.transform.localPosition
    local x = math.clamp(goMapPos.x + eventData.delta.x, - self.limitX, self.limitX)
    local y = math.clamp(goMapPos.y + eventData.delta.y, - self.limitY, self.limitY)
    self.goMap.transform.localPosition = CS.UnityEngine.Vector3(x, y, 0)
    self.compPosition.gameObject:SetActive(false)
end

function UICityMapMediator:OnClickMap(_, eventData)
    local inputPos = UIHelper.ScreenPos2UIPos(eventData.position)
    self.goEmpthArchor.transform.localPosition = CS.UnityEngine.Vector3(inputPos.x, inputPos.y, 0)
    self.compPosition.gameObject.transform.position = self.goEmpthArchor.transform.position
    local localPos = self.compPosition.gameObject.transform.localPosition
    local mapX = self:GetMapCoorValue(localPos.x)
    local mapY = self:GetMapCoorValue(localPos.y)
    self.compPosition.gameObject:SetActive(true)
    self.compPosition:FeedData({x = mapX, y = mapY})
end

function UICityMapMediator:OnZoomMap(distance)
    self.scale = math.clamp(self.scale + distance / 100, MIN_SCALE, MAX_SCALE)
    self:RefreshMapScale(self.scale)
    self.compChildSetBar.Lua:OutInputChangeSliderValue((self.scale - MIN_SCALE) * 100 + distance)
end

function UICityMapMediator:RefreshDetailsTick()
    self:RefreshExplore()
end

function UICityMapMediator:RefreshExplore()
    local city = ModuleRefer.CityModule.myCity
    local exploreManager = city.cityExplorerManager
    local _,coord = exploreManager:GetTeamPosition()
    local x, y = coord.X, coord.Y
    local posX = self:GetMapPosValue(x)
    local posY = self:GetMapPosValue(y)
    if not self.exploreItem then
        self.exploreItem = UIHelper.DuplicateUIComponent(self.compGroupExpore, self.compGroupExpore.gameObject.transform.parent)
        self.exploreItem.gameObject:SetActive(true)
    end
    local targetPos = exploreManager:GetAnyTeamTargetCityCoord()
    if targetPos and not (targetPos.X == 0 and targetPos.Y == 0) then
        local targetPosX = self:GetMapPosValue(targetPos.X)
        local targetPosY = self:GetMapPosValue(targetPos.Y)
        self.exploreItem:FeedData({x = posX, y = posY, tx = targetPosX, ty = targetPosY})
    else
        self.exploreItem:FeedData({x = posX, y = posY})
    end

end

function UICityMapMediator:RefreshBuilding()
    local city = ModuleRefer.CityModule.myCity
    local castle = city:GetCastle()
    local buildingTypeConfig = ConfigRefer.BuildingTypes
    for id, v in pairs(castle.BuildingInfos) do
        if v.BuildingType == BuildingType.Stronghold or self.scale >= 0.76 then
            local typeCell = buildingTypeConfig:Find(v.BuildingType)
            local posX = self:GetMapPosValue(v.Pos.X)
            local posY = self:GetMapPosValue(v.Pos.Y)
            if not self.buildingItems[id] then
                self.buildingItems[id] = UIHelper.DuplicateUIComponent(self.compGroupBuildling, self.compGroupBuildling.gameObject.transform.parent)
            end
            self.buildingItems[id].gameObject:SetActive(true)
            self.buildingItems[id]:FeedData({x = posX, y = posY, cell = typeCell})
        else
            if self.buildingItems[id] then
                self.buildingItems[id].gameObject:SetActive(false)
            end
        end
    end
end

function UICityMapMediator:RefreshCreep()
    local city = ModuleRefer.CityModule.myCity
    local creeps = city.creepManager:GetCreepNodeCollection()
    for _, elementCfg in pairs(creeps) do
        local creepCell = UIHelper.DuplicateUIComponent(self.compGroupPollution, self.compGroupPollution.gameObject.transform.parent)
        creepCell.gameObject:SetActive(true)
        local posX = math.floor(self:GetMapPosValue(elementCfg:Pos():X()))
        local posY = math.floor(self:GetMapPosValue(elementCfg:Pos():Y()))
        creepCell:FeedData({x = posX, y = posY, pos = elementCfg:Pos()})
    end
end

function UICityMapMediator:GetMapPosValue(value)
    return (self.originSizeX / 512) * value - self.originSizeX / 2
end

function UICityMapMediator:GetMapCoorValue(value)
    return (value + self.originSizeX / 2) / (self.originSizeX / 512)
end


function UICityMapMediator:OnClose()
    if self.tickTimer then
        TimerUtility.StopAndRecycle(self.tickTimer)
        self.tickTimer = nil
    end
end

return UICityMapMediator
