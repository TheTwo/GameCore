local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local TouchInfoDefine = require("TouchInfoDefine")
local CityConst = require("CityConst")
local I18N = require('I18N')
local TimerUtility = require("TimerUtility")

local AREA_COUNT = 8

---@class EventMapMediator : BaseUIMediator
local EventMapMediator = class('EventMapMediator', BaseUIMediator)

function EventMapMediator:ctor()

end

function EventMapMediator:OnCreate()
    self.goCampsite = self:GameObject('p_campsite')
    self.compChildCommonBack = self:LuaBaseComponent('child_common_btn_back')
    self.tableviewproTableReward = self:TableViewPro('p_table_reward')
    self.goWindow1 = self:GameObject("p_window_1")
    self.goCirclemenu = self:GameObject('p_circlemenu')
    self.btnMap = self:Button("p_map", Delegate.GetOrCreate(self, self.HideCircle))
    self.compChildTouchCircleGroupName = self:LuaBaseComponent('child_touch_circle_group_name')
    self.compChildTouchCircleButton = self:LuaBaseComponent('child_touch_circle_button')
    self.compChildTouchCircleGroupPair = self:LuaBaseComponent('child_touch_circle_group_pair')
    self.compChildTouchCircleGroupPair1 = self:LuaBaseComponent('child_touch_circle_group_pair_1')
    self.compChildTouchCircleGroup = self:LuaBaseComponent('child_touch_circle_group_text')
    self.compChildTouchCircleGroupReward = self:LuaBaseComponent('child_touch_circle_group_reward')
    self.progressIcon = {}
    self.progressGo = {}
    self.progressFullGo = {}
    self.progressText = {}
    self.progressLockGo = {}
    self.progressSelectGo = {}
    self.progressBtn = {}
    for i = 1, AREA_COUNT do
        self.progressIcon[#self.progressIcon + 1] = self:GameObject('p_icon_' .. i)
        self.progressGo[#self.progressGo + 1] = self:GameObject('p_progress_' .. i)
        self.progressFullGo[#self.progressFullGo + 1] = self:GameObject('p_img_full_' .. i)
        self.progressText[#self.progressText + 1] = self:Text('p_text_position_' .. i)
        self.progressLockGo[#self.progressLockGo + 1] = self:GameObject('p_lock_' .. i)
        self.progressSelectGo[#self.progressSelectGo + 1] = self:GameObject('p_map_selected_' .. i)
        self.progressBtn[#self.progressBtn + 1] = self:Button('p_btn_' .. i, function() self:OnClickAreaIncident(i) end)
    end
    g_Game.EventManager:AddListener(EventConst.INCIDENT_INFO_UPDATE, Delegate.GetOrCreate(self, self.RefreshIncidentInfo))
end

function EventMapMediator:OnShow(param)
    self.goCirclemenu:SetActive(false)
    self:RefreshIncidentInfo()
end

function EventMapMediator:RefreshIncidentInfo()
    self.area2incidentIds = {}
    for areaId, areaCfg in ConfigRefer.CityZone:ipairs() do
        local incidentId = areaCfg:IncidentId()
        self.area2incidentIds[areaId] = incidentId
    end
    for index = 1, AREA_COUNT do
        local isHide = self.area2incidentIds[index] == nil or self.area2incidentIds[index] == 0
        if isHide then
            self.progressIcon[index]:SetActive(false)
        else
            self.progressIcon[index]:SetActive(true)
            local isUnlock = ModuleRefer.IncidentModule:IsIncidentUnlock(self.area2incidentIds[index])
            if isUnlock then
                local incidentId = self.area2incidentIds[index]
                self.progressGo[index]:SetActive(true)
                self.progressLockGo[index]:SetActive(false)
                self.progressSelectGo[index]:SetActive(false)
                local isFinish = ModuleRefer.IncidentModule:IsIncidentFinish(incidentId)
                if isFinish then
                    self.progressFullGo[index]:SetActive(true)
                    self.progressText[index].text = "100%"
                else
                    self.progressFullGo[index]:SetActive(false)
                    self.progressText[index].text = ModuleRefer.IncidentModule:GetProgressText(incidentId)
                end
            else
                self.progressGo[index]:SetActive(false)
                self.progressLockGo[index]:SetActive(true)
                self.progressSelectGo[index]:SetActive(false)
            end
        end
    end
    self:RefreshRewardItem()
end

function EventMapMediator:RefreshRewardItem()
    self.tableviewproTableReward:Clear()
    for areaId, incidentId in pairs(self.area2incidentIds) do
        local isAward = ModuleRefer.IncidentModule:CheckIsAward(incidentId)
        if isAward then
            local data = {}
            data.areaId = areaId
            data.incidentId = incidentId
            self.tableviewproTableReward:AppendData(data)
        end
    end
end

function EventMapMediator:OnClickAreaIncident(areaId)
    local incidentId = self.area2incidentIds[areaId]
    local isUnlock = ModuleRefer.IncidentModule:IsIncidentUnlock(incidentId)
    for i = 1, AREA_COUNT do
        self.progressSelectGo[i]:SetActive(i == areaId)
    end
    self:ShowTouchCircle(areaId, isUnlock)
end

function EventMapMediator:HideCircle()
    self.goCirclemenu:SetActive(false)
    for i = 1, AREA_COUNT do
        self.progressSelectGo[i]:SetActive(false)
    end
end

function EventMapMediator:ShowTouchCircle(areaId, isUnlock)
    self.goCirclemenu:SetActive(true)
    self.goWindow1:SetActive(false)
    local incidentId = self.area2incidentIds[areaId]
    self.goCirclemenu.transform.position = self.progressBtn[areaId].transform.position

    self.compChildTouchCircleGroupPair:SetVisible(isUnlock)
    self.compChildTouchCircleGroupPair1:SetVisible(isUnlock)
    self.compChildTouchCircleGroupReward:SetVisible(isUnlock)
    if isUnlock then
        self.compChildTouchCircleGroupName:FeedData({name = I18N.Get(ConfigRefer.Incident:Find(incidentId):Name())})
        self.compChildTouchCircleGroupPair:FeedData({name = I18N.Get("city_zone"), content = I18N.Get(ConfigRefer.CityZone:Find(areaId):Name())})
        self.compChildTouchCircleGroupPair1:FeedData({name = I18N.Get("explore_rate"), content = ModuleRefer.IncidentModule:GetProgressText(incidentId)})
        local rewardArrays = ModuleRefer.IncidentModule:GetRewards(incidentId)
        self.compChildTouchCircleGroupReward:SetVisible(rewardArrays ~= nil)
        if rewardArrays then
            self.compChildTouchCircleGroupReward:FeedData({title = I18N.Get("city_incident_reward"), rewards = rewardArrays})
        end
    else
        self.compChildTouchCircleGroupName:FeedData({name = I18N.Get("unknown_zone")})
    end
    local callback = function()
        local areaCfg = ConfigRefer.CityZone:Find(areaId)
        local position = CS.UnityEngine.Vector3(areaCfg:CenterPos():X(), areaCfg:CenterPos():Y(), 0)
        ModuleRefer.CityModule.myCity:GetCamera():ZoomToWithFocus(CityConst.CITY_RECOMMEND_CAMERA_SIZE, CS.UnityEngine.Vector3(0.5, 0.5, 0), position, 2)
    end
    self.compChildTouchCircleButton:FeedData({
        background = TouchInfoDefine.ButtonBacks.BackNormal,
        text = I18N.Get("goto"),
        func = callback
    })
    self.compChildTouchCircleGroup:FeedData(I18N.Get(ConfigRefer.Incident:Find(incidentId):Des()))
    TimerUtility.DelayExecute(function()
        self.goWindow1:SetActive(true)
    end, 0.02)
end

function EventMapMediator:OnHide(param)
end

function EventMapMediator:OnOpened(param)
    self.compChildCommonBack:FeedData({
        title = I18N.Get("city_map"),
        backBtnFunc = Delegate.GetOrCreate(self, self.OnBtnExitClicked)})
end

function EventMapMediator:OnBtnExitClicked()
    g_Game.UIManager:CloseByName(require('UIMediatorNames').EventMapMediator)
end

function EventMapMediator:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.INCIDENT_INFO_UPDATE, Delegate.GetOrCreate(self, self.RefreshIncidentInfo))
end

return EventMapMediator
