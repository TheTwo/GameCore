local BaseUIComponent = require ('BaseUIComponent')
---@class SignInGroup : BaseUIComponent
local SignInGroup = class('SignInGroup', BaseUIComponent)

function SignInGroup:OnCreate()
    self.compDay1 = self:LuaObject('p_btn_day_1')
    self.compDay2 = self:LuaObject('p_btn_day_2')
    self.compDay3 = self:LuaObject('p_btn_day_3')
    self.compDay4 = self:LuaObject('p_btn_day_4')
    self.compDay5 = self:LuaObject('p_btn_day_5')
    self.compDay6 = self:LuaObject('p_btn_day_6')
    self.compDay7 = self:LuaObject('p_btn_day_7')
    self.compDay8 = self:LuaObject('p_btn_day_8')
    self.items = {self.compDay1, self.compDay2, self.compDay3, self.compDay4, self.compDay5, self.compDay6, self.compDay7, self.compDay8}
end

---@param param SignInItemData[]
function SignInGroup:OnFeedData(param)
    for i = 1, #self.items do
        self.items[i]:FeedData(param[i])
    end
end

return SignInGroup