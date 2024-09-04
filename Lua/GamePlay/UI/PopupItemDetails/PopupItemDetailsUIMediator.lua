local BaseUIMediator = require ('BaseUIMediator')
local PopupItemDetailsUIMediator = class('PopupItemDetailsUIMediator', BaseUIMediator)

function PopupItemDetailsUIMediator:OnCreate()
    ---@type CommonItemDetails
    self.compChildTipsItem = self:LuaBaseComponent('child_tips_item')
    self._closeCallback = nil
end

---@param param CommonItemDetailsParameter
function PopupItemDetailsUIMediator:OnShow(param)
    self._closeCallback = nil
    if not param then
        return
    end
    self._closeCallback = param.closeCallBack
    self.compChildTipsItem:FeedData(param)
end

function PopupItemDetailsUIMediator:OnHide(param)
    if self._closeCallback then
        self._closeCallback()
    end
    self._closeCallback = nil
end

return PopupItemDetailsUIMediator