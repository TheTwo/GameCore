local BaseTableViewProCell = require("BaseTableViewProCell")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
---@class EarthRevivalNewsCell : BaseTableViewProCell
local EarthRevivalNewsCell = class("EarthRevivalNewsCell", BaseTableViewProCell)

function EarthRevivalNewsCell:OnCreate()
    self.btnRoot = self:Button("", Delegate.GetOrCreate(self, self.OnClickBtnRoot))
    self.textNormal = self:Text("p_text_news_normal", "worldstage_jrxw")
    self.textSelect = self:Text("p_text_news_selected", "worldstage_jrxw")
    self.goNormal = self:GameObject("p_normal")
    self.goSelected = self:GameObject("p_selected")
    self.notifyNode = self:LuaObject("child_reddot_default")
end

function EarthRevivalNewsCell:OnShow()
    g_Game.EventManager:AddListener(EventConst.ON_DAILY_REWARD_CLAIMED, Delegate.GetOrCreate(self, self.UpdateReddot))
end

function EarthRevivalNewsCell:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ON_DAILY_REWARD_CLAIMED, Delegate.GetOrCreate(self, self.UpdateReddot))
end

function EarthRevivalNewsCell:OnFeedData(data)
    self.data = data
    self:UpdateReddot()
end

function EarthRevivalNewsCell:Select()
    g_Game.EventManager:TriggerEvent(EventConst.ON_EARTH_REVIVAL_NEWS_CELL_CLICK)
    self.goNormal:SetActive(false)
    self.goSelected:SetActive(true)
end

function EarthRevivalNewsCell:UnSelect()
    self.goNormal:SetActive(true)
    self.goSelected:SetActive(false)
end

function EarthRevivalNewsCell:OnClickBtnRoot()
    self:SelectSelf()
end

function EarthRevivalNewsCell:UpdateReddot()
    self.notifyNode:SetVisible(not ModuleRefer.EarthRevivalModule:NewsDailyRewardClaimed())
end

return EarthRevivalNewsCell