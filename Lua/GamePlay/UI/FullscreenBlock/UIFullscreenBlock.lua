local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class UIFullScreenBlock : BaseUIMediator
local UIFullscreenBlock = class('UIFullScreenBlock', BaseUIMediator)

function UIFullscreenBlock:ctor()

end

function UIFullscreenBlock:OnShow(param)
    --g_Game.UIManager.inputEnabled = false
end

function UIFullscreenBlock:OnHide(param)
    --g_Game.UIManager.inputEnabled = true
end

function UIFullscreenBlock:OnOpened(param)
end

function UIFullscreenBlock:OnClose(param)
end


return UIFullscreenBlock
