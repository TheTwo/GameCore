---@class TouchMenuPollutedData
---@field new fun(content:string,icon:string|nil):TouchMenuPollutedData
local TouchMenuPollutedData = class("TouchMenuPollutedData")

---@param icon string
---@param content string
function TouchMenuPollutedData:ctor(content, icon)
    self.content = content
    self.icon = icon or "sp_icon_ban_01"
end

---@return TouchMenuPollutedData
function TouchMenuPollutedData:SetIcon(icon)
    self.icon = icon
    return self
end

---@return TouchMenuPollutedData
function TouchMenuPollutedData:SetContent(content)
    self.content = content
    return self
end

return TouchMenuPollutedData