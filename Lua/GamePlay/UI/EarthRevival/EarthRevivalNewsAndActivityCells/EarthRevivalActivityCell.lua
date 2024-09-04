local BaseTableViewProCell = require("BaseTableViewProCell")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local EventConst = require("EventConst")
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local NotificationType = require("NotificationType")
local TimeFormatter = require("TimeFormatter")
local ActivityCenterConst = require("ActivityCenterConst")
local WorldEventDefine = require('WorldEventDefine')
local UIHelper = require("UIHelper")

---@class EarthRevivalActivityCell : BaseTableViewProCell
local EarthRevivalActivityCell = class("EarthRevivalActivityCell", BaseTableViewProCell)

---@class EarthRevivalActivityData
---@field id number
---@field select boolean

function EarthRevivalActivityCell:ctor()
    self.id = 0
    self.tick = false
    self.endTime = 0
    self.multipliers = {}
end

function EarthRevivalActivityCell:OnCreate()
    self.btnRoot = self:Button("p_btn_activitys", Delegate.GetOrCreate(self, self.OnClickBtnRoot))
    self.statusCtrl = self:StatusRecordParent("")
    self.imgIconActivity = self:Image("p_icon_activity")
    self.textActivity = self:Text("p_text_news")
    self.textStatus = self:Text("p_text_status")
    self.textActivitySelect = self:Text("p_text_news_select")
    self.textStatusSelect = self:Text("p_text_status_select")
    self.goMultiplier = self:GameObject("p_icon_1")
    self.textMultiplier = self:Text("p_text_discount")
    self.goSelected = self:GameObject("p_img_select")
    ---@see NotificationNode
    self.luaNotifyNode = self:LuaObject("child_reddot_default")
end

function EarthRevivalActivityCell:OnShow()
    self:UnSelect()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    for i, go in ipairs(self.multipliers) do
        UIHelper.DeleteUIGameObject(go)
        self.multipliers[i] = nil
    end
end

function EarthRevivalActivityCell:OnHide()
    self.tick = false
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    for i, go in ipairs(self.multipliers) do
        UIHelper.DeleteUIGameObject(go)
        self.multipliers[i] = nil
    end
end

---@param data EarthRevivalActivityData
function EarthRevivalActivityCell:OnFeedData(data)
    self.id = data.id
    self:InitActivityInfos()
    local notifyNode = ModuleRefer.NotificationModule:GetDynamicNode(
            'ActivityCenterTab_' .. self.id, NotificationType.ACTIVITY_CENTER_TAB)
    local newlyUnlockNode = ModuleRefer.NotificationModule:GetDynamicNode(
        ActivityCenterConst.NotificationNodeNames.ActivityCenterTabNew .. self.id, NotificationType.ACTIVITY_CENTER_TAB)
    self.luaNotifyNode.redNew:SetActive(ModuleRefer.ActivityCenterModule:IsActivityTabNewlyUnlock(self.id))
    ModuleRefer.NotificationModule:AttachToGameObject(notifyNode, self.luaNotifyNode.go, self.luaNotifyNode.redDot)
    self:UpdateReddot()
end

function EarthRevivalActivityCell:UpdateReddot()
    self.luaNotifyNode.redNew:SetActive(ModuleRefer.ActivityCenterModule:IsActivityTabNewlyUnlock(self.id))
end

function EarthRevivalActivityCell:InitActivityInfos()
    local cfg = ConfigRefer.ActivityCenterTabs:Find(self.id)
    local actCfg = ConfigRefer.ActivityRewardTable:Find(cfg:RefActivityReward())
    local title = '*页面名未配置'
    if actCfg then
        title = I18N.Get(actCfg:Name())
    elseif cfg and not Utils.IsNullOrEmpty(cfg:TitleKey()) then
        title = I18N.Get(cfg:TitleKey())
    end
    self.textActivity.text = title
    self.textActivitySelect.text = title
    local multiplier = cfg:Multiplier()
    if multiplier > 100 then multiplier = multiplier / 100 end
    if multiplier and multiplier > 0 then
        self.goMultiplier:SetActive(true)
        self.textMultiplier.text = multiplier .. '%'
        for i = 1, multiplier do
            local go = UIHelper.DuplicateUIGameObject(self.goMultiplier)
            self.multipliers[i] = go
        end
        self.goMultiplier:SetActive(false)
    else
        self.goMultiplier:SetActive(false)
    end
    local artResourceUIId = cfg:Icon()
    g_Game.SpriteManager:LoadSprite(artResourceUIId, self.imgIconActivity)
    local _, endTimeStamp = ModuleRefer.ActivityCenterModule:GetActivityTabStartEndTime(self.id)
    self.endTime = endTimeStamp.Seconds
    if self.endTime > 0 then
        self.tick = true
        self:OnSecondTick()
    else
        self.tick = false
        self.textStatus.text = ""
    end
end

function EarthRevivalActivityCell:OnSecondTick()
    if not self.tick then return end
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local remainTime = math.max(self.endTime - curTime, 0)
    self.textStatus.text = TimeFormatter.SimpleFormatTimeWithDayHourSeconds(remainTime)
end

function EarthRevivalActivityCell:Select()
    self.statusCtrl:ApplyStatusRecord(1)
    self.goSelected:SetActive(true)
    ModuleRefer.ActivityCenterModule:ClearTabNewlyUnlockStatus(self.id)
    self:UpdateReddot()
    g_Game.EventManager:TriggerEvent(EventConst.ON_EARTH_REVIVAL_ACTIVITY_CELL_CLICK, self.id)
end

function EarthRevivalActivityCell:UnSelect()
    self.statusCtrl:ApplyStatusRecord(0)
    self.goSelected:SetActive(false)
end

function EarthRevivalActivityCell:OnClickBtnRoot()
    self:SelectSelf()
end

return EarthRevivalActivityCell