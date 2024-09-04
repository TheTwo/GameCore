local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local UIMediatorNames = require ('UIMediatorNames')
local CommonItemDetailsDefine = require ('CommonItemDetailsDefine')
local ModuleRefer = require ('ModuleRefer')
local PlayerGetAutoRewardParameter = require('PlayerGetAutoRewardParameter')
local I18N = require('I18N')
---@class SignInItem : BaseUIComponent
local SignInItem = class('SignInItem', BaseUIComponent)

---@class SignInItemData
---@field dayIndex number
---@field isCanGet boolean
---@field isGot boolean
---@field itemGroupId number
---@field rewardId number

function SignInItem:OnCreate()
    self.btnDay1 = self:Button('', Delegate.GetOrCreate(self, self.OnBtnDay1Clicked))
    self.goStatusCollect = self:GameObject('p_status_collect')
    self.compItem = self:LuaBaseComponent("child_item_standard_s")
    self.goStatusSigned = self:GameObject('p_status_signed')
    self.textDay = self:Text('p_text_day')
end

---@param param SignInItemData
function SignInItem:OnFeedData(param)
    self.textDay.text = I18N.Get(("sign_in_day%d"):format(param.dayIndex))
    self.goStatusCollect:SetActive(param.isCanGet)
    self.goStatusSigned:SetActive(param.isGot)
    self.rewardId = param.rewardId
    local items = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(param.itemGroupId)
    if items and #items > 0 then
        local item = items[1]
        self.itemId = item.configCell:Id()
        local itemData = {
            configCell = item.configCell,
            showTips = false,
            count = item.count,
        }
        if param.isCanGet then
            itemData.onClick = function() self:OnBtnDay1Clicked() end
        end
        self.compItem:FeedData(itemData)
    end
    self.isCanGet = param.isCanGet
end

function SignInItem:OnBtnDay1Clicked(args)
    if self.isCanGet then
        local param = PlayerGetAutoRewardParameter.new()
        param.args.Op.ConfigId = self.rewardId
        param:SendWithFullScreenLock()
    end
end


return SignInItem
