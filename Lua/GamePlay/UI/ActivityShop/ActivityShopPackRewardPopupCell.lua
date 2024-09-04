local BaseUIComponent = require('BaseUIComponent')
local I18N = require('I18N')
---@class ActivityShopPackRewardPopupCell : BaseUIComponent
local ActivityShopPackRewardPopupCell = class('ActivityShopPackRewardPopupCell', BaseUIComponent)

local STATUS = {
    ORANGE = 0,
    NORMAL = 1,
}

function ActivityShopPackRewardPopupCell:OnCreate()
    self.imgBaseOrange = self:Image('p_base_orange')
    self.imgBaseNormal = self:Image('p_base_nml')
    self.itemIcon = self:LuaObject('child_item_standard')
    self.textName = self:Text('p_text_item_name')
    self.textNum = self:Text('p_text_item_num')

    self.statusCtrler = self:StatusRecordParent('')
end

---@param params ItemIconData
function ActivityShopPackRewardPopupCell:OnFeedData(params)
    if not params then
        return
    end
    self.textName.text = I18N.Get(params.configCell:NameKey())
    self.textNum.text = params.count
    local iconData = {
        configCell = params.configCell,
        showCount = false,
        showTips = true,
    }
    self.itemIcon:FeedData(iconData)
    self.quality = params.configCell:Quality()
    if self.quality >= 5 then
        self.statusCtrler:ApplyStatusRecord(STATUS.ORANGE)
    else
        self.statusCtrler:ApplyStatusRecord(STATUS.NORMAL)
    end
end

return ActivityShopPackRewardPopupCell