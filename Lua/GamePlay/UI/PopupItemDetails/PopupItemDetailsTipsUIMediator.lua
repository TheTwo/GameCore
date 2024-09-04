local BaseUIMediator = require ('BaseUIMediator')
local PopupItemDetailsTipsUIMediator = class('PopupItemDetailsTipsUIMediator', BaseUIMediator)

function PopupItemDetailsTipsUIMediator:OnCreate()
    ---@type CommonItemDetails
    self.compChildTipsItem = self:LuaBaseComponent('child_tips_item_s')
    self._closeCallback = nil
end

---@param param CommonItemDetailsParameter
function PopupItemDetailsTipsUIMediator:OnShow(param)
    self._closeCallback = nil
    if not param then
        return
    end
    self._closeCallback = param.closeCallBack
    self.compChildTipsItem:FeedData(param)
end

function PopupItemDetailsTipsUIMediator:OnHide(param)
    if self._closeCallback then
        self._closeCallback()
    end
    self._closeCallback = nil
end

return PopupItemDetailsTipsUIMediator