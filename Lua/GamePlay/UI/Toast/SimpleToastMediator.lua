---scene: scene_toast
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local LuaReusedComponentPool = require('LuaReusedComponentPool')

---@class SimpleToastMediator : BaseUIMediator
local SimpleToastMediator = class('SimpleToastMediator', BaseUIMediator)

local DURATION = 3

function SimpleToastMediator:ctor()
    ---@type number
    self.openTime = 0
end

function SimpleToastMediator:OnCreate()
    self.textText = self:LuaObject('ui_emoji_text')
    self.go = self:GameObject('layout')

    self.trans = self:Transform("")
end

function SimpleToastMediator:OnOpened(param)
    self.textText:FeedData({text = param.msg})

    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function SimpleToastMediator:OnClose(param)
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))

    self.trans:DOKill()
end

---@param delta number
function SimpleToastMediator:Tick(delta)
    self.openTime = self.openTime + delta
    if self.openTime > DURATION then
        g_Game.UIManager:Close(self.runtimeId)
    end
end

return SimpleToastMediator
