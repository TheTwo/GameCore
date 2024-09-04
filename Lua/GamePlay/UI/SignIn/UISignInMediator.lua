local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local UISignInMediator = class('UISignInMediator',BaseUIMediator)

function UISignInMediator:OnCreate()
    self.compChildActivitySign = self:LuaObject('child_activity_sign')
end

function UISignInMediator:OnOpened(param)
    self.compChildActivitySign:FeedData({isShowClose = true})
    self.popIds = (param or {}).popIds
end

function UISignInMediator:OnClose(param)
    if self.popIds then
        ModuleRefer.LoginPopupModule:OnPopupShown(self.popIds)
    end
end

return UISignInMediator