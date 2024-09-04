local BaseUIMediator = require('BaseUIMediator')
---@class UIGameBgMediator : BaseUIMediator
local UIGameBgMediator = class('UIGameBgMediator', BaseUIMediator)

function UIGameBgMediator:OnCreate()
    local img = self:Image('loading_image')
    local imgRect = img.rectTransform
    require('UIHelper').ResizeFullFitImageSize(img,imgRect.sizeDelta.x,imgRect.sizeDelta.y)
end

function UIGameBgMediator:OnClose(param)
    local a = 11
end

return UIGameBgMediator