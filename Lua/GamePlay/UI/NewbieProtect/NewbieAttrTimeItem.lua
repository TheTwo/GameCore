local BaseUIMediator = require ('BaseUIMediator')
local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local TimeFormatter = require('TimeFormatter')

---@class NewbieAttrTimeItem : BaseTableViewProCell
local NewbieAttrTimeItem = class('NewbieAttrTimeItem', BaseTableViewProCell)


---@class NewbieAttrTimeItemParam
---@field endtime number

function NewbieAttrTimeItem:OnCreate()
    self.textTime = self:Text('p_text_time')
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
end

function NewbieAttrTimeItem:OnClose()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
end 

---@param param NewbieAttrTimeItemParam
function NewbieAttrTimeItem:OnFeedData(param)
    if not param.endtime then
        return
    end

    self.endTime = param.endtime
    self:RefreshTime()
end

function NewbieAttrTimeItem:OnSecondTicker()
    self:RefreshTime()
end

function NewbieAttrTimeItem:RefreshTime()
    if not self.endTime or self.endTime <= 0 then
        return
    end
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local leftTime = self.endTime - curTime
    if leftTime <= 0 then
        self.textTime.text = I18N.Get("protect_info_expired")
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
        return
    end
    self.textTime.text = I18N.Get("protect_info_time_left")..TimeFormatter.SimpleFormatTimeWithoutZero(leftTime)
end


return NewbieAttrTimeItem