local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local RPPType = require("RPPType")
local ConfigRefer = require("ConfigRefer")
local UIRaisePowerPopupMediatorContentProvider = require('UIRaisePowerPopupMediatorContentProvider')
---@class UIRaisePowerPopupMediatorContentProvider_CatchPet
---@field new fun():UIRaisePowerPopupMediatorContentProvider_CatchPet
local UIRaisePowerPopupMediatorContentProvider_CatchPet = class('UIRaisePowerPopupMediatorContentProvider_CatchPet',UIRaisePowerPopupMediatorContentProvider)

function UIRaisePowerPopupMediatorContentProvider_CatchPet:ctor()
    UIRaisePowerPopupMediatorContentProvider.ctor(self)
end

function UIRaisePowerPopupMediatorContentProvider_CatchPet:GetTitle()
    return I18N.Get("rpp_title")    
end

function UIRaisePowerPopupMediatorContentProvider_CatchPet:GetHintText()
    return I18N.Get("rpp_des_pet")
end

return UIRaisePowerPopupMediatorContentProvider_CatchPet