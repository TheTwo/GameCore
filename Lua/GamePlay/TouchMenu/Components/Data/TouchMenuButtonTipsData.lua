---@class TouchMenuButtonTipsData
---@field new fun(icon, content):TouchMenuButtonTipsData
local TouchMenuButtonTipsData = sealedClass("TouchMenuButtonTipsData")

---@param icon string|fun():string
---@param content string|fun():string
---@param tips string|fun():string
function TouchMenuButtonTipsData:ctor(icon, content, tips)
    self.icon = icon
    self.content = content
    self.tips = tips
    
    self.dynamicIcon = type(icon) == "function"
    self.dynamicContent = type(content) == "function"
    self.dynamicTips = type(tips) == "function"
end

---@return TouchMenuButtonTipsData
function TouchMenuButtonTipsData:SetIcon(icon)
    self.icon = icon
    self.dynamicIcon = type(icon) == "function"
    return self
end

function TouchMenuButtonTipsData:ShowIcon()
    return type(self.icon) ~= "nil"
end

---@return TouchMenuButtonTipsData
function TouchMenuButtonTipsData:SetContent(content)
    self.content = content
    self.dynamicContent = type(content) == "function"
    return self
end

function TouchMenuButtonTipsData:SetIconColor(color)
    self.iconColor = color
    return self
end

---@param tips string
function TouchMenuButtonTipsData:SetTips(tips)
    self.tips = tips
    self.dynamicTips = type(tips) == "function"
    return self
end

return TouchMenuButtonTipsData