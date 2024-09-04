---@class LegoUIPage_SpecialData
---@field new fun(image, toggleI18N, buttonI18N, onClick):LegoUIPage_SpecialData
local LegoUIPage_SpecialData = class("LegoUIPage_SpecialData")

function LegoUIPage_SpecialData:ctor(image, toggleI18N, buttonI18N, onClick)
    self.image = image
    self.toggleI18N = toggleI18N
    self.buttonI18N = buttonI18N
    self.onClick = onClick
end

return LegoUIPage_SpecialData